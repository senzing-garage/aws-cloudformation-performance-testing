# senzing-test-results-20250813-25M-provisioned-r6i-8xlarge-single-senzing-4

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

1. Performed: Aug 13, 2025
2. Senzing version: 4.0.0.25224
3. Instructions:
   [aws-cloudformation-performance-testing](https://github.com/senzing-garage/aws-cloudformation-performance-testing)
    1. [cloudformationAuroraProvisionedSingleDB.yaml](./cloudformationAuroraProvisionedSingleDB.yaml)
4. Changes:
    1. Pre-load input queue by setting loader DesiredCount and MinCapacity to 0
    1. Postgres 14.9
    1. Using X86_64 (AMD64) as `CpuArchitecture` for consumer, redoer, and sshd

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
      Family: aurora-postgresql14
      Parameters:
        shared_preload_libraries: 'pg_stat_statements'
        track_io_timing: 1
        enable_seqscan: 0
    ```
1. sshd docker container tagged `staging` failed to run. created new task definition using 1.4.11 and updated the CFT to reflect that.

## Results

### Observations

1. Inserts per second:
    1. Peak: 2363/second
    1. Warm-up: 0 mins
    1. Average after warm-up: n/a
    1. Average over entire run: 1781/second
    1. Time to load 25M: 3.9 hours
    1. Records in dead-letter queue: 0
    1. Volume read IOPS:      1,686,563
    1. Volume write IOPS:   115,298,381
    1. See [dsrc_record.csv](data/dsrc_record.csv)

1. Max tasks:

    - Max Consumer tasks: 39
    - Max Redoer tasks: 39

### Final metrics

#### SQS

##### SQS Metrics input queue

![SQS input metrics 1](images/sqs-input-metrics-1.png "SQS input metrics 1")
![SQS input metrics 2](images/sqs-input-metrics-2.png "SQS input metrics 2")

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
![Database metrics 6](images/database-metrics-core-6.png "Database metrics 6")
![Database metrics 7](images/database-metrics-core-7.png "Database metrics 7")


##### DSRC_RECORD

1. [dsrc_record.csv](data/dsrc_record.csv)

#### Logs

```
G2=> SELECT NOW(), COUNT(*) FROM DSRC_RECORD;
             now              |  count
------------------------------+----------
 2025-08-13 21:43:43.45223+00 | 25000000
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM OBS_ENT;
              now              |  count
-------------------------------+----------
 2025-08-13 21:43:48.394707+00 | 24999937
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_ENT;
             now              |  count
------------------------------+----------
 2025-08-13 21:43:59.66382+00 | 21123737
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_ENT_OKEY;
              now              |  count
-------------------------------+----------
 2025-08-13 21:44:04.531884+00 | 24999937
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM SYS_EVAL_QUEUE;
              now              | count
-------------------------------+-------
 2025-08-13 21:44:08.368903+00 |     0
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_ENT WHERE ent_state != 0 ;
              now              | count
-------------------------------+-------
 2025-08-13 21:44:11.839841+00 |    11
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_RELATE;
              now              |  count
-------------------------------+----------
 2025-08-13 21:44:18.764274+00 | 11042709
(1 row)

G2=> select min(first_seen_dt) load_start, count(*) / (extract(EPOCH FROM (max(first_seen_dt)-min(first_seen_dt)))/60) erpm, count(*) total, max(first_seen_dt)-min(first_seen_dt) duration, (count(*) / (extract(EPOCH FROM (max(first_seen_dt)-min(first_seen_dt)))/60))/60 as avg_erps from dsrc_record;
       load_start        |          erpm           |  total   |   duration   |       avg_erps
-------------------------+-------------------------+----------+--------------+-----------------------
 2025-08-13 16:44:31.789 | 106832.7521869020481985 | 25000000 | 03:54:00.638 | 1780.5458697817008033
(1 row)

G2=> select dr.RECORD_ID,oe.OBS_ENT_ID,reo.RES_ENT_ID from DSRC_RECORD dr left outer join OBS_ENT oe ON dr.dsrc_id = oe.dsrc_id and dr.ent_src_key = oe.ent_src_key left outer join RES_ENT_OKEY reo ON oe.OBS_ENT_ID = reo.OBS_ENT_ID where reo.RES_ENT_ID is null;
 record_id | obs_ent_id | res_ent_id
-----------+------------+------------
(0 rows)

G2=> select dr.RECORD_ID,reo.OBS_ENT_ID,reo.RES_ENT_ID from RES_ENT_OKEY reo left outer join OBS_ENT oe ON oe.OBS_ENT_ID = reo.OBS_ENT_ID  left outer join DSRC_RECORD dr  ON dr.dsrc_id = oe.dsrc_id and dr.ent_src_key = oe.ent_src_key where dr.RECORD_ID is null;
 record_id | obs_ent_id | res_ent_id
-----------+------------+------------
(0 rows)
```

## Methods

### Database queries

1. :pencil2: On local workstation, set environment variables:

    ```console
    export SENZING_SSHD_HOST=00.00.00.00
    export SENZING_SSHD_USERNAME=root
    export SENZING_SSHD_PASSWORD=aaaaaaaaaaaaaaaa
    ```

1. On local workstation, ssh to `senzing/sshd` container`:

    ```console
    ssh ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}
    ```

1. :pencil2: In `sshd` container, set environment variables:

    ```console

    export SENZING_DATABASE_HOST_CORE=mjd-100m-aurora-senzing-core-cluster.cluster-cn3qi42a3jus.us-east-1.rds.amazonaws.com
    export SENZING_DATABASE_PASSWORD=aaaaaaaaaaaaaaaa
    ```

1. In `sshd` container, connect to database:

    ```console
    psql -h ${SENZING_DATABASE_HOST_CORE} -p 5432 -U senzing -W -d G2
    ```

1. In `sshd` container, connect to database:

    ```console
    \copy (SELECT date_trunc('minute', first_seen_dt) as time, count(*) inserts_per_minute FROM dsrc_record GROUP BY time ORDER BY time desc) To '/tmp/test.csv' With CSV

    SELECT NOW(), COUNT(*) FROM DSRC_RECORD;
    SELECT NOW(), COUNT(*) FROM SYS_EVAL_QUEUE;
    ```

1. :pencil2: On local workstation, identify where file is to be downloaded:

    ```console
    export SENZING_DOWNLOAD_FILE=~/docktermj.git/senzing-test-results/aws/ecs/20211006-20M-200-192ACU-clustered-senzing-2.8.2-encrypted/data/dsrc_record.csv
    ```

1. On local workstation, download the SQL results:

    ```console
    scp ${SENZING_SSHD_USERNAME}@${SENZING_SSHD_HOST}:/tmp/test.csv ${SENZING_DOWNLOAD_FILE}
    ```
