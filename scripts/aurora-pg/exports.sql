-- =============================================================================
-- exports.sql  —  write detail CSVs to /tmp on the shell host. After running,
-- scp them back to your results/<run>/data directory (see the runbook).
--
-- \copy writes to the machine running psql (the sshd shell), NOT the DB server.
-- =============================================================================
\set ON_ERROR_STOP on

-- Inserts per minute over the whole run (load-rate curve for the spreadsheet).
-- File name kept as dsrc_record.csv to match the results/ convention.
\copy (SELECT date_trunc('minute', first_seen_dt) AS time, count(*) AS inserts_per_minute FROM dsrc_record GROUP BY time ORDER BY time DESC) TO '/tmp/dsrc_record.csv' WITH CSV HEADER

-- Match-key distribution — resolved entities and relationships:
\copy (SELECT match_key, count(*) FROM res_ent_okey GROUP BY match_key ORDER BY 2 DESC) TO '/tmp/match_key_ent.csv' WITH CSV HEADER
\copy (SELECT match_key, count(*) FROM res_relate   GROUP BY match_key ORDER BY 2 DESC) TO '/tmp/match_key_rel.csv' WITH CSV HEADER

-- Raw stat sources for the record. NOTE: these are cumulative-since-epoch dumps,
-- not deltas — for honest cross-run IO numbers use the 10-baseline / 20-final
-- harness instead (see ../../docs/cloud-db-io-metrics.md). pg_stat_io is PG16+.
\copy (SELECT * FROM pg_stat_io WHERE reads <> 0 OR writes <> 0 OR extends <> 0) TO '/tmp/pg_stat_io.csv' WITH CSV HEADER
\copy (SELECT * FROM pg_stat_statements) TO '/tmp/pg_stat_statements.csv' WITH CSV HEADER

\echo 'Exports written to /tmp/*.csv on this host. scp them back to results/<run>/data.'
