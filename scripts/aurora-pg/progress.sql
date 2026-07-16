-- =============================================================================
-- progress.sql  —  run repeatedly DURING a load to watch throughput & queue depth.
-- Safe to run anytime; read-only. Re-run every few minutes to eyeball the rate.
--
-- ⚠️  count(*)-BASED — OK at 25M, but on large/heavily-loaded DBs (e.g. 100M)
--     these full scans degrade catastrophically (seen: 47s -> 114s -> 31min hang)
--     under enable_seqscan=0 + a churning sys_eval_queue, AND they pin the vacuum
--     horizon and pollute the harness deltas. For those runs use progress-live.sql
--     (instant, catalog-only) for live monitoring and final-capture.sql for exact
--     end-of-run numbers. See the runbook.
-- =============================================================================
\set ON_ERROR_STOP on
\timing on

-- Row counts across the key Senzing tables, with a timestamp so successive runs
-- give you a by-hand rate. (count(*) on the big tables can take a while at scale.)
SELECT now() AS at,
       (SELECT count(*) FROM dsrc_record)                  AS dsrc_record,
       (SELECT count(*) FROM obs_ent)                      AS obs_ent,
       (SELECT count(*) FROM res_ent)                      AS res_ent,
       (SELECT count(*) FROM res_ent_okey)                 AS res_ent_okey,
       (SELECT count(*) FROM sys_eval_queue)               AS sys_eval_queue,
       (SELECT count(*) FROM res_ent WHERE ent_state != 0) AS res_ent_active,
       (SELECT count(*) FROM res_relate)                   AS res_relate;

-- Overall load throughput so far: total loaded, wall-clock duration, and
-- entity-resolutions per minute (erpm) / per second (avg_erps).
SELECT min(first_seen_dt)                                  AS load_start,
       max(first_seen_dt) - min(first_seen_dt)             AS duration,
       count(*)                                            AS total,
       count(*) / (extract(EPOCH FROM (max(first_seen_dt) - min(first_seen_dt))) / 60)        AS erpm,
       (count(*) / (extract(EPOCH FROM (max(first_seen_dt) - min(first_seen_dt))) / 60)) / 60 AS avg_erps
FROM dsrc_record;
