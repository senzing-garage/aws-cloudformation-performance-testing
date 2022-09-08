# senzing-test-results-20200922-larger-redoer

## Contents

1. [Overview](#overview)
1. [System](#system)
1. [Results](#results)
    1. [Observations](#observations)
    1. [Final metrics](#final-metrics)
        1. [Container](#container)
            1. [AutoScale](#autoscale)
            1. [Stream-loader CPU Utilization](#stream-loader-cpu-utilization)
            1. [Redoer CPU Utilization](#redoer-cpu-utilization)
        1. [Database](#database)
        1. [Logs](#logs)

## Overview

1. Performed: Sep 22, 2020
1. Senzing version: 2.1.0
1. Instructions:
   [advanced](https://github.com/Senzing/docker-compose-aws-ecscli-demo/tree/master/docs/advanced)
    1. [Pinned version](https://github.com/Senzing/docker-compose-aws-ecscli-demo/tree/1ad1fdb507d4d9cde2ab1cdf22fb6de4cf770c2f/docs/advanced)

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

1. Did not run until the end due to oscillation.
1. One thread in redoer died.  Not sure if that is causing an issue.
1. Next round:
    1. Use a redoer that dies if a thread dies.
    1. Document connection failures

### Final metrics

#### Container

##### AutoScale

##### Stream-loader CPU Utilization

![Stream Loader CPU Utilization](images/stream-loader-CPU-Utilization.png "Stream-loader CPU Utilization")

##### Redoer CPU Utilization

![Redoer CPU Utilization](images/redoer-CPU-Utilization.png "Redoer CPU Utilization")

#### Database

![Database metrics](images/database-metrics.png "Database metrics")

#### Logs

1. [stream-loader-log-01](data/stream-loader-log-01.csv)
1. [stream-loader-log-02](data/stream-loader-log-02.csv)
1. [redoer-log-01](data/redoer-log-01.csv)
