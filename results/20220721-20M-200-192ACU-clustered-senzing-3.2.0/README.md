# senzing-test-results-20220721-20M-200-192ACU-clustered-senzing-3.2.0

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

1. Performed: Jul 21, 2022
2. Senzing version: 3.2.0-22201
3. Instructions:
   [aws-cloudformation-ecs-staging-simple-100M](https://github.com/Senzing/aws-cloudformation-ecs/tree/main/cloudformation/aws-cloudformation-ecs-staging-simple-100M)
    1. [Cloudformation.yaml]()
4. Stream loader changes:
    1. `SENZING_THREADS_PER_PROCESS` increased from 8 to 20
    1. `CPU` increased from 2048 to 4096
    1. `Memory` increased from 12288 to 30720


## System

1. Database
    1. Aurora PosgreSQL Serverless
    1. ACU range: 2 - 192

## Results

### Observations

1. Inserts per second:
    1. Peak: 2994/second
    1. Warm-up: 33 mins
    1. Average after warm-up: 2611/second
    1. Average over entire run: 2165/second
    1. Time to load 20M: 2.55 hours
    1. Records in dead-letter queue: 0
    1. Total Billed read IOPS:    5,419,094
    1. Total Billed write IOPS: 119,066,657
    1. See [dsrc_record.csv](data/dsrc_record.csv)

Note:  This is using local senzing data.  Withinfo disabled.

Max Stream-loader tasks: 70
Max Redoer-loader tasks: 20

### Final metrics

#### SQS

##### SQS Metrics input queue

![SQS input metrics](images/sqs-input-metrics.png "SQS input metrics")

##### SQS Metrics output queue

N/A.  Ran without `withinfo` enabled.

![SQS output metrics](images/sqs-output-metrics.png "SQS output metrics")

##### SQS Metrics redoer input queue

![SQS redoer input metrics](images/sqs-redoer-input-metrics.png "SQS redoer input metrics")

##### SQS Metrics redoer output queue

N/A.  Ran without `withinfo` enabled.

![SQS redoer output metrics](images/sqs-redoer-output-metrics.png "SQS redoer output metrics")

#### EFS

##### EFS Metrics

![EFS metrics](images/efs-metrics.png "EFS metrics")

#### ECS

##### Stream-loader CPU Utilization

![Stream Loader CPU Utilization](images/stream-loader-CPU-Utilization.png "Stream-loader CPU Utilization")

##### Stream-loader Memory Utilization

![Stream Loader Memory Utilization](images/stream-loader-Memory-Utilization.png "Stream-loader Memory Utilization")

##### Redoer-producer CPU Utilization

![Redoer-producer CPU Utilization](images/redoer-producer-CPU-Utilization.png "Redoer-producer CPU Utilization")

##### Redoer-producer Memory Utilization

![Redoer-producer Memory Utilization](images/redoer-producer-Memory-Utilization.png "Redoer-producer Memory Utilization")

##### Redoer-loader CPU Utilization

![Redoer-loader CPU Utilization](images/redoer-loader-CPU-Utilization.png "Redoer-loader CPU Utilization")

##### Redoer-loader Memory Utilization

![Redoer-loader Memory Utilization](images/redoer-loader-Memory-Utilization.png "Redoer-loader Memory Utilization")

#### RDS

##### Database Metrics CORE final

![Database metrics](images/database-metrics-core.png "Database metrics")

##### Database Metrics LIBFEAT final

![Database metrics](images/database-metrics-libfeat.png "Database metrics")

##### Database Metrics RES final

![Database metrics](images/database-metrics-res.png "Database metrics")

##### DSRC_RECORD

1. [dsrc_record.csv](data/dsrc_record.csv)

#### Logs

```
G2=> SELECT NOW(), COUNT(*) FROM DSRC_RECORD;
              now              |  count
-------------------------------+----------
 2022-07-21 12:15:08.453244+00 | 20000000
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM SYS_EVAL_QUEUE;
             now              | count
------------------------------+-------
 2022-07-21 12:16:17.69687+00 |     0
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM OBS_ENT;
              now              |  count
-------------------------------+----------
 2022-07-21 12:16:17.711423+00 | 19999959
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_ENT;
              now              |  count
-------------------------------+----------
 2022-07-21 12:19:20.440533+00 | 17478755
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_ENT_OKEY;
              now              |  count
-------------------------------+----------
 2022-07-21 12:17:28.659197+00 | 19999959
(1 row)

G2=> SELECT NOW(), COUNT(*) FROM RES_RELATE;
              now              |  count
-------------------------------+---------
 2022-07-21 12:17:47.459671+00 | 9121672
(1 row)

G2=> select min(first_seen_dt) load_start, count(*) / (extract(EPOCH FROM (max(first_seen_dt)-min(first_seen_dt)))/60) erpm, count(*) total, max(first_seen_dt)-min(first_seen_dt) duration from dsrc_record;
       load_start        |       erpm       |  total   |   duration
-------------------------+------------------+----------+--------------
 2022-07-21 08:17:49.612 | 130816.910178711 | 20000000 | 02:32:53.126
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
