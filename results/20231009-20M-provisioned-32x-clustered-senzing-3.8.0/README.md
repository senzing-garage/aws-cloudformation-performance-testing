# senzing-test-results-20231009-20M-provisioned-32x-clustered-senzing-3.8.0

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

1. Performed: Oct 09, 2023
2. Senzing version: 3.8.0-23258
3. Instructions:
   [aws-cloudformation-performance-testing](https://github.com/senzing-garage/aws-cloudformation-performance-testing)
    1. [cloudformationAuroraV2.yaml](https://github.com/senzing-garage/aws-cloudformation-performance-testing/blob/main/cloudformationAuroraV2.yaml)
4. Changes:
    1. Pre-load input queue by setting loader DesiredCount and MinCapacity to 0
    1. Postgres 14.8

## System

1. Database
    1. Aurora PosgreSQL Provisioned
    1. Multiple databases
    1. Class: db.r6i.32xlarge
    1. IO Opt (StorageType: aurora-iopt1)

## Results

### Observations

1. Inserts per second:
    1. Peak: 8597/second
    1. Warm-up: 0 mins
    1. Average after warm-up: n/a
    1. Average over entire run: 6962/second
    1. Time to load 20M: 48 mins
    1. Records in dead-letter queue: 0
    1. Volume read IOPS:            23
    1. Volume write IOPS:   38,441,895
    1. See [dsrc_record.csv](data/dsrc_record.csv)

1. Max tasks:

    - Max Stream-loader tasks: 125
    - Max Redoer tasks: 28

1. Notes:
    - db.r6i.32xlarge RES cluster seems to be running at 61% CPU with 125 loaders running.


### Final metrics

#### SQS

##### SQS Metrics input queue

![SQS input metrics](images/sqs-input-metrics.png "SQS input metrics")

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

##### Database Metrics LIBFEAT final

![Database metrics 1](images/database-metrics-libfeat-1.png "Database metrics 1")
![Database metrics 2](images/database-metrics-libfeat-2.png "Database metrics 2")
![Database metrics 3](images/database-metrics-libfeat-3.png "Database metrics 3")

##### Database Metrics RES final

![Database metrics 1](images/database-metrics-res-1.png "Database metrics 1")
![Database metrics 2](images/database-metrics-res-2.png "Database metrics 2")
![Database metrics 3](images/database-metrics-res-3.png "Database metrics 3")


##### DSRC_RECORD

1. [dsrc_record.csv](data/dsrc_record.csv)

#### Logs

```
G2=> SELECT NOW(), COUNT(*) FROM DSRC_RECORD;
              now              |  count
-------------------------------+----------
 2023-10-09 15:24:25.467444+00 | 20000000
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM OBS_ENT;
              now              |  count
-------------------------------+----------
 2023-10-09 15:45:12.863086+00 | 19999959
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_ENT;
              now              |  count
-------------------------------+----------
 2023-10-09 15:45:16.461987+00 | 17461909
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_ENT_OKEY;
              now              |  count
-------------------------------+----------
 2023-10-09 15:45:19.754568+00 | 19999959
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM SYS_EVAL_QUEUE;
              now              | count
-------------------------------+-------
 2023-10-09 15:45:24.343085+00 |     0
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_RELATE;
              now              |  count
-------------------------------+---------
 2023-10-09 15:45:27.620169+00 | 9115780
(1 row)

G2=> select min(first_seen_dt) load_start, count(*) / (extract(EPOCH FROM (max(first_seen_dt)-min(first_seen_dt)))/60) erpm, count(*) total, max(first_seen_dt)-min(first_seen_dt) duration, (count(*) / (extract(EPOCH FROM (max(first_seen_dt)-min(first_seen_dt)))/60))/60 as avg_erps from dsrc_record;
       load_start        |          erpm           |  total   |   duration   |       avg_erps
-------------------------+-------------------------+----------+--------------+-----------------------
 2023-10-09 14:34:05.123 | 417703.8194489163889799 | 20000000 | 00:47:52.849 | 6961.7303241486064830
(1 row)

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
