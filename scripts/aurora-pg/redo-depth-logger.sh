#!/usr/bin/env bash
# redo-depth-logger.sh - log the Senzing redo backlog (SYS_EVAL_QUEUE row count on the CORE / default node) every
# $INTERVAL seconds, for combined-driver runs where there is no redoer service to watch.
#
# Run ON THE SSHD HOST right before the consumers start:
#   nohup bash /tmp/redo-depth-logger.sh > /tmp/redo-depth.log 2>&1 &
#   env: INTERVAL=60
# Each line: <UTC timestamp> <sys_eval_queue rows>. Stop with: pkill -f redo-depth-logger.sh
# The connection comes from SENZING_ENGINE_CONFIGURATION_JSON (SQL.CONNECTION), so it works for single-DB and
# HYBRID stacks alike. The password is never printed.
set -uo pipefail
: "${SENZING_ENGINE_CONFIGURATION_JSON:?not set on this host}"
INTERVAL=${INTERVAL:-60}

read -r U H P D PW < <(python3 - <<'PY'
import json, os, re, sys
url = json.loads(os.environ["SENZING_ENGINE_CONFIGURATION_JSON"])["SQL"]["CONNECTION"]
m = re.match(r"postgresql://([^:]+):(.*)@([^:@]+):(\d+):(\w+)$", url)
if not m: sys.exit("cannot parse SQL.CONNECTION")
u, pw, h, p, d = m.groups(); print(u, h, p, d, pw)
PY
)
while :; do
  n=$(PGPASSWORD="$PW" psql -X -At -h "$H" -p "$P" -U "$U" -d "$D" -c "SELECT count(*) FROM sys_eval_queue" 2>&1 | tail -1)
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $n"
  sleep "$INTERVAL"
done
