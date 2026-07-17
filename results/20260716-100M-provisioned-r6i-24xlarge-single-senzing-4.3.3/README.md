# senzing-test-results-20260716-100M-provisioned-r6i-24xlarge-single-senzing-4.3.3

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

1. Performed: Jul 16, 2026
2. Senzing version: 4.3.3 (verify `:4.3.3` image tag exists + deployed build)
3. Instructions:
   [aws-cloudformation-performance-testing](https://github.com/senzing-garage/aws-cloudformation-performance-testing)
    1. [cloudformationAuroraProvisionedSingleDB.yaml](./cloudformationAuroraProvisionedSingleDB.yaml)
4. Changes:
    1. Pre-load input queue by setting loader DesiredCount and MinCapacity to 0
    1. Postgres 17.5
    1. Using X86_64 (AMD64) as `CpuArchitecture` for consumer, redoer, and sshd
    1. `RecordMax` = 100M
    1. DB instance class bumped to `db.r6i.24xlarge` (template edit — not a CFT parameter)
    1. enabled `ENTITY_LOCK_MODE: ADVISORY` (`"ER": {"ENTITY_LOCK_MODE": "ADVISORY"}`)
    1. no Aurora read-offload (single `CONNECTION`, no `READ_ONLY_CONNECTION`)
    1. Senzing images pinned to `:4.3.3` tag (redoer, sqs-consumer, sdk-tools, sshd) — not `:staging`
    1. `max_connections: 10000` in the DB parameter group (fixes the 100M connection-exhaustion seen on the 4.4 run; 8000 was too tight). NB: `superuser_reserved_connections` isn't settable on Aurora — default reserve is fine given the 10000 ceiling
    1. Removed the `AcceptEula` / `SecurityResponsibility` launch prompts (leftover customer-sample ceremony; **inert** — not passed to any container/software, so the A/B vs the flawed 4.4 run is unaffected)
    1. Launched in **us-west-2** (not us-east-2 like the 4.4 run) because us-east-2 had no `db.r6i.24xlarge` capacity in the writer AZ. No template edit needed (the CFT has no hardcoded region/AZ — AZs derive dynamically). Same-AZ colocation of writer + consumer + redoer is preserved. Region does **not** affect the regression A/B (the OKEY-orphan / silent-drop / advisory-lock behavior is a software concurrency issue); throughput is expected within run-to-run noise of us-east-2 (same `r6i` hardware, same IO-optimized Aurora), noted here only for the record

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
![Database metrics 3](images/database-metrics-core-3.png "Database metrics 3")
![Database metrics 4](images/database-metrics-core-4.png "Database metrics 4")
![Database metrics 5](images/database-metrics-core-5.png "Database metrics 5")

##### Database IO / transaction deltas

Captured with the snapshot/diff harness (see
[performance-test runbook](../../docs/performance-test-runbook.md) §4 and
[`scripts/aurora-pg/`](../../scripts/aurora-pg/)).

```
<!-- Paste the delta output of scripts/aurora-pg/20-final.sql here (from
     data/final-deltas.txt): FACT headline, scalar deltas, top statements,
     per-table activity. Take the baseline BEFORE the load so this covers the
     full 100M run. wal_bytes is blank on Aurora (use VolumeWriteIOPs). -->
```

1. [pg_stat_io.csv](data/pg_stat_io.csv)
1. [pg_stat_statements.csv](data/pg_stat_statements.csv)

##### DSRC_RECORD

1. [dsrc_record.csv](data/dsrc_record.csv)

##### Match keys

1. [match_key_ent.csv](data/match_key_ent.csv)
1. [match_key_rel.csv](data/match_key_rel.csv)

#### Logs

```
<!-- Paste this run's progress.sql (final counts + erpm) and validate.sql
     (both queries must return 0 rows) output here. -->
```

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

##### A/B parity with the 4.4 run

Reproduce the **same** unresolved-record forensics as the
[20260715 4.4 run](../20260715-100M-provisioned-r6i-24xlarge-single-senzing-4.4.0/senzing-eng-escalation.md)
so the comparison is apples-to-apples. After the drain gate:

1. `validate.sql` query 1 → the observed-but-unresolved `obs_ent_id`s (4.4 had 40;
   clean 4.1 had 0). Record the count (`res_ent_okey` = `obs_ent` − N).
2. Put those ids in [`scripts/aurora-pg/unresolved-forensics.sql`](../../scripts/aurora-pg/unresolved-forensics.sql)
   and run it (features / locking_id / has_res_ent_okey / last_touch clustering /
   still-queued).
3. In CloudWatch Logs Insights (full run window, **consumer + redoer** log groups) export:
   - every `OKEY ORPHAN PREVENTED` line, and
   - a bare-id scan of all non-OKEY messages for those ids.
4. Classify with [`scripts/aurora-pg/classify-unresolved.py`](../../scripts/aurora-pg/classify-unresolved.py)
   (replace its id list) and record the split: OKEY-victim / collateral / silent /
   corruption / infinite.

**The A/B question:** does 4.3.3-advisory also hit
`oent-swap-okey-split-commit-regression` + silent drops (→ an advisory-mode issue), or
is it clean (→ a 4.4 regression)? Capture the `OKEY ORPHAN PREVENTED`,
`ExclusiveLock on advisory lock`, `CORRUPTION_FOUND`, and `INFINITE` counts above for
the side-by-side.

## Methods

Full step-by-step process — connect, watch progress, capture IO/transaction
metrics, validate, export CSVs, and scan logs — is in the
[performance-test runbook](../../docs/performance-test-runbook.md). Reusable SQL
helpers live in [`scripts/aurora-pg/`](../../scripts/aurora-pg/):

- `progress.sql` — row counts + throughput (erpm) during the load
- `00-setup.sql` / `10-baseline.sql` / `20-final.sql` — IO/transaction delta capture
- `validate.sql` — post-load integrity checks (expect zero rows)
- `exports.sql` — writes `dsrc_record.csv`, `match_key_*.csv`, `pg_stat_*.csv` to `/tmp`
