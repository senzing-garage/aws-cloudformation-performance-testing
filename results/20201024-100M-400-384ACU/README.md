# senzing-test-results-20201024-100M-400-384ACU

## Contents

1. [Overview](#overview)
1. [System](#system)
1. [Results](#results)
    1. [Observations](#observations)
    1. [Final metrics](#final-metrics)
        1. [SQS](#sqs)
            1. [SQS Metrics](#sqs-metrics)
        1. [EFS](#efs)
            1. [EFS Metrics](#efs-metrics)
        1. [ECS](#ecs)
            1. [Stream-loader CPU Utilization](#stream-loader-cpu-utilization)
        1. [RDS](#rds)
            1. [Database Metrics](#database-metrics)
            1. [DSRC_RECORD](#dsrc_record)
        1. [Logs](#logs)

## Overview

1. Performed: Oct 24, 2020
1. Senzing version: 2.2.2
1. Instructions:
   [advanced](https://github.com/senzing-garage/docker-compose-aws-ecscli-demo/tree/master/docs/advanced)
    1. [Pinned version](https://github.com/senzing-garage/docker-compose-aws-ecscli-demo/tree/1c3b75b97ee64aa7559a83bbfc83912989a0daab/docs/advanced-100M-serverless)

## System

1. Database
    1. Aurora PosgreSQL Serverless
    1. ACU range: 2 - 384
1. Stream-producer containers
    1. 4 separate services, each loading 25M records using `SENZING_RECORD_MIN` and `SENZING_RECORD_MAX`.
    1. **SENZING_INPUT_URL:** "https://public-read-access.s3.amazonaws.com/TestDataSets/test-dataset-100m.json.gz"
    1. **SENZING_THREADS_PER_PRINT:** 30
    1. ecs-params
        1. task_size:
            1. mem_limit: 8GB
            1. cpu_limit: 1024
1. Stream-loader containers
    1. 1 Service
    1. Scale: 1 - 400
    1. AutoScale threshold: TargetValue=30.0
    1. **SENZING_THREADS_PER_PROCESS:** 8
    1. ecs-params
        1. task_size:
            1. mem_limit: 8GB
            1. cpu_limit: 1024
    1. `ScaleInCooldown=300`
    1. `ScaleOutCooldown=1200`

## Results

### Observations

1. Inserts per second:
    1. Peak: 1620/second
    1. Warm-up: 1.1 hours - But never reached steady state
    1. Average after warm-up: 848/second
    1. Average over entire run: 821/second
    1. Time to load 34M: 12.8 hours
    1. Records in dead-letter queue: 0
    1. See [dsrc_record.csv](data/dsrc_record.csv)
1. Scale in:
    1. Stream-loaders scale from 90 to 1: n.n hours
    1. Database scale from 192 to 8 ACUs: n.n hours
    1. Database scale from 192 to 2 ACUs: n.n hours

### Final metrics

#### SQS

##### SQS Metrics

![SQS metrics](images/sqs-metrics.png "SQS metrics")

#### EFS

##### EFS Metrics

![EFS metrics](images/efs-metrics.png "EFS metrics")

#### ECS

##### Stream-loader CPU Utilization

![Stream Loader CPU Utilization](images/stream-loader-CPU-Utilization.png "Stream-loader CPU Utilization")

#### RDS

##### Database Metrics

![Database metrics](images/database-metrics.png "Database metrics")

##### DSRC_RECORD

1. [dsrc_record.csv](data/dsrc_record.csv)

#### Logs
