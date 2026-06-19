# senzing-test-results-20260619-25M-provisioned-r6i-8xlarge-single-senzing-4.4.0

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

1. Performed: Jun 19, 2026
2. Senzing version: 4.4.0.26167
3. Instructions:
   [aws-cloudformation-performance-testing](https://github.com/senzing-garage/aws-cloudformation-performance-testing)
    1. [cloudformationAuroraProvisionedSingleDB.yaml](./cloudformationAuroraProvisionedSingleDB.yaml)
4. Changes:
    1. Pre-load input queue by setting loader DesiredCount and MinCapacity to 0
    1. Postgres 17.5
    1. Using X86_64 (AMD64) as `CpuArchitecture` for consumer, redoer, and sshd
    1. enabled Aurora read-offload by enabling a read-only connection and database

## System

1. Database
    1. Aurora PosgreSQL Provisioned
    1. Single database
    1. Class: db.r6i.8xlarge
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

1. Inserts per second:
    1. Peak: 2594/second
    1. Average over entire run: 2042/second
    1. Time to load 25M: 3.38
    1. Records in dead-letter queue: 0
    1. Volume read IOPS Writer:      1,987,682
    1. Volume read IOPS Reader:       n/a
    1. Volume write IOPS:          110,278,324
    1. See [dsrc_record.csv](data/dsrc_record.csv)

1. Max tasks:

    - Max Consumer tasks: 61
    - Max Redoer tasks: 59

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

##### Database IO / transaction deltas

Captured with the snapshot/diff harness (see
[performance-test runbook](../../docs/performance-test-runbook.md) §4 and
[`scripts/aurora-pg/`](../../scripts/aurora-pg/)).

```
<!-- Paste the delta output of scripts/aurora-pg/20-final.sql here:
     FACT headline (logical/physical block reads, WAL bytes, txns, tuple ins/upd/del),
     top statements, per-table activity. -->
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
root@ip-10-0-43-115:~# $PG -f /tmp/progress.sql
Password for user senzing:
Timing is on.
              at               | dsrc_record | obs_ent  | res_ent  | res_ent_okey | sys_eval_queue | res_ent_active | res_relate
-------------------------------+-------------+----------+----------+--------------+----------------+----------------+------------
 2026-06-19 19:24:22.661415+00 |    25000000 | 24999937 | 21109299 |     24999937 |              0 |             97 |   11208231
(1 row)

Time: 11461.939 ms (00:11.462)
       load_start        |   duration   |  total   |          erpm           |       avg_erps
-------------------------+--------------+----------+-------------------------+-----------------------
 2026-06-19 14:52:39.483 | 03:23:12.084 | 25000000 | 123030.6484108869328656 | 2050.5108068481155478
(1 row)

Time: 4188.421 ms (00:04.188)
root@ip-10-0-43-115:~# $PG -f /tmp/validate.sql
Password for user senzing:
Timing is on.
 record_id | obs_ent_id | res_ent_id
-----------+------------+------------
(0 rows)

Time: 30117.178 ms (00:30.117)
 record_id | obs_ent_id | res_ent_id
-----------+------------+------------
(0 rows)

Time: 30583.258 ms (00:30.583)
```

#### Errors

```
==============================================
Term                       |  instance count |
==============================================
(SENZ0086)                 |         0       |
(error|except)             |       119       |
(ExclusiveLock on advisory lock)|  114       |
(UNHANDLED DATABASE ERROR) |         0       |
(CORRUPTION_FOUND)         |         1       |
(RetryTimeout)             |         0       |
(FAILED)                   |         0       |
(INFINITE)                 |         0       |
(MISSING_RES_ENT_AND_OKEY) |         0       |
(still)                    |         0       |
(stolen)                   |         0       |
(cancel)                   |         0       |
(another command is already in progress) | 0 |
==============================================

ERR... ExclusiveLock on advisory lock (114/119):
2026-06-19 18:58:23.142 [szstatic:7fe14ffff6c0] ERR: PQresultStatus returned [(7:0:ERROR:  deadlock detected; DETAIL:  Process 20694 waits for ExclusiveLock on advisory lock [16412,766509056,26905780,1]; blocked by process 20712.; Process 20712 waits for ExclusiveLock on advisory lock [16412,766509056,5594456,1]; blocked by process 20694.; HINT:  See server log for query details.; ;Process 20694 waits for ExclusiveLock on advisory lock [16412,766509056,26905780,1]; blocked by process 20712.; Process 20712 waits for ExclusiveLock on advisory lock [16412,766509056,5594456,1]; blocked by process 20694.40P01)] executing: SELECT pg_advisory_lock($1)

```

## Methods

Full step-by-step process — connect, watch progress, capture IO/transaction
metrics, validate, export CSVs, and scan logs — is in the
[performance-test runbook](../../docs/performance-test-runbook.md). Reusable SQL
helpers live in [`scripts/aurora-pg/`](../../scripts/aurora-pg/):

- `progress.sql` — row counts + throughput (erpm) during the load
- `00-setup.sql` / `10-baseline.sql` / `20-final.sql` — IO/transaction delta capture
- `validate.sql` — post-load integrity checks (expect zero rows)
- `exports.sql` — writes `dsrc_record.csv`, `match_key_*.csv`, `pg_stat_*.csv` to `/tmp`
