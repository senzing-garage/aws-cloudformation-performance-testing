#!/usr/bin/env python3
"""
Producer watchdog for a perf stack: detects stream-producer tasks that stop making progress (e.g. the
2026-09-29 EOFError hang on a truncated S3 gzip stream) and restarts them from just before the last line sent.

  python3 watch_producers.py STACK [--dry-run] [--interval 120] [--stall 600] [--overlap 1000]

Every interval: for each RUNNING producer task, read its latest Monitor line from CloudWatch
(/senzing/perf-prov/STACK, stream job/producer/<task id>) and its SENZING_RECORD_MIN/MAX overrides.
A task is STALLED when output_counter_line_number_in_file hasn't advanced for --stall seconds while it is
below its RECORD_MAX (or its log shows EOFError/Traceback). Then (unless --dry-run): stop it and run a
replacement with RECORD_MIN = max(orig MIN, last_output_line - overlap), same RECORD_MAX, same task def and
network as the Lambda runner. Exits when no producer is RUNNING. Prints one status line per task per interval.
"""
import argparse, json, re, subprocess, sys, time
from datetime import datetime, timezone

def aws(*a, ok_empty=True):
    try:
        out = subprocess.check_output(["aws", *a, "--output", "json"], stderr=subprocess.PIPE, timeout=120).strip()
        return json.loads(out) if out else {}
    except subprocess.CalledProcessError as e:
        print(f"  ! aws {' '.join(a[:2])} failed: {e.stderr.decode()[:200]}", flush=True)
        return None
    except Exception as e:
        print(f"  ! aws {' '.join(a[:2])} error: {e}", flush=True)
        return None

def now(): return datetime.now(timezone.utc).strftime("%H:%M:%S")

MON = re.compile(r"Monitor: (\{.*\})")

def last_monitor(lg, stream):
    r = aws("logs", "get-log-events", "--log-group-name", lg, "--log-stream-name", stream, "--limit", "40", "--no-start-from-head")
    if not r: return None, False, False
    mon, bad, exited = None, False, False
    for e in r.get("events", []):
        m = e["message"]
        if "EOFError" in m or "Traceback" in m: bad = True
        if " Exit " in m or "Monitoring halted" in m: exited = True
        g = MON.search(m)
        if g:
            try: mon = json.loads(g.group(1))
            except ValueError: pass
    return mon, bad, exited

def overrides(task):
    env = {}
    for co in task.get("overrides", {}).get("containerOverrides", []):
        for kv in co.get("environment", []): env[kv["name"]] = kv["value"]
    return int(env.get("SENZING_RECORD_MIN", -1)), int(env.get("SENZING_RECORD_MAX", -1))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stack"); ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--interval", type=int, default=120); ap.add_argument("--stall", type=int, default=600)
    ap.add_argument("--overlap", type=int, default=1000)
    ap.add_argument("--skip-stall", type=int, default=2700,
                    help="stall limit while a producer is still skipping to its RECORD_MIN (Monitor shows line == MIN, sent == 0)")
    a = ap.parse_args()
    S, C, LG = a.stack, f"{a.stack}-cluster", f"/senzing/perf-prov/{a.stack}"
    fam = f"{S}-task-definition-stream-producer"
    def net_ids():
        res = aws("cloudformation", "describe-stack-resources", "--stack-name", S)
        phys = {r["LogicalResourceId"]: r.get("PhysicalResourceId") for r in (res or {}).get("StackResources", [])}
        return phys.get("Ec2SecurityGroupLambdaRunner"), [phys.get("Ec2SubnetPrivate1"), phys.get("Ec2SubnetPrivate2")]
    sg, subnets = net_ids()
    print(f"{now()} watching {fam}; restart net sg={sg} subnets={subnets}; dry_run={a.dry_run}", flush=True)
    progress = {}   # task_id -> (last_output_line, last_change_epoch)
    restarted = set()
    while True:
        lt = aws("ecs", "list-tasks", "--cluster", C, "--family", fam, "--desired-status", "RUNNING")
        if lt is None: time.sleep(a.interval); continue
        arns = lt.get("taskArns", [])
        q = aws("sqs", "get-queue-attributes", "--queue-url",
                f"https://sqs.us-east-2.amazonaws.com/511635769224/{S}-sqs-input", "--attribute-names", "ApproximateNumberOfMessages")
        depth = (q or {}).get("Attributes", {}).get("ApproximateNumberOfMessages", "?")
        print(f"{now()} producers={len(arns)} queue={depth}", flush=True)
        if not arns:
            print(f"{now()} NO PRODUCERS RUNNING - done. restarted={sorted(restarted) or 'none'}", flush=True); return
        tasks = (aws("ecs", "describe-tasks", "--cluster", C, "--tasks", *arns) or {}).get("tasks", [])
        for t in tasks:
            tid = t["taskArn"].split("/")[-1]; mn, mx = overrides(t)
            mon, bad, exited = last_monitor(LG, f"job/producer/{tid}")
            out_line = (mon or {}).get("output_counter_line_number_in_file"); rate = (mon or {}).get("output_counter_rate_interval")
            in_line = (mon or {}).get("input_counter_line_number_in_file")
            # progress = the furthest line READ (it advances while a high-range producer skips to its RECORD_MIN,
            # and froze in the 09-29 hang); resume point = the last line SENT.
            pos = max(x for x in (in_line, out_line, -1) if x is not None)
            sent = (mon or {}).get("output_counter_total")
            nowe = time.time()
            if pos >= 0:
                prev = progress.get(tid)
                if prev is None or pos > prev[0]: progress[tid] = (pos, nowe)
            last_pos, since = progress.get(tid, (None, nowe))
            idle = int(nowe - since)
            print(f"   {tid[:12]} range={mn}-{mx} in_line={in_line} out_line={out_line} sent={sent} rate={rate}/s idle={idle}s"
                  f"{' [skipping]' if (sent in (0, None)) else ''}"
                  f"{' EOF/TRACEBACK' if bad else ''}{' (exit logged)' if exited else ''}", flush=True)
            # While skipping to RECORD_MIN the Monitor line stays at MIN with sent == 0 (observed 10-05), so it looks idle;
            # give that phase a much longer limit (measured skip ~2.7 min per 40M lines).
            skipping = (sent in (0, None)) and (last_pos is None or last_pos <= mn + 1)
            limit = a.skip_stall if skipping else a.stall
            stalled = (bad and not exited) or (last_pos is not None and idle >= limit and last_pos < mx and not exited)
            if stalled and tid not in restarted:
                new_min = max(mn, (out_line or mn) - a.overlap)
                print(f"   >>> STALLED {tid[:12]}: read line {last_pos}, last sent line {out_line}, idle {idle}s. "
                      f"{'WOULD restart' if a.dry_run else 'Restarting'} with RECORD_MIN={new_min} RECORD_MAX={mx}", flush=True)
                if a.dry_run: continue
                if not sg or not all(subnets): sg, subnets = net_ids()
                if not sg or not all(subnets):
                    print(f"   >>> cannot restart: network ids unresolved (sg={sg} subnets={subnets})", flush=True); continue
                aws("ecs", "stop-task", "--cluster", C, "--task", t["taskArn"], "--reason",
                    f"watchdog: stalled at line {last_pos} for {idle}s; restarting from {new_min}")
                ov = {"containerOverrides": [{"name": "producer", "environment": [
                        {"name": "SENZING_RECORD_MIN", "value": str(new_min)}, {"name": "SENZING_RECORD_MAX", "value": str(mx)}]}]}
                net = {"awsvpcConfiguration": {"assignPublicIp": "DISABLED", "securityGroups": [sg], "subnets": subnets}}
                r = aws("ecs", "run-task", "--cluster", C, "--task-definition", t["taskDefinitionArn"], "--launch-type", "FARGATE",
                        "--platform-version", "1.4.0", "--network-configuration", json.dumps(net), "--overrides", json.dumps(ov),
                        "--count", "1")
                new = [x["taskArn"].split("/")[-1] for x in (r or {}).get("tasks", [])]
                print(f"   >>> replacement: {new or 'FAILED: ' + json.dumps((r or {}).get('failures'))}", flush=True)
                restarted.add(tid)
        time.sleep(a.interval)

if __name__ == "__main__":
    main()
