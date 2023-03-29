# senzing-test-results-20230328-100M-200-192ACU-clustered-senzing-3.5.0

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

1. Performed: Mar 28, 2023
2. Senzing version: 3.5.0.23084
3. Instructions:
   [aws-cloudformation-ecs-staging-simple-100M](https://github.com/Senzing/aws-cloudformation-ecs/tree/main/cloudformation/aws-cloudformation-ecs-staging-simple-100M)
    1. [Cloudformation.yaml]()
4. Changes:
    1. using SQS Consumer: https://github.com/brianmacy/sz_sqs_consumer
    1. Consumer updated, SENZING_PREFETCH = SENZING_THREADS_PER_PROCESS
    1. Core: Max ACU 192
    1. Libfeat: Max ACU 192
    1. Res: Max ACU 384
    1. using Simple redoer: https://github.com/brianmacy/sz_simple_redoer

## System

1. Database
    1. Aurora PosgreSQL Serverless
    1. ACU range: 2 - 192

## Results

### Observations

1. Inserts per second:
    1. Peak: not collected
    1. Warm-up: not collected
    1. Average after warm-up: not collected
    1. Average over entire run: 1345/second
    1. Time to load 100M: 20.65 hours
    1. Records in dead-letter queue: 0
    1. Total Billed read IOPS:   not collected
    1. Total Billed write IOPS:  not collected

Note:  This is using local senzing data.  Withinfo disabled.

- Max loader tasks: 62
- Max Redoer tasks: 21


### Final metrics

#### SQS

not collected

#### ECS

##### Sz SQS Consumer CPU and Memory Utilization

![Sz SQS Consumer CPU and Memory Utilization](images/stream-loader.png "Sz SQS Consumer CPU and Memory Utilization")

##### Sz Simple Redoer CPU and Memory Utilization

![Sz Simple Redoer CPU and Memory Utilization](images/redoer.png "Sz Simple Redoer CPU and Memory Utilization")

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
       now       |  count
------------------------------+-----------
 2023-03-28 20:52:25.98778+00 | 100000000
(1 row)
G2=> SELECT NOW(), COUNT(*) FROM OBS_ENT;
       now       | count
-------------------------------+----------
 2023-03-28 20:55:40.762148+00 | 99998927
(1 row)
G2=> SELECT NOW(), COUNT(*) FROM RES_ENT;
       now       | count
-------------------------------+----------
 2023-03-28 21:36:39.850032+00 | 61419812
(1 row)
G2=> SELECT NOW(), COUNT(*) FROM RES_ENT_OKEY;
       now       | count
-------------------------------+----------
 2023-03-28 21:38:06.499258+00 | 99998927
(1 row)
G2=> SELECT NOW(), COUNT(*) FROM RES_RELATE;
       now       | count
-------------------------------+----------
 2023-03-28 21:41:36.608153+00 | 53858697
(1 row)
G2=> select min(first_seen_dt) load_start, count(*) / (extract(EPOCH FROM (max(first_seen_dt)-min(first_seen_dt)))/60) erpm, count(*) total, max(first_seen_dt)-min(first_seen_dt) duration, (count(*) / (extract(EPOCH FROM (max(first_seen_dt)-min(first_seen_dt)))/60))/60 as avg_erps from dsrc_record;
    load_start    |    erpm    |  total  |  duration  |   avg_erps
-------------------------+------------------+-----------+--------------+------------------
 2023-03-27 22:29:40.216 | 80714.4205554123 | 100000000 | 20:38:56.159 | 1345.24034259021
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
