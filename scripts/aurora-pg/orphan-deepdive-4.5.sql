-- orphan-deepdive-4.5.sql
-- DB-side state of the 4.5 "OKEY FLUSH ASSERTION FAILED" orphans (guard-caught, then SENZ0010, then DLQ).
-- READ-ONLY (SELECTs + TEMP tables). Run on the sshd host AFTER final-capture, BEFORE any repair test:
--   $PG -f /tmp/orphan-deepdive-4.5.sql > /tmp/orphan-deepdive.txt 2>&1
-- The ids below are from 20260929-100M-...-4.5.0.26268 (validate.sql q1 + the one guard hit that converged).
-- Output contains ids/timestamps only, except section 6 (a FEATURES preview). Keep section 6's output out of the public repo.

\timing on

-- 0. Guard episodes from CloudWatch (obs_ent_id, guard hits, first/last hit UTC, outcome).
DROP TABLE IF EXISTS _guard;
CREATE TEMP TABLE _guard (obs_ent_id bigint PRIMARY KEY, hits int, first_hit timestamp, last_hit timestamp, outcome text);
INSERT INTO _guard VALUES
 (43941309 , 374,'2026-09-29 20:55:20','2026-09-29 21:00:19','orphan'),
 (32683731 , 331,'2026-09-29 20:56:12','2026-09-29 21:01:11','orphan'),
 (49700916 , 228,'2026-09-29 21:05:00','2026-09-29 21:09:59','orphan'),
 (63658802 , 341,'2026-09-29 22:24:36','2026-09-29 22:29:35','orphan'),
 (65167600 , 295,'2026-09-29 22:38:59','2026-09-29 22:43:55','orphan'),
 (68932502 , 284,'2026-09-29 22:48:38','2026-09-29 22:53:38','orphan'),
 (69623324 , 275,'2026-09-29 22:49:48','2026-09-29 22:54:47','orphan'),
 (82502528 , 243,'2026-09-29 23:02:56','2026-09-29 23:07:54','orphan'),
 (75782375 , 567,'2026-09-29 23:51:53','2026-09-29 23:56:51','orphan'),
 (86507744 , 603,'2026-09-29 23:54:52','2026-09-29 23:59:50','orphan'),
 (98108857 , 879,'2026-09-30 00:43:26','2026-09-30 00:48:21','orphan'),
 (100204658,1352,'2026-09-30 00:46:41','2026-09-30 00:51:38','orphan'),
 (98511411 , 128,'2026-09-30 00:48:04','2026-09-30 00:48:24','converged'),
 (98236077 ,1641,'2026-09-30 01:11:57','2026-09-30 01:16:56','orphan'),
 (100247130,1638,'2026-09-30 01:29:41','2026-09-30 01:34:38','orphan'),
 (96469831 ,1256,'2026-09-30 01:32:32','2026-09-30 01:37:28','orphan'),
 (94779725 , 760,'2026-09-30 01:34:13','2026-09-30 01:39:09','orphan'),
 (88490872 ,1931,'2026-09-30 01:41:46','2026-09-30 01:46:44','orphan');

-- 1. Is the guard list == the DB's orphan set? (expect 17 rows, all outcome=orphan; the converged one must NOT appear)
\echo ===== 1. current orphans (obs_ent without res_ent_okey) joined to guard episodes =====
DROP TABLE IF EXISTS _orph;
CREATE TEMP TABLE _orph AS
  SELECT o.obs_ent_id FROM obs_ent o
  WHERE o.obs_ent_id IN (SELECT obs_ent_id FROM _guard)
    AND NOT EXISTS (SELECT 1 FROM res_ent_okey k WHERE k.obs_ent_id = o.obs_ent_id);
SELECT g.outcome, (x.obs_ent_id IS NOT NULL) AS is_orphan_now, count(*)
FROM _guard g LEFT JOIN _orph x USING (obs_ent_id)
GROUP BY 1, 2 ORDER BY 1, 2;
-- expect: converged | f | 1   and   orphan | t | 17

-- 2. Per-record state vs its guard window.
--    last_touch_dt (epoch ms) BEFORE first_hit  => the obs_ent row was committed before the guarded resolve ever ran
--                                                  (supports "insert committed in an earlier txn; rollback only undid resolution")
--    locking_id / lock_dsrc_action non-zero/null => a stranded lock
\echo ===== 2. per-record state vs guard window =====
SELECT g.obs_ent_id, g.outcome, g.hits, r.record_id,
       r.first_seen_dt, r.last_seen_dt,
       to_timestamp(NULLIF(o.last_touch_dt,0)/1000.0) AT TIME ZONE 'UTC' AS obs_last_touch_utc,
       g.first_hit, g.last_hit,
       CASE WHEN o.last_touch_dt IS NULL THEN NULL
            ELSE round(extract(epoch FROM (to_timestamp(o.last_touch_dt/1000.0) AT TIME ZONE 'UTC') - g.first_hit)::numeric,1) END
         AS touch_minus_first_hit_s,
       o.locking_id, o.lock_dsrc_action,
       length(o.features) AS features_len,
       EXISTS (SELECT 1 FROM res_ent_okey k WHERE k.obs_ent_id = g.obs_ent_id) AS has_okey
FROM _guard g
JOIN obs_ent o          ON o.obs_ent_id = g.obs_ent_id
LEFT JOIN dsrc_record r ON r.dsrc_id = o.dsrc_id AND r.ent_src_key = o.ent_src_key
ORDER BY g.first_hit;

-- 3. The converged one: which entity did it land in, by which rule, and how big is that entity?
\echo ===== 3. converged obs_ent 98511411 -> resolved entity =====
SELECT k.obs_ent_id, k.res_ent_id, k.errule_id, k.match_key,
       (SELECT count(*) FROM res_ent_okey k2 WHERE k2.res_ent_id = k.res_ent_id) AS entity_record_count,
       e.ent_state, e.locking_id,
       to_timestamp(NULLIF(e.last_touch_dt,0)/1000.0) AT TIME ZONE 'UTC' AS entity_last_touch_utc
FROM res_ent_okey k JOIN res_ent e ON e.res_ent_id = k.res_ent_id
WHERE k.obs_ent_id = 98511411;

-- 4. Anything still pending for these records? (expect 0 rows: sys_eval_queue drained)
\echo ===== 4. still queued in sys_eval_queue? (expect 0 rows) =====
SELECT g.obs_ent_id, q.msg_id
FROM _guard g JOIN obs_ent o ON o.obs_ent_id = g.obs_ent_id
JOIN sys_eval_queue q ON q.ent_src_key = o.ent_src_key;

-- 5. Were any resolved entities left in a non-zero state (the res_ent_active set) touched inside a guard window?
--    Overlap would suggest the orphan's target entity is one of the "active" leftovers.
--    NB: ent_state has no index -> full scan of RES_ENT (~60M rows); takes a minute or two.
\echo ===== 5. res_ent with ent_state<>0, last touched inside any guard window =====
SELECT e.res_ent_id, e.ent_state,
       to_timestamp(NULLIF(e.last_touch_dt,0)/1000.0) AT TIME ZONE 'UTC' AS last_touch_utc,
       g.obs_ent_id AS during_guard_of
FROM res_ent e
JOIN _guard g ON (to_timestamp(NULLIF(e.last_touch_dt,0)/1000.0) AT TIME ZONE 'UTC')
                 BETWEEN g.first_hit - interval '5 seconds' AND g.last_hit + interval '5 seconds'
WHERE e.ent_state <> 0
ORDER BY g.first_hit, e.res_ent_id;

-- 6. LOCAL ONLY (do not paste publicly): peek at the stored FEATURES format for one orphan and the converged one,
--    so we know how to join FEATURES -> LIB_FEAT in a follow-up query.
\echo ===== 6. FEATURES preview (LOCAL ONLY) =====
SELECT obs_ent_id, length(features) AS len, left(features, 300) AS features_head
FROM obs_ent WHERE obs_ent_id IN (49700916, 98511411);
