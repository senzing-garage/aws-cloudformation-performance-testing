-- =============================================================================
-- 20-final.sql  —  run IMMEDIATELY after the workload (right after the last
-- addRecord). Captures the final snapshot and prints the deltas: the FACT
-- headline, every scalar counter, top statements, and per-table activity.
-- DELTA = final - baseline. Report the delta, never the raw cumulative value.
-- =============================================================================
\set ON_ERROR_STOP on

-- Clear any prior 'final' snapshot so this script is safe to re-run
-- (re-snapshots at the current moment; baseline is untouched).
DELETE FROM perf.snap_scalar    WHERE label = 'final';
DELETE FROM perf.snap_statement WHERE label = 'final';
DELETE FROM perf.snap_table     WHERE label = 'final';

SELECT perf.snapshot('final');

\echo ''
\echo '=================== RUN WINDOW ==================='
SELECT min(captured_at) FILTER (WHERE label='baseline') AS baseline_at,
       max(captured_at) FILTER (WHERE label='final')    AS final_at,
       max(captured_at) FILTER (WHERE label='final')
         - min(captured_at) FILTER (WHERE label='baseline') AS elapsed
FROM perf.snap_scalar;

\echo ''
\echo '=================== FACT REPORT HEADLINE (eviction-immune) ==================='
WITH d AS (
  SELECT metric, f.value - b.value AS delta
  FROM perf.snap_scalar f JOIN perf.snap_scalar b USING (metric)
  WHERE f.label='final' AND b.label='baseline'
)
SELECT
  (SELECT delta FROM d WHERE metric='db.blks_read')
    + (SELECT delta FROM d WHERE metric='db.blks_hit') AS logical_block_reads,
  (SELECT delta FROM d WHERE metric='db.blks_read')     AS physical_block_reads,
  (SELECT delta FROM d WHERE metric='wal.wal_bytes')    AS wal_bytes,
  (SELECT delta FROM d WHERE metric='db.xact_commit')   AS xact_commit,
  (SELECT delta FROM d WHERE metric='db.tup_inserted')  AS tup_inserted,
  (SELECT delta FROM d WHERE metric='db.tup_updated')   AS tup_updated,
  (SELECT delta FROM d WHERE metric='db.tup_deleted')   AS tup_deleted;

\echo ''
\echo '=================== ALL SCALAR DELTAS ==================='
SELECT f.metric, f.value - b.value AS delta
FROM perf.snap_scalar f JOIN perf.snap_scalar b USING (metric)
WHERE f.label='final' AND b.label='baseline'
ORDER BY f.metric;

\echo ''
\echo '=========== PER-STATEMENT DELTAS (top 25 by exec-time; EVICTION-LOSSY, top-N only) ==========='
SELECT f.calls - coalesce(b.calls,0)                       AS calls,
       f.rows  - coalesce(b.rows,0)                        AS rows,
       round(f.total_exec_time - coalesce(b.total_exec_time,0)) AS total_ms,
       f.shared_blks_read    - coalesce(b.shared_blks_read,0)    AS blks_read,
       f.shared_blks_written - coalesce(b.shared_blks_written,0) AS blks_written,
       f.shared_blks_dirtied - coalesce(b.shared_blks_dirtied,0) AS blks_dirtied,
       f.wal_bytes           - coalesce(b.wal_bytes,0)           AS wal_bytes,
       left(f.query, 80)                                   AS query
FROM perf.snap_statement f
LEFT JOIN perf.snap_statement b
       ON b.queryid = f.queryid AND b.label='baseline'
WHERE f.label='final'
  AND f.total_exec_time - coalesce(b.total_exec_time,0) > 0
ORDER BY f.total_exec_time - coalesce(b.total_exec_time,0) DESC
LIMIT 25;

\echo ''
\echo '=================== PER-TABLE DELTAS (tables touched by the run) ==================='
SELECT f.relname,
       f.n_tup_ins     - b.n_tup_ins     AS ins,
       f.n_tup_upd     - b.n_tup_upd     AS upd,
       f.n_tup_del     - b.n_tup_del     AS del,
       f.n_tup_hot_upd - b.n_tup_hot_upd AS hot_upd,
       f.seq_scan      - b.seq_scan      AS seq_scan,
       f.idx_scan      - b.idx_scan      AS idx_scan,
       f.heap_blks_read - b.heap_blks_read AS heap_read,
       f.heap_blks_hit  - b.heap_blks_hit  AS heap_hit,
       f.idx_blks_read  - b.idx_blks_read  AS idx_read
FROM perf.snap_table f JOIN perf.snap_table b USING (relid)
WHERE f.label='final' AND b.label='baseline'
  AND (f.n_tup_ins - b.n_tup_ins)
    + (f.n_tup_upd - b.n_tup_upd)
    + (f.n_tup_del - b.n_tup_del) > 0
ORDER BY (f.n_tup_ins - b.n_tup_ins)
       + (f.n_tup_upd - b.n_tup_upd)
       + (f.n_tup_del - b.n_tup_del) DESC;
