# senzing-test-results-20260720-100M-provisioned-r6i-24xlarge-single-senzing-4.3.3

> **This run: 4.3.3 with advisory lock mode OFF** — `EnableEntityLockModeAdvisory=false`,
> so the JSON has **no** `"ER":{"ENTITY_LOCK_MODE":"ADVISORY"}` block at all.
>
> **Primary question (per engine dev):** the [20260716 run](../20260716-100M-provisioned-r6i-24xlarge-single-senzing-4.3.3/README.md)
> had the ER block *present but supposedly ignored*, yet the logs were full of
> `pg_advisory_lock` deadlocks + a 2M-rollback cascade + 12 unresolved records. Does
> removing the ER block entirely make those **advisory-lock errors disappear**?
> - **Errors GONE** → the "ignored" config was NOT inert — its mere presence tripped an
>   advisory code path (and may have caused the cascade + lost records). Significant.
> - **Errors STILL present** → `pg_advisory_lock` is 4.3.3's *default* locking primitive,
>   the ER block truly was inert (naming-collision), and the cascade is default behavior.
>
> ⚠️ This means our current docs' "naming-collision / default primitive" explanation is a
> **hypothesis this run will confirm or refute** — not settled fact. Compare the
> `ExclusiveLock on advisory lock` / `pg_advisory_lock` counts, the cascade
> (`xact_rollback`, `UNHANDLED DATABASE ERROR`, `FAILED`), and the unresolved count
> directly against 20260716.

## Contents

1. [Overview](#overview)
1. [Caveats](#caveats)
1. [Results](#results)
    1. [Observations](#observations)
    1. [Final metrics](#final-metrics)
        1. [SQS](#sqs)
        1. [EFS](#efs)
        1. [ECS](#ecs)
        1. [RDS](#rds)
        1. [Logs](#logs)

## Overview

1. Performed: Jul 20, 2026 (rename dir to the actual run date if it differs)
2. Senzing version: 4.3.3 (`:4.3.3` image tag; verify deployed build)
3. Instructions:
   [aws-cloudformation-performance-testing](https://github.com/senzing-garage/aws-cloudformation-performance-testing)
    1. [cloudformationAuroraProvisionedSingleDB.yaml](./cloudformationAuroraProvisionedSingleDB.yaml)
4. Changes:
    1. Pre-load input queue by setting loader DesiredCount and MinCapacity to 0
    1. Postgres 17.5
    1. Using X86_64 (AMD64) as `CpuArchitecture` for consumer, redoer, and sshd
    1. `RecordMax` = 100M
    1. DB instance class bumped to `db.r6i.24xlarge` (template edit — not a CFT parameter)
    1. **`EnableEntityLockModeAdvisory` = `false`** — advisory lock mode **OFF**. This is
       the deliberate difference vs the 20260716 run. (4.3.3 ignores the advisory feature
       regardless, so effective mode = default either way; here it is explicitly off.)
       NB: 4.3.3 still uses the PostgreSQL `pg_advisory_lock()` *primitive* by default —
       expect advisory-lock deadlocks in the logs; that is separate from the Senzing
       `ENTITY_LOCK_MODE` feature.
    1. no Aurora read-offload (single `CONNECTION`, no `READ_ONLY_CONNECTION`)
    1. Senzing images pinned to `:4.3.3` tag (redoer, sqs-consumer, sdk-tools, sshd) — not `:staging`
    1. `max_connections: 10000` in the DB parameter group
    1. `AcceptEula` / `SecurityResponsibility` launch prompts removed (inert)
    1. Region: fill in at run time (us-east-2 if 24xlarge capacity is available; else
       us-west-2 as on 20260716 — record which)

## System

1. Database
    1. Aurora PosgreSQL Provisioned
    1. Single database
    1. Class: db.r6i.24xlarge
    1. IO Opt (StorageType: aurora-iopt1)
    1. sychronous commit, NOT turned off
    1. Auto scaling of loaders turned from 30% to 25% CPU
    1. Updated DB parameter group to enable some tracking:
    ```
    RdsDbParameterGroup:
    Properties:
      Description: !Sub '${AWS::StackName}-rds-db-parameter-group-description'
      Family: aurora-postgresql17
      Parameters:
        shared_preload_libraries: 'pg_stat_statements'
        track_io_timing: 1
        enable_seqscan: 0
        # pglogical.synchronous_commit: 0
    ```

## Results

### Observations

1. Inserts per second (Peak/Average/Time computed from [dsrc_record.csv](data/dsrc_record.csv); verify against the erpm query):
    1. Peak: TBD/second
    1. Average over entire run: TBD/second
    1. Time to load 100M: TBD hours
    1. Records in dead-letter queue: TBD
    1. Volume read IOPS Writer:      TBD
    1. Volume read IOPS Reader:      n/a
    1. Volume write IOPS:            TBD
    1. See [dsrc_record.csv](data/dsrc_record.csv)

1. Max tasks:

    - Max Consumer tasks: TBD
    - Max Redoer tasks: TBD

### Findings (vs 20260716 4.3.3 set-but-ignored, and vs 4.4)

<!-- After capture, fill in:
  - throughput vs 20260716 (expect ~parity: peak ~5,613 / avg ~3,255 / ~8.5h)
  - res_ent_okey = obs_ent - N unresolved (20260716 was 12; does it reproduce?)
  - xact_rollback + UNHANDLED DATABASE ERROR + FAILED (20260716: 2.08M / 106,605 / 155,848)
    -> does the connection-recovery cascade reproduce with advisory explicitly OFF?
  - res_ent_active (20260716: 34,623)
  - forensics on the unresolved: locking_id != 0 stranded lock? (20260716 fingerprint)
  - 0 OKEY ORPHAN PREVENTED expected (4.3.3 has no advisory code path)
-->

### Final metrics

#### SQS

##### SQS Metrics input queue

![SQS input metrics 1](images/sqs-input-metrics-1.png "SQS input metrics 1")

##### SQS Metrics output queue

N/A.  Ran without `withinfo` enabled.

![SQS output metrics](images/sqs-output-metrics.png "SQS output metrics")

#### ECS

##### Sz SQS Consumer CPU Utilization

![Sz SQS Consumer CPU Utilization](images/stream-loader-CPU-Utilization.png "Sz SQS Consumer CPU Utilization")

##### Sz SQS Consumer Memory Utilization

![Sz SQS Consumer Memory Utilization](images/stream-loader-Memory-Utilization.png "Sz SQS Consumer Memory Utilization")

##### Sz Simple Redoer CPU Utilization

![Sz Simple Redoer CPU Utilization](images/redoer-CPU-Utilization.png "Sz Simple Redoer CPU Utilization")

##### Sz Simple Redoer Memory Utilization

![Sz Simple Redoer Memory Utilization](images/redoer-Memory-Utilization.png "Sz Simple Redoer Memory Utilization")

#### RDS

##### Database Metrics CORE/LIBFEAT/RES final

![Database metrics 1](images/database-metrics-core-1.png "Database metrics 1")
![Database metrics 2](images/database-metrics-core-2.png "Database metrics 2")

##### Database IO / transaction deltas

Captured with the snapshot/diff harness (see
[performance-test runbook](../../docs/performance-test-runbook.md) §4 and
[`scripts/aurora-pg/`](../../scripts/aurora-pg/)).

```
<!-- Paste data/final-deltas.txt: RUN WINDOW, FACT headline, scalar deltas
     (watch xact_rollback — 20260716 cascade had 2,085,437 vs a clean ~700),
     per-table activity. Baseline BEFORE the load = full-run delta. -->
```

1. [pg_stat_io.csv](data/pg_stat_io.csv)
1. [pg_stat_statements.csv](data/pg_stat_statements.csv)

##### DSRC_RECORD

1. [dsrc_record.csv](data/dsrc_record.csv)

##### Match keys

1. [match_key_ent.csv](data/match_key_ent.csv)
1. [match_key_rel.csv](data/match_key_rel.csv)

#### Logs

Final counts + throughput (from final-capture.txt):

```
<!-- Paste final counts: dsrc_record, obs_ent, res_ent_okey (= obs_ent - N),
     res_ent, res_relate, sys_eval_queue (0), res_ent_active; + load erpm/avg.
     Then validate.sql query 1 (the N unresolved obs_ent_ids) and query 2 (0). -->
```

Forensics on any unresolved (run [`scripts/aurora-pg/unresolved-forensics.sql`](../../scripts/aurora-pg/unresolved-forensics.sql)
— it now auto-computes the unresolved set, no id list to edit). Compare the fingerprint
to 20260716: `locking_id != 0` (stranded lock), `features=t`, no `res_ent_okey`, not
queued.

#### Errors

```
==============================================
Term                       |  instance count |
==============================================
(SENZ0086)                 |       TBD       |
(error|except)             |       TBD       |
(ExclusiveLock on advisory lock)|  TBD       |
(UNHANDLED DATABASE ERROR) |       TBD       |
(CORRUPTION_FOUND)         |       TBD       |
(RetryTimeout)             |       TBD       |
(FAILED)                   |       TBD       |
(INFINITE)                 |       TBD       |
(OKEY ORPHAN PREVENTED)    |       TBD       |
(MISSING_RES_ENT_AND_OKEY) |       TBD       |
(still)                    |       TBD       |
(stolen)                   |       TBD       |
(cancel)                   |       TBD       |
(another command is already in progress) | TBD |
==============================================
```

> **The decisive comparison — this run (ER block absent) vs 20260716 (ER block present):**
> | signal | 20260716 (advisory=true, ignored) | this run (advisory=false) | reading |
> |---|---|---|---|
> | `ExclusiveLock on advisory lock` | 588 | **TBD** | 0 → config-triggered; >0 → default primitive |
> | `pg_advisory_lock` deadlocks | present | **TBD** | same |
> | `xact_rollback` | 2,085,437 | **TBD** | 0-ish → cascade was config-triggered |
> | `UNHANDLED DATABASE ERROR` | 106,605 | **TBD** | |
> | `FAILED` | 155,848 | **TBD** | |
> | unresolved (`obs_ent − res_ent_okey`) | 12 | **TBD** | 0 → loss tied to the ER config |
> | `OKEY ORPHAN PREVENTED` | 0 | **TBD** | expect 0 (no 4.4 advisory path) |
>
> Scan the app log group (`/senzing/perf-prov/<stack>`) **in the run's region**, and
> **validate the search with a control term** (a message you know is present) before
> trusting any zero — the 20260716 near-miss taught us an empty-scope/region query can
> return a false 0.

## Methods

Full step-by-step process is in the
[performance-test runbook](../../docs/performance-test-runbook.md). Reusable SQL
helpers live in [`scripts/aurora-pg/`](../../scripts/aurora-pg/).
