# senzing-test-results-aws-ecs-100M

## Contents

1. [Overview](#overview)
1. [System](#system)
1. [Results](#results)
    1. [Observations](#observations)
    1. [Final metrics](#final-metrics)
        1. [Container](#container)
            1. [Container CPU Utilization](#container-cpu-utilization)
            1. [Container Memory Utilization](#container-memory-utilization)
        1. [Database](#database)
            1. [Commit Latency](#commit-latency)
            1. [Commit Throughput](#commit-throughput)
            1. [DB Connections](#db-connections)
            1. [Database CPU Utilization](#database-cpu-utilization)
            1. [Maximum Used Transaction IDs](#maximum-used-transaction-ids)
            1. [Read IOPS](#read-iops)
            1. [Read Throughput](#read-throughput)
            1. [Row counts](#row-counts)
            1. [Write IOPS](#write-iops)
            1. [Write Latency](#write-latency)
            1. [Write Throughput](#write-throughput)
1. [Cleanup](#cleanup)

## Overview

1. Performed: Aug 30, 2020
1. Senzing version: 2.1.0 pre-release
1. Instructions:
   [advanced-100M](https://github.com/Senzing/docker-compose-aws-ecscli-demo/tree/master/docs/advanced-100M)
    1. [Pinned version](https://github.com/Senzing/docker-compose-aws-ecscli-demo/tree/2be5a2668e7ae9ae576b5e8cd2488289e2ae8c57/docs/advanced-100M)

## System

1. Database
    1. Aurora PosgreSQL server-based
    1. `db.r5.16xlarge`
    1. 64 vCPU  512 GiB ram
1. Stream-producer containers
    1. 2 separate services, each loading 50M records using `SENZING_RECORD_MIN` and `SENZING_RECORD_MAX`.
    1. **SENZING_INPUT_URL:** "https://public-read-access.s3.amazonaws.com/TestDataSets/test-dataset-100m.json.gz"
    1. **SENZING_THREADS_PER_PRINT:** 30
    1. ecs-params
        1. task_size:
            1. mem_limit: 8GB
            1. cpu_limit: 1024
1. Stream-loader containers
    1. Scale: 90
    1. **SENZING_THREADS_PER_PROCESS:** 8
    1. ecs-params
        1. task_size:
            1. mem_limit: 8GB
            1. cpu_limit: 1024

## Results

### Observations

1. Cost of insert:
    1. ~$12 per million inserts
    1. Where money is spent:
        1. 70% Database
        1. 20% Containers
        1. 7% SQS
1. Runtime: 25 hours
    1. At  4-hour mark, 26M inserted.
    1. At 12-hour mark, 60M inserted.
    1. At 18-hour mark, 79M inserted.
    1. At 21-hour mark, 88M inserted
    1. At 25-hour mark, 100M inserted.
1. PostgreSQL transaction ids (XID) seem to hover around 250M
1. Snapshot size: 1455 GiB

### Final metrics

#### Container

##### Container CPU Utilization

![Container CPU Utilization](images-final/container-CPU-Utilization.png "Container CPU Utilization")

##### Container Memory Utilization

![Container Memory Utilization](images-final/container-Memory-Utilization.png "Container Memory Utilization")

#### Database

##### Commit Latency

![Commit Latency](images-final/database-Commit-Latency.png "Commit Latency")

##### Commit Throughput

![Commit Throughput](images-final/database-Commit-Throughput.png "Commit Throughput")

##### DB Connections

![DB Connections](images-final/database-DB-Connections.png "DB Connections")

##### Database CPU Utilization

![Database CPU Utilization](images-final/database-CPU-Utilization.png "Database CPU Utilization")

##### Maximum Used Transaction IDs

![Maximum Used Transaction IDs](images-final/database-Maximum-Used-Transaction-IDs.png "Maximum Used Transaction IDs")

##### Read IOPS

![Read IOPS](images-final/database-Read-IOPS.png "Read IOPS")

##### Read Throughput

![Read Throughput](images-final/database-Read-Throughput.png "Read Throughput")

##### Row counts

![Row Counts](images-final/database-row-counts.png "Row Counts")

##### Write IOPS

![Write IOPS](images-final/database-Write-IOPS.png "Write IOPS")

##### Write Latency

![Write Latency](images-final/database-Write-Latency.png "Write Latency")

##### Write Throughput

![Write Throughput](images-final/database-Write-Throughput.png "Write Throughput")

#### AWS Costs

##### 1 day

![One day](images-final/aws-cost-1-day.png "One day")

##### 3 day

![Three day](images-final/aws-cost-3-day.png "Three day")

## Cleanup

1. Stop stream-loader service
1. Snapshot database
1. Stop database cluster
    1. [Instructions](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-cluster-stop-start.html)
