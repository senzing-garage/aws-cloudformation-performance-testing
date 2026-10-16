#!/usr/bin/env bash
# hybrid-lock-snapshot.sh - capture the live lock picture on all three Senzing HYBRID nodes (CORE / RES / LIBFEAT).
#
# Why: in the 20261015 run the load stalled for ~2 h with every DB ~idle. Enhanced Monitoring showed many
# "idle in transaction" and "UPDATE/INSERT waiting" backends on CORE and RES, with the same client IPs holding a
# transaction on one node while waiting on another (a cross-node lock-wait that neither Postgres can see as a
# deadlock). To prove or disprove a cycle we need pg_locks + pg_stat_activity from all nodes at the same moment.
#
# Run ON THE SSHD HOST (connections come from SENZING_ENGINE_CONFIGURATION_JSON, like hybrid-prepare-nodes.sh):
#   bash /tmp/hybrid-lock-snapshot.sh once                    # one snapshot now
#   nohup bash /tmp/hybrid-lock-snapshot.sh watch > /tmp/locks/watch.log 2>&1 &
#        # every $INTERVAL s, check each node; snapshot ALL nodes when any node has >= $THRESHOLD sessions waiting on a
#        # Lock, then again at most every $MIN_GAP s while the pile-up lasts.
#   env: INTERVAL=30 THRESHOLD=40 MIN_GAP=300 OUT=/tmp/locks
#
# Output per snapshot (OUT/<UTC ts>/): <node>-activity.csv (non-idle sessions, with pg_blocking_pids) and
# <node>-locks.csv (every lock held or awaited by those sessions, advisory keys included), plus summary.txt.
# client_addr + client_port identify the ECS task (one IP per task) so waits can be matched across nodes.
# Passwords are never printed. Only IDs and SQL text (bind parameters are $n placeholders); no record content.
set -euo pipefail
MODE=${1:-once}; INTERVAL=${INTERVAL:-30}; THRESHOLD=${THRESHOLD:-40}; MIN_GAP=${MIN_GAP:-300}; OUT=${OUT:-/tmp/locks}
: "${SENZING_ENGINE_CONFIGURATION_JSON:?not set on this host}"
NODES="CORE RES LIBFEAT"

parse() {  # Senzing URL postgresql://user:password@host:port:dbname -> "user host port dbname password"
  python3 - "$1" <<'PY'
import json, os, re, sys
cfg = json.loads(os.environ["SENZING_ENGINE_CONFIGURATION_JSON"])
url = {"CORE": cfg["SQL"]["CONNECTION"], "RES": cfg.get("C1", {}).get("DB_1", ""), "LIBFEAT": cfg.get("C2", {}).get("DB_1", "")}[sys.argv[1]]
m = re.match(r"postgresql://([^:]+):(.*)@([^:@]+):(\d+):(\w+)$", url)
if not m: sys.exit(f"cannot parse {sys.argv[1]} connection (is BACKEND=HYBRID?)")
u, pw, h, p, d = m.groups(); print(u, h, p, d, pw)
PY
}
psql_node() {  # psql_node NODE [psql args...]
  local node=$1; shift
  read -r U H P D PW < <(parse "$node")
  PGPASSWORD="$PW" PGOPTIONS="-c client_min_messages=warning -c statement_timeout=60000" \
    psql -X -q -v ON_ERROR_STOP=1 -h "$H" -p "$P" -U "$U" -d "$D" "$@"
}

ACTIVITY_SQL="SELECT now() AS ts, '%NODE%' AS node, a.pid, a.client_addr, a.client_port, a.state,
  a.wait_event_type, a.wait_event, pg_blocking_pids(a.pid) AS blocked_by,
  a.backend_xid, a.backend_xmin, a.xact_start, a.state_change, a.query_start,
  left(regexp_replace(a.query, '\s+', ' ', 'g'), 300) AS query
FROM pg_stat_activity a
WHERE a.datname = current_database() AND a.pid <> pg_backend_pid() AND a.state IS DISTINCT FROM 'idle'"

LOCKS_SQL="WITH s AS (SELECT pid FROM pg_stat_activity
                      WHERE datname = current_database() AND pid <> pg_backend_pid() AND state IS DISTINCT FROM 'idle')
SELECT now() AS ts, '%NODE%' AS node, l.pid, l.locktype, l.relation::regclass AS relation, l.page, l.tuple,
  l.transactionid, l.virtualxid, l.classid, l.objid, l.objsubid, l.mode, l.granted, l.fastpath, l.waitstart
FROM pg_locks l JOIN s USING (pid)
WHERE l.locktype <> 'virtualxid' OR NOT l.granted"

waiting_count() {  # sessions waiting on a heavyweight lock on NODE
  psql_node "$1" -At -c "SELECT count(*) FROM pg_stat_activity WHERE datname = current_database() AND wait_event_type = 'Lock'"
}

snapshot() {
  local ts dir n
  ts=$(date -u +%Y%m%dT%H%M%SZ); dir="$OUT/$ts"; mkdir -p "$dir"
  # Capture the nodes concurrently so the three pictures are as close in time as possible.
  for n in $NODES; do
    (
      psql_node "$n" -c "\\copy (${ACTIVITY_SQL//%NODE%/$n}) TO '$dir/${n,,}-activity.csv' WITH CSV HEADER"
      psql_node "$n" -c "\\copy (${LOCKS_SQL//%NODE%/$n}) TO '$dir/${n,,}-locks.csv' WITH CSV HEADER"
    ) &
  done
  wait
  {
    echo "snapshot $ts"
    for n in $NODES; do
      echo "== $n: non-idle sessions by state / wait"
      python3 - "$dir/${n,,}-activity.csv" <<'PY'
import csv, collections, sys
rows = list(csv.DictReader(open(sys.argv[1])))
c = collections.Counter((r["state"], r["wait_event_type"] or "-", r["wait_event"] or "-") for r in rows)
for (st, wt, we), k in c.most_common(10): print(f"   {k:5d}  {st:28s} {wt}:{we}")
blocked = [r for r in rows if r["blocked_by"] not in ("{}", "")]
print(f"   blocked sessions: {len(blocked)}; distinct client IPs among them: {len({r['client_addr'] for r in blocked})}")
PY
    done
  } > "$dir/summary.txt"
  cat "$dir/summary.txt"
}

case "$MODE" in
  once) snapshot ;;
  watch)
    mkdir -p "$OUT"; last=0
    echo "watching $NODES every ${INTERVAL}s; snapshot when any node has >= $THRESHOLD lock waiters (min gap ${MIN_GAP}s) -> $OUT"
    while true; do
      line=""; hit=0
      for n in $NODES; do w=$(waiting_count "$n" || echo "?"); line="$line $n=$w"; [[ "$w" =~ ^[0-9]+$ ]] && (( w >= THRESHOLD )) && hit=1; done
      echo "$(date -u +%H:%M:%S) lock waiters:$line"
      now=$(date +%s)
      if (( hit )) && (( now - last >= MIN_GAP )); then snapshot; last=$now; fi
      sleep "$INTERVAL"
    done ;;
  *) echo "usage: $0 once|watch" >&2; exit 2 ;;
esac
