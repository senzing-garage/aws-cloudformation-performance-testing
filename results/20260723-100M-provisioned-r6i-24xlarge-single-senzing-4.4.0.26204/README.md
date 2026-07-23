# senzing-test-results-20260723-100M-provisioned-r6i-24xlarge-single-senzing-4.4.0.26204

> **This run: Senzing 4.4.0.26204 (latest), 100M, advisory lock mode ON, + the new
> RES_ENT.FEATURES feature.** Two things differ vs the 20260715 4.4.0.26167 run
> (advisory ON, no FEATURES): (a) newer 4.4.0.26204 build, (b) `RES_ENT.FEATURES` column added
> pre-load. Question: does the FEATURES feature / newer build change the OKEY-split
> silent-orphan behavior (4.4.0.26167 lost **40** records) and/or throughput?

> 🧪 **REQUIRED PRE-LOAD STEP — add the RES_ENT.FEATURES column.** After the Senzing
> schema is initialized (RES_ENT exists) and **before starting the consumers**, run:
> ```bash
> $PG -f /tmp/4.4-add-res-ent-features.sql     # ALTER TABLE RES_ENT ADD COLUMN IF NOT EXISTS FEATURES TEXT;
> ```
> ([`scripts/aurora-pg/4.4-add-res-ent-features.sql`](../../scripts/aurora-pg/4.4-add-res-ent-features.sql))
> Records resolved before the column exists won't carry FEATURES — so this must happen
> **before any loading.** Suggested order: stack up → verify schema (RES_ENT present) →
> **run this ALTER** → `00-setup` → `10-baseline` → start consumers.

> ✅ **IMAGES VERIFIED — genuine 4.4.0.26204 (self-built, IMMUTABLE tag).** Devops added a
> GitHub Action so we build our own version and push it to ECR under a chosen immutable tag
> — no more `:staging` drift or mislabel risk (the root cause of every prior image mishap).
> All four `-v4` (4.x) images at `:4.4.0-26204` report BUILD_VERSION **4.4.0.26204** (BUILD
> 2026_07_23__14_03), verified via `/opt/senzing/er/szBuildVersion.json`:
> - consumer: `sz_sqs_consumer-v4:4.4.0-26204` → **4.4.0.26204** / digest `sha256:____` (was local; grab via `docker manifest inspect`)
> - redoer:   `sz_simple_redoer-v4:4.4.0-26204` → **4.4.0.26204** / digest `sha256:a2559966ac17a7cbaf1650f44b8b228dc86bb938ab572c602732109fc31c30da`
> - sdk-tools: `senzingsdk-tools:4.4.0-26204` → **4.4.0.26204** / digest `sha256:f4eaefb839ebcc145f45428299675306f632039587bd3d6b2b3e9addd42f8f79`
> - sshd:      `sshd:4.4.0-26204` → **4.4.0.26204** / digest `sha256:333bcdb7eb8b7f8b40e1930b9c1e6a1833a71cb0cf8f5db2c293cc91f1479607`
> Template pinned to `:4.4.0-26204` (immutable — can't drift). Confirm the **running-task**
> digests match these once the stack is up (§1.5).

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

1. Performed: TBD, 2026 (rename dir to the actual run date + exact build)
2. Senzing version: **4.4.0.26204** (self-built, verified via g2/szBuildVersion.json; immutable tag `:4.4.0-26204`)
3. Instructions:
   [aws-cloudformation-performance-testing](https://github.com/senzing-garage/aws-cloudformation-performance-testing)
    1. [cloudformationAuroraProvisionedSingleDB.yaml](./cloudformationAuroraProvisionedSingleDB.yaml)
4. Changes:
    1. Pre-load input queue by setting loader DesiredCount and MinCapacity to 0
    1. Postgres 17.5
    1. Using X86_64 (AMD64) as `CpuArchitecture` for consumer, redoer, and sshd
    1. `RecordMax` = 100M
    1. DB instance class bumped to `db.r6i.24xlarge` (template edit — not a CFT parameter)
    1. **`EnableEntityLockModeAdvisory` = `true`** — advisory lock mode ON (adds
       `"ER": {"ENTITY_LOCK_MODE": "ADVISORY"}`), same as the 20260715 4.4 run
    1. **NEW: `ALTER TABLE RES_ENT ADD COLUMN FEATURES TEXT` run pre-load** (see banner) —
       enables the 4.4 features-on-RES_ENT capability
    1. no Aurora read-offload (single `CONNECTION`, no `READ_ONLY_CONNECTION`)
    1. Senzing images = **`:4.4.0-26204`** (immutable, self-built) on the `-v4` (4.x) repos —
       all four verified 4.4.0.26204; not `:staging`, not `:4.3.3`, not the non-`-v4` 3.x repos
    1. `max_connections: 10000` in the DB parameter group
    1. Consumer + redoer task size **2 vCPU / 4 GB** (4.x-appropriate; 4.x engine is
       memory-light — do NOT use the 3.x 30 GB sizing). Expect ~165 consumers at peak
       (2 vCPU tasks), like the prior 4.x runs.
    1. `AcceptEula` / `SecurityResponsibility` launch prompts removed (inert)
    1. Region: fill in at run time (us-east-2 if 24xlarge capacity; else us-west-2)

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
    1. Volume read IOPS Writer:      TBD   (ReadIOPS, writer instance, Sum — NOT VolumeReadIOPs)
    1. Volume read IOPS Reader:      n/a
    1. Volume write IOPS:            TBD   (WriteIOPS, writer instance, Sum)
    1. See [dsrc_record.csv](data/dsrc_record.csv)

1. Max tasks:

    - Max Consumer tasks: TBD
    - Max Redoer tasks: TBD

### Findings (4.4.0.26204 + FEATURES vs 20260715 4.4.0.26167)

<!-- After capture, fill in:
  - res_ent_okey = obs_ent - N unresolved. 4.4.0.26167 (advisory, NO features) = 40 silent
    OKEY orphans. Does 4.4.0.26204 + FEATURES change N? (0 = fixed; still ~40 = not FEATURES-related)
  - OKEY ORPHAN PREVENTED count + unresolved-forensics on any unresolved (classify-unresolved.py)
  - throughput vs 4.4.0.26167 (peak 6,074 / avg 3,365 / 8.25h) — does FEATURES cost throughput?
  - errors: advisory-lock (4.4.0.26167 had 617), CORRUPTION_FOUND, INFINITE, xact_rollback
  - confirm RES_ENT.FEATURES is populated (spot-check: SELECT count(*) FROM res_ent WHERE features IS NOT NULL)
-->

### Final metrics

#### SQS

##### SQS Metrics input queue

![SQS input metrics 1](images/sqs-input-metrics-1.png "SQS input metrics 1")

##### SQS Metrics output queue

N/A.  Ran without `withinfo` enabled.

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
     (xact_rollback, deadlocks), per-table activity. Baseline BEFORE the load. -->
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
     Then validate.sql query 1 (unresolved) and query 2 (dangling) — expect 0/0.
     Also confirm FEATURES populated: SELECT count(*) FROM res_ent WHERE features IS NOT NULL; -->
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

## Methods

Full step-by-step process is in the
[performance-test runbook](../../docs/performance-test-runbook.md) (note **§1.5 image
verification** before loading, and the **RES_ENT.FEATURES ALTER** in the banner — run it
after schema init, before loaders). Reusable SQL helpers live in
[`scripts/aurora-pg/`](../../scripts/aurora-pg/).
