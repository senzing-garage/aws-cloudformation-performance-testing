# Gathering IO / transaction metrics on AWS Aurora PostgreSQL & Azure SQL

A field guide for the performance tester. Goal: capture **trustworthy** IO and
transaction counters around a Senzing workload so two runs (e.g. immediate vs
deferred-write, or feature-on vs feature-off) can be compared honestly.

It is all done with SQL scripts — no host/OS access is needed (and on these
managed services you don't have it anyway).

> Aligns with the `sz-io-bench` FACT-report methodology
> (`.claude/faqs/architecture/deferred-write-io-benchmark.md`). For Senzing's
> recommended *tuning* settings (separate from metrics) see the Senzing docs:
> [Tuning Your Database → Aurora PostgreSQL](https://www.senzing.com/docs/tutorials/database/database_tuning/#aurora-postgresql)
> and
> [→ Microsoft SQL Server / Azure Hyperscale SQL](https://www.senzing.com/docs/tutorials/database/database_tuning/#microsoft-sql-server-and-azure-hyperscale-sql).

---

## The one rule that makes the numbers real

**Almost every counter on both platforms is *cumulative since some epoch*
(server start, statistics reset, or plan-cache load) — never a per-workload
total.** So the only honest method is **snapshot → run → snapshot → subtract**:

```
1. (once) Enable the stats sources.
2. BASELINE: snapshot every counter (or reset it to zero) immediately before the workload.
3. RUN the workload (load / search / redo) — and nothing else against that DB.
4. FINAL: snapshot the same counters immediately after.
5. DELTA = FINAL − BASELINE. Report the delta, never the raw cumulative value.
```

Two failure modes this avoids:
- **Warm-vs-cold contamination** — comparing a raw cumulative read across runs
  conflates this run with everything before it.
- **Eviction-lossy sources** — `pg_stat_statements` and SQL Server's
  `dm_exec_query_stats` evict entries under cache pressure, so a raw read is a
  *top-N survivors* list, not a total. Use them for *per-statement* attribution
  only; take headline totals from eviction-immune counters (below).

Isolate the DB: one workload at a time, no other clients, no autovacuum storm
mid-measurement if you can help it (note it if it fires).

---

## AWS Aurora PostgreSQL

> **Quick start (scripted).** The whole method below is packaged as a drop-in
> psql harness in [`scripts/aurora-pg/`](../scripts/aurora-pg/) — it captures
> *every* counter in one call and does the subtraction for you:
> ```console
> psql "$DBURL" -f scripts/aurora-pg/00-setup.sql    # once per database
> psql "$DBURL" -f scripts/aurora-pg/10-baseline.sql # right before the workload
> #   ... run the workload ...
> psql "$DBURL" -f scripts/aurora-pg/20-final.sql    # right after — prints deltas
> ```
> The sections below explain what those scripts do (and the reset-based
> alternative) so you can read or adapt them.

### 1. Enable (DB **cluster** parameter group — requires a reboot to apply static params)

| Parameter | Value | Why |
|---|---|---|
| `shared_preload_libraries` | include `pg_stat_statements` | per-statement call/row/time attribution (static — needs reboot) |
| `track_io_timing` | `on` | real read/write *time* in `pg_stat_*` (dynamic) |
| `track_activities` | `on` | live session/statement visibility (default on) |
| `pg_stat_statements.track` | `all` | include statements inside functions/triggers |
| `pg_stat_statements.max` | `10000`+ | fewer evictions → more trustworthy per-statement deltas |

Then, once per database:
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Optional but recommended on Aurora: turn on **Performance Insights** (console /
API) for a wait-event timeline you can't get from catalogs alone. PI is
complementary — the deltas below are still your source of truth for counts.

### 2. The metric sources (all eviction-immune except `pg_stat_statements`)

| Source | Gives you |
|---|---|
| `pg_stat_database` | xact_commit/rollback, blks_read (physical), blks_hit (cache), tup_* , temp files/bytes, deadlocks |
| `pg_statio_user_tables` / `pg_statio_user_indexes` | heap/index/toast blocks read vs hit, per relation |
| `pg_stat_user_tables` | tup_inserted/updated/deleted/hot, seq vs idx scans, per relation |
| `pg_stat_wal` *(PG14+; **NOT on Aurora** — see caveat)* | wal_records, wal_fpi, **wal_bytes** (the WAL-volume headline) |
| `pg_stat_statements` | calls, rows, total/mean exec time, shared blks hit/read/written/dirtied — **per statement** |
| `aurora_stat_*` *(Aurora-only)* | e.g. `aurora_stat_system_waits`, backend wait attribution |

> Aurora caveat: the storage layer is distributed and there is **no OS
> filesystem to read**, so PG16's `pg_stat_io` reflects the engine's buffer
> traffic, not raw EBS-style device IO. For "logical IO" use `blks_read +
> blks_hit` (8 KB blocks) from `pg_stat_database` / `pg_statio_*`; for physical
> read pressure use Performance Insights / CloudWatch `VolumeReadIOPs`. Report
> logical-block deltas as the comparable cross-run number (physical reads depend
> on cache warmth and aren't apples-to-apples).
>
> **No `pg_stat_wal` on Aurora:** `pg_stat_get_wal()` is blocked
> (`ERROR: ... not supported for Aurora`) because Aurora doesn't use stock
> PostgreSQL WAL — its distributed storage handles redo. So there is no
> `wal_bytes` headline from the catalogs. Use CloudWatch **`VolumeWriteIOPs`**
> (and `VolumeBytesUsed` growth) as the write-volume proxy. The
> `scripts/aurora-pg` harness catches this and just skips the WAL metrics.

### 3. Baseline — reset (cleanest) *or* snapshot

Reset is simplest if you have privileges (`rds_superuser`):
```sql
-- BASELINE via reset: run immediately before the workload.
SELECT pg_stat_reset();                       -- per-DB: pg_stat_database, *_user_tables, statio
SELECT pg_stat_reset_shared('wal');           -- pg_stat_wal
SELECT pg_stat_reset_shared('bgwriter');      -- checkpoint/bgwriter (optional)
SELECT pg_stat_statements_reset();            -- per-statement
```

If you can't reset (shared instance), snapshot into a table instead:
```sql
CREATE TABLE IF NOT EXISTS perf_snap (
  label text, ts timestamptz default now(), metric text, value numeric);

-- BASELINE snapshot
INSERT INTO perf_snap(label, metric, value)
SELECT 'baseline', 'db.'||k, v FROM (
  SELECT xact_commit, xact_rollback, blks_read, blks_hit,
         tup_inserted, tup_updated, tup_deleted, temp_files, temp_bytes, deadlocks
  FROM pg_stat_database WHERE datname = current_database()
) d, LATERAL (VALUES
  ('xact_commit',xact_commit::numeric),('xact_rollback',xact_rollback::numeric),
  ('blks_read',blks_read::numeric),('blks_hit',blks_hit::numeric),
  ('tup_inserted',tup_inserted::numeric),('tup_updated',tup_updated::numeric),
  ('tup_deleted',tup_deleted::numeric),('temp_files',temp_files::numeric),
  ('temp_bytes',temp_bytes::numeric),('deadlocks',deadlocks::numeric)
) AS kv(k,v);

INSERT INTO perf_snap(label, metric, value)
SELECT 'baseline','wal.wal_bytes', wal_bytes::numeric FROM pg_stat_wal;
```

### 4. Run the workload, then gather the delta

If you **reset**, the post-run read *is* the delta:
```sql
-- FINAL after reset = the workload's totals
SELECT xact_commit, xact_rollback,
       blks_read AS phys_block_reads, blks_hit AS logical_block_hits,
       (blks_read + blks_hit) AS logical_block_reads,
       tup_inserted, tup_updated, tup_deleted, temp_files, temp_bytes, deadlocks
FROM pg_stat_database WHERE datname = current_database();

SELECT wal_records, wal_fpi, wal_bytes FROM pg_stat_wal;

-- Per-statement attribution (eviction-lossy — treat as top-N, not a total).
-- wal_records/wal_fpi/wal_bytes are per-statement WAL (PG13+) — the most telling
-- columns for write-heavy / deferred-write comparisons.
SELECT calls, rows, round(total_exec_time) AS total_ms,
       shared_blks_hit, shared_blks_read, shared_blks_written, shared_blks_dirtied,
       temp_blks_read, temp_blks_written,
       wal_records, wal_fpi, wal_bytes,
       left(query, 80) AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 25;
```

If you **snapshotted**, repeat the baseline INSERT with `label='final'` and diff:
```sql
SELECT f.metric, f.value - b.value AS delta
FROM perf_snap f JOIN perf_snap b USING (metric)
WHERE f.label='final' AND b.label='baseline'
ORDER BY f.metric;
```

---

## Azure SQL Database (single DB / Hyperscale)

The big difference from a self-managed SQL Server: **you cannot restart the
instance and you cannot freely `DBCC FREEPROCCACHE`/reset most counters.** So on
Azure SQL the method is *always* snapshot-diff into temp tables, plus **Query
Store** (which is designed exactly for this and survives failover).

### 1. Enable

```sql
-- Query Store: the durable, eviction-resistant per-query history (per database).
ALTER DATABASE CURRENT SET QUERY_STORE = ON;
ALTER DATABASE CURRENT SET QUERY_STORE (
  OPERATION_MODE = READ_WRITE,
  INTERVAL_LENGTH_MINUTES = 1,           -- finest aggregation bucket
  DATA_FLUSH_INTERVAL_SECONDS = 60,
  QUERY_CAPTURE_MODE = ALL,              -- capture everything during the test (revert to AUTO after)
  MAX_STORAGE_SIZE_MB = 1024);
```

Nothing needs a preload/reboot. `sys.dm_*` DMVs are available by default (need
`VIEW DATABASE STATE`, which the app login usually has on its own DB).

### 2. The metric sources

| Source | Gives you | Eviction-immune? |
|---|---|---|
| `sys.dm_io_virtual_file_stats(DB_ID(), NULL)` | num_of_reads/writes, **num_of_bytes_read/written**, io_stall_ms — per data/log file. **Log file = WAL-equivalent bytes.** | ✅ (cumulative since DB online) |
| `sys.dm_os_performance_counters` | `Page lookups/sec`, `Batch Requests/sec`, `Page reads/writes/sec`, `Log Bytes Flushed/sec` (counters are cumulative totals despite the `/sec` name) | ✅ |
| Query Store (`sys.query_store_runtime_stats` + plan/query/interval views) | per-query count_executions, logical_io_reads/writes, CPU, duration, **rowcount** | ✅ (durable) |
| `sys.dm_exec_query_stats` | per-plan execution_count, logical_reads/writes | ❌ plan-cache eviction → top-N only |
| `sys.dm_db_resource_stats` | Azure DTU/vCore/IO/log utilization % (20s buckets, ~1h history) — confirms you weren't throttled | n/a (sampled) |

> Headline IO: take **logical reads** from `Page lookups/sec` (Buffer Manager,
> 8 KB pages, eviction-immune), **calls** from `Batch Requests/sec`, and **WAL
> bytes** from the log file's `num_of_bytes_written` in
> `dm_io_virtual_file_stats`. Do **not** headline `dm_exec_query_stats` — it's
> plan-cache-lossy (this is the exact correction `sz-io-bench` made: logical IO
> from eviction-immune counters, query_stats for per-statement only).

### 3. Baseline — snapshot into temp tables (you can't reset on Azure SQL)

```sql
-- BASELINE: run immediately before the workload.
SELECT file_id, num_of_reads, num_of_bytes_read, num_of_writes,
       num_of_bytes_written, io_stall
INTO   #vfs_base
FROM   sys.dm_io_virtual_file_stats(DB_ID(), NULL);

SELECT counter_name, cntr_value
INTO   #perf_base
FROM   sys.dm_os_performance_counters
WHERE  counter_name IN ('Page lookups/sec','Page reads/sec','Page writes/sec',
                        'Batch Requests/sec','Log Bytes Flushed/sec')
  AND  instance_name IN ('', '_Total');

-- Query Store: just note the wall-clock window; you'll filter intervals by time.
SELECT SYSUTCDATETIME() AS baseline_utc;
```

### 4. Run the workload, then gather the delta

```sql
-- FINAL deltas: run immediately after the workload.
SELECT v.file_id,
       CASE WHEN mf.type_desc='LOG' THEN 'LOG (WAL-equiv)' ELSE 'DATA' END AS kind,
       v.num_of_reads      - b.num_of_reads        AS reads,
       v.num_of_bytes_read - b.num_of_bytes_read   AS bytes_read,
       v.num_of_writes     - b.num_of_writes       AS writes,
       v.num_of_bytes_written - b.num_of_bytes_written AS bytes_written,
       v.io_stall          - b.io_stall            AS io_stall_ms
FROM   sys.dm_io_virtual_file_stats(DB_ID(), NULL) v
JOIN   #vfs_base b ON b.file_id = v.file_id
JOIN   sys.database_files mf ON mf.file_id = v.file_id
ORDER  BY kind;

SELECT p.counter_name,
       p.cntr_value - b.cntr_value AS delta
FROM   sys.dm_os_performance_counters p
JOIN   #perf_base b ON b.counter_name = p.counter_name
WHERE  p.instance_name IN ('', '_Total');
-- 'Page lookups/sec' delta = logical block reads (8 KB pages) for the workload.
-- 'Batch Requests/sec' delta = SQL calls. 'Log Bytes Flushed/sec' delta ~ WAL bytes.
```

Per-query attribution from Query Store (durable; filter to the test window):
```sql
SELECT q.query_id, SUM(rs.count_executions) AS execs,
       SUM(rs.count_executions * rs.avg_logical_io_reads)  AS logical_reads,
       SUM(rs.count_executions * rs.avg_logical_io_writes) AS logical_writes,
       SUM(rs.count_executions * rs.avg_rowcount)          AS rows_,
       SUBSTRING(qt.query_sql_text,1,80) AS sql_
FROM   sys.query_store_runtime_stats rs
JOIN   sys.query_store_runtime_stats_interval i ON i.runtime_stats_interval_id = rs.runtime_stats_interval_id
JOIN   sys.query_store_plan p  ON p.plan_id  = rs.plan_id
JOIN   sys.query_store_query q  ON q.query_id = p.query_id
JOIN   sys.query_store_query_text qt ON qt.query_text_id = q.query_text_id
WHERE  i.start_time >= @baseline_utc      -- the timestamp captured at baseline
GROUP  BY q.query_id, SUBSTRING(qt.query_sql_text,1,80)
ORDER  BY logical_reads DESC;
```

Confirm you weren't throttled (so the IO numbers reflect work, not a cap):
```sql
SELECT MAX(avg_cpu_percent) cpu, MAX(avg_data_io_percent) data_io,
       MAX(avg_log_write_percent) log_io
FROM   sys.dm_db_resource_stats;   -- last ~1h, 20s buckets
```

After the test, set Query Store back to `QUERY_CAPTURE_MODE = AUTO` to avoid
capture overhead in steady state.

---

## Mapping to the `sz-io-bench` FACT report (so numbers line up)

| FACT field | Aurora PostgreSQL | Azure SQL |
|---|---|---|
| logical block reads | `blks_read + blks_hit` (8 KB) | `Page lookups/sec` delta (8 KB) |
| physical block reads | `blks_read` / PI VolumeReadIOPs | `Page reads/sec` delta |
| logical block writes | `pg_stat_statements.shared_blks_written` | (no eviction-immune analog → report 0) |
| WAL bytes | `pg_stat_wal.wal_bytes` (**N/A on Aurora** → CloudWatch `VolumeWriteIOPs`) | log file `num_of_bytes_written` |
| SQL calls | `pg_stat_statements.calls` (sum) | `Batch Requests/sec` delta |
| txns | `pg_stat_database.xact_commit` | Query Store `count_executions` of `COMMIT`, or app-side |
| tuple insert/update/delete | `pg_stat_user_tables.tup_*` | (no tuple-level DMV → report 0) |

Common gotchas, both platforms:
- The `/sec`-named SQL Server perf counters are **cumulative totals**, not rates
  — diff two snapshots, don't read once.
- `dm_io_virtual_file_stats` / `pg_stat_*` survive only until a failover/restart
  resets the epoch; on a managed failover mid-test, throw the run out.
- Take the baseline as **late** as possible (right before the first `addRecord`)
  and the final as **early** as possible (right after the last) to keep
  background noise out of the delta.
