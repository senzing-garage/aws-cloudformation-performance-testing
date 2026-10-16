#!/usr/bin/env python3
"""Is a HYBRID lock pile-up moving or stuck? Compare consecutive hybrid-lock-snapshot.sh snapshots.

  python3 scripts/aurora-pg/hybrid-lock-compare.py <locks dir containing <UTC ts>/ snapshot dirs>

For each node and each pair of consecutive snapshots: how many blocked sessions (same pid AND same xact_start) are still
blocked, how many of those are still waiting on the same blocker pids, and how many idle-in-transaction sessions still
hold the same transaction. Near-100% persistence across minutes = no progress (a wait cycle nobody breaks).
"""
import csv, os, sys
import gzip, os
def opencsv(path):
    """Read <path> or, if absent, <path>.gz (snapshots are gzipped when committed)."""
    return gzip.open(path + ".gz", "rt") if not os.path.exists(path) and os.path.exists(path + ".gz") else open(path)
root = sys.argv[1]
snaps = sorted(d for d in os.listdir(root) if os.path.isdir(os.path.join(root, d)) and d[:4].isdigit())
def load(s, n):
    p = os.path.join(root, s, f"{n}-activity.csv")
    return {(r["pid"], r["xact_start"]): r for r in csv.DictReader(opencsv(p))} if (os.path.exists(p) or os.path.exists(p + ".gz")) else {}
print("snapshots:", ", ".join(snaps))
for n in ("core", "res", "libfeat"):
    print(f"== {n}")
    for a, b in zip(snaps, snaps[1:]):
        A, B = load(a, n), load(b, n)
        blkA = {k: r for k, r in A.items() if r["blocked_by"] not in ("{}", "")}
        still = [k for k in blkA if k in B and B[k]["blocked_by"] not in ("{}", "")]
        same = [k for k in still if B[k]["blocked_by"] == blkA[k]["blocked_by"]]
        iitA = {k for k, r in A.items() if r["state"] == "idle in transaction"}
        iitB = {k for k, r in B.items() if r["state"] == "idle in transaction"}
        print(f"  {a} -> {b}: blocked {len(blkA)} -> still blocked {len(still)} ({100*len(still)/max(len(blkA),1):.0f}%), same blockers {len(same)}; "
              f"idle-in-txn {len(iitA)} -> same txn still idle {len(iitA & iitB)} ({100*len(iitA & iitB)/max(len(iitA),1):.0f}%); "
              f"non-idle sessions {len(A)} -> {len(B)}")
