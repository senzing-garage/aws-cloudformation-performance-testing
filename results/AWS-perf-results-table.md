
20250515
======================================================================================================================
Build:                          |  3.10.3-24159  |  3.12.3.24323  |  4.0.0.25132   |  4.0.0.25132   |  4.0.0.25132   |
Number of records:              |    25 M        |    24ish M     |    25 M        |    25 M        |    25 M        |
Peak:                           |  2444          |  2015          |  2427          |  2499          |  2483          |
Warm-up:                        |     0 mins     |    29 mins     |     0 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |  1749          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  1937          |  1582          |  1727          |  1820          |  1772          |
Time to load 20M:               |     3.1 hours  |     3.67 hours |     4 hours    |   3.8 hours    |   3.9 hours    |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      828,136   |      546,056   |    2,391,877   |    2,496,854   |    2,458,397   |
Total Billed write IOPS:        |   94,762,780   |   96,234,006   |  128,618,481   |  128,271,910   |  128,175,673   |
Max loader tasks:               |     44         |     40         |     30         |     36         |     36         |
Max redoer tasks:               |     38         |     40         |     43         |     43         |     39         |
Notes:                          | single DB inst | single DB inst | single DB inst | single DB inst | single DB inst |
                                | db.r6i.8xlarge |   serverless   | db.r6i.8xlarge | db.r6i.8xlarge | db.r6i.8xlarge |
                                | IO opt - AMD   |                |    IO opt      |    IO opt      |    IO opt      |
                                |                |                |                | 25% CPU loader | 25% CPU loader |
                                |                |                |                |                | sync commit off|
======================================================================================================================

20250514
======================================================================================================================
Build:                          |  3.8.0-23303   |  3.10.3-24159  |  3.12.3.24323  |  4.0.0.25064   |  4.0.0.25132   |
Number of records:              |   20M          |    25 M        |    24ish M     |    25 M        |    25 M        |
Peak:                           |  5222          |  2444          |  2015          |  4266          |  2427          |
Warm-up:                        |     0 mins     |     0 mins     |    29 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |   n/a          |  1749          |   n/a          |   n/a          |
Average over entire run:        |  4597          |  1937          |  1582          |  3521          |  1727          |
Time to load 20M:               |    1.22 hours  |     3.1 hours  |     3.67 hours |     1.97 hours |     4 hours    |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |           31   |      828,136   |      546,056   |           44   |    2,391,877   |
Total Billed write IOPS:        |   80,844,597   |   94,762,780   |   96,234,006   |  121,551,476   |  128,618,481   |
Max loader tasks:               |     64         |     44         |     40         |     78         |     30         |
Max redoer tasks:               |     31         |     38         |     40         |    143         |     43         |
Notes:                          | single DB inst | single DB inst | single DB inst | single DB inst | single DB inst |
                                |db.r6id.24xlarge| db.r6i.8xlarge |   serverless   | db.r6i.24xlarge| db.r6i.8xlarge |
                                |     IO opt     | IO opt - AMD   |                | IO opt - AMD   |    IO opt      |
======================================================================================================================

20250306
=====================================================================================================
Build:                          |  3.8.0-23303   |  3.10.3-24159  |  3.12.3.24323  |  4.0.0.25064   |
Number of records:              |   20M          |    25 M        |    24ish M     |    25 M        |
Peak:                           |  5222          |  2444          |  2015          |  4266          |
Warm-up:                        |     0 mins     |     0 mins     |    29 mins     |     0 mins     |
Average after warm-up:          |   n/a          |   n/a          |  1749          |   n/a          |
Average over entire run:        |  4597          |  1937          |  1582          |  3521          |
Time to load 20M:               |    1.22 hours  |     3.1 hours  |     3.67 hours |     1.97 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |           31   |      828,136   |      546,056   |           44   | <-odd
Total Billed write IOPS:        |   80,844,597   |   94,762,780   |   96,234,006   |  121,551,476   |
Max loader tasks:               |     64         |     44         |     40         |     78         | <-lots of processes
Max redoer tasks:               |     31         |     38         |     40         |    143         | <-lots of processes
Notes:                          | single DB inst | single DB inst | single DB inst | single DB inst |
                                |db.r6id.24xlarge| db.r6i.8xlarge |   serverless   | db.r6i.24xlarge|
                                |     IO opt     | IO opt - AMD   |                | IO opt - AMD   |
=====================================================================================================

==================================================================
Build:                          |  2.8.2-21243  |  3.8.0-23258   |
Peak:                           |  2635         |  5565          |
Average over entire run:        |  1401         |  3141          |
Time to load 20M:               |     4.0 hours |  1.77 hours    |
==================================================================

20241120
=====================================================================================================
Build:                          |  3.8.3-24043   |  3.10.4-24184  |  3.12.1.24295  |  3.12.3.24323  |
Number of records:              |    20 M        |    25 M        |    25 M        |    24ish M     |
Number of records loaded:       | 20000000       | 21645223       | 21645223       | 20928140       |
Peak:                           |  6004          |  2382          |  2049          |  2015          |
Warm-up:                        |    10 mins     |    31 mins     |    15 mins     |    29 mins     |
Average after warm-up:          |  4116          |  2025          |  1690          |  1749          |
Average over entire run:        |  3758          |  1776          |  1612          |  1582          |
Time to load 20M:               |     1.47 hours |     3.4 hours  |     3.73 hours |     3.67 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      669,101   |       18,904   |      574,897   |      546,056   |
Total Billed write IOPS:        |   81,852,443   |   96,558,504   |   99,307,108   |   96,234,006   |
Max loader tasks:               |     83         |     42         |     36         |     40         |
Max redoer tasks:               |     56         |     43         |     37         |     40         |
Notes:                          | multi DB inst  | single DB inst | single DB inst | single DB inst |
                                |   serverless   |   serverless   |   serverless   |   serverless   |
=====================================================================================================


20241021
======================================================================================================================
Build:                          |  3.8.3-24043   |  3.10.3-24159  |  3.10.4-24184  |  3.12.1-24281  |  3.12.1.24295  |
Number of records:              |    20 M        |    25 M        |    25 M        |    25 M        |    25 M        |
Number of records loaded:       | 20000000       | 21645223       | 21645223       | 21645223       | 21645223       |
Peak:                           |  6004          |  5309          |  2382          |  2049          |  2049          |
Warm-up:                        |    10 mins     |    25 mins     |    31 mins     |    29 mins     |    15 mins     |
Average after warm-up:          |  4116          |  4492          |  2025          |  1816          |  1690          |
Average over entire run:        |  3758          |  3530          |  1776          |  1659          |  1612          |
Time to load 20M:               |     1.47 hours |     1.7 hours  |     3.4 hours  |     3.62 hours |     3.73 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      669,101   |      508,216   |       18,904   |      576,546   |      574,897   |
Total Billed write IOPS:        |   81,852,443   |  100,824,689   |   96,558,504   |   98,743,472   |   99,307,108   |
Max loader tasks:               |     83         |    100         |     42         |     38         |     36         |
Max redoer tasks:               |     56         |     76         |     43         |     38         |     37         |
Notes:                          | multi DB inst  | multi DB inst  | single DB inst | single DB inst | single DB inst |
                                |   serverless   |   serverless   |   serverless   |   serverless   |   serverless   |
======================================================================================================================

20241007
=====================================================================================================
Build:                          |  3.8.3-24043   |  3.10.3-24159  |  3.10.4-24184  |  3.12.1-24281  |
Number of records:              |    20 M        |    25 M        |    25 M        |    25 M        |
Number of records loaded:       | 20000000       | 21645223       | 21645223       | 21645223       |
Peak:                           |  6004          |  5309          |  2382          |  2049          |
Warm-up:                        |    10 mins     |    25 mins     |    31 mins     |    29 mins     |
Average after warm-up:          |  4116          |  4492          |  2025          |  1816          |
Average over entire run:        |  3758          |  3530          |  1776          |  1659          |
Time to load 20M:               |     1.47 hours |     1.7 hours  |     3.4 hours  |     3.62 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      669,101   |      508,216   |       18,904   |      576,546   |
Total Billed write IOPS:        |   81,852,443   |  100,824,689   |   96,558,504   |   98,743,472   |
Max loader tasks:               |     83         |    100         |     42         |     38         |
Max redoer tasks:               |     56         |     76         |     43         |     38         |
Notes:                          | multi DB inst  | multi DB inst  | single DB inst | single DB inst |
                                |   serverless   |   serverless   |   serverless   |   serverless   |
=====================================================================================================

Diagnostic runs:
20240702
====================================================================================
Build:                          |  3.10.1.24135  |  3.10.3-24163  |  3.10.4-24184  |
Number of records:              |    25 M        |    25 M        |    25 M        |
Peak:                           |  2501          |  2404          |  2382          |
Warm-up:                        |    25 mins     |    29 mins     |    31 mins     |
Average after warm-up:          |  2197          |  2139          |  2025          |
Average over entire run:        |  1937          |  1896          |  1776          |
Time to load 20M:               |     3.1 hours  |     3.2 hours  |     3.4 hours  |
Records in dead-letter queue:   |     0          |     0          |     0          |
Total Billed read IOPS:         |      607,778   |      149,894   |       18,904   |
Total Billed write IOPS:        |   99,726,985   |   96,757,579   |   96,558,504   |
Max loader tasks:               |     45         |     44         |     42         |
Max redoer tasks:               |     43         |     43         |     43         |
Notes:                          | single DB inst | single DB inst | single DB inst |
                                |   serverless   |   serverless   |   serverless   |
====================================================================================


2x M perf test run:
20240610
===================================================================
Build:                          |  3.8.3-24043   |  3.10.3-24159  |
Number of records:              |    20 M        |    25 M        |
Peak:                           |  6004          |  5309          |
Warm-up:                        |    10 mins     |    25 mins     |
Average after warm-up:          |  4116          |  4492          |
Average over entire run:        |  3758          |  3530          |
Time to load 20M:               |     1.47 hours |     1.7 hours  |
Records in dead-letter queue:   |     0          |     0          |
Total Billed read IOPS:         |      669,101   |      508,216   |
Total Billed write IOPS:        |   81,852,443   |  100,824,689   |
Max loader tasks:               |     83         |    100         |
Max redoer tasks:               |     56         |     76         |
Notes:                          | multi DB inst  | multi DB inst  |
                                |   serverless   |   serverless   |
===================================================================

2x M perf test run:
20240607
===================================================================
Build:                          |  3.10.0-24115  |  3.10.3-24159  |
Number of records:              |    20 M        |    25 M        |
Peak:                           |  2627          |  2444          |
Warm-up:                        |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |   n/a          |
Average over entire run:        |  2314          |  1937          |
Time to load 20M:               |     2.4 hours  |     3.1 hours  |
Records in dead-letter queue:   |     0          |     0          |
Total Billed read IOPS:         |      672,562   |      828,136   |
Total Billed write IOPS:        |   84,355,485   |   94,762,780   |
Max loader tasks:               |     30         |     44         |
Max redoer tasks:               |     40         |     38         |
Notes:                          | single DB inst | single DB inst |
                                | db.r6i.8xlarge | db.r6i.8xlarge |
                                | IO opt - AMD   | IO opt - AMD   |
===================================================================


20M perf test run:
20240425
=======================================================================================================================================
Build:                          |  3.8.2-24009   |  3.8.3-24043   |  3.8.3-24043   |  3.9.0-24058   |  3.9.1-24074   |  3.10.0-24115  |
Peak:                           |  2704          |  2955          |  6004          |  2736          |  2679          |  2627          |
Warm-up:                        |     0 mins     |    12 mins     |    10 mins     |     0 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |  2665          |  4116          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  2640          |  2499          |  3758          |  2350          |  2321          |  2314          |
Time to load 20M:               |     2.1 hours  |     2.21 hours |     1.47 hours |     2.35 hours |     2.38 hours |     2.4 hours  |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      308,590   |      498,257   |      669,101   |      167,371   |      724,890   |      672,562   |
Total Billed write IOPS:        |   78,831,249   |   87,776,206   |   81,852,443   |   74,908,026   |   84,475,715   |   84,355,485   |
Max loader tasks:               |     40         |     41         |     83         |     42         |     30         |     30         |
Max redoer tasks:               |     43         |     42         |     56         |     40         |     31         |     40         |
Notes:                          | single DB inst | single DB inst | multi DB inst  | single DB inst | single DB inst | single DB inst |
                                | db.r6i.8xlarge |   serverless   |   serverless   | db.r6i.8xlarge | db.r6i.8xlarge | db.r6i.8xlarge |
                                | IO opt - AMD   |                |                | IO opt - AMD   | IO opt - AMD   | IO opt - AMD   |
=======================================================================================================================================


20240315
======================================================================================================================
Build:                          |  3.8.2-24009   |  3.8.3-24043   |  3.8.3-24043   |  3.9.0-24058   |  3.9.1-24074   |
Peak:                           |  2704          |  2955          |  6004          |  2736          |  2679          |
Warm-up:                        |     0 mins     |    12 mins     |    10 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |  2665          |  4116          |   n/a          |   n/a          |
Average over entire run:        |  2640          |  2499          |  3758          |  2350          |  2321          |
Time to load 20M:               |     2.1 hours  |     2.21 hours |     1.47 hours |     2.35 hours |     2.38 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      308,590   |      498,257   |      669,101   |      167,371   |      724,890   |
Total Billed write IOPS:        |   78,831,249   |   87,776,206   |   81,852,443   |   74,908,026   |   84,475,715   |
Max loader tasks:               |     40         |     41         |     83         |     42         |     30         |
Max redoer tasks:               |     43         |     42         |     56         |     40         |     31         |
Notes:                          | single DB inst | single DB inst | multi DB inst  | single DB inst | single DB inst |
                                | db.r6i.8xlarge |   serverless   |   serverless   | db.r6i.8xlarge | db.r6i.8xlarge |
                                | IO opt - AMD   |                |                | IO opt - AMD   | IO opt - AMD   |
======================================================================================================================



20240228
======================================================================================================================
Build:                          |  3.8.2-24009   |  3.8.2-24011   |  3.8.3-24043   |  3.8.3-24043   |  3.9.0-24058   |
Peak:                           |  2704          |  2708          |  2955          |  6004          |  2736          |
Warm-up:                        |     0 mins     |     0 mins     |    12 mins     |    10 mins     |     0 mins     |
Average after warm-up:          |   n/a          |   n/a          |  2665          |  4116          |   n/a          |
Average over entire run:        |  2640          |  2355          |  2499          |  3758          |  2350          |
Time to load 20M:               |     2.1 hours  |     2.35 hours |     2.21 hours |     1.47 hours |     2.35 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      308,590   |      689,234   |      498,257   |      669,101   |      167,371   |
Total Billed write IOPS:        |   78,831,249   |   84,635,912   |   87,776,206   |   81,852,443   |   74,908,026   |
Max loader tasks:               |     40         |     35         |     41         |     83         |     42         |
Max redoer tasks:               |     43         |     37         |     42         |     56         |     40         |
Notes:                          | single DB inst | single DB inst | single DB inst | multi DB inst  | single DB inst |
                                | db.r6i.8xlarge | db.r6i.8xlarge |   serverless   |   serverless   | db.r6i.8xlarge |
                                | IO opt - AMD   | IO opt - ARM   |                |                | IO opt - AMD   |
======================================================================================================================


20240213
=======================================================================================================================================
Build:                          |  3.8.0-23258   |  3.8.2-24009   |  3.8.2-24011   |  3.8.0-23258   |  3.8.3-24043   |  3.8.3-24043   |
Peak:                           |  2724          |  2704          |  2708          |  3010          |  2955          |  6004          |
Warm-up:                        |     0 mins     |     0 mins     |     0 mins     |    13 mins     |    12 mins     |    10 mins     |
Average after warm-up:          |   n/a          |   n/a          |   n/a          |  2638          |  2665          |  4116          |
Average over entire run:        |  2393          |  2640          |  2355          |  2493          |  2499          |  3758          |
Time to load 20M:               |    2.32 hours  |     2.1 hours  |     2.35 hours |     2.23 hours |     2.21 hours |     1.47 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      192,839   |      308,590   |      689,234   |      229,730   |      498,257   |      669,101   |
Total Billed write IOPS:        |   74,549,743   |   78,831,249   |   84,635,912   |   85,411,348   |   87,776,206   |   81,852,443   |
Max loader tasks:               |     40         |     40         |     35         |     45         |     41         |     83         |
Max redoer tasks:               |     23         |     43         |     37         |     25         |     42         |     56         |
Notes:                          | single DB inst | single DB inst | single DB inst | single DB inst | single DB inst | multi DB inst  |
                                | db.r6i.8xlarge | db.r6i.8xlarge | db.r6i.8xlarge |   serverless   |   serverless   |   serverless   |
                                |     IO opt     | IO opt - AMD   | IO opt - ARM   |                |                |                |
=======================================================================================================================================



20240112
====================================================================================
Build:                          |  3.8.0-23258   |  3.8.2-24009   |  3.8.2-24011   |
Peak:                           |  2724          |  2704          |  2708          |
Warm-up:                        |     0 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  2393          |  2640          |  2355          |
Time to load 20M:               |    2.32 hours  |     2.1 hours  |     2.35 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |
Total Billed read IOPS:         |      192,839   |      308,590   |      689,234   |
Total Billed write IOPS:        |   74,549,743   |   78,831,249   |   84,635,912   |
Max loader tasks:               |     40         |     40         |     35         |
Max redoer tasks:               |     23         |     43         |     37         |
Notes:                          | single DB inst | single DB inst | single DB inst |
                                | db.r6i.8xlarge | db.r6i.8xlarge | db.r6i.8xlarge |
                                |     IO opt     | IO opt - AMD   | IO opt - ARM   |
====================================================================================

20231219
=====================================================================================================
Build:                          |  3.8.0-23284   |  3.8.0-23284   |  3.8.0-23303   |  3.8.0-23303   |
Peak:                           |  3447          |  3916          |  3900          |  3001          |
Warm-up:                        |     0 mins     |     0 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  2999          |  3231          |  3413          |  2665          |
Time to load 20M:               |     1.85 hours |     1.73 hours |     1.63 hours |     2.08 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |           72   |            6   |            6   |           32   |
Total Billed write IOPS:        |  143,587,589   |   61,417,763   |   63,067,972   |   71,227,988   |
Max loader tasks:               |     40         |     52         |           46   |           36   |
Max redoer tasks:               |     13         |     13         |           15   |           12   |
Notes:                          | single DB inst | single DB inst | single DB inst | single DB inst |
  r7g - graviton3               | db.r7g.12xlarge| db.r7g.16xlarge|db.r6gd.16xlarge|db.r6gd.12xlarge|
  r6g - graviton2               |     IO opt     |     IO opt     |     IO opt     |     IO opt     |
=====================================================================================================

20231218
======================================================================================================================
Build:                          |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23303   |  3.8.0-23258   |  3.8.0-23303   |
Peak:                           |  5216          |  8597          |  5301          |  5392          |  5222          |
Warm-up:                        |     0 mins     |     0 mins     |     0 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |   n/a          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  4662          |  6962          |  4613          |  4553          |  4597          |
Time to load 20M:               |    1.20 hours  |    48 Mins     |     1.2  hours |    1.22 hours  |    1.22 hours  |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |           35   |           23   |           32   |           13   |           31   |
Total Billed write IOPS:        |   75,637,378   |   38,441,895   |   80,968,617   |   58,882,169   |   80,844,597   |
Max loader tasks:               |     77         |     125        |           68   |     75         |     64         |
Max redoer tasks:               |     20         |      28        |           17   |     14         |     31         |
Notes:                          | single DB inst |    multi DB    | single DB inst | single DB inst | single DB inst |
                                | db.r6i.32xlarge| db.r6i.32xlarge|db.r6id.32xlarge| db.r6i.24xlarge|db.r6id.24xlarge|
                                |     IO opt     |     IO opt     |     IO opt     |     IO opt     |     IO opt     |
======================================================================================================================


====================================================================================
Build:                          |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23284   | <----
Peak:                           |  3326          |  4578          |  4618          | This is a
Warm-up:                        |     0 mins     |     0 mins     |     0 mins     | hybrid install
Average after warm-up:          |   n/a          |   n/a          |   n/a          | the database
Average over entire run:        |  2893          |  3871          |  3864          | was intel, but
Time to load 20M:               |    1.92 hours  |    1.45 hours  |    1.43 hours  | loaders and
Records in dead-letter queue:   |     0          |     0          |     0          | redoers were
Total Billed read IOPS:         |            9   |           45   |            6   | graviton
Total Billed write IOPS:        |   32,287,062   |   80,902,551   |   65,678,413   |
Max loader tasks:               |     44         |     59         |     51         |
Max redoer tasks:               |     14         |     14         |     18         |
Notes:                          | single DB inst | single DB inst | single DB inst |
                                | db.r6i.12xlarge| db.r6i.16xlarge| db.r6i.16xlarge|
                                |     IO opt     |     IO opt     |     IO opt     |
====================================================================================
Build:                          |  3.8.0-23284   |  3.8.0-23284   |  3.8.0-23284   |
Peak:                           |  3447          |  3872          |  3916          |
Warm-up:                        |     0 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  2999          |  3159          |  3231          |
Time to load 20M:               |     1.85 hours |     1.77 hours |     1.73 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |
Total Billed read IOPS:         |           72   |           32   |            6   |
Total Billed write IOPS:        |  143,587,589   |   80,455,417   |   61,417,763   |
Max loader tasks:               |     40         |     52         |     52         |
Max redoer tasks:               |     13         |     13         |     13         |
Notes:                          | single DB inst | single DB inst | single DB inst |
                                | db.r7g.12xlarge| db.r7g.16xlarge| db.r7g.16xlarge|
                                |     IO opt     |     IO opt     |     IO opt     |
====================================================================================



========================================================================================================================================================
Build:                          |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |
Peak:                           |  5845          |  2724          |  3326          |  4578          |  5392          |  5216          |  8597          |
Warm-up:                        |     0.13 hours |     0 mins     |     0 mins     |     0 mins     |     0 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |  3800          |   n/a          |   n/a          |   n/a          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  3579          |  2393          |  2893          |  3871          |  4553          |  4662          |  6962          |
Time to load 20M:               |     1.55 hours |    2.32 hours  |    1.92 hours  |    1.45 hours  |    1.22 hours  |    1.20 hours  |    48 Mins     |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |    1,140,226   |      192,839   |            9   |           45   |           13   |           35   |           23   |
Total Billed write IOPS:        |  153,285,668   |   74,549,743   |   32,287,062   |   80,902,551   |   58,882,169   |   75,637,378   |   38,441,895   |
Max loader tasks:               |     78         |     40         |     44         |     59         |     75         |     77         |     125        |
Max redoer tasks:               |     27         |     23         |     14         |     14         |     14         |     20         |      28        |
Notes:                          | 30% loader cpu | single DB inst | single DB inst | single DB inst | single DB inst | single DB inst |    multi DB    |
                                |V1 DB 2-192 ACU | db.r6i.8xlarge | db.r6i.12xlarge| db.r6i.16xlarge| db.r6i.24xlarge| db.r6i.32xlarge| db.r6i.32xlarge|
                                |                |     IO opt     |     IO opt     |     IO opt     |     IO opt     |     IO opt     |     IO opt     |
========================================================================================================================================================
Build:                          |                |  3.8.0-23284   |  3.8.0-23284   |  3.8.0-23284   |
Peak:                           |                |  2962          |  3447          |  3872          |
Warm-up:                        |                |     0 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |                |   n/a          |   n/a          |   n/a          |
Average over entire run:        |                |  2640          |  2999          |  3159          |
Time to load 20M:               |                |     2.1 hours  |     1.85 hours |     1.77 hours |
Records in dead-letter queue:   |                |     0          |     0          |     0          |
Total Billed read IOPS:         |                |      371,525   |           72   |           32   |
Total Billed write IOPS:        |                |   79,550,498   |  143,587,589   |   80,455,417   |
Max loader tasks:               |                |     38         |     40         |     52         |
Max redoer tasks:               |                |     25         |     13         |     13         |
Notes:                          |                | single DB inst | single DB inst | single DB inst |
                                |                | db.r7g.8xlarge | db.r7g.12xlarge| db.r7g.16xlarge|
                                |                |     IO opt     |     IO opt     |     IO opt     |
=====================================================================================================


=======================================================================================================================================
Build:                          |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |
Peak:                           |  5845          |  8847          |  4309          |  2511          |  3326          |  4578          |
Warm-up:                        |     0.13 hours |     0 mins     |     0 mins     |     1 mins     |     0 mins     |     0 mins     |
Average after warm-up:          |  3800          |   n/a          |   n/a          |  2263          |   n/a          |   n/a          |
Average over entire run:        |  3579          |  6872          |  3151          |  2271          |  2893          |  3871          |
Time to load 20M:               |     1.55 hours |    48 Mins     |    1.77 hours  |    2.45 hours  |    1.92 hours  |    1.45 hours  |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |    1,140,226   |           21   |      138,795   |      383,053   |            9   |           45   |
Total Billed write IOPS:        |  153,285,668   |   43,889,497   |   81,025,325   |   80,747,403   |   32,287,062   |   80,902,551   |
Max loader tasks:               |     78         |     123        |     52         |     37         |     44         |     59         |
Max redoer tasks:               |     27         |      18        |      9         |     14         |     14         |     14         |
Notes:                          | 30% loader cpu |pre-loaded queue|pre-loaded queue|   single DB    | single DB inst | single DB inst |
                                |V1 DB 2-192 ACU | db.r6i.32xlarge| db.r6i.4xlarge | db.r6i.8xlarge | db.r6i.12xlarge| db.r6i.16xlarge|
                                |                |     IO opt     |     IO opt     |     IO opt     |     IO opt     |     IO opt     |
=======================================================================================================================================


==========================================================================================================================================================================================
Build:                          |  3.7.0-23235   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |
Peak:                           |  4132          |  5845          |  5565          |  6489          |  8847          |  7798          |  4309          |  7798          |  4262          |
Warm-up:                        |     0.6  hours |     0.13 hours |     0.18 hours |     0.00 hours |     0.00 hours |     0.07 hours |     0 hours    |     0.07 hours |     3 mins     |
Average after warm-up:          |  3327          |  3800          |  3527          |  N/A           |  N/A           |  6162          |   n/a          |  6162          |  3128          |
Average over entire run:        |  2938          |  3579          |  3141          |  3791          |  6872          |  5851          |  3151          |  5851          |  2852          |
Time to load 20M:               |     1.88 hours |     1.55 hours |     1.77 hours |     1.47 hours |    48 Mins     |    57 Mins     |    1.77 hours  |    57 Mins     |    1.95 hours  |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |      270,154   |    1,140,226   |    1,292,359   |           21   |           21   |           19   |      138,795   |           19   |       67,497   |
Total Billed write IOPS:        |   89,706,883   |  153,285,668   |   69,182,119   |   67,048,111   |   43,889,497   |   81,479,603   |   81,025,325   |   81,479,603   |   78,283,087   |
Max loader tasks:               |     60         |     78         |     84         |     55         |     123        |    113         |     52         |    113         |     49         |
Max redoer tasks:               |     13         |     27         |     30         |     14         |      18        |     20         |      9         |     20         |      7         |
Notes:                          | sz_sqs_consumer| 30% loader cpu | 30% loader cpu | provisioned    |pre-loaded queue|pre-loaded queue|pre-loaded queue|pre-loaded queue|pre-loaded queue|
                                |sz_simple_redoer|V1 DB 2-192 ACU |V1 DB 2-192 ACU | db.r6i.32xlarge| db.r6i.32xlarge| db.r6i.32xlarge| db.r6i.4xlarge | db.r6i.32xlarge| db.r6i.4xlarge |
                                |                |                |                |     IO opt     |     IO opt     |   no IO opt    |     IO opt     |   no IO opt    |   no IO opt    |
==========================================================================================================================================================================================

=======================================================================================================================================
Build:                          |  3.5.0.23044   |  3.6.0.23160   |  3.6.0.23160   |  3.8.0-23258   |  3.8.0-23258   |  3.8.0-23258   |
Peak:                           |  3430          |  4231          |  4266          |  3495          |  3020          |  3010          |
Warm-up:                        |     0.45 hours |     0.35 hours |     0.48 hours |     0.02 hours |     0.23 hours |     0.22 hours |
Average after warm-up:          |  2741          |  2802          |  3559          |  2760          |  2375          |  2638          |
Average over entire run:        |  2415          |  2488          |  3137          |  2760          |  2240          |  2493          |
Time to load 20M:               |     2.33 hours |     2.22 hours |     1.77 hours |     2.0  hours |     2.48 hours |     2.23 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |     0          |
Total Billed read IOPS:         |   21,704,226   |     73,021,926 |    7,958,177   |      166,939   |      846,564   |      229,730   |<- changed to volume read IOPS
Total Billed write IOPS:        |   69,134,272   |     94,894,153 |   48,696,085   |   84,804,069   |   67,755,672   |   85,411,348   |<- changed to volume write IOPS
Max loader tasks:               |    65          |    54          |     62         |     42         |     70         |     45         |(AWS doesn't have "Billed" IOPS
Max redoer tasks:               |    11          |     9          |     12         |     25         |     28         |     25         | stat available any more)
Notes:                          | sz_sqs_consumer|    go-load     | sz_sqs_consumer| 30% loader cpu | 20% loader cpu | 30% loader cpu |
                                |sz_simple_redoer|sz_simple_redoer|sz_simple_redoer|  DB 64-64 ACU  |  DB 2-128 ACU  |  DB 2-128 ACU  |
=======================================================================================================================================


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




=====================================================================================================================
100M perf test run:
=====================================================================================================================

20250307
====================================================================================
Build:                          |  3.8.0.23303   |  3.9.1.24074   |  4.0.0.25065   |
Peak:                           |  5358          |  5053          |  2483          |
Warm-up:                        |     0.0  hours |     0.0  hours |     0.0  hours |
Average after warm-up:          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  1856          |  2067          |   788          |
Time to load 100M:              |    14.97 hours |    13.43 hours |    35.25 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |
Volume read IOPS                |   23,253,554   |   46,846,823   |  205,865,075   |
Volume write IOPS               |  389,707,354   |  413,350,943   |  606,453,122   |
Max loader tasks:               |           69   |           53   |    33          |
Max redoer tasks:               |           60   |           75   |    30          |
Notes:                          | single DB inst | single DB inst | single DB inst |
                                |db.r6id.24xlarge| db.r6i.24xlarge| db.r6i.8xlarge | <-- note small database
                                |   IO opt       |   IO opt       |   IO opt       |
====================================================================================


20240315
====================================================================================
Build:                          |  3.8.0.23303   |  3.8.0.23303   |  3.9.1.24074   |
Peak:                           |  5268          |  5358          |  5053          |
Warm-up:                        |     0.0  hours |     0.0  hours |     0.0  hours |
Average after warm-up:          |   n/a          |   n/a          |   n/a          |
Average over entire run:        |  2440          |  1856          |  2067          |
Time to load 100M:              |    11.37 hours |    14.97 hours |    13.43 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |
Volume read IOPS                |   10,132,919   |   23,253,554   |   46,846,823   |
Volume write IOPS               |   64,709,674   |  389,707,354   |  413,350,943   |
Max loader tasks:               |    83          |           69   |           53   |
Max redoer tasks:               |   124          |           60   |           75   |
Notes:                          | single DB inst | single DB inst | single DB inst |
                                | db.r6i.32xlarge|db.r6id.24xlarge| db.r6i.24xlarge|
                                |   IO opt       |   IO opt       |   IO opt       |
====================================================================================

20231220
===================================================================
Build:                          |  3.8.0.23303   |  3.8.0.23303   |
Peak:                           |  5268          |  5358          |
Warm-up:                        |     0.0  hours |     0.0  hours |
Average after warm-up:          |   n/a          |   n/a          |
Average over entire run:        |  2440          |  1856          |
Time to load 100M:              |    11.37 hours |    14.97 hours |
Records in dead-letter queue:   |     0          |     0          |
Volume read IOPS                |   10,132,919   |   23,253,554   |
Volume write IOPS               |   64,709,674   |  389,707,354   |
Max loader tasks:               |    83          |           69   |
Max redoer tasks:               |   124          |           60   |
Notes:                          | single DB inst | single DB inst |
                                | db.r6i.32xlarge|db.r6id.24xlarge|
                                |   IO opt       |   IO opt       |
===================================================================


======================================================================================================================
Build:                          |  3.5.0-23044   |  3.6.0.23160   |  3.7.0.23235   |  3.8.0.23303   |  3.8.0.23303   |
Peak:                           |  3426          |  4274          |  4039          |  5840          |  5268          |
Warm-up:                        |    0.33 hours  |     0.25 hours |     0.35 hours |     0.15 hours |     0.0  hours |
Average after warm-up:          |  1238          |  1543          |  1254          |  1448          |   n/a          |
Average over entire run:        |  1232          |  1533          |  1246          |  1452          |  2440          |
Time to load 100M:              |    22.53 hours |    18.12 hours |    22.27 hours |    19.25 hours |    11.37 hours |
Records in dead-letter queue:   |     0          |     0          |     0          |     0          |     0          |
Volume read IOPS                |   882,035,913  |  834,099,266   |   52,810,611   |   51,285,770   |   10,132,919   |
Volume write IOPS               |   455,594,372  |  630,115,766   |  440,730,877   |  411,956,606   |   64,709,674   |
Max loader tasks:               |    60          |    63          |    59          |    99          |    83          |
Max redoer tasks:               |    19          |    20          |    18          |    46          |   124          |
Notes:                          | sz_sqs_consumer|                |                |                | single DB inst |
                                |sz_simple_redoer|                |                |                | db.r6i.32xlarge|
                                |                |                |                |                |   IO opt       |
======================================================================================================================


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

