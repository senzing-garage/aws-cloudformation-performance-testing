-- =============================================================================
-- 00-setup.sql  —  run ONCE per database, before your first measured run.
--
-- Creates the pg_stat_statements extension, a `perf` schema, the snapshot
-- tables, and a perf.snapshot(label) function that captures every
-- eviction-immune counter in one call. Idempotent — safe to re-run.
--
-- Requires: pg_stat_statements in shared_preload_libraries (static — needs a
-- cluster reboot to take effect) and rds_superuser (the Aurora master user has
-- it). See ../../docs/cloud-db-io-metrics.md for the parameter-group settings.
-- =============================================================================
\set ON_ERROR_STOP on

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE SCHEMA IF NOT EXISTS perf;

-- Whole-DB / WAL scalars as key-value rows (one wide diff later).
CREATE TABLE IF NOT EXISTS perf.snap_scalar (
  label       text        NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now(),
  metric      text        NOT NULL,
  value       numeric
);

-- Per-statement attribution. EVICTION-LOSSY: pg_stat_statements drops entries
-- under cache pressure, so treat these as top-N attribution, not totals.
CREATE TABLE IF NOT EXISTS perf.snap_statement (
  label             text        NOT NULL,
  captured_at       timestamptz NOT NULL DEFAULT now(),
  queryid           bigint,
  query             text,
  calls             numeric,
  rows              numeric,
  total_exec_time   numeric,
  shared_blks_hit   numeric,
  shared_blks_read  numeric,
  shared_blks_written  numeric,
  shared_blks_dirtied  numeric,
  temp_blks_read    numeric,
  temp_blks_written numeric,
  wal_records       numeric,
  wal_fpi           numeric,
  wal_bytes         numeric
);

-- Per-table tuple + block IO (eviction-immune).
CREATE TABLE IF NOT EXISTS perf.snap_table (
  label         text        NOT NULL,
  captured_at   timestamptz NOT NULL DEFAULT now(),
  relid         oid,
  relname       text,
  n_tup_ins     numeric,
  n_tup_upd     numeric,
  n_tup_del     numeric,
  n_tup_hot_upd numeric,
  seq_scan      numeric,
  idx_scan      numeric,
  heap_blks_read numeric,
  heap_blks_hit  numeric,
  idx_blks_read  numeric,
  idx_blks_hit   numeric
);

CREATE OR REPLACE FUNCTION perf.snapshot(p_label text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE
  v_ver int := current_setting('server_version_num')::int;
BEGIN
  -- pg_stat_database — whole-DB, eviction-immune.
  INSERT INTO perf.snap_scalar(label, metric, value)
  SELECT p_label, 'db.'||k, v
  FROM (
    SELECT xact_commit, xact_rollback, blks_read, blks_hit,
           tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted,
           temp_files, temp_bytes, deadlocks, blk_read_time, blk_write_time
    FROM pg_stat_database WHERE datname = current_database()
  ) d, LATERAL (VALUES
    ('xact_commit',      d.xact_commit::numeric),
    ('xact_rollback',    d.xact_rollback::numeric),
    ('blks_read',        d.blks_read::numeric),
    ('blks_hit',         d.blks_hit::numeric),
    ('tup_returned',     d.tup_returned::numeric),
    ('tup_fetched',      d.tup_fetched::numeric),
    ('tup_inserted',     d.tup_inserted::numeric),
    ('tup_updated',      d.tup_updated::numeric),
    ('tup_deleted',      d.tup_deleted::numeric),
    ('temp_files',       d.temp_files::numeric),
    ('temp_bytes',       d.temp_bytes::numeric),
    ('deadlocks',        d.deadlocks::numeric),
    ('blk_read_time_ms', d.blk_read_time::numeric),
    ('blk_write_time_ms',d.blk_write_time::numeric)
  ) AS kv(k, v);

  -- pg_stat_wal — WAL-volume headline (PG14+). NOT supported on Aurora
  -- (pg_stat_get_wal() is blocked: Aurora doesn't use stock PostgreSQL WAL), so
  -- wrap in its own subtransaction and skip gracefully if it errors. Use the
  -- CloudWatch VolumeWriteIOPs metric as the write-volume proxy on Aurora.
  IF v_ver >= 140000 THEN
    BEGIN
      INSERT INTO perf.snap_scalar(label, metric, value)
      SELECT p_label, 'wal.'||k, v
      FROM (SELECT wal_records, wal_fpi, wal_bytes FROM pg_stat_wal) w,
      LATERAL (VALUES
        ('wal_records', w.wal_records::numeric),
        ('wal_fpi',     w.wal_fpi::numeric),
        ('wal_bytes',   w.wal_bytes::numeric)
      ) AS kv(k, v);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'pg_stat_wal unavailable (e.g. Aurora) — skipping WAL metrics: %', SQLERRM;
    END;
  END IF;

  -- Per-statement, aggregated to one row per queryid for this database.
  -- wal_* per statement is PG13+ — the most telling columns for write-heavy runs.
  INSERT INTO perf.snap_statement(label, queryid, query, calls, rows, total_exec_time,
    shared_blks_hit, shared_blks_read, shared_blks_written, shared_blks_dirtied,
    temp_blks_read, temp_blks_written, wal_records, wal_fpi, wal_bytes)
  SELECT p_label, queryid, left(max(query), 200),
         sum(calls), sum(rows), sum(total_exec_time),
         sum(shared_blks_hit), sum(shared_blks_read),
         sum(shared_blks_written), sum(shared_blks_dirtied),
         sum(temp_blks_read), sum(temp_blks_written),
         sum(wal_records), sum(wal_fpi), sum(wal_bytes)
  FROM pg_stat_statements
  WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
  GROUP BY queryid;

  -- Per-table tuple + block IO.
  INSERT INTO perf.snap_table(label, relid, relname, n_tup_ins, n_tup_upd, n_tup_del,
    n_tup_hot_upd, seq_scan, idx_scan, heap_blks_read, heap_blks_hit,
    idx_blks_read, idx_blks_hit)
  SELECT p_label, t.relid, t.relname, t.n_tup_ins, t.n_tup_upd, t.n_tup_del,
         t.n_tup_hot_upd, t.seq_scan, coalesce(t.idx_scan, 0),
         io.heap_blks_read, io.heap_blks_hit,
         coalesce(io.idx_blks_read, 0), coalesce(io.idx_blks_hit, 0)
  FROM pg_stat_user_tables t
  JOIN pg_statio_user_tables io ON io.relid = t.relid;
END;
$$;

-- Confirm the enablement settings actually took (these come from the cluster
-- parameter group + reboot, not from this script).
\echo '--- relevant settings (want: pg_stat_statements preloaded, track_io_timing=on) ---'
SELECT name, setting FROM pg_settings
WHERE name IN ('shared_preload_libraries','track_io_timing','track_activities',
               'pg_stat_statements.track','pg_stat_statements.max')
ORDER BY name;

\echo 'Setup complete. Before each run: \i 10-baseline.sql   After each run: \i 20-final.sql'
