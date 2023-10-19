# Results of provisioned database comparative testing
#### 2023 Oct 19

- intro?

The purpose of this series of test executions is to understand the performance characteristics of various Amazon Web Services (AWS) Aurora database instance classes and AWS Elastic Container (ECS) task runtime platforms when loading data into the Senzing database.  In particular to compare the difference in both speed and cost of Intel and Graviton 3 processors across database instance class types.

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