# Aurora PostgreSQL IO/transaction metrics — scripted harness

Drop-in companion to [`docs/cloud-db-io-metrics.md`](../../docs/cloud-db-io-metrics.md).
It turns the manual *snapshot → run → snapshot → subtract* methodology into two
commands and does the subtraction for you, so two runs can be compared honestly
(e.g. immediate vs deferred-write, feature-on vs feature-off).

## Prerequisites

- `pg_stat_statements` in the cluster parameter group's `shared_preload_libraries`
  and `track_io_timing = on` (static → needs a reboot). See the doc's enablement
  table. `00-setup.sql` prints these settings so you can confirm they took.
- Connect as the Aurora master user (has `rds_superuser`).

## Usage

```console
# Once per database (creates extension, perf schema, snapshot function):
psql "$DBURL" -f 00-setup.sql

# Around each measured run:
psql "$DBURL" -f 10-baseline.sql     # immediately before the first addRecord
#   ... run the Senzing workload, and nothing else against this DB ...
psql "$DBURL" -f 20-final.sql        # immediately after the last addRecord
```

`20-final.sql` prints the run window, the FACT-report headline (logical/physical
block reads, WAL bytes, txns, tuple ins/upd/del), every scalar delta, the top 25
statements by exec-time delta (now including **per-statement WAL bytes** and
write/dirty block deltas), and per-table tuple + block IO.

Re-running `10-baseline.sql` clears the previous snapshot, so each run starts clean.

### Companion scripts (used by the runbook)

| Script | Run when | Purpose |
|---|---|---|
| `progress-live.sql` | during the load (repeatedly) | **instant** catalog-only progress + churn health + horizon watchdog. Use this on large/loaded DBs. |
| `drain-check.sql` | after loader reports done | drain gate — confirm the queue truly drained before capturing |
| `final-capture.sql` | after `20-final.sql`, load quiet | exact end-of-run counts + throughput/erpm (forces heap seq scan; VACUUMs first) |
| `validate.sql` | after the load | orphan / dangling-key integrity checks (expect zero rows) |
| `exports.sql` | after the load | write detail CSVs to `/tmp` for download |
| `progress.sql` | 25M runs only | ⚠️ count(*)-based; hangs on 100M under load — prefer `progress-live.sql` |

For the full launch → connect → measure → record process, see
[`docs/performance-test-runbook.md`](../../docs/performance-test-runbook.md).

## What it captures

| Layer | Source | Eviction-immune? |
|---|---|---|
| whole-DB xact/blocks/tuples/temp/deadlocks + IO timing | `pg_stat_database` | ✅ |
| WAL records / FPI / **bytes** | `pg_stat_wal` (PG14+) | ✅ |
| per-statement calls/rows/time/blocks/**WAL** | `pg_stat_statements` | ❌ top-N only |
| per-table tuples, scans, heap/idx blocks | `pg_stat_user_tables` + `pg_statio_user_tables` | ✅ |

## Notes & limits

- **Reset vs snapshot:** this harness uses the snapshot-into-table path (works
  without disturbing other sessions). Its own snapshot writes add a few txns and
  a few KB of WAL to the delta — negligible against a multi-million-record load.
  For bit-exact small-N runs, use the `pg_stat_reset()` path in the doc instead.
- **Eviction:** per-statement rows can be evicted under cache pressure — treat
  that section as attribution, not a total. Headline totals come from the
  eviction-immune scalars.
- **Failover:** a managed failover/restart resets the counter epoch. If one fires
  mid-run, throw the run out.
- Physical reads (`blks_read`) depend on cache warmth and aren't apples-to-apples
  across runs; compare on logical block reads. For true device IOPS use
  Performance Insights / CloudWatch `VolumeReadIOPs`.

## Cleanup

```sql
DROP SCHEMA perf CASCADE;   -- removes snapshot tables + function
```
