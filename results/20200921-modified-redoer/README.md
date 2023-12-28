# senzing-test-results-20200921-modified-redoer

## Contents

1. [Overview](#overview)
1. [System](#system)
1. [Results](#results)
    1. [Observations](#observations)
    1. [Final metrics](#final-metrics)
        1. [Container](#container)
            1. [AutoScale](#autoscale)
            1. [Container CPU Utilization](#container-cpu-utilization)
            1. [Container Memory Utilization](#container-memory-utilization)
        1. [Database](#database)
           1. [Last hour](#last-hour)
           1. [DSRC_RECORD](#dsrc_record)

## Overview

1. Performed: Sep 21, 2020
1. Senzing version: 2.1.0
1. Instructions:
   [advanced](https://github.com/senzing-garage/docker-compose-aws-ecscli-demo/tree/master/docs/advanced)
    1. [Pinned version](https://github.com/senzing-garage/docker-compose-aws-ecscli-demo/tree/864dd2296f0664ce00713b22be40476ce4f85afa/docs/advanced)

## System

1. Database
    1. Aurora PosgreSQL Serverless
    1. Max ACU: 192
1. Stream-producer containers
    1. 2 separate services, each loading 5M records using `SENZING_RECORD_MIN` and `SENZING_RECORD_MAX`.
    1. **SENZING_INPUT_URL:** "https://public-read-access.s3.amazonaws.com/TestDataSets/test-dataset-100m.json.gz"
    1. **SENZING_THREADS_PER_PRINT:** 30
    1. ecs-params
        1. task_size:
            1. mem_limit: 8GB
            1. cpu_limit: 1024
1. Stream-loader containers
    1. 1 Service
    1. Scale: 90
    1. AutoScale threshold: TargetValue=30.0
    1. **SENZING_THREADS_PER_PROCESS:** 8
    1. ecs-params
        1. task_size:
            1. mem_limit: 8GB
            1. cpu_limit: 1024
    1. `ScaleInCooldown=600`
    1. `ScaleOutCooldown=300`

## Results

### Observations

1. Oscillation until redoer killed.
1. Inserts per second:
    1. Peak: 1780/second
    1. Database scale from 2 to 192 ACUs: x.x hours
    1. Average at 192 ACUs: 1732/second
    1. Average over entire run: 905/second
    1. Time to load 10M: x.x hours
    1. Database scale from 192 to 32 ACUs: x.x hours
    1. Records in dead-letter queue: 0
    1. See [dsrc_record.csv](data/dsrc_record.csv)
1. Next round:
    1. Prime engine in stream-loader.
    1. Increate redoer CPU and Memory
    1. Document connection failures

### Final metrics

#### Container

##### AutoScale

##### Container CPU Utilization

![Container CPU Utilization](images/container-CPU-Utilization.png "Container CPU Utilization")

##### Container Memory Utilization

![Container Memory Utilization](images/container-Memory-Utilization.png "Container Memory Utilization")

#### Database

##### Last hour

![Database metrics](images/database-metrics.png "Database metrics")

##### DSRC_RECORD

1.[dsrc_record.csv](data/dsrc_record.csv)
