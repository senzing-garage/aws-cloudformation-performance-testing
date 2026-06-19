-- =============================================================================
-- 10-baseline.sql  —  run IMMEDIATELY before the workload (last thing before
-- the first addRecord). Clears any prior snapshot and captures the baseline.
-- =============================================================================
\set ON_ERROR_STOP on

TRUNCATE perf.snap_scalar, perf.snap_statement, perf.snap_table;
SELECT perf.snapshot('baseline');

\echo ''
\echo 'BASELINE captured. Run the workload (and nothing else against this DB),'
\echo 'then run:  \i 20-final.sql'
