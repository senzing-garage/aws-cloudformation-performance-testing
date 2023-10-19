# Results of provisioned database comparative testing
#### 2023 Oct 19

- intro?

The purpose of this series of test executions is to understand the performance characteristics of various Amazon Web Services (AWS) Aurora database instance classes[^1] and AWS Elastic Container (ECS) task runtime platforms[^2] when loading data with Senzing.  In particular to compare the difference in both speed and cost of Intel and Graviton 3 processors across database instance class types and runtime platforms. Full results of all Senzing AWS performance testing can be found in the Senzing AWS performance testing GitHub repository[^3].

## The Methodology


To test different platforms we need to hold constant as many variables as possible. We used the same CloudFormation Template[^4] (CFT) across all of our test executions.  There are only a few changes to the CFT necessary to switch between Intel and Graviton Databases and runtime platforms. We used Senzing version 3.8.0 for our tests.

### The data
- First 20M from standard test data set
- Same data for each run
- 20M queued before test start

We chose to process 20 million records as part of our test.  The same 20 million records were used for each test.  This test set is the same set we use to test new version of Senzing to validate performance across new releases.  Using the same set of data gives us reasonably predictable results across the different database instance classes and runtime platforms.

### Senzing loader configuration
- Start 8 loaders
- 30% CPU … auto scaling setup?

To guarantee that records are available for Senzing loader tasks to process, we pre-loaded a Simple Queue Service[^5] (SQS) queue with the 20 million records.  Early on we discovered that large database class types would scale to out pace our sending of records to the SQS queue. This led us to redesign the test to load the SQS queue prior to executing the test. In our normal performance testing, we start 8 loader tasks on stack creation.  When we redesigned the test we changed the CFT to start the stack with 0 loaders tasks. We then manually start the 8 loader tasks once the SQS was fully loaded with 20 million records.  The AWS application auto scaling policy was set for the loader tasks as 30% of the average CPU usage. In previous testing we found that if the CPU is above 30%, then there is usually database availability that other loader tasks could utilize. In the CFT, the loader policy looks like this:

```
  ApplicationAutoScalingScalingPolicyStreamLoader:
    Condition: IfRunStreamLoader
    Properties:
      PolicyName: !Sub "${AWS::StackName}-scaling-policy-stream-loader"
      PolicyType: TargetTrackingScaling
      ScalingTargetId: !Ref ApplicationAutoScalingScalableTargetStreamLoader
      TargetTrackingScalingPolicyConfiguration:
        PredefinedMetricSpecification:
          PredefinedMetricType: ECSServiceAverageCPUUtilization
        ScaleInCooldown: 1200
        ScaleOutCooldown: 300
        TargetValue: 30
    Type: AWS::ApplicationAutoScaling::ScalingPolicy
```

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

Another area of experimentation that could be beneficial is the quantity of and auto scaling settings for the loader tasks. We predefined 8 loader tasks to start our tests.  If we knew, a priori, that we'd need, for example, 50 loaders based on the database instance class we were using, we could start with that number of tasks instead of scaling up to an appropriate number. Likewise, these tests used a fairly simple auto scaling policy.  It could be that a more sophisticated scale up policy might more efficiently load the database when many records are being processed.  Similarly, a more sophisticated scale down policy could come with some cost saving when processing is completed and loader tasks need to scale back.


[^1]: [AWS Database Instance Classes](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Concepts.DBInstanceClass.html)
[^2]: [AWS ECS Task Runtime Platforms](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#runtime-platform)
[^3]: Results of Senzing testing can be in the Senzing AWS performance testing repo results directory [here](https://github.com/Senzing/aws-cloudformation-performance-testing/tree/main/results).
[^4]: [CloudFormation Templates](https://aws.amazon.com/cloudformation/resources/templates/)
[^5]: [Simple Queue Service](https://aws.amazon.com/sqs/)