#!/usr/bin/env python3
"""
Classify unresolved OBS_ENT_IDs against a CloudWatch Logs export.

For each unresolved id, report which role(s) it plays across the log lines:
  obs      : obsEntID=            -> direct OKEY-ORPHAN victim
  live     : from live resEntID=  -> source of the suppressed OKEY remove
  target   : add to resEntID=...  -> the "target destroyed" entity
  corr/inf/other : appears in a non-OKEY-ORPHAN message (CORRUPTION_FOUND / INFINITE / other)
  (none)   : never appears -> truly silent, failed with zero logging

Usage:
  python3 classify-unresolved.py export.json [more.json ...]

Feed it the "copy as JSON" (or "Export results" download) from these two
CloudWatch Logs Insights queries over the FULL run window (consumer + redoer
log groups):

  # all OKEY-ORPHAN lines (unfiltered - gets the full swap graph)
  fields @timestamp, @message
  | filter @message like /OKEY ORPHAN PREVENTED/
  | sort @timestamp asc | limit 10000

  # non-OKEY mentions of any unresolved id (catches CORRUPTION_FOUND / INFINITE / other)
  fields @timestamp, @logStream, @message
  | filter @message like /(id1|id2|.../ ...your ids... /)/
  | filter @message not like /OKEY ORPHAN PREVENTED/
  | sort @timestamp asc | limit 5000

REPLACE the UNRESOLVED list below with the current run's ids (from validate.sql
query 1 -- observed-but-unresolved). The values shipped here are the 40 from the
20260715 100M v4.4.0.26167 run, kept as a worked example.
"""
import json, re, sys
from collections import defaultdict

UNRESOLVED = [
 24900385,27162105,31780752,32187715,37694182,38268728,39636022,39813403,
 41076893,43966566,49601388,50949050,51018134,52434440,52459400,54434516,
 60117436,60448956,62666046,66736818,68784892,70025591,72867390,73383261,
 77293682,79747322,83228978,84502166,92153396,92289621,92364105,92988409,
 93316516,97729754,97821075,100513093,100842057,101346345,101605291,103702154,
]
U = set(UNRESOLVED)

RE_OBS    = re.compile(r'obsEntID=(\d+)')
RE_LIVE   = re.compile(r'from live resEntID=(\d+)')
RE_TARGET = re.compile(r'add to resEntID=(\d+)')
RE_ANYRES = re.compile(r'resEntID=(\d+)')


def messages(obj):
    """Yield @message strings from a CloudWatch export in its various shapes."""
    if isinstance(obj, dict):
        obj = obj.get('results', obj.get('events', [obj]))
    for row in obj:
        if isinstance(row, dict):
            yield row.get('@message') or row.get('message') or ''
        elif isinstance(row, list):                       # [{field,value}, ...]
            d = {c.get('field'): c.get('value') for c in row if isinstance(c, dict)}
            yield d.get('@message') or d.get('message') or ''
        elif isinstance(row, str):
            yield row


roles = defaultdict(lambda: defaultdict(int))             # id -> role -> count

for path in sys.argv[1:]:
    with open(path) as f:
        data = json.load(f)
    for msg in messages(data):
        if not msg:
            continue
        if 'OKEY ORPHAN PREVENTED' in msg:
            for grp, rx in (('obs', RE_OBS), ('live', RE_LIVE), ('target', RE_TARGET)):
                for m in rx.findall(msg):
                    if int(m) in U:
                        roles[int(m)][grp] += 1
        else:
            cls = ('corr' if 'CORRUPTION_FOUND' in msg
                   else 'inf' if 'INFINITE' in msg
                   else 'other')
            for m in set(RE_ANYRES.findall(msg) + RE_OBS.findall(msg)):
                if int(m) in U:
                    roles[int(m)][cls] += 1

print(f"{'obs_ent_id':>12} | obs live tgt corr inf other | verdict")
print('-' * 74)
for i in UNRESOLVED:
    r = roles.get(i, {})
    verdict = ('OKEY-victim'      if r.get('obs')
               else 'destroyed-target' if r.get('target')
               else 'okey-source' if r.get('live')
               else 'CORRUPTION'  if r.get('corr')
               else 'INFINITE'    if r.get('inf')
               else 'other-msg'   if r.get('other')
               else '*** NEVER LOGGED ***')
    print(f"{i:>12} | {r.get('obs',0):>3} {r.get('live',0):>4} {r.get('target',0):>3} "
          f"{r.get('corr',0):>4} {r.get('inf',0):>3} {r.get('other',0):>5} | {verdict}")

never = [i for i in UNRESOLVED if i not in roles]
print('-' * 74)
print(f"seen in logs: {len(UNRESOLVED) - len(never)}/{len(UNRESOLVED)}    never logged: {len(never)}")
if never:
    print("never logged:", never)
