-- healed-check.sql : READ-ONLY. Did every obs_ent the 26275 engine logged as healed/repaired end up with a RES_ENT_OKEY?
\timing on
DROP TABLE IF EXISTS _healed;
CREATE TEMP TABLE _healed (obs_ent_id bigint, kind text, logged_res_ent bigint, logged_at timestamp);
INSERT INTO _healed VALUES
 (23286953,'ORPHAN REPAIRED',23286953,'2026-10-05 22:13:00'),
 (18497612,'AMBIGUOUS-BRIDGE',16886276,'2026-10-05 22:18:28'),
 (28296015,'AMBIGUOUS-BRIDGE',497715,'2026-10-05 22:36:15'),
 (42920935,'ORPHAN REPAIRED',42920935,'2026-10-05 22:52:28'),
 (43333459,'AMBIGUOUS-BRIDGE',1982213,'2026-10-05 23:00:58'),
 (30997394,'ORPHAN REPAIRED',30997394,'2026-10-05 23:03:43'),
 (45080612,'AMBIGUOUS-BRIDGE',2230860,'2026-10-05 23:42:29'),
 (73712562,'AMBIGUOUS-BRIDGE',14950855,'2026-10-06 00:56:54'),
 (65172585,'AMBIGUOUS-BRIDGE',6820875,'2026-10-06 01:31:59'),
 (73172234,'AMBIGUOUS-BRIDGE',22209168,'2026-10-06 01:51:10'),
 (73472227,'ORPHAN REPAIRED',73472227,'2026-10-06 01:52:19'),
 (65293978,'AMBIGUOUS-BRIDGE',7112629,'2026-10-06 01:54:13'),
 (83535663,'AMBIGUOUS-BRIDGE',9501249,'2026-10-06 02:46:52'),
 (87131833,'AMBIGUOUS-BRIDGE',394603,'2026-10-06 02:50:43'),
 (87333639,'AMBIGUOUS-BRIDGE',21173209,'2026-10-06 02:52:20'),
 (91428708,'AMBIGUOUS-BRIDGE',19040536,'2026-10-06 02:59:28'),
 (95029774,'ORPHAN REPAIRED',95029774,'2026-10-06 03:21:55'),
 (85268548,'ORPHAN REPAIRED',85268548,'2026-10-06 03:26:05'),
 (85272651,'AMBIGUOUS-BRIDGE',42272653,'2026-10-06 03:30:12'),
 (91477862,'AMBIGUOUS-BRIDGE',14206378,'2026-10-06 03:49:18'),
 (90692016,'AMBIGUOUS-BRIDGE',39359217,'2026-10-06 03:59:04'),
 (96939404,'AMBIGUOUS-BRIDGE',5667487,'2026-10-06 04:10:43'),
 (96642900,'AMBIGUOUS-BRIDGE',42245192,'2026-10-06 04:13:37'),
 (103423841,'AMBIGUOUS-BRIDGE',290154,'2026-10-06 04:29:33'),
 (42343700,'ABANDONING',42343700,'2026-10-06 06:18:03');
\echo ===== each healed / repaired / abandoned obs_ent: membership now =====
SELECT h.kind, h.obs_ent_id, h.logged_res_ent, k.res_ent_id AS okey_res_ent,
       (k.res_ent_id = h.logged_res_ent) AS same_as_logged, o.lock_dsrc_action, o.locking_id, r.record_id, h.logged_at
FROM _healed h
LEFT JOIN res_ent_okey k ON k.obs_ent_id = h.obs_ent_id
LEFT JOIN obs_ent o      ON o.obs_ent_id = h.obs_ent_id
LEFT JOIN dsrc_record r  ON r.ent_src_key = o.ent_src_key AND r.dsrc_id = o.dsrc_id
ORDER BY h.kind, h.logged_at;
\echo ===== the abandoned redo entity: state now =====
SELECT e.res_ent_id, e.ent_state, e.locking_id, (SELECT count(*) FROM res_ent_okey k WHERE k.res_ent_id = e.res_ent_id) AS records
FROM res_ent e WHERE e.res_ent_id IN (SELECT logged_res_ent FROM _healed WHERE kind = 'ABANDONING');
\echo ===== summary =====
SELECT kind, count(*) AS n, count(k.obs_ent_id) AS with_okey FROM _healed h LEFT JOIN res_ent_okey k USING (obs_ent_id) GROUP BY kind ORDER BY kind;
