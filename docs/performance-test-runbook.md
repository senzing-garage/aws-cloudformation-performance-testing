# Performance-test runbook (Aurora PostgreSQL)

End-to-end steps for a Senzing load/perf test on an AWS CloudFormation stack, in
the order you actually do them:

**launch → connect → setup+baseline → run & watch → drain gate → capture → pull back → scan logs → record.**

> Stack launch itself is GUI-driven and already documented in the
> [top-level README](../README.md#launch-aws-cloudformation). This runbook picks
> up **after** the stack is up and focuses on measurement.

> **Secrets:** every credential comes from the **CloudFormation stack Outputs
> tab** (or Secrets Manager) at run time. Never paste real passwords, tokens, or
> cluster endpoints into this file or any committed file.

---

## 0. What you'll need

| Thing | Where to get it (GUI) |
|---|---|
| SSH user / password | Sshd ECS task env → `SshUsername`, `SshPassword` |
| sshd host | Sshd ECS task's public IP → `Host` |
| DB host (writer) | Stack **Outputs** → `DatabaseHostCore` |
| DB name / user / port | Stack **Outputs** → `DatabaseName`, `DatabaseUsername`, `DatabasePortCore` |
| DB password | Stack **Outputs** → `DatabasePassword` |
| App log group | CloudWatch → Logs → search for your stack name |

SQL helpers live in [`scripts/aurora-pg/`](../scripts/aurora-pg/).

---

## 1. Launch the stack

Follow the [README launch steps](../README.md#launch-aws-cloudformation). Perf-relevant parameters:

- **RecordMax** — size of the load (`1M`…`100M`).
- **EnableEntityLockModeAdvisory** — adds `"ER": {"ENTITY_LOCK_MODE": "ADVISORY"}`.
- **EnableReadOnlyConnection** / **ReadOnlyConnections** — Aurora reader replica for `LIB_FEAT` reads.

> **Not a parameter:** the DB instance class is hardcoded in the template
> (`DBInstanceClass: db.r6i.8xlarge`, two places). For a bigger box (e.g. 100M on
> `db.r6i.24xlarge`) edit the template before uploading. The Senzing **version**
> is also not a parameter — it's the `:staging` / pinned image tags in
> `Mappings → Images`.

Record every non-default parameter — it goes in the results folder name and notes.

---

## 2. Connect to the shell and the database

```bash
# --- on your LAPTOP: reach the sshd container (values from stack Outputs) ------
export SENZING_SSHD_HOST=<Host>
export SENZING_SSHD_USERNAME=<SshUsername>
ssh ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}      # paste SshPassword at the prompt
```

```bash
# --- on the SSHD HOST: point psql at the DB --------------------------------
export SENZING_DATABASE_HOST_CORE=<DatabaseHostCore>
export SENZING_DATABASE_NAME=<DatabaseName>            # e.g. G2
export SENZING_DATABASE_USERNAME=<DatabaseUsername>    # e.g. senzing
export SENZING_DATABASE_PASSWORD=<DatabasePassword>                   # <-- so psql -f NEVER prompts

# One reusable handle for every step below:
PG="psql -h ${SENZING_DATABASE_HOST_CORE} -p 5432 -U ${SENZING_DATABASE_USERNAME} -d ${SENZING_DATABASE_NAME}"
$PG -c 'select 1'                                      # connectivity check
```

> With **`PGPASSWORD` exported**, `psql -f` runs without a password prompt — you
> do **not** need to `echo` the password anywhere. If you see `Password for user`
> prompts, `PGPASSWORD` isn't set in this shell; re-export it.

<details>
<summary>IAM-authentication variant (token instead of password)</summary>

```bash
sudo apt update && sudo apt install -y awscli
export $(cat /proc/1/environ | tr '\0' '\n' | grep -E '^(AWS_|DB_)' | xargs)
export PGPASSWORD=$(aws rds generate-db-auth-token \
    --hostname "$DB_ENDPOINT" --port "$DB_PORT" \
    --region "$AWS_REGION" --username senzing)
PG="psql \"host=$DB_ENDPOINT port=$DB_PORT dbname=$DB_NAME user=senzing sslmode=require\""
```
</details>

---

## 3. Copy the SQL helpers onto the shell host

`psql -f` reads files local to where psql runs (the sshd host), so copy them over
once per run (from the repo root on your laptop):

```bash
command scp scripts/aurora-pg/*.sql ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}:/tmp/
```

> `command scp` bypasses a possible `alias scp='noglob scp'` (common in zsh /
> oh-my-zsh), which stops the shell expanding `*.sql` and makes scp fail with
> `stat local "scripts/aurora-pg/*.sql": No such file or directory`.

| Script | When | Purpose |
|---|---|---|
| `00-setup.sql` | once per DB | create `pg_stat_statements`, `perf` schema + snapshot function |
| `10-baseline.sql` | **before** the load | baseline snapshot of the counters |
| `progress-live.sql` | during the load (loop) | instant catalog-only progress + churn + horizon watchdog |
| `drain-check.sql` | after loader reports done | drain gate — is the queue truly empty? |
| `20-final.sql` | at capture | final snapshot; prints the deltas |
| `validate.sql` | at capture | orphan / dangling-key integrity checks (expect 0 rows) |
| `exports.sql` | at capture | write detail CSVs to `/tmp` |
| `final-capture.sql` | at capture (after `20-final`) | exact counts + throughput/erpm |
| `progress.sql` | 25M only ⚠️ | old `count(*)` monitor — hangs on 100M under load; prefer `progress-live.sql` |

---

## 4. Before the load — setup + baseline

Run these **before you start the loaders** so the delta covers the whole run:

```bash
$PG -f /tmp/00-setup.sql      # once per database (needs pg_stat_statements preloaded)
$PG -f /tmp/10-baseline.sql   # LAST thing before starting the loaders
```

`10-baseline.sql` is idempotent (it clears any prior snapshot). If you baseline
mid-load, the eventual delta only covers the tail — note the % loaded if so.

---

## 5. During the load — watch progress

Start the loaders, then loop **`progress-live.sql`** every 30–60s (ideally a
second psql session). It's catalog/stats-only — instant, holds no snapshot,
doesn't pollute the harness deltas:

```bash
echo $SENZING_DATABASE_PASSWORD
$PG -f /tmp/progress-live.sql
```

Headline progress = `dsrc_record.cum_ins` (exact for the insert-only table).
Watch `sys_eval_queue.est_net_depth` for the drain trend and the horizon watchdog.

> ⚠️ **Do NOT use the old `count(*)`-based `progress.sql` on a 100M / loaded DB.**
> Under `enable_seqscan=0` + a churning `sys_eval_queue` those scans degrade
> catastrophically (observed 47s → 114s → a 31-min hang), pin the vacuum horizon,
> and contaminate the harness deltas. It's fine only for small (25M) runs.

---

## 6. Drain gate — is the load *actually* done?

Inserts finishing ≠ done: resolution is async and `sys_eval_queue` keeps churning
after the last `addRecord`. Run **`drain-check.sql`** until ALL hold:

```bash
echo $SENZING_DATABASE_PASSWORD
$PG -f /tmp/drain-check.sql
```

- (a) the loader's own done signal is in;
- (b) ~0 active Senzing client backends;
- (c) `cum_ins`/`cum_del` flat and non-decreasing across two polls;
- (d) the queue EXISTS-probe returns `f` on ≥3 consecutive polls.

Only when all four hold do you proceed to capture.

---

## 7. Capture the results (run in THIS order)

```bash

# 1) close the measured window — deltas to a file (headline IO/txn result)
echo $SENZING_DATABASE_PASSWORD
$PG -f /tmp/20-final.sql > /tmp/final-deltas.txt 2>&1

# 2) data-integrity checks — both must return 0 rows
$PG -f /tmp/validate.sql

# 3) detail CSVs to /tmp
$PG -f /tmp/exports.sql

# 4) exact end-of-run counts + throughput/erpm (AFTER 20-final, as the table owner)
$PG -f /tmp/final-capture.sql > /tmp/final-capture.txt 2>&1
```

- `20-final.sql` — run window, FACT headline (logical/physical block reads, WAL
  bytes, txns, tuple ins/upd/del), scalar deltas, top statements, per-table
  activity. Safe to re-run (re-snapshots `final`). On Aurora `wal_bytes` is blank
  (use CloudWatch `VolumeWriteIOPs`).
- `final-capture.sql` — the exact counts + erpm for the report. It VACUUMs first
  and forces a heap seq scan, so it must run **after** `20-final.sql` (outside the
  measured window) and **as the Senzing table owner** (or it errors on the VACUUM
  ownership check — that's intentional, so a silently-skipped VACUUM can't hide).

---

## 8. Pull the results back to your laptop

```bash
echo $SENZING_SSHD_PASSWORD
RUN=results/$(date +%Y%m%d)-<recordmax>-<topology>-single-senzing-<version>/data
mkdir -p "$RUN"
for f in dsrc_record match_key_ent match_key_rel pg_stat_io pg_stat_statements; do
  scp ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}:/tmp/$f.csv "$RUN"/
done
# the .txt reports (not .csv):
scp ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}:/tmp/final-deltas.txt  "$RUN"/   # IO/txn deltas
scp ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}:/tmp/final-capture.txt "$RUN"/   # exact counts + erpm
```

(scp will prompt for the SSH password — paste `SshPassword`.)

---

## 9. Scan CloudWatch logs for errors

In the CloudWatch **Logs Insights** console, select your stack's app log group
and run (adjust the time range to your run window):

```
fields @timestamp, @message, @logStream
| filter @message like /(?i)(error|except)/
| filter @message not like /(?i)(current transaction is aborted, commands ignored until end of transaction block)/
| sort @timestamp desc
| limit 7000
```

Terms worth a pass each (expect zero unless noted): `SENZ0086`,
`UNHANDLED DATABASE ERROR`, `CORRUPTION_FOUND`, `RetryTimeout`, `FAILED`,
`INFINITE`, `MISSING_RES_ENT_AND_OKEY`, `OKEY ORPHAN PREVENTED`,
`ExclusiveLock on advisory lock`, `still`, `stolen`, `cancel`,
`another command is already in progress`.

> **`OKEY ORPHAN PREVENTED`** (FAQ `oent-swap-okey-split-commit-regression`) is the
> 4.4 OKEY-split commit regression — under concurrency an entity's OKEY `add` can be
> dropped when the target entity is destroyed mid-swap, and the redo self-heal may
> not converge, leaving records unresolved (`OBS_ENT` with no `RES_ENT_OKEY`). If you
> see it, run [`scripts/aurora-pg/unresolved-forensics.sql`](../scripts/aurora-pg/unresolved-forensics.sql)
> against the offending `OBS_ENT_ID`s. `ExclusiveLock on advisory lock` (`55P03` lock
> timeout on `pg_advisory_lock`) is the `ENTITY_LOCK_MODE=ADVISORY` contention that
> triggers those races at scale.

CLI equivalent (quick count):

```bash
aws logs filter-log-events \
  --log-group-name <your-app-log-group> \
  --filter-pattern "CORRUPTION_FOUND" \
  --start-time $(date -v-1H +%s)000 \
  --region <your-region>
```

---

## 10. Record the results

Create `results/<YYYYMMDD>-<recordmax>-<topology>-senzing-<version>/` and capture:

- load-rate / erpm summary — from `final-capture.txt`,
- IO / transaction deltas — from `final-deltas.txt`,
- exported CSVs → `data/`,
- non-default stack parameters and any anomalies (autovacuum, failover, log errors),
- update [`results/AWS-perf-results-table.md`](../results/AWS-perf-results-table.md).
