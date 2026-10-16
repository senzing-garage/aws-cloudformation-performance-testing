#!/usr/bin/env python3
"""Cross-node wait-for analysis of one hybrid-lock-snapshot.sh snapshot.
  python3 scripts/aurora-pg/hybrid-lock-graph.py <snapshot dir> <task-ips.tsv>
task-ips.tsv: ip<TAB>service:name<TAB>RUNNING|STOPPED<TAB>startedAt<TAB>stoppedAt (aws ecs describe-tasks, text output)."""
import csv, sys, collections
import gzip, os
def opencsv(path):
    """Read <path> or, if absent, <path>.gz (snapshots are gzipped when committed)."""
    return gzip.open(path + ".gz", "rt") if not os.path.exists(path) and os.path.exists(path + ".gz") else open(path)
d, tipf = sys.argv[1], sys.argv[2]
svc = {}
for line in open(tipf):
    f = line.rstrip("\n").split("\t")
    if f[0] and f[0] != "None" and f[2] == "RUNNING": svc[f[0]] = f[1].split(":")[1]
A = {}; L = collections.defaultdict(list)
for n in ("core", "res", "libfeat"):
    for r in csv.DictReader(opencsv(f"{d}/{n}-activity.csv")):
        A[(n, r["pid"])] = r
    for r in csv.DictReader(opencsv(f"{d}/{n}-locks.csv")):
        L[(n, r["pid"])].append(r)
def ip(n, pid): return A.get((n, pid), {}).get("client_addr", "?")
# 1) who waits on whom, per node (session level), and holder state
print("== per node: waiter -> blocker; blocker state; service mix")
edges = collections.defaultdict(set)   # IP-level: (waiter_ip) -> {(node, blocker_ip)}
for n in ("core", "res"):
    holders = collections.Counter(); hstate = collections.Counter(); wsvc = collections.Counter(); hsvc = collections.Counter()
    nblk = 0
    for (nn, pid), r in A.items():
        if nn != n or r["blocked_by"] in ("{}", ""): continue
        nblk += 1; wsvc[svc.get(r["client_addr"], "?")] += 1
        for b in r["blocked_by"].strip("{}").split(","):
            br = A.get((n, b))
            if not br: hstate["(gone)"] += 1; continue
            holders[b] += 1; hstate[br["state"] + (" / blocked" if br["blocked_by"] not in ("{}", "") else "")] += 1
            hsvc[svc.get(br["client_addr"], "?")] += 1
            edges[r["client_addr"]].add((n, br["client_addr"]))
    print(f" {n}: blocked sessions {nblk}; distinct blocker pids {len(holders)}; waiter services {dict(wsvc)}")
    print(f"     blocker states {dict(hstate.most_common(6))}; blocker services {dict(hsvc)}")
    top = holders.most_common(5)
    for b, k in top:
        br = A[(n, b)]
        tl = [l for l in L[(n, b)] if l["locktype"] == "tuple" and l["granted"] == "t"]
        print(f"     top blocker pid {b} ({svc.get(br['client_addr'],'?')} {br['client_addr']}) blocks {k}; state={br['state']}; xact_start={br['xact_start'][11:19]}; tuple locks held={[(l['relation'],l['page'],l['tuple']) for l in tl][:3]}; last query={br['query'][:70]}")
# 2) hot rows: waiting tuple locks by (relation,page,tuple)
print("== hot rows (waiting tuple locks)")
for n in ("core", "res"):
    c = collections.Counter((l["relation"], l["page"], l["tuple"]) for k, ls in L.items() if k[0] == n for l in ls if l["locktype"] == "tuple")
    print(f" {n}: distinct rows {len(c)}; top: {c.most_common(5)}")
# 3) holder chains across nodes: for each blocker session that is idle in transaction, does its task have sessions waiting on the OTHER node?
print("== cross-node: idle-in-txn blockers whose task is waiting on the other node")
waiting_ips = {n: {r["client_addr"] for (nn, p), r in A.items() if nn == n and r["blocked_by"] not in ("{}", "")} for n in ("core", "res")}
for n, other in (("core", "res"), ("res", "core")):
    bl = {A[(n, b)]["client_addr"] for (nn, p), r in A.items() if nn == n and r["blocked_by"] not in ("{}", "") for b in r["blocked_by"].strip("{}").split(",") if (n, b) in A and A[(n, b)]["state"] == "idle in transaction"}
    both = bl & waiting_ips[other]
    print(f" blockers on {n} that are idle-in-txn: {len(bl)} task IPs; of those, {len(both)} also have sessions WAITING on {other}")
# 4) IP-level cycles spanning both nodes (Tarjan SCC)
print("== IP-level wait-for graph (edges from both nodes): strongly connected components")
G = collections.defaultdict(set)
for w, s in edges.items():
    for (n, b) in s:
        if b != w: G[w].add((b, n))
idx = {}; low = {}; st = []; on = set(); sccs = []; c = [0]
sys.setrecursionlimit(100000)
def sc(v):
    idx[v] = low[v] = c[0]; c[0] += 1; st.append(v); on.add(v)
    for (w, n) in G.get(v, ()):
        if w not in idx: sc(w); low[v] = min(low[v], low[w])
        elif w in on: low[v] = min(low[v], idx[w])
    if low[v] == idx[v]:
        comp = []
        while True:
            x = st.pop(); on.discard(x); comp.append(x)
            if x == v: break
        sccs.append(comp)
for v in list(G): 
    if v not in idx: sc(v)
big = [s for s in sccs if len(s) > 1]
print(f" nodes {len(G)}; non-trivial SCCs {len(big)}; sizes {sorted((len(s) for s in big), reverse=True)[:8]}")
for s in big[:3]:
    ss = set(s); en = collections.Counter(n for v in s for (w, n) in G[v] if w in ss)
    print(f"  SCC size {len(s)}: internal edges by node {dict(en)}; services {dict(collections.Counter(svc.get(v,'?') for v in s))}")
