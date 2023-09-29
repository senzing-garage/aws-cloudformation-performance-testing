

20M perf test run:

=======================================================================================================================================
Build:                          |  3.5.0.23044   |  3.6.0.23160   |  3.7.0-23235   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |
Peak:                           |  3430          |  4266          |  4132          |  3010          |  5845          |  5565          |
Warm-up:                        |     0.45 hours |     0.48 hours |     0.6  hours |     0.22 hours |     0.13 hours |     0.18 hours |
Average after warm-up:          |  2741          |  3559          |  3327          |  2638          |  3800          |  3527          |
Average over entire run:        |  2415          |  3137          |  2938          |  2493          |  3579          |  3141          |
Time to load 20M:               |     2.33 hours |     1.77 hours |     1.88 hours |     2.23 hours |     1.55 hours |     1.77 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |   21,704,226   |    7,958,177   |      270,154   |      229,730   |    1,140,226   |    1,292,359   |
Total Billed write IOPS:        |   69,134,272   |   48,696,085   |   89,706,883   |   85,411,348   |  153,285,668   |   69,182,119   |
Max loader tasks:               |    65          |     62         |     60         |     45         |     78         |     84         |
Max redoer tasks:               |    11          |     12         |     13         |     25         |     27         |     30         |
Notes:                          | sz_sqs_consumer| sz_sqs_consumer| sz_sqs_consumer| 30% loader cpu | 30% loader cpu | 30% loader cpu |
                                |sz_simple_redoer|sz_simple_redoer|sz_simple_redoer|  DB 2-128 ACU  |V1 DB 2-192 ACU |V1 DB 2-192 ACU |
=======================================================================================================================================

======================================================================================================================
Build:                          |  3.5.0.23044   |  3.6.0.23160   |  3.6.0.23160   |  3.8.0-23258   |  3.8.0-23258   |
Peak:                           |  3430          |  4231          |  4266          |  3495          |  3020          |
Warm-up:                        |     0.45 hours |     0.35 hours |     0.48 hours |     0.02 hours |     0.23 hours |
Average after warm-up:          |  2741          |  2802          |  3559          |  2760          |  2375          |
Average over entire run:        |  2415          |  2488          |  3137          |  2760          |  2240          |
Time to load 20M:               |     2.33 hours |     2.22 hours |     1.77 hours |     2.0  hours |     2.48 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |   21,704,226   |     73,021,926 |    7,958,177   |      166,939   |      846,564   |<- changed to volume read IOPS
Total Billed write IOPS:        |   69,134,272   |     94,894,153 |   48,696,085   |   84,804,069   |   67,755,672   |<- changed to volume write IOPS
Max loader tasks:               |    65          |    54          |     62         |     42         |     70         |(AWS doesn't have "Billed" IOPS
Max redoer tasks:               |    11          |     9          |     12         |     25         |     28         | stat available any more)
Notes:                          | sz_sqs_consumer|    go-load     | sz_sqs_consumer| 30% loader cpu | 20% loader cpu |
                                |sz_simple_redoer|sz_simple_redoer|sz_simple_redoer|  DB 64-64 ACU  |  DB 2-128 ACU  |
======================================================================================================================


=======================================================================================================================================================
Build:                          |  2.8.2-21243  |  2.8.8-22088   |  3.0.0-22119   |  3.2.0-22229   |  3.3.0.22245   |  3.4.0.22352   |  3.4.0.23002   |
Peak:                           |  2635         |  2588          |  2868          |  3235          |  3165          |  2887          |  2944          |
Warm-up:                        |     2 hours   |     1.62 hours |     0.67 hours |     0.48 hours |     0.5  hours |     0.58 hours |     0.43 hours |
Average after warm-up:          |  2204         |  2303          |  1967          |  2745          |  2614          |  2438          |  2529          |
Average over entire run:        |  1401         |  1572          |  1667          |  2331          |  2222          |  2083          |  2208          |
Time to load 20M:               |     4.0 hours |     3.5 hours  |     3.32 hours |     2.37 hours |     2.48 hours |     2.65 hours |     2.5  hours |
Records in dead-letter queue:   |     0         |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |               |                |   87,380,092   |    8,075,496   |   19,287,696   |   34,298,747   |   7,456,800    |
Total Billed write IOPS:        |               |                |  148,886,718   |  116,664,154   |   94,608,757   |  103,727,910   |  64,280,349    |
Notes:                          |               |                |                | embedded       | embedded       | embedded       | embedded       |
                                |               |                |                | senzing        | senzing        | senzing        | senzing        |
=======================================================================================================================================================

=======================================================================================================================================
Build:                          |  3.4.0.23002   |  3.4.0.23002   |  3.4.0.23005   |  3.4.0.23005   |  3.5.0.23044   |  3.4.0.23005   |
Peak:                           |  2944          |  2992          |  3609          |  3579          |  3430          |  4278          |
Warm-up:                        |     0.43 hours |     0.37 hours |     0.38 hours |     0.38 hours |     0.45 hours |     0.02 hours |
Average after warm-up:          |  2529          |  2513          |  3056          |  3128          |  2741          |  3113          |
Average over entire run:        |  2208          |  2278          |  2653          |  2729          |  2415          |  3086          |
Time to load 20M:               |     2.5  hours |     2.43 hours |     2.08 hours |     2.03 hours |     2.33 hours |     1.92 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |   7,456,800    |   33,650,705   |   24,320,628   |    8,524,304   |   21,704,226   |  not recorded  |
Total Billed write IOPS:        |  64,280,349    |   89,414,998   |   64,445,602   |   65,619,220   |   69,134,272   |  not recorded  |
Max loader tasks:               |                |                |    68          |    63          |    65          |    58          |
Max redoer tasks:               |                |                |     8          |    12          |    11          |    10          |
Notes:                          | embedded       | sz_sqs_consumer| sz_sqs_consumer|sz_simple_redoer| sz_sqs_consumer| sz_sqs_consumer|
                                | senzing        |prefetch=threads|   2-384 ACU    |                |sz_simple_redoer|sz_simple_redoer|
=======================================================================================================================================


======================================================================================================================
Build:                          |  3.4.0.23002   |  3.4.0.23002   |  3.4.0.23002   |  3.4.0.23002   |  3.4.0.23005   |
Peak:                           |  2944          |  2870          |  2992          |  2922          |  2284          |
Warm-up:                        |     0.43 hours |     0.58 hours |     0.37 hours |     0.3  hours |     0.5  hours |
Average after warm-up:          |  2529          |  2378          |  2513          |  2276          |  2053          |
Average over entire run:        |  2208          |  2070          |  2278          |  2089          |  1859          |
Time to load 20M:               |     2.5  hours |     2.67 hours |     2.43 hours |     2.39 hours |     2.98 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |   7,456,800    |   34,812,188   |   33,650,705   |   36,419,618   |   2,740,754    |
Total Billed write IOPS:        |  64,280,349    |  113,205,429   |   89,414,998   |   74,157,822   |  60,978,671    |
Notes:                          | embedded       | sz_sqs_consumer| sz_sqs_consumer| sz_sqs_consumer| sz_sqs_consumer|
                                | senzing        |                |prefetch=threads|      40 threads| 1 db, 384 ACU  |
======================================================================================================================

==================================================
Build:                          |  3.4.0.22352   |
Peak:                           |  1353          |
Warm-up:                        |  never         | <- (we never reached 100000/min)
Average after warm-up:          |  n/a           |
Average over entire run:        |  1145          |
Time to load 20M:               |     4.83 hours |
Records in dead-letter queue:   |     0          |
Total Billed read IOPS:         |    1,800,853   | <- (none recorded for res)
Total Billed write IOPS:        |   72,894,806   | <- (none recorded for res)
Notes:                          | serverless v2  |
                                | postgres 14.5  |
==================================================

===================================================================
Build:                          |  3.4.0.22352   |  3.4.0.22352   |
Peak:                           |  2915          |  2092          |
Warm-up:                        |  0.45 hours    |  0.42 hours    |
Average after warm-up:          |  2691          |  1893          |
Average over entire run:        |  2364          |  1783          |
Time to load 20M:               |     2.33 hours |     3.1 hours  |
Records in dead-letter queue:   |     0          |     0          |
Total Billed read IOPS:         |        20,641  |       13,678   | <- (none recorded for v2 libfeat)
Total Billed write IOPS:        |   105,543,679  |   79,479,639   | <- (none recorded for v2 libfeat)
Notes:                          | serverless v1  | serverless v2  |
                                | postgres 11.23 | postgres 14.5  |
===================================================================

20M serverless v1 vs v2 at 64 ACU each:
===================================================================
Build:                          |  3.4.0.22352   |  3.4.0.22352   |
Peak:                           |  1405          |  1216          |
Warm-up:                        |   0.37 hours   |  0.37 hours    |
Average after warm-up:          |  1203          |  1059          |
Average over entire run:        |  1170          |  1042          |
Time to load 20M:               |     4.73 hours |     5.32 hours |
Records in dead-letter queue:   |     0          |     0          |
Total Billed read IOPS:         |     4,326,489  |    2,789,287   | <- (none recorded for v2 core)
Total Billed write IOPS:        |   146,430,085  |   99,698,417   | <- (none recorded for v2 core)
Notes:                          | serverless v1  | serverless v2  |
                                | postgres 11.23 | postgres 14.5  |
===================================================================



=======================================================================================================================================================
Build:                          |  2.8.2-21243  |  2.8.8-22088   |  3.2.0-22229   |  3.3.0.22245   |  3.4.0.22343   |  3.4.0.22343   |  3.4.0.22348   |
Peak:                           |  2635         |  2588          |  3235          |  3165          |  2891          |  2864          |  2873          |
Warm-up:                        |     2 hours   |     1.62 hours |     0.48 hours |     0.5  hours |     0.55 hours |     0.48 hours |     0.48 hours |
Average after warm-up:          |  2204         |  2303          |  2745          |  2614          |  2450          |  2473          |  2505          |
Average over entire run:        |  1401         |  1572          |  2331          |  2222          |  2096          |  2137          |  2151          |
Time to load 20M:               |     4.0 hours |     3.5 hours  |     2.37 hours |     2.48 hours |     2.63 hours |     2.58 hours |     2.57 hours |
Records in dead-letter queue:   |     0         |     0          |     0          |     0          |     1          |     3          |     0          |
Total Billed read IOPS:         |               |                |    8,075,496   |   19,287,696   |  27,556,292    |   25,631,592   |   25,591,272   |
Total Billed write IOPS:        |               |                |  116,664,154   |   94,608,757   |  57,402,959    |  106,383,644   |  106,162,689   |
Notes:                          |               |                | embedded       | embedded       | embedded       | embedded       | embedded       |
                                |               |                | senzing        | senzing        | senzing        | senzing        | senzing        |
=======================================================================================================================================================





=====================================================================================================================
Build:                          |  2.8.2-21243  |  2.8.8-22088   |  3.0.0-22119   |  3.1.0-22152   |  3.2.0-22201   |
Peak:                           |  2635         |  2588          |  2868          |  2736          |  2872          |
Warm-up:                        |     2 hours   |     1.62 hours |     0.75 hours |     0.9  hours |     0.9  hours |
Average after warm-up:          |  2204         |  2303          |  1967          |  2413          |  2468          |
Average over entire run:        |  1401         |  1572          |  1667          |  1862          |  1873          |
Time to load 20M:               |     4.0 hours |     3.5 hours  |     3.32 hours |     2.97 hours |     2.95 hours |
Records in dead-letter queue:   |     0         |     0          |     0          |     0          |     0          |
StreamLoader withinfo->ouputQ:  |   YES         |    NO          |    NO          |    NO          |    NO          |
Total Billed read IOPS          |               |                |   87,380,092   |   19,850,407   |   20,346,195   |
Total Billed write IOPS         |               |                |  148,886,718   |  120,464,308   |   93,738,844   |


=====================================================================================================================




100M perf test run:

====================================================================================
Build:                          |  3.5.0-23044   |  3.6.0.23160   |  3.7.0.23235   |
Peak:                           |  3426          |  4274          |  4039          |
Warm-up:                        |    0.33 hours  |     0.25 hours |     0.35 hours |
Average after warm-up:          |  1238          |  1543          |  1254          |
Average over entire run:        |  1232          |  1533          |  1246          |
Time to load 100M:              |    22.53 hours |    18.12 hours |    22.27 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |
Volume read IOPS                |   882,035,913  |  834,099,266   |   52,810,611   |
Volume write IOPS               |   455,594,372  |  630,115,766   |  440,730,877   |
Max loader tasks:               |    60          |    63          |    59          |
Max redoer tasks:               |    19          |    20          |    18          |
Notes:                          | sz_sqs_consumer|                |                |
                                |sz_simple_redoer|                |                |
====================================================================================


========================================================================================================================================================
Build:                          |  2.8.8-22088   |  3.0.0-22102   |  3.0.0-22110   |  3.4.0-22350   |  3.4.0-23002   |  3.5.0-23044   |  3.5.0-23084   |
Peak:                           |  2665          |  2745          |  2858          |  3017          |  2967          |  3426          | not collected  |
Warm-up:                        |     1.13 hours |     1.45 hours |    0.92 hours  |    0.47 hours  |    0.47 hours  |    0.33 hours  | not collected  |
Average after warm-up:          |  1548          |  1665          |  1797          |  1630          |  1439          |  1238          | not collected  |
Average over entire run:        |  1497          |  1575          |  1727          |  1606          |  1421          |  1232          |  1345          |
Time to load 100M:              |    23.12 hours |    17.67 hours |    16.07 hours |    17.28 hours |    19.53 hours |    22.53 hours |    20.65 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS          |                |                |                |  768,870,955   | 1,199,978,286  |   882,035,913  | not collected  |
Total Billed write IOPS         |                |                |                |  656,884,630   |   672,190,198  |   455,594,372  | not collected  |
Max loader tasks:               |                |                |    68          |    63          |    65          |    60          |    62          |
Max redoer tasks:               |                |                |     8          |    12          |    11          |    19          |    21          |
Notes:                          |                |                |                |                |                | sz_sqs_consumer|                |
                                |                |                |                |                |                |sz_simple_redoer|                |
========================================================================================================================================================


========================================================================================================================================================
Build:                          |  2.8.8-22088   |  3.0.0-22102   |  3.0.0-22110   |  3.4.0-22350   |  3.4.0-23002   |  3.5.0-23044   |  3.5.0-23044   |
Peak:                           |  2665          |  2745          |  2858          |  3017          |  2967          |  3400          |  3426          |
Warm-up:                        |     1.13 hours |     1.45 hours |    0.92 hours  |    0.47 hours  |    0.47 hours  |    0.32 hours  |    0.33 hours  |
Average after warm-up:          |  1548          |  1665          |  1797          |  1630          |  1439          |  1259          |  1238          |
Average over entire run:        |  1497          |  1575          |  1727          |  1606          |  1421          |  1254          |  1232          |
Time to load 100M:              |    23.12 hours |    17.67 hours |    16.07 hours |    17.28 hours |    19.53 hours |    22.13 hours |    22.53 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS          |                |                |                |  768,870,955   | 1,199,978,286  |   799,229,585  |   882,035,913  |
Total Billed write IOPS         |                |                |                |  656,884,630   |   672,190,198  |   471,872,715  |   455,594,372  |
Max loader tasks:               |                |                |    68          |    63          |    65          |    66          |    60          |
Max redoer tasks:               |                |                |     8          |    12          |    11          |    18          |    19          |
Notes:                          |                |                |                |                |                | sz_sqs_consumer| sz_sqs_consumer|
                                |                |                |                |                |                |sz_simple_redoer|sz_simple_redoer|
========================================================================================================================================================

100M perf test run (old):
======================================================================================================================
Build:                          |  2.8.8-22088   |  3.0.0-22102   |  3.0.0-22110   |  3.4.0-22350   |  3.4.0-23002   |
Peak:                           |  2665          |  2745          |  2858          |  3017          |  2967          |
Warm-up:                        |     1.13 hours |     1.45 hours |    0.92 hours  |    0.47 hours  |    0.47 hours  |
Average after warm-up:          |  1548          |  1665          |  1797          |  1630          |  1439          |
Average over entire run:        |  1497          |  1575          |  1727          |  1606          |  1421          |
Time to load 100M:              |    23.12 hours |    17.67 hours |    16.07 hours |    17.28 hours |    19.53 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
StreamLoader withinfo->ouputQ:  |    NO          |    NO          |    NO          |    NO          |    NO          |
Redoer withinfo->ouputQ:        |   YES          |   YES          |    NO          |    NO          |    NO          |
Total Billed read IOPS          |                |                |                |  768,870,955   | 1,199,978,286  |
Total Billed write IOPS         |                |                |                |  656,884,630   |   672,190,198  |
======================================================================================================================

