

20M perf test run:
=====================================================================================================
Build:                          |  3.2.0-22201   |  3.2.0-22229   |  3.3.0.22245   |  3.3.0.22245   |
Peak:                           |  2771          |  3235          |  3128          |  3165          |
Warm-up:                        |     0.7  hours |     0.48 hours |     0.58 hours |     0.5  hours |
Average after warm-up:          |  2265          |  2745          |  2586          |  2614          |
Average over entire run:        |  1883          |  2331          |  2151          |  2222          |
Time to load 20M:               |     2.93 hours |     2.37 hours |     2.57 hours |     2.48 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |
StreamLoader withinfo->ouputQ:  |    NO          |    NO          |    NO          |    NO          |
Total Billed read IOPS:         |   41,585,961   |    8,075,496   |   20,911,476   |   19,287,696   |
Total Billed write IOPS:        |  134,027,300   |  116,664,154   |   64,107,655   |   94,608,757   |
Notes:                          | stream/redoer  | embedded       | embedded       | embedded       |
                                | loader changes | senzing        | senzing        | senzing        |
=====================================================================================================

=================
|  3.2.0-22201
|  2994
|     0.55 hours
|  2611
|  2165
|     2.55 hours
|     0
|    NO
|    5,419,094
|  119,066,657
| stream loader
| config changes
=================

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

