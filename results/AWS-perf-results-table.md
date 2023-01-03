

20M perf test run:
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
=====================================================================================================
Build:                          |  2.8.8-22088   |  3.0.0-22102   |  3.0.0-22110   |  3.4.0-22350   |
Peak:                           |  2665          |  2745          |  2858          |  3017          |
Warm-up:                        |     1.13 hours |     1.45 hours |    0.92 hours  |    0.47 hours  |
Average after warm-up:          |  1548          |  1665          |  1797          |  1630          |
Average over entire run:        |  1497          |  1575          |  1727          |  1606          |
Time to load 100M:              |    23.12 hours |    17.67 hours |    16.07 hours |    17.28 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |
StreamLoader withinfo->ouputQ:  |    NO          |    NO          |    NO          |    NO          |
Redoer withinfo->ouputQ:        |   YES          |   YES          |    NO          |    NO          |
Total Billed read IOPS          |                |                |                |  768,870,955   |
Total Billed write IOPS         |                |                |                |  656,884,630   |
=====================================================================================================

