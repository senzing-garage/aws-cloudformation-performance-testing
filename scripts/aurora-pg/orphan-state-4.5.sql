-- seq-check.sql : READ-ONLY. What is in sys_eval_queue now, and where are the 17 original orphans?
\timing on

\echo ===== 1. sys_eval_queue now: total rows by data source =====
SELECT dsrc_code, count(*) AS rows, min(msg_id) AS min_msg_id, max(msg_id) AS max_msg_id
FROM sys_eval_queue GROUP BY dsrc_code ORDER BY 1;

\echo ===== 2. the 17 original orphans: resolved now? marker? anything queued? =====
SELECT o.obs_ent_id, r.record_id, o.locking_id, o.lock_dsrc_action,
       EXISTS (SELECT 1 FROM res_ent_okey k WHERE k.obs_ent_id = o.obs_ent_id)  AS has_okey,
       (SELECT k.res_ent_id FROM res_ent_okey k WHERE k.obs_ent_id = o.obs_ent_id) AS res_ent_id,
       (SELECT count(*) FROM sys_eval_queue q WHERE q.ent_src_key = o.ent_src_key) AS queued_msgs,
       r.last_seen_dt
FROM obs_ent o
JOIN dsrc_record r ON r.ent_src_key = o.ent_src_key AND r.dsrc_id = o.dsrc_id
WHERE o.obs_ent_id IN (32683731,43941309,49700916,63658802,65167600,68932502,69623324,75782375,82502528,
                       86507744,88490872,94779725,96469831,98108857,98236077,100204658,100247130)
ORDER BY has_okey, o.obs_ent_id;

\echo ===== 3. LOCAL ONLY: first 10 queued messages (may contain record data) =====
SELECT msg_id, dsrc_code, ent_src_key, left(msg, 200) AS msg_head FROM sys_eval_queue ORDER BY msg_id LIMIT 10;
