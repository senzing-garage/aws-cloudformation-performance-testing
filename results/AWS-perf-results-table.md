

20M perf test run:
=======================================================================================================================================================
Build:                          |  2.8.2-21243  |  2.8.8-22088   |  3.0.0-22119   |  3.2.0-22229   |  3.3.0.22245   |  3.4.0.22348   |  3.4.0.22352   |
Peak:                           |  2635         |  2588          |  2868          |  3235          |  3165          |  2873          |  2887          |
Warm-up:                        |     2 hours   |     1.62 hours |     0.67 hours |     0.48 hours |     0.5  hours |     0.48 hours |     0.58 hours |
Average after warm-up:          |  2204         |  2303          |  1967          |  2745          |  2614          |  2505          |  2438          |
Average over entire run:        |  1401         |  1572          |  1667          |  2331          |  2222          |  2151          |  2083          |
Time to load 20M:               |     4.0 hours |     3.5 hours  |     3.32 hours |     2.37 hours |     2.48 hours |     2.57 hours |     2.65 hours |
Records in dead-letter queue:   |     0         |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |               |                |   87,380,092   |    8,075,496   |   19,287,696   |   25,591,272   |   34,298,747   |
Total Billed write IOPS:        |               |                |  148,886,718   |  116,664,154   |   94,608,757   |  106,162,689   |  103,727,910   |
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

