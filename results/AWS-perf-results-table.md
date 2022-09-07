

20M perf test run:
=====================================================================================================
Build:                          |  3.2.0-22201   |  3.2.0-22201   |  3.2.0-22201   |  3.2.0-22229   |
Peak:                           |  2872          |  2994          |  2771          |  3235          |
Warm-up:                        |     0.9  hours |     0.55 hours |     0.7  hours |     0.48 hours |
Average after warm-up:          |  2468          |  2611          |  2265          |  2745          |
Average over entire run:        |  1873          |  2165          |  1883          |  2331          |
Time to load 20M:               |     2.95 hours |     2.55 hours |     2.93 hours |     2.37 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |
StreamLoader withinfo->ouputQ:  |    NO          |    NO          |    NO          |    NO          |
Total Billed read IOPS:         |   20,346,195   |    5,419,094   |   41,585,961   |    8,075,496   |
Total Billed write IOPS:        |   93,738,844   |  119,066,657   |  134,027,300   |  116,664,154   |
Notes:                          |                | stream loader  | stream/redoer  | embedded       |
                                |                | config changes | loader changes | senzing        |
=====================================================================================================

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

