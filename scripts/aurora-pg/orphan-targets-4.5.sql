-- orphan-targets-4.5.sql
-- Were each orphan's RESOLVED target entities being changed DURING its guard window?
-- Targets come from orphan-probe-4.5.py (search_by_attributes with the orphan's own attributes, RESOLVED level).
-- The converged record (obs_ent 98511411 -> entity 22248760) is the control.
-- READ-ONLY. All joins are indexed (RES_ENT_OKEY_SK, OBS_ENT_SK, DSRC_RECORD_SK).
--   $PG -f /tmp/orphan-targets-4.5.sql > /tmp/orphan-targets.txt 2>&1

\timing on

DROP TABLE IF EXISTS _tgt;
CREATE TEMP TABLE _tgt (obs_ent_id bigint, res_ent_id bigint, first_hit timestamp, last_hit timestamp, outcome text);
INSERT INTO _tgt VALUES
 (43941309 ,  3260050,'2026-09-29 20:55:20','2026-09-29 21:00:19','orphan'),
 (32683731 ,  2853872,'2026-09-29 20:56:12','2026-09-29 21:01:11','orphan'),
 (63658802 , 19454513,'2026-09-29 22:24:36','2026-09-29 22:29:35','orphan'),
 (65167600 , 14064352,'2026-09-29 22:38:59','2026-09-29 22:43:55','orphan'),
 (68932502 , 28910449,'2026-09-29 22:48:38','2026-09-29 22:53:38','orphan'),
 (69623324 , 10537896,'2026-09-29 22:49:48','2026-09-29 22:54:47','orphan'),
 (82502528 ,  1712724,'2026-09-29 23:02:56','2026-09-29 23:07:54','orphan'),
 (75782375 ,  9507337,'2026-09-29 23:51:53','2026-09-29 23:56:51','orphan'),
 (86507744 , 40350282,'2026-09-29 23:54:52','2026-09-29 23:59:50','orphan'),
 (98108857 ,  8651703,'2026-09-30 00:43:26','2026-09-30 00:48:21','orphan'),
 (98108857 , 45355285,'2026-09-30 00:43:26','2026-09-30 00:48:21','orphan'),
 (100204658, 32235939,'2026-09-30 00:46:41','2026-09-30 00:51:38','orphan'),
 (100204658, 33849209,'2026-09-30 00:46:41','2026-09-30 00:51:38','orphan'),
 (100247130, 76604121,'2026-09-30 01:29:41','2026-09-30 01:34:38','orphan'),
 (96469831 , 12517635,'2026-09-30 01:32:32','2026-09-30 01:37:28','orphan'),
 (96469831 , 15177248,'2026-09-30 01:32:32','2026-09-30 01:37:28','orphan'),
 (96469831 , 70693082,'2026-09-30 01:32:32','2026-09-30 01:37:28','orphan'),
 (94779725 ,   601643,'2026-09-30 01:34:13','2026-09-30 01:39:09','orphan'),
 (94779725 , 59649669,'2026-09-30 01:34:13','2026-09-30 01:39:09','orphan'),
 (88490872 , 27155591,'2026-09-30 01:41:46','2026-09-30 01:46:44','orphan'),
 (98511411 , 22248760,'2026-09-30 00:48:04','2026-09-30 00:48:24','CONTROL-converged');

-- A. Per target entity: size now, when it was last touched, and how many of its records were first seen
--    inside [first_hit - 60 s, last_hit + 60 s]. A concurrent-add race shows up as records_new_in_window > 0.
\echo ===== A. target entity activity vs the orphan guard window =====
SELECT t.outcome, t.obs_ent_id, t.res_ent_id,
       count(*)                                                   AS records_now,
       min(r.first_seen_dt)                                       AS oldest_record_first_seen,
       max(r.first_seen_dt)                                       AS newest_record_first_seen,
       count(*) FILTER (WHERE r.first_seen_dt BETWEEN t.first_hit - interval '60 s' AND t.last_hit + interval '60 s')
                                                                  AS records_new_in_window,
       to_timestamp(NULLIF(e.last_touch_dt,0)/1000.0) AT TIME ZONE 'UTC' AS entity_last_touch_utc,
       (to_timestamp(NULLIF(e.last_touch_dt,0)/1000.0) AT TIME ZONE 'UTC')
           BETWEEN t.first_hit - interval '60 s' AND t.last_hit + interval '60 s' AS entity_touched_in_window,
       e.ent_state
FROM _tgt t
JOIN res_ent e          ON e.res_ent_id = t.res_ent_id
JOIN res_ent_okey k     ON k.res_ent_id = t.res_ent_id
JOIN obs_ent o          ON o.obs_ent_id = k.obs_ent_id
JOIN dsrc_record r      ON r.ent_src_key = o.ent_src_key AND r.dsrc_id = o.dsrc_id
GROUP BY t.outcome, t.obs_ent_id, t.res_ent_id, t.first_hit, t.last_hit, e.last_touch_dt, e.ent_state
ORDER BY t.first_hit, t.res_ent_id;

-- B. The individual target records that arrived inside the window (ids + seconds relative to the orphan's first guard hit).
\echo ===== B. target records first seen inside the guard window =====
SELECT t.obs_ent_id AS orphan_obs_ent_id, t.res_ent_id, o.obs_ent_id AS target_obs_ent_id, r.record_id,
       round(extract(epoch FROM r.first_seen_dt - t.first_hit)::numeric, 1) AS first_seen_minus_first_hit_s,
       round(extract(epoch FROM r.last_seen_dt  - t.first_hit)::numeric, 1) AS last_seen_minus_first_hit_s
FROM _tgt t
JOIN res_ent_okey k ON k.res_ent_id = t.res_ent_id
JOIN obs_ent o      ON o.obs_ent_id = k.obs_ent_id
JOIN dsrc_record r  ON r.ent_src_key = o.ent_src_key AND r.dsrc_id = o.dsrc_id
WHERE r.first_seen_dt BETWEEN t.first_hit - interval '60 s' AND t.last_hit + interval '60 s'
ORDER BY t.first_hit, first_seen_minus_first_hit_s;
