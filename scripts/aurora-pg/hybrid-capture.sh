#!/usr/bin/env bash
# hybrid-capture.sh - end-of-run capture for a Senzing HYBRID (CORE / RES / LIBFEAT) perf run.
#
# Run ON THE SSHD HOST after the load and redo have drained, with the run's SQL scripts already in /tmp
# (drain-check.sql, 20-final.sql, validate.sql, exports.sql, final-capture.sql, hybrid-lock-snapshot.sh):
#   bash /tmp/hybrid-capture.sh 2>&1 | tee /tmp/hybrid-capture.log
#
# Connections and the password come from SENZING_ENGINE_CONFIGURATION_JSON (as hybrid-prepare-nodes.sh), so no
# PG_* variables or PGPASSWORD need to be set. Writes everything to /tmp; copy back with
#   scp "$H:/tmp/final-deltas-*.txt" "$H:/tmp/validate.txt" "$H:/tmp/final-capture.txt" "$H:/tmp/hybrid-counts.txt" "$D/"
#   scp "$H:/tmp/dsrc_record.csv" "$H:/tmp/match_key_ent.csv" "$H:/tmp/match_key_rel.csv" "$H:/tmp/pg_stat_*-*.csv" "$D/"
#   scp -r "$H:/tmp/locks/" "$D/"
# Steps: stop the lock watcher + one last snapshot; drain-check (CORE); 20-final (all nodes); validate (CORE; slow,
# ~20 min at 100M); exports (CORE) + per-node pg_stat_io / pg_stat_statements; final-capture (CORE; VACUUMs first);
# FEATURES count, per-node row counts and table sizes.
set -uo pipefail
: "${SENZING_ENGINE_CONFIGURATION_JSON:?not set on this host}"

conn() {  # conn NODE -> "user host port dbname password"
  python3 - "$1" <<'PY'
import json, os, re, sys
cfg = json.loads(os.environ["SENZING_ENGINE_CONFIGURATION_JSON"])
url = {"CORE": cfg["SQL"]["CONNECTION"], "RES": cfg.get("C1", {}).get("DB_1", ""), "LIBFEAT": cfg.get("C2", {}).get("DB_1", "")}[sys.argv[1]]
m = re.match(r"postgresql://([^:]+):(.*)@([^:@]+):(\d+):(\w+)$", url)
if not m: sys.exit(f"cannot parse {sys.argv[1]} connection (is BACKEND=HYBRID?)")
u, pw, h, p, d = m.groups(); print(u, h, p, d, pw)
PY
}
pg() {  # pg NODE [psql args...]
  local node=$1; shift
  read -r U H P D PW < <(conn "$node")
  PGPASSWORD="$PW" psql -X -h "$H" -p "$P" -U "$U" -d "$D" "$@"
}
step() { echo; echo "=== $(date -u +%H:%M:%S) $*"; }

step "lock watcher: stop + final snapshot"
pkill -f "hybrid-lock-snapshot.sh watch" && sleep 2
[ -f /tmp/hybrid-lock-snapshot.sh ] && bash /tmp/hybrid-lock-snapshot.sh once

step "drain-check (CORE)"
pg CORE -f /tmp/drain-check.sql

step "20-final (all nodes)"
for n in CORE RES LIBFEAT; do
  pg $n -f /tmp/20-final.sql > /tmp/final-deltas-$n.txt 2>&1
  echo "$n -> /tmp/final-deltas-$n.txt ($(wc -l < /tmp/final-deltas-$n.txt) lines)"
done

step "validate (CORE) - q1 = loaded but unresolved (orphans), q2 = dangling keys; slow"
pg CORE -f /tmp/validate.sql > /tmp/validate.txt 2>&1
grep -E "rows?\)" /tmp/validate.txt

step "exports (CORE full set + per-node pg_stat files)"
pg CORE -f /tmp/exports.sql && for f in pg_stat_io pg_stat_statements; do mv /tmp/$f.csv /tmp/$f-core.csv; done
for n in RES LIBFEAT; do
  l=$(echo "$n" | tr '[:upper:]' '[:lower:]')
  pg $n -c "\copy (SELECT * FROM pg_stat_io WHERE reads <> 0 OR writes <> 0 OR extends <> 0) TO '/tmp/pg_stat_io-$l.csv' WITH CSV HEADER" \
        -c "\copy (SELECT * FROM pg_stat_statements) TO '/tmp/pg_stat_statements-$l.csv' WITH CSV HEADER"
done

step "final-capture (CORE; VACUUMs first)"
pg CORE -f /tmp/final-capture.sql > /tmp/final-capture.txt 2>&1
tail -8 /tmp/final-capture.txt

step "FEATURES, per-node row counts and sizes"
{
  pg CORE -c "SELECT count(*) AS res_ent, count(features) AS features_not_null FROM res_ent"
  pg RES -c "SELECT 'res_feat_ekey' AS t, count(*) FROM res_feat_ekey UNION ALL SELECT 'res_feat_stat', count(*) FROM res_feat_stat"
  pg LIBFEAT -c "SELECT 'lib_feat' AS t, count(*) FROM lib_feat"
  for n in CORE RES LIBFEAT; do
    echo "== $n"
    pg $n -c "SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS total FROM pg_statio_user_tables WHERE schemaname = current_schema() ORDER BY pg_total_relation_size(relid) DESC"
  done
} | tee /tmp/hybrid-counts.txt

step "done; files in /tmp: final-deltas-*.txt validate.txt final-capture.txt hybrid-counts.txt *.csv locks/"
