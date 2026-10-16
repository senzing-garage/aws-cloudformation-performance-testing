#!/usr/bin/env python3
"""
Run watcher for a perf stack (load + redo phase). Every --interval s prints input/inflight/DLQ and consumer/redoer counts
(with maxima); every --scan-every intervals runs CloudWatch Logs Insights over the run window:
  * term counts: SENZ1019 / "does not exist" (GDEV-4738), OKEY guard / SENZ0010 / deadletter (GDEV-4734), CORRUPTION_FOUND,
    INFINITE loops, 55P03, deadlocks, the GDEV-4734 guard/heal/repair/abandon lines, and the 4.4.3.26287
    REPAIR_ENTITY re-drive and SENZ0010 'observed entity locklist' lines
  * GDEV-4738 FEATURES blob effectiveness: resEntFeaturesServedFromBlob / ...FromEKey (cumulative per process -> max per
    stream, summed)
  * a catch-all of OKEY / repair / heal message shapes
Stops when the input is drained and the fleet has been quiet (consumers<=1, redoers<=1) for 2 checks, or at --cap-h.

  python3 scripts/watch_run.py STACK START_ISO_UTC [--interval 900] [--scan-every 4] [--cap-h 20] [--region us-east-2]
"""
import argparse, json, subprocess, time
from datetime import datetime, timezone

ap = argparse.ArgumentParser()
ap.add_argument("stack"); ap.add_argument("start")
ap.add_argument("--interval", type=int, default=900); ap.add_argument("--scan-every", type=int, default=4)
ap.add_argument("--cap-h", type=float, default=20); ap.add_argument("--region", default="us-east-2")
a = ap.parse_args()
S, C, LG = a.stack, f"{a.stack}-cluster", f"/senzing/perf-prov/{a.stack}"
T0 = int(datetime.fromisoformat(a.start).replace(tzinfo=timezone.utc).timestamp())

def aws(*args):
    try:
        out = subprocess.check_output(["aws", *args, "--region", a.region, "--output", "json"],
                                      stderr=subprocess.DEVNULL, timeout=120).strip()
        return json.loads(out) if out else {}
    except Exception:
        return None

def now(): return datetime.now(timezone.utc).strftime("%H:%M")

TERMS = {"senz1019": "SENZ1019", "not_exist": "does not exist",
         "guard": "OKEY FLUSH ASSERTION FAILED", "senz10": "SENZ0010", "dlq_log": "Sending to deadletter",
         "healed": "AMBIGUOUS-BRIDGE ORPHAN HEALED", "repaired": "RES_ENT_OKEY ORPHAN REPAIRED", "abandon": "ABANDONING a redo",
         "okey44": "OKEY ORPHAN PREVENTED", "redrive": "hit a retryable failure; re-driving",
         "obs_lock": "observed entity locklist", "corrupt": "CORRUPTION_FOUND", "loop": "INFINITE RESOLUTION LOOP",
         "lock_to": "55P03", "deadlk": "deadlock detected"}

def run_query(qs, limit=1000):
    q = aws("logs", "start-query", "--log-group-name", LG, "--start-time", str(T0), "--end-time", str(int(time.time())),
            "--limit", str(limit), "--query-string", qs)
    if not q: return None
    for _ in range(72):
        r = aws("logs", "get-query-results", "--query-id", q["queryId"])
        if r and r.get("status") == "Complete":
            return [{x["field"]: x["value"] for x in row} for row in r["results"]]
        if r and r.get("status") in ("Failed", "Cancelled", "Timeout"): return None
        time.sleep(5)
    return None

def scan():
    stats = ", ".join(f'sum(strcontains(@message,"{v}")) as {k}' for k, v in TERMS.items())
    r = run_query(f"stats {stats}")
    print("  logs:", " ".join(f"{k}={v}" for k, v in (r[0].items() if r else [])) if r is not None else "QUERY FAILED", flush=True)
    r = run_query('filter @message like /resEntFeaturesServedFrom/ '
                  '| parse @message /"resEntFeaturesServedFromBlob":\\s*(?<blob>\\d+)/ '
                  '| parse @message /"resEntFeaturesServedFromEKey":\\s*(?<ekey>\\d+)/ '
                  '| stats max(blob) as b, max(ekey) as e by @logStream')
    if r is None: print("  FEATURES stats: QUERY FAILED", flush=True)
    else:
        b = sum(float(x.get("b") or 0) for x in r); e = sum(float(x.get("e") or 0) for x in r)
        print(f"  FEATURES (sum of per-process max): servedFromBlob={int(b):,} servedFromEKey={int(e):,} streams={len(r)}", flush=True)
    r = run_query('filter @message like /SENZ1019|does not exist|OKEY|[Rr]epair|REPAIR|[Hh]eal|HEAL/ and @message not like /"workload"/ '
                  '| parse @message /(?<shape>[A-Z_ ]{6,60})/ | stats count(*) as n by shape | sort n desc', limit=20)
    if r is None: print("  line shapes: QUERY FAILED", flush=True)
    elif not r: print("  line shapes: none", flush=True)
    else: print("  line shapes:", "; ".join(f'{x.get("shape","?").strip()}×{x.get("n")}' for x in r[:8]), flush=True)

def qattr(name):
    r = aws("sqs", "get-queue-url", "--queue-name", name)
    url = (r or {}).get("QueueUrl")
    if not url: return None, None
    r = aws("sqs", "get-queue-attributes", "--queue-url", url, "--attribute-names",
            "ApproximateNumberOfMessages", "ApproximateNumberOfMessagesNotVisible")
    at = (r or {}).get("Attributes", {})
    return at.get("ApproximateNumberOfMessages"), at.get("ApproximateNumberOfMessagesNotVisible")

maxc = maxr = 0; i = 0; drained = False; quiet = 0
while True:
    vis, inf = qattr(f"{S}-sqs-input"); dlq, _ = qattr(f"{S}-sqs-dead-letter")
    sv = aws("ecs", "describe-services", "--cluster", C, "--services", "consumer", "redoer")
    cnt = {s["serviceName"]: s["runningCount"] for s in (sv or {}).get("services", [])}
    cc, rr = cnt.get("consumer"), cnt.get("redoer")
    maxc = max(maxc, cc or 0); maxr = max(maxr, rr or 0)
    print(f"{now()} input={vis} inflight={inf} dlq={dlq} consumers={cc} redoers={rr} (max {maxc}/{maxr})", flush=True)
    if i % a.scan_every == 0: scan()
    i += 1
    if not drained and vis == "0" and inf == "0":
        drained = True; print(f"INPUT DRAINED {now()}", flush=True); scan()
    if drained and cc is not None and rr is not None and cc <= 1 and rr <= 1: quiet += 1
    else: quiet = 0
    if quiet >= 2: print(f"REDO PHASE QUIET {now()}", flush=True); scan(); break
    if time.time() > T0 + a.cap_h * 3600: print(f"TIME CAP {now()}", flush=True); scan(); break
    time.sleep(a.interval)
