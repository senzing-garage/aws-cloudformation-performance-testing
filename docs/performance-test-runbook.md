# Performance-test runbook (Aurora PostgreSQL)

End-to-end steps for running a Senzing load/perf test on an AWS CloudFormation
stack and gathering the numbers: launch → connect → watch progress → capture
IO/transaction metrics → validate → export → scan logs → record results.

> Stack launch itself is GUI-driven and already documented in the
> [top-level README](../README.md#launch-aws-cloudformation). This runbook
> picks up **after** the stack is up and focuses on measurement — the part that
> used to live only in personal notes.

> **Secrets:** every credential below comes from the **CloudFormation stack
> Outputs tab** (or Secrets Manager) at run time. Never paste real passwords,
> tokens, or cluster endpoints into this file or any committed file.

---

## 0. What you'll need

| Thing | Where to get it (GUI) |
|---|---|
| SSH password | Sshd ECS task's env vars → `SshUsername`, `SshPassword` |
| sshd host | Sshd ECS task's public IP → `Host`  |
| DB host (writer) | Stack **Outputs** → `DatabaseHostCore` |
| DB reader endpoint | Stack **Outputs** → `DatabaseHostReader` (only if read-offload enabled) |
| DB name / user / port | Stack **Outputs** → `DatabaseName`, `DatabaseUsername`, `DatabasePortCore` |
| DB password | Stack **Outputs** → `DatabasePassword` |
| App log group | CloudWatch → Logs → search for your stack name |

The SQL helpers referenced here live in [`scripts/aurora-pg/`](../scripts/aurora-pg/).

---

## 1. Launch the stack

Follow the [README launch steps](../README.md#launch-aws-cloudformation). Note
the perf-relevant parameters on this template:

- **RecordMax** — size of the load (`1M`…`100M`).
- **EnableReadOnlyConnection** / **ReadOnlyConnections** — add an Aurora reader
  replica and route Senzing `LIB_FEAT` reads to it.
- **EnableEntityLockModeAdvisory** — add `"ER": {"ENTITY_LOCK_MODE": "ADVISORY"}`
  to the engine config.

Record every non-default parameter — it goes in the results folder name and notes.

---

## 2. Connect to the shell and the database

Fill these from the stack Outputs (this block is a template — keep real values
out of git):

```bash
# --- from stack Outputs ---
export SENZING_SSHD_HOST=<Host>
export SENZING_SSHD_USERNAME=<SshUsername>
export SENZING_SSHD_PASSWORD=<SshPassword>          # paste at the prompt; don't echo

export SENZING_DATABASE_HOST_CORE=<DatabaseHostCore>
export SENZING_DATABASE_NAME=<DatabaseName>         # e.g. G2
export SENZING_DATABASE_USERNAME=<DatabaseUsername> # e.g. senzing
export PGPASSWORD=<DatabasePassword>                # exported so psql -f won't prompt

# SSH into the sshd container, then connect with psql:
ssh ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}
psql -h ${SENZING_DATABASE_HOST_CORE} -p 5432 -U ${SENZING_DATABASE_USERNAME} -d ${SENZING_DATABASE_NAME}
```

<details>
<summary>IAM-authentication variant (token instead of password)</summary>

```bash
# On the sshd host. DB_* vars are injected into PID 1 by the task definition.
sudo apt update && sudo apt install -y awscli
export $(cat /proc/1/environ | tr '\0' '\n' | grep -E '^(AWS_|DB_)' | xargs)
export PGPASSWORD=$(aws rds generate-db-auth-token \
    --hostname "$DB_ENDPOINT" --port "$DB_PORT" \
    --region "$AWS_REGION" --username senzing)
psql "host=$DB_ENDPOINT port=$DB_PORT dbname=$DB_NAME user=senzing sslmode=require"
```
</details>

---

## 3. Copy the SQL helpers onto the shell host

`psql \i` / `-f` read files local to where psql runs (the sshd host), so copy
the scripts over once per run (from the repo root):

```bash
command scp scripts/aurora-pg/*.sql ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}:/tmp/
```

> `command scp` bypasses a possible `alias scp='noglob scp'` (common in zsh /
> oh-my-zsh setups), which otherwise stops the shell from expanding `*.sql` and
> makes scp fail with `stat local "scripts/aurora-pg/*.sql": No such file or
> directory`. Glob-free alternative: `scp -r scripts/aurora-pg …:/tmp/` — but
> that lands the files at `/tmp/aurora-pg/`, so adjust the `-f` paths below.

| Script | Purpose |
|---|---|
| `00-setup.sql` | once per DB: create `pg_stat_statements`, `perf` schema + snapshot function |
| `10-baseline.sql` | capture counters immediately before the run |
| `20-final.sql` | capture counters after the run and print the deltas |
| `progress.sql` | row counts + throughput (erpm), run repeatedly during the load |
| `validate.sql` | post-run orphan / dangling-key integrity checks |
| `exports.sql` | write detail CSVs to `/tmp` for download |

---

## 4. Capture IO / transaction metrics around the run

This is the honest *snapshot → run → snapshot → subtract* method (full rationale
in [`docs/cloud-db-io-metrics.md`](cloud-db-io-metrics.md)). Run from the sshd
shell with `PGPASSWORD` exported:

```bash
PG="psql -h ${SENZING_DATABASE_HOST_CORE} -p 5432 -U ${SENZING_DATABASE_USERNAME} -d ${SENZING_DATABASE_NAME}"

$PG -f /tmp/00-setup.sql      # once per database (needs pg_stat_statements preloaded — see metrics doc)
$PG -f /tmp/10-baseline.sql   # immediately BEFORE you start the load
#   ... run the Senzing load (and nothing else against this DB) ...
$PG -f /tmp/20-final.sql > /tmp/final-deltas.txt 2>&1   # immediately AFTER the load
```

Redirect the final deltas to a file (above) — it's the headline result and you
do **not** want it living only in terminal scrollback. `20-final.sql` captures
the run window, the FACT-report headline (logical/physical block reads, WAL
bytes, txns, tuple ins/upd/del), all scalar deltas, the top statements (incl.
per-statement WAL bytes), and per-table activity. It is safe to re-run (it
re-snapshots `final`); on Aurora `wal_bytes` is blank (use `VolumeWriteIOPs`).

`scp` `final-deltas.txt` back with the CSVs (Step 7), then paste it into the run
README's "Database IO / transaction deltas" section.

---

## 5. Watch progress during the load

Re-run every few minutes to eyeball throughput and queue depth:

```bash
$PG -f /tmp/progress.sql
```

---

## 6. Validate data integrity (after the load)

Both queries must return **zero** rows:

```bash
$PG -f /tmp/validate.sql
```

---

## 7. Export detail CSVs and pull them back

On the shell, write the CSVs to `/tmp`:

```bash
$PG -f /tmp/exports.sql
```

Then, from your laptop, scp them into the results folder for this run
(naming convention: `YYYYMMDD-<recordmax>-<topology>-senzing-<version>`):

```bash
RUN=results/$(date +%Y%m%d)-25M-provisioned-r6i-8xlarge-single-senzing-4.4.0/data
mkdir -p "$RUN"
for f in dsrc_record match_key_ent match_key_rel pg_stat_io pg_stat_statements; do
  scp ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}:/tmp/$f.csv "$RUN"/
done
# the delta report from Step 4 (note: .txt, not .csv):
scp ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}:/tmp/final-deltas.txt "$RUN"/
```

---

## 8. Scan CloudWatch logs for errors

In the CloudWatch **Logs Insights** console, select your stack's app log group
and run (last query wins — adjust the time range to your run window):

```
fields @timestamp, @message, @logStream
| filter @message like /(?i)(error|except)/
| filter @message not like /(?i)(current transaction is aborted, commands ignored until end of transaction block)/
| sort @timestamp desc
| limit 7000
```

Terms worth a pass each (expect zero unless noted): `SENZ0086`,
`UNHANDLED DATABASE ERROR`, `CORRUPTION_FOUND`, `RetryTimeout`, `FAILED`,
`INFINITE`, `MISSING_RES_ENT_AND_OKEY`, `still`, `stolen`, `cancel`,
`another command is already in progress`.

CLI equivalent (handy for a quick count):

```bash
aws logs filter-log-events \
  --log-group-name <your-app-log-group> \
  --filter-pattern "CORRUPTION_FOUND" \
  --start-time $(date -v-1H +%s)000 \
  --region <your-region>
```

---

## 9. Record the results

Create `results/<YYYYMMDD>-<recordmax>-<topology>-senzing-<version>/` and capture:

- the load-rate / erpm summary (from `progress.sql`),
- the metrics deltas (from `20-final.sql`),
- the exported CSVs (`data/`),
- non-default stack parameters and any anomalies (autovacuum, failover, log errors),
- update [`results/AWS-perf-results-table.md`](../results/AWS-perf-results-table.md).
