# senzing-test-results-20261019-5M-provisioned-r6i-8xlarge-single-senzing-4.5.0.26288-combined-consumer-validation

> **First run of the combined load + redo driver** ([brianmacy/sz_queue_combined_consumer](https://github.com/brianmacy/sz_queue_combined_consumer)
> v0.5.0, SQS binary, image `sz_sqs_combined_consumer-v4:4.5.0-26288`) in place of the `sz_sqs_consumer-v4` + `sz_simple_redoer-v4` pair.
> Senzing 4.5.0.26288, 5M records, single Aurora PG 17.5 `db.r6i.8xlarge`, advisory lock ON, redo share 20 %, 20 threads per task.
>
> 🎯 **Purpose: does it work end to end on SQS?** Not a performance comparison: driver, build and DB size all differ from earlier runs.
> A driver-vs-driver calibration (redo 0 % / 100 % against the split pair on the same build) is a separate run.
>
> **RESULT: ✅ it works end to end.** 5,000,000 records loaded from SQS in 43 m 49 s (avg 1,902/s, peak 2,066/s) by up to 40 tasks;
> redo ran during the load (effective share 0.19 vs 0.20 target), took over when the queue drained, and finished on its own
> (`sys_eval_queue` 0). **0 orphans** (`validate` q1 / q2 = 0 / 0; `obs_ent` = `res_ent_okey` = 4,999,995), **0 dead-lettered, 0 rejected,
> 0 errors, 0 SENZ0010**; scale-to-zero stopped all 40 tasks cleanly in 14 s. Not tested here: HYBRID, long-record visibility extension,
> and a real dead-letter (none occurred).

## Overview
1. **Performed:** 2026-10-19, in parallel with the HYBRID 4.4.3.26292 100M run. Stack `perf-5m-combined` (us-east-2, writer in **us-east-2a**), created 20:19:52, CREATE_COMPLETE 20:30:38 UTC.
   Deploy check: writer `db.r6i.8xlarge` Aurora PG 17.5; consumer task definition = the combined image digest `9b4cdae3…`, `StopTimeout` 30,
   env `SENZING_REDO_PERCENT=20`, `SENZING_THREADS_PER_PROCESS=20`, `SENZING_SQS_QUEUE_URL`, `SENZING_SQS_DEAD_LETTER_QUEUE_URL`; no redoer
   service (ECS reports it `MISSING`). One producer for 5M (~2.2k/s), watchdog from 20:33. **Full pre-load:** producer exited 21:08:50, no restarts; SQS `NumberOfMessagesSent` = **5,000,000** (21:15). `10-baseline` ~21:16; consumers → 8 at 21:17:05 UTC (autoscaling min 8 / **max 40**, capped for the 8xlarge DB). By 21:18:46 all
   8 tasks run the combined digest, each logs `DeadLetter: …perf-5m-combined-sqs-dead-letter`, `Combined stats` shows
   `threads {load_pref 16, redo_pref 4}` (20 threads, 20 % redo) and `mode: mixed`, and each passed `Processed 10000 adds` (178–284/s per task);
   queue 5,000,000 → 4,899,864 visible + 454 in flight. Watcher `scripts/watch_run.py perf-5m-combined 2026-10-19T21:16:00`.
   Autoscaling 8 → 31 (21:27) → **40** (21:32, the cap). Input and in-flight both 0 at ~22:01; every task logged
   `MQ drained (depth 0): load-preferring workers fall into redo (full-capacity drain)` and switched to `redo_drain`. `drain-check` 22:03:
   `dsrc_record` 5,000,000, `sys_eval_queue` empty (978,927 inserted / 978,925 deleted), 0 active client backends.
   **Stop test 22:03:37:** consumers scaled to 0 (min = max = 0); all 40 tasks gone within 14 s, each logging
   `Processed total of … (0 rejected, 0 redo dropped, 0 errors)` and `Senzing environment destroyed; exiting cleanly`. Summed over the 40 tasks:
   **5,000,000 adds, 976,995 redo records, 0 rejected, 0 redo dropped, 0 errors**. Capture 22:04 (`20-final`, `validate`, `exports`, `final-capture`), all in `data/`.
2. **Template:** [`cloudformationAuroraProvisionedSingleDB-combined.yaml`](./cloudformationAuroraProvisionedSingleDB-combined.yaml): the single-DB
   template with one `consumer` service running the combined image and no redoer service. Parameters: `RecordMax=5M`, `CombinedRedoPercent=20`,
   `CombinedThreadsPerProcess=20`, `DatabaseInstanceClass=db.r6i.8xlarge`, advisory true. Consumer env: `SENZING_SQS_QUEUE_URL`,
   `SENZING_SQS_DEAD_LETTER_QUEUE_URL` (explicit; the role has no `sqs:GetQueueUrl`), `SENZING_REDO_PERCENT`, `SENZING_THREADS_PER_PROCESS`;
   `StopTimeout` 30 s.
3. **Images** (4.5.0-26288, pinned by digest; `szBuildVersion` 4.5.0.26288 / `2026_10_15__21_13`):
   | Image | Digest |
   |---|---|
   | `sz_sqs_combined_consumer-v4` (driver 0.5.0, amd64) | `sha256:9b4cdae30782962b9c75fd0503e0781fd7fceb1ecd925b29a9c6febd94ddd2ef` |
   | `senzingsdk-tools` | `sha256:f947e2e161a091d4f071e960b808af4bab82a4ab6748c7b647729c5406d1abb1` |
   | `sshd` | `sha256:d074a31eab5a6583b03c9a6a4066dde82ede8d2b25ec0b56be9e68b65f4e3ae4` |
   | `init-database` (pinned) | `sha256:a68062d23dc9…`: schema byte-identical to 4.5.0.26288; its default config lacks 4.5.0.26288's four new `SETTINGS` (`NAME_/ADDR_TRANSLITERATED_KEYS`, `NAME_/ADDR_TRANSLATED_KEYS`) |

## Validation checklist
| Check | How | Result |
|---|---|---|
| Starts, reads SQS, adds records | task logs (`Processed N adds`), SQS deletes | ✅ 5,000,000 adds summed over 40 tasks, no duplicates |
| Redo runs during load and takes over when the queue drains | `Combined stats:` lines (`redo_share_effective`, mode), `sys_eval_queue` → 0 | ✅ share 0.19 (target 0.20), `MQ drained` → `redo_drain` at 22:01, 976,995 redo records, `sys_eval_queue` 0 at 22:03 |
| Autoscaling on CPU works with one service | ECS task count over time | ✅ 8 → 31 → 40 (cap) in 15 min |
| Dead-lettering: `REJECTING:` marker, DLQ count, `SzReason` attribute | logs + SQS DLQ | – none occurred (0 `REJECTING`, DLQ 0); DLQ URL resolved by every task |
| Long records: `Extended visibility` and no 12 h-limit crash | logs | – none occurred |
| Scale-in / stop is graceful (≤ 30 s, no stuck tasks, messages redelivered) | ECS stopped tasks + logs | ✅ 40 → 0 in 14 s, every task `exiting cleanly` |
| Process crashes / exit 255 | ECS stopped reasons, logs | ✅ none (all stops were the scaling activity) |
| Data integrity: `validate` q1 / q2, `obs_ent` = `res_ent_okey` | `validate.sql`, `final-capture.sql` | ✅ 0 / 0; 4,999,995 = 4,999,995 |
| Logs | ANSI colour codes in CloudWatch (cosmetic; `NO_COLOR` not honored) | known |

## Results
### Observations
- **Peak:** 2,066/second (minute of 21:27 UTC)
- **Average over entire run:** 1,902/second (erpm 114,111; load 21:17:35 → 22:01:24)
- **Time to load 5M:** 43 m 49 s
- **Records in dead-letter queue:** 0
- **Total read / write IOPS (writer):** 1 / 22,709,874 (21:15 → 22:04)
- **Max combined tasks:** 40 (the cap)

Final counts ([final-capture.txt](data/final-capture.txt)): `dsrc_record` 5,000,000 · `obs_ent` 4,999,995 · `res_ent_okey` 4,999,995 ·
`res_ent` 4,818,571 · `res_relate` 1,205,268 · `sys_eval_queue` 0 · `res_ent_active` 1,298. `db.deadlocks` 111, `db.xact_rollback` 111
([final-deltas.txt](data/final-deltas.txt)); log scan: 0 SENZ1019 / SENZ0010 / `REJECTING`, CORRUPTION_FOUND 4, 111 `deadlock detected` (retried).

### Final metrics
No screenshots: a functional validation run, not a performance run. The numbers above come from the logs, `final-capture` and CloudWatch.

#### Logs
`data/final-capture.txt`, `data/final-deltas.txt`, `data/validate.txt`, `data/pg_stat_*.csv`.
#### Errors
```
SENZ1019 0 · SENZ0010 0 · REJECTING 0 · Sending to deadletter 0 · CORRUPTION_FOUND 4 · INFINITE 0 · 55P03 0 · deadlock detected 111
OKEY FLUSH ASSERTION / HEALED / REPAIRED 0 / 0 / 0 · re-driving 0 · ABANDONING 0
```

## Methods
1. Deploy `cloudformationAuroraProvisionedSingleDB-combined.yaml` (parameters above); verify the running image digest.
2. Producer watchdog; full pre-load (SQS `NumberOfMessagesSent` = 5,000,000, producers exited).
3. On sshd: `00-setup.sql`, `10-baseline.sql` (single DB, `$PG`).
4. Consumers → 8 (autoscaling min 8; max capped for an 8xlarge DB, see Overview); `scripts/watch_run.py perf-5m-combined <start>`.
5. Capture after drain: `drain-check` → `20-final` → `validate` → `exports` → `final-capture`.
