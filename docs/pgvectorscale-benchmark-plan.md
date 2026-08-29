# pgvectorscale (StreamingDiskANN) vs pgvector (HNSW) — benchmark plan (sketch)

Status: **proposed** (2026-08-28). Separate track from the Aurora embedding load tests.

## Goal
Apples-to-apples comparison of **pgvector HNSW** vs **pgvectorscale StreamingDiskANN** on our
OpenSanctions embeddings — index build cost, **search latency / recall / throughput**, and memory +
disk footprint — to decide whether DiskANN is worth adopting for embedding *search* at scale.

## ⚠️ #1 thing to confirm FIRST (gates the whole track)
Does the Senzing engine's `EMBEDDED_SEARCH` actually issue a query an ANN index can serve
(`... ORDER BY embedding <=> $query LIMIT k`)? If the engine does its own vector math / full scan
rather than an indexable k-NN query, then **the HNSW-vs-DiskANN choice doesn't affect Senzing search**
and this becomes a generic pgvector benchmark, not a Senzing one. **Ask Jae/engine before investing.**
Also confirm the distance metric the engine uses (cosine vs L2 vs inner-product) — the index ops class
must match (`vector_cosine_ops` etc.) or the index won't be used.

## Why this is NOT on our Aurora CFT
pgvectorscale is a custom Rust extension; **AWS Aurora/RDS only allow their managed extension allowlist
(pgvector ✅, pgvectorscale ❌).** So this runs on **self-managed PostgreSQL**, entirely separate from the
Aurora load-test fleet.

## Infra (minimal benchmark rig)
- **EC2** instance. Two sensible options:
  - `r6i.8xlarge` to mirror the Aurora DB class (RAM-comparable), OR
  - `r6id.*` / `i4i.*` for fast **local NVMe** — DiskANN is disk-based, so local SSD is the fair substrate.
- **PostgreSQL 17** + `pgvector 0.8.0` + `pgvectorscale` (latest). Easiest install: the
  **`timescale/timescaledb-ha`** container image (bundles pgvector + pgvectorscale, no manual Rust build),
  or build pgvectorscale from source against a stock PG 17.
- Size `shared_buffers` / `maintenance_work_mem` / `work_mem` to the instance; document them.
- IaC: a small CFT or Terraform (EC2 + EBS/NVMe + PG install via user-data), or a documented manual setup.
  Keep it lightweight — it's a rig, not the perf fleet.

## Dataset
- Reuse our real embeddings: `name_embedding` (~657K) + `semantic_value` (~107K), 512-dim — export via
  `pg_dump`/`COPY` from an existing run (e.g. jae-embed-017 while it's up), or re-generate.
- Test at **multiple scales to find the crossover**: 1M (current), 10M, ~50M (replicate/synthesize as
  needed). pgvectorscale's advantage grows where the HNSW graph stops fitting in RAM (~10M+ at 512-dim).
- **Query set:** ~1K–10K held-out query vectors + **ground-truth top-k** (exact brute-force k-NN) for recall.

## Indexes to compare (same table/metric)
- **HNSW:** `USING hnsw (embedding vector_cosine_ops) WITH (m=16, ef_construction=100)`; sweep `ef_search`.
- **StreamingDiskANN:** `USING diskann (embedding vector_cosine_ops)` (+ SBQ quantization options); sweep
  its query-time search params. Match the distance metric to the engine's.

## Metrics
- **Build:** wall-clock, CPU, peak memory, final **index size on disk**.
- **Search:** latency **p50/p95/p99 at fixed recall targets** (e.g. 95%, 99%); **throughput (QPS)** at target
  recall; the **recall-vs-latency** and **recall-vs-QPS** curves (the real ANN tradeoff).
- **Resource:** RAM footprint (does it need the whole index in RAM? DiskANN shouldn't), disk usage.
- **Load (optional, ties to the HNSW-on realism point):** insert throughput with the index present —
  HNSW graph-maintenance vs DiskANN maintenance cost per insert.

## Method
1. Provision rig; install PG + pgvector + pgvectorscale.
2. Load embeddings; build each index (record build metrics).
3. Compute ground-truth top-k (brute force) for the query set.
4. Sweep query-time params → recall-vs-latency + recall-vs-QPS curves at each scale (1M / 10M / 50M).

## Deliverable
A `results/<date>-pgvectorscale-vs-hnsw/` dir (mirroring our run dirs): README with the recall/latency/QPS
curves, a build-time + index-size + RAM/disk table, and a recommendation. One comparison table across scales.

## Risks / notes
- Whole track is gated on the engine-search question above.
- pgvectorscale install friction — prefer the Timescale HA image.
- Scale-up data (10M–50M realistic embeddings) needs sourcing/synthesizing.
- Keep OpenSanctions record content out of any public commit (same rule as the load-test runs).
