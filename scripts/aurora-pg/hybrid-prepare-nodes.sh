#!/usr/bin/env bash
# hybrid-prepare-nodes.sh - prepare the three Senzing HYBRID (clustered) nodes before the load.
#
# Run ON THE SSHD HOST after the stack's init job and BEFORE 00-setup / consumers:
#   bash /tmp/hybrid-prepare-nodes.sh            # dry run: inventory + what it WOULD do
#   bash /tmp/hybrid-prepare-nodes.sh --apply    # do it
#
# Follows the Senzing "Scaling Out Your Database With Clustering" procedure for the v4 HYBRID map used by
# cloudformationAuroraProvisionedClustered.yaml  (LIB_FEAT -> C2/LIBFEAT; RES_FEAT_EKEY, RES_FEAT_STAT -> C1/RES):
#   1. every node gets the full Senzing schema (applied to RES/LIBFEAT only if the init job left them empty;
#      the Senzing config itself is registered on CORE only)
#   2. unused tables are DROPPED on each node:
#        CORE    : drop LIB_FEAT, RES_FEAT_STAT, RES_FEAT_EKEY
#        RES     : keep RES_FEAT_EKEY, RES_FEAT_STAT + the SYS_* tables
#        LIBFEAT : keep LIB_FEAT + the SYS_* tables
#      SYS_* stay on the auxiliary nodes because the 4.4.3 engine reads SYS_VARS (schema version 'VERSION','SCHEMA')
#      on EVERY node at startup; without it engine init fails with SENZ1019 'relation "sys_vars" does not exist'
#      (observed 2026-10-13). The Senzing clustering article says to drop everything except the mapped tables,
#      which doesn't work with 4.4.3. Missing SYS_* tables are recreated from the official schema file.
#      This matters for GDEV-4738: with RES_FEAT_EKEY still present (empty) on CORE, the pre-4.4.3 wrong-node read
#      silently succeeds instead of raising SENZ1019, which would mask the bug being validated.
#   3. RES_ENT.FEATURES is added on CORE (RES_ENT is not remapped, so it lives on CORE).
# Connections come from SENZING_ENGINE_CONFIGURATION_JSON (SQL.CONNECTION = CORE, C1.DB_1 = RES, C2.DB_1 = LIBFEAT).
# Passwords are never printed.
set -euo pipefail
APPLY=0; [ "${1:-}" = "--apply" ] && APPLY=1
SCHEMA=/opt/senzing/er/resources/schema/szcore-schema-postgresql-create.sql
: "${SENZING_ENGINE_CONFIGURATION_JSON:?not set on this host}"

ALL_TABLES="LIB_FEAT SYS_HW_CHECK DSRC_RECORD OBS_ENT RES_ENT RES_ENT_OKEY RES_FEAT_EKEY RES_FEAT_STAT RES_RELATE RES_REL_EKEY SYS_SEQUENCE SYS_CFG SYS_CODES_USED SYS_VARS SYS_STATUS SYS_EVAL_QUEUE"

# Senzing URL form: postgresql://user:password@host:port:dbname  -> "user host port dbname password"
parse() {
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
  PGPASSWORD="$PW" PGOPTIONS="-c client_min_messages=warning" psql -X -q -v ON_ERROR_STOP=1 -h "$H" -p "$P" -U "$U" -d "$D" "$@"
}
tables_on() {  # lowercase list of Senzing tables present on NODE
  psql_node "$1" -At -c "SELECT string_agg(upper(tablename), ' ' ORDER BY tablename) FROM pg_tables WHERE schemaname = current_schema() AND upper(tablename) IN ($(for t in $ALL_TABLES; do printf "'%s'," $t; done | sed 's/,$//'))"
}
SYS_TABLES="SYS_HW_CHECK SYS_SEQUENCE SYS_CFG SYS_CODES_USED SYS_VARS SYS_STATUS SYS_EVAL_QUEUE"
keep_for() { case $1 in CORE) echo "";; RES) echo "RES_FEAT_EKEY RES_FEAT_STAT $SYS_TABLES";; LIBFEAT) echo "LIB_FEAT $SYS_TABLES";; esac; }
restore_sys() {  # recreate any missing SYS_* table (DDL + seed rows) on NODE from the official schema file
  local node=$1 have t; have=" $(tables_on $node) "
  for t in $SYS_TABLES; do
    [[ "$have" == *" $t "* ]] && continue
    if [ $APPLY = 1 ]; then
      grep -E "^(CREATE TABLE $t |CREATE (UNIQUE )?INDEX [A-Z_0-9]+ ON $t\(|INSERT INTO $t )" "$SCHEMA" | psql_node $node -f - >/dev/null
      echo "   $node: restored $t"
    else echo "   $node: WOULD restore $t"; fi
  done
}
drop_for() {
  case $1 in
    CORE) echo "LIB_FEAT RES_FEAT_STAT RES_FEAT_EKEY";;
    *)    local keep; keep=" $(keep_for "$1") "; for t in $ALL_TABLES; do [[ "$keep" == *" $t "* ]] || printf "%s " "$t"; done;;
  esac
}

echo "== engine config backend: $(python3 -c 'import json,os;print(json.loads(os.environ["SENZING_ENGINE_CONFIGURATION_JSON"])["SQL"]["BACKEND"])')"
for n in CORE RES LIBFEAT; do read -r U H P D PW < <(parse $n); echo "   $n -> $H:$P/$D"; done

echo "== 1. schema on every node"
for n in CORE RES LIBFEAT; do
  have=$(tables_on $n); cnt=$(wc -w <<<"$have")
  echo "   $n: $cnt/16 Senzing tables present"
  if [ "$cnt" -eq 0 ] && [ $n != CORE ]; then
    if [ $APPLY = 1 ]; then psql_node $n -f "$SCHEMA" >/dev/null && echo "   $n: schema applied ($(wc -w <<<"$(tables_on $n)")/16)"; else echo "   $n: WOULD apply $SCHEMA"; fi
  elif [ "$cnt" -eq 0 ]; then echo "   !! CORE has no schema - the init job did not run; stop here"; exit 1; fi
done

echo "== 1b. SYS_* tables on the auxiliary nodes (required by the 4.4.3 engine)"
for n in RES LIBFEAT; do restore_sys $n; done

echo "== 2. drop unused tables"
for n in CORE RES LIBFEAT; do
  for t in $(drop_for $n); do
    if [ $APPLY = 1 ]; then psql_node $n -c "DROP TABLE IF EXISTS $t" >/dev/null; else echo "   $n: WOULD drop $t"; fi
  done
  [ $APPLY = 1 ] && echo "   $n now has: $(tables_on $n)"
done

echo "== 3. RES_ENT.FEATURES on CORE"
if [ $APPLY = 1 ]; then psql_node CORE -c "ALTER TABLE RES_ENT ADD COLUMN IF NOT EXISTS FEATURES TEXT" >/dev/null; fi
psql_node CORE -At -c "SELECT 'RES_ENT columns: ' || string_agg(column_name, ',' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema = current_schema() AND table_name = 'res_ent'"

echo "== final inventory (expected: CORE 13 tables incl. RES_ENT+FEATURES; RES = RES_FEAT_EKEY RES_FEAT_STAT + 7 SYS_*; LIBFEAT = LIB_FEAT + 7 SYS_*)"
for n in CORE RES LIBFEAT; do echo "   $n: $(tables_on $n)"; done
[ $APPLY = 1 ] || echo "(dry run - re-run with --apply)"
echo
echo "# psql handles for the capture scripts (paste into this shell; export PGPASSWORD first or psql will prompt):"
for n in CORE RES LIBFEAT; do read -r U H P D PW < <(parse $n); echo "PG_$n=\"psql -h $H -p $P -U $U -d $D\""; done
