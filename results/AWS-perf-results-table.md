

20M perf test run:
======================================================================================================================
Build:                          |  3.2.0-22229   |  3.3.0.22245   |  3.4.0.22333   |  3.4.0.22343   |  3.4.0.22343   |
Peak:                           |  3235          |  3165          |  2980          |  2891          |  2864          |
Warm-up:                        |     0.48 hours |     0.5  hours |     0.48 hours |     0.55 hours |     0.48 hours |
Average after warm-up:          |  2745          |  2614          |  2660          |  2450          |  2473          |
Average over entire run:        |  2331          |  2222          |  2331          |  2096          |  2137          |
Time to load 20M:               |     2.37 hours |     2.48 hours |     2.37 hours |     2.63 hours |     2.58 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     1          |     3          |
Total Billed read IOPS:         |    8,075,496   |   19,287,696   |        6,491   |  27,556,292    |   25,631,592   |
Total Billed write IOPS:        |  116,664,154   |   94,608,757   |   78,340,242   |  57,402,959    |  106,383,644   |
Notes:                          | embedded       | embedded       | embedded       | embedded       | embedded       |
                                | senzing        | senzing        | senzing        | senzing        | senzing        |
======================================================================================================================


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
Build:                          |  2.8.8-22088   |  3.0.0-22102   |  3.0.0-22110   |
Peak:                           |  2665          |  2745          |  2858          |
Warm-up:                        |     1.13 hours |     1.45 hours |    55 mins     |
Average after warm-up:          |  1548          |  1665          |  1797          |
Average over entire run:        |  1497          |  1575          |  1727          |
Time to load 100M:              |    23.12 hours |    17.67 hours |    16.07 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |
StreamLoader withinfo->ouputQ:  |    NO          |    NO          |    NO          |
Redoer withinfo->ouputQ:        |   YES          |   YES          |    NO          |
====================================================================================

