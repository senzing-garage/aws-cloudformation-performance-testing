-- =============================================================================
-- validate.sql  —  data-integrity sanity checks after a load completes.
-- BOTH queries should return ZERO rows. Any rows = records that didn't resolve
-- cleanly (orphans / dangling keys) — investigate before trusting the run.
-- =============================================================================
\set ON_ERROR_STOP on
\timing on

-- 1) DSRC_RECORDs with no resolved entity (loaded but never resolved):
SELECT dr.record_id, oe.obs_ent_id, reo.res_ent_id
FROM   dsrc_record dr
LEFT JOIN obs_ent oe       ON dr.dsrc_id = oe.dsrc_id AND dr.ent_src_key = oe.ent_src_key
LEFT JOIN res_ent_okey reo ON oe.obs_ent_id = reo.obs_ent_id
WHERE  reo.res_ent_id IS NULL;

-- 2) RES_ENT_OKEY rows pointing at a record that doesn't exist (dangling key):
SELECT dr.record_id, reo.obs_ent_id, reo.res_ent_id
FROM   res_ent_okey reo
LEFT JOIN obs_ent oe       ON oe.obs_ent_id = reo.obs_ent_id
LEFT JOIN dsrc_record dr   ON dr.dsrc_id = oe.dsrc_id AND dr.ent_src_key = oe.ent_src_key
WHERE  dr.record_id IS NULL;
