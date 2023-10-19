# Results of provisioned database comparative testing
#### 2023 Oct 19

- intro?

The purpose of this series of test executions is to understand the performance characteristics of various Amazon Web Services (AWS) Aurora database instance classes and AWS Elastic Container (ECS) task runtime platforms when loading data with Senzing.  In particular to compare the difference in both speed and cost of Intel and Graviton 3 processors across database instance class types and runtime platforms. Full results of all Senzing AWS performance testing can be found in the Senzing AWS performance testing GitHub repo[^1].

## The Methodology


To test different platforms we need to hold constant as many variables as possible. We used the same CloudFormation Template (CFT) across all of our test executions.  There are only a few changes to the CFT necessary to switch between Intel and Graviton Databases and runtime platforms. We used Senzing version 3.8.0 for our tests.

### The data
- First 20M from standard test data set
- Same data for each run
- 20M queued before test start

We chose to process 20 million records as part of our test.  The same 20 million records were used for each test.  This test set is the same set we use to test new version of Senzing to validate performance across new releases.

### Senzing loader configuration
- Start 8 loaders
- 30% CPU … auto scaling setup?

To guarantee that records are available for Senzing loader tasks to process, we pre-loaded a Simple Queue Service (SQS) queue with the 20 million records.  Early on we discovered that large database class types would scale to out pace our sending of records into the SQS queue. This led us to redesign the test to load the SQS queue prior to executing the test. In our normal performance testing, we start 8 loader tasks on stack creation.  When we redesigned the test we changed the CFT to start 0 loaders tasks. We then manually start the 8 loader tasks once the SQS was fully loaded.

### Database configuration
- IO optimized
- Single DB, single instance
- DB parameters?

## The Comparison

- Platform size
- Cross platform
- Total time
- Avg. records per second
- Cost estimates

Minimize auto scaling by starting X number of loaders at start

## Further work

- hybrid DB instance class and runtime platform

As new instance classes and runtime platforms become available, we should re-run these tests and compare to these results.  Further work could be done to see if there are any advantages to using a hybrid set in which the database instance may be running on one architecture while the loaders are on another.  There could be cost savings and speed improvements by fine tuning these options.

## References:

1. Senzing AWS performance repository:  https://github.com/Senzing/aws-cloudformation-performance-testing
1. AWS Database class intance types:  https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.DBInstanceClass.html


[^1]: Results of Senzing testing can be in the Senzing AWS performance testing repo results directory [here](https://github.com/Senzing/aws-cloudformation-performance-testing/tree/main/results).