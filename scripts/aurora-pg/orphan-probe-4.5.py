#! /usr/bin/env python3
"""
orphan-probe-4.5.py - engine-side view of the 4.5 guard orphans (run on the sshd host).

Default (READ-ONLY): for each orphan record, fetch the record and search with its own attributes to
show which entities it SHOULD join (entity id, match level, match key, rule, entity size), plus the
entity the converged record ended up in (pass --converged-record-id from orphan-deepdive-4.5.sql section 3).

--reevaluate RECORD_ID  (WRITES to the DB; run only after the pristine snapshot exists):
    calls reevaluate_record on ONE orphan, then reports whether it now has an entity. Re-run validate.sql after.

Usage on sshd:
  export PYTHONPATH=/opt/senzing/er/sdk/python:$PYTHONPATH   # SENZING_ENGINE_CONFIGURATION_JSON is already set there
  python3 /tmp/orphan-probe-4.5.py > /tmp/orphan-probe.txt 2>&1
  python3 /tmp/orphan-probe-4.5.py --reevaluate 598304638    # e.g. the fast-failing 49700916

Prints ids, match levels/keys, rule codes and counts only (no names/addresses), except under --show-json.
"""
import argparse
import csv
import json
import os
import sys

from senzing import SzError
from senzing_core import SzAbstractFactoryCore

DATA_SOURCE = "TEST"
# record_id -> (obs_ent_id, guard_hits)   from validate.sql q1 + CloudWatch
ORPHANS = {
    "561972462": (43941309, 374), "544184792": (32683731, 331), "598304638": (49700916, 228),
    "441754847": (63658802, 341), "496097295": (65167600, 295), "538068695": (68932502, 284),
    "520098662": (69623324, 275), "544560158": (82502528, 243), "567971778": (75782375, 567),
    "507695948": (86507744, 603), "598782155": (98108857, 879), "465600576": (100204658, 1352),
    "453174730": (98236077, 1641), "532246852": (100247130, 1638), "598370653": (96469831, 1256),
    "568258238": (94779725, 760), "495855280": (88490872, 1931),
}
STRIP = {"DATA_SOURCE", "RECORD_ID", "DSRC_ACTION"}
JSON_FALLBACK = {}  # record_id -> JSON_DATA from dsrc_record (orphans: get_record fails with SENZ0055)


def summarize_search(resp):
    out = []
    for r in json.loads(resp).get("RESOLVED_ENTITIES", []):
        mi, ent = r.get("MATCH_INFO", {}), r.get("ENTITY", {}).get("RESOLVED_ENTITY", {})
        size = sum(s.get("RECORD_COUNT", 0) for s in ent.get("RECORD_SUMMARY", []))
        out.append((ent.get("ENTITY_ID"), mi.get("MATCH_LEVEL_CODE"), mi.get("MATCH_KEY"), mi.get("ERRULE_CODE"), size))
    return out


def entity_of(engine, record_id):
    try:
        e = json.loads(engine.get_entity_by_record_id(DATA_SOURCE, record_id)).get("RESOLVED_ENTITY", {})
        return e.get("ENTITY_ID"), len(e.get("RECORDS", []))
    except SzError as err:
        return None, f"{err.__class__.__name__}: {str(err)[:160]}"


def probe(engine, record_id, show_json):
    obs, hits = ORPHANS.get(record_id, (None, None))
    print(f"\n=== record_id={record_id} obs_ent_id={obs} guard_hits={hits}")
    try:
        data = json.loads(engine.get_record(DATA_SOURCE, record_id)).get("JSON_DATA") or {}
    except SzError as err:
        print(f"  get_record: {err.__class__.__name__}: {str(err)[:120]}")
        if record_id not in JSON_FALLBACK:
            print("  (no --json-csv fallback for this record; skipping search)")
            return
        try:
            data = json.loads(JSON_FALLBACK[record_id])
        except ValueError:
            print(f"  dsrc_record JSON_DATA is not plain JSON (starts {JSON_FALLBACK[record_id][:12]!r}); skipping search")
            return
        print("  using JSON_DATA from dsrc_record (--json-csv)")
    attrs = {k: v for k, v in data.items() if k not in STRIP}
    if show_json:
        print(f"  JSON_DATA (LOCAL ONLY): {json.dumps(attrs)}")
    print(f"  current entity: {entity_of(engine, record_id)}")
    try:
        cands = summarize_search(engine.search_by_attributes(json.dumps(attrs)))
    except SzError as err:
        print(f"  search_by_attributes: {err.__class__.__name__}: {str(err)[:200]}")
        return
    order = {"RESOLVED": 0, "POSSIBLY_SAME": 1, "POSSIBLY_RELATED": 2, "NAME_ONLY": 3}
    cands.sort(key=lambda c: (order.get(c[1], 9), c[0] or 0))
    n_res = sum(1 for c in cands if c[1] == "RESOLVED")
    print(f"  search candidates: {len(cands)} (RESOLVED: {n_res})")
    for eid, lvl, key, rule, size in cands[:max(10, n_res)]:
        print(f"    entity={eid} level={lvl} key={key} rule={rule} records={size}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--reevaluate", metavar="RECORD_ID", help="WRITE: reevaluate one orphan record")
    ap.add_argument("--readd", metavar="RECORD_ID", help="WRITE: re-add one orphan from its dsrc_record JSON_DATA (needs --json-csv); same as a DLQ replay")
    ap.add_argument("--reevaluate-entity", metavar="ENTITY_ID", type=int, help="WRITE: reevaluate this entity first (e.g. the orphan's target), then run --reevaluate/--readd")
    ap.add_argument("--verbose", action="store_true", help="engine verbose logging to stderr (for the engine team)")
    ap.add_argument("--converged-record-id", help="record_id of converged obs_ent 98511411 (from SQL section 3)")
    ap.add_argument("--show-json", action="store_true", help="print record attributes (LOCAL ONLY)")
    ap.add_argument("--only", help="comma-separated record_ids to probe (default: all 17)")
    ap.add_argument("--json-csv", help="CSV of record_id,json_data exported from dsrc_record (fallback for orphans)")
    a = ap.parse_args()
    if a.json_csv:
        with open(a.json_csv, newline="") as fh:
            for row in csv.reader(fh):
                if len(row) == 2:
                    JSON_FALLBACK[row[0]] = row[1]
        print(f"loaded {len(JSON_FALLBACK)} JSON_DATA rows from {a.json_csv}")

    settings = os.getenv("SENZING_ENGINE_CONFIGURATION_JSON")
    if not settings:
        sys.exit("SENZING_ENGINE_CONFIGURATION_JSON is not set")
    # Keep the factory referenced for the whole run: if it is garbage-collected, the engines it created are
    # destroyed ("engine object has been destroyed and can no longer be used").
    sz_factory = SzAbstractFactoryCore("orphan_probe", settings, verbose_logging=a.verbose)
    engine = sz_factory.create_engine()

    if a.reevaluate or a.readd or a.reevaluate_entity:
        rid = a.reevaluate or a.readd
        if rid:
            print(f"BEFORE: record {rid} entity = {entity_of(engine, rid)}")
        if a.reevaluate_entity:
            try:
                engine.reevaluate_entity(a.reevaluate_entity)
                print(f"reevaluate_entity({a.reevaluate_entity}): returned OK")
            except SzError as err:
                print(f"reevaluate_entity({a.reevaluate_entity}): {err.__class__.__name__}: {str(err)[:300]}")
        if a.readd:
            if a.readd not in JSON_FALLBACK:
                sys.exit(f"--readd {a.readd}: not in --json-csv")
            try:
                engine.add_record(DATA_SOURCE, a.readd, JSON_FALLBACK[a.readd])
                print(f"add_record({a.readd}): returned OK")
            except SzError as err:
                print(f"add_record({a.readd}): {err.__class__.__name__}: {str(err)[:300]}")
        if a.reevaluate:
            try:
                engine.reevaluate_record(DATA_SOURCE, a.reevaluate)
                print(f"reevaluate_record({a.reevaluate}): returned OK")
            except SzError as err:
                print(f"reevaluate_record({a.reevaluate}): {err.__class__.__name__}: {str(err)[:300]}")
        if rid:
            print(f"AFTER:  record {rid} entity = {entity_of(engine, rid)}")
        print("Next: check obs_ent.lock_dsrc_action for this record and re-run validate.sql.")
        return

    ap_only = a.only.split(",") if a.only else list(ORPHANS)
    for rid in ap_only:
        probe(engine, rid, a.show_json)
    if a.converged_record_id:
        print("\n=== CONVERGED record (obs_ent 98511411)")
        probe(engine, a.converged_record_id, a.show_json)


if __name__ == "__main__":
    main()
