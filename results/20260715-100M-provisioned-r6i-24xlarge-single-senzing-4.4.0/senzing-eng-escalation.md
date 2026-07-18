# Senzing advisory-mode 100M — TWO distinct record-loss defects (4.4 silent OKEY-orphan; 4.3.3 connection cascade)

**Reporter:** Senzing performance testing (AWS CloudFormation / Aurora PostgreSQL)
**Date:** 2026-07-16 (4.4); updated 2026-07-18 (4.3.3 A/B)
**Severity (proposed):** High — under `ENTITY_LOCK_MODE=ADVISORY` at 100M, **both**
4.4 and 4.3.3 leave records permanently unresolved with no recovery path. The
mechanisms differ by version (see the two sections below); the shared trigger is
advisory-lock contention on hot entities.

> **Two defects, one trigger.** The body below (Environment, Coverage, Questions)
> details the **4.4** defect — `oent-swap-okey-split-commit-regression`, silent OKEY
> orphan. The **4.3.3 A/B follow-up** immediately after TL;DR is a **separate**
> defect — a connection-recovery cascade that strands entity locks. Both surface only
> with advisory lock mode enabled at 100M scale.

## TL;DR

A 100M-record load on Senzing **4.4.0.26167** left **40 records observed but never
resolved** (present in `OBS_ENT`, absent from `RES_ENT_OKEY`). Classifying them
against the logs splits them into **two failure modes**: **10 carry the named
regression `oent-swap-okey-split-commit-regression`** (`OKEY ORPHAN PREVENTED … add
to resEntID=… was dropped (target destroyed) … self-heals via redo`), and **30
produce no log line at all** — completely silent drops (see Coverage). For the logged
mode, the message says placement "self-heals via redo,"
but for these 40 it **did not converge**: they end with no `RES_ENT_OKEY`, they are
**not** in `SYS_EVAL_QUEUE`, and they were **not dead-lettered** (DLQ = 0 for the
whole run). The consumer logged the condition as handled ("kept on source … self-heals
via redo"), ACK'd the SQS message, and moved on — so there is **no recovery path**: no
pending redo, no error-queue capture, and `MISSING_RES_ENT_AND_OKEY` logged **0**. The
drop is completely silent.

## 4.3.3 A/B follow-up (2026-07-18) — a SECOND, distinct advisory-mode defect

We re-ran the identical 100M advisory-mode test on **Senzing 4.3.3** (same template,
`db.r6i.24xlarge`, `max_connections=10000`, `ENTITY_LOCK_MODE=ADVISORY`; us-west-2 due
to capacity). Full detail:
[20260716 4.3.3 run README](../20260716-100M-provisioned-r6i-24xlarge-single-senzing-4.3.3/README.md).

**4.3.3 is NOT a clean baseline — it fails differently, not less.**

- **12 records left unresolved** (`RES_ENT_OKEY` = `OBS_ENT` − 12; 4.4 was −40; the
  non-advisory 4.1 run was 0). So unresolved-records under advisory mode is **not a
  4.4-only regression** — 4.3.3 has it too.
- **Different mechanism.** All 12 have **`locking_id ≠ 0` (a stranded entity lock)**;
  4.4's 40 all had `locking_id = 0`. And **0 `OKEY ORPHAN PREVENTED`** in the logs
  (full window, all groups) → 4.3.3 does **not** hit the OKEY-split regression.
- **Root cause (proposed): a connection-recovery cascade.** After an advisory-lock
  **deadlock** (40P01 on `SELECT pg_advisory_lock`), the 4.3.3 client leaves the PG
  connection in aborted-transaction state (`PQTRANS_INERROR`) — its own logs say *"a
  prior error was swallowed upstream"* — instead of rolling back / resetting. The
  `SELECT pg_advisory_unlock($1)` then fails on that poisoned connection, so the
  resolve dies mid-flight with the **entity lock still held** and no `RES_ENT_OKEY`.
  The poisoned connection then cascades: **2,185,189** `current transaction is aborted`
  (25P02), **2,085,101** `prepared statement "…" already exists`, **106,605**
  `UNHANDLED DATABASE ERROR`, **155,848** refused statements (`Connection found in
  aborted-transaction state`). DB-level `xact_rollback` = **2,085,437** (4.4: 698).
- **Same input records fail in both versions.** 4 of the 12 4.3.3-unresolved records
  (`record_id` 568258243, 568258238, 520309908, 495886296) were **also** among the 40
  in 4.4. → specific hot / duplicate-heavy entities lose the advisory-lock fight
  regardless of version. **Advisory-lock contention is the shared trigger; the
  consequence is version-specific.**
- Throughput was ~parity (4.3.3 peak 5,613 / avg 3,255 / 8.51 h load vs 4.4
  6,074 / 3,365 / 8.25 h).

**Net for engineering:** advisory lock mode at 100M produces record loss in BOTH
builds via two different bugs — 4.4 silently orphans records (OKEY-split), 4.3.3 loudly
strands them (connection-cascade after a `pg_advisory_lock` deadlock). Neither
auto-recovers (not queued, not dead-lettered). Additional 4.3.3 questions: (1) why is a
connection left in `PQTRANS_INERROR` after an advisory-lock deadlock instead of being
reset — is the upstream error-swallow a known issue? (2) is the stranded `locking_id`
expected to block those entities from any future re-resolution?

## Environment

| | |
|---|---|
| Senzing version | **4.4.0.26167** (consumer image digest `sha256:7c1672a05f5008b13942a25c895ff4694bf77158d42742337fe21b2e1e3bcc90`) |
| Components | `sz_sqs_consumer-v4` + `sz_simple_redoer-v4`, `SENZING_THREADS_PER_PROCESS=20` |
| Concurrency | autoscaling to peak **165 consumer + 157 redoer** tasks (MaxCapacity 200) |
| Engine config | **`"ER": {"ENTITY_LOCK_MODE": "ADVISORY"}`**, single `CONNECTION` (no read-offload) |
| Database | Aurora PostgreSQL **17.5**, provisioned, single writer `db.r6i.24xlarge`, IO-optimized |
| DB params | `max_connections=10000`, `enable_seqscan=0`, `track_io_timing=1`, `pg_stat_statements` |
| Load | 100,000,000 records via SQS |
| Throughput | peak 6,074/s, avg 3,365/s, load 8.25 h (18:37 Jul-15 → 02:53 Jul-16 UTC) |

## Symptom

`RES_ENT_OKEY` count = `OBS_ENT` count − 40 (99,998,887 = 99,998,927 − 40). The 40
`OBS_ENT_ID`s each reached `OBS_ENT` but never received a `RES_ENT` / `RES_ENT_OKEY`.
Full list of `record_id` / `obs_ent_id` is in the run README.

## Log signature (verbatim, representative)

```
ERR: OKEY ORPHAN PREVENTED: obsEntID=97821075 OKEY-remove from live resEntID=97821075
SUPPRESSED — its add to resEntID=97821075 was dropped (target destroyed); kept on
source to avoid a dropped record (placement self-heals via redo).
See FAQ oent-swap-okey-split-commit-regression.
```

Interlinked example (same event touches several of the affected entities — evidence
of hot-entity contention):

```
ERR: OKEY ORPHAN PREVENTED: obsEntID=93316516 OKEY-remove from live resEntID=70025591 SUPPRESSED — its add to resEntID=70025591 was dropped (target destroyed) ...
ERR: OKEY ORPHAN PREVENTED: obsEntID=93316516 OKEY-remove from live resEntID=24900385 SUPPRESSED — its add to resEntID=70025591 was dropped (target destroyed) ...
ERR: OKEY ORPHAN PREVENTED: obsEntID=92153396 OKEY-remove from live resEntID=49601388 SUPPRESSED — its add to resEntID=49601388 was dropped (target destroyed) ...
```

`70025591`, `24900385`, `49601388` are themselves in the unresolved-40 set.

## Database evidence (per the offending `OBS_ENT_ID`s)

Queried directly on the writer after the queue drained (`unresolved-forensics.sql`):

- `features` **populated** for all 40 → feature extraction completed; failure is in
  the resolve/OKEY-placement step, not upstream.
- `locking_id = 0` for all 40 → no stranded advisory/entity lock left behind.
- **No `RES_ENT_OKEY` row** for any of the 40.
- **Not present in `SYS_EVAL_QUEUE`** (queue drained to 0) → no redo is pending;
  the "self-heals via redo" path is not going to run for these.
- **Not dead-lettered** (DLQ = 0 for the entire run) → the consumer treated the
  OKEY-orphan as handled, ACK'd the SQS message, and moved on. With the redo queue
  also empty, **there is no recovery path** — the loss is fully silent.
- `LAST_TOUCH_DT` spread **evenly across the entire load** (19:40 → 02:45 UTC, ~1 per
  10 min) → a steady contention-driven rate, not a single burst.

## Surrounding error profile (CloudWatch, run window)

| Term | Count | Note |
|---|---:|---|
| `UNHANDLED DATABASE ERROR` | 0 | connection-exhaustion from a prior run is fixed |
| `error|except` (total) | 635 | |
| `ExclusiveLock on advisory lock` | 617 | `55P03` lock timeout on `SELECT pg_advisory_lock($1)`; = `pg_stat_database.deadlocks` delta |
| `CORRUPTION_FOUND` | 104 | (prior run 0; 25M advisory runs 1–2) |
| `POTENTIAL INFINITE RESOLUTION LOOP` | 22 | `UNRESOLVE MOVEMENT COUNT OF 20 EXCEEDED` |
| `FAILED` / `RetryTimeout` / `cancel` | 1 / 2 / 5 | |
| `MISSING_RES_ENT_AND_OKEY` | 0 | the drop is **silent** |

Our reading: the 617 advisory-lock timeouts are the **concurrency trigger** that
makes "target destroyed" races frequent and aborts resolves mid-flight. The 104
`CORRUPTION_FOUND` and 22 `INFINITE` events involve *other* entities — none of the 40
appear in them. The 40 unresolved records split between the OKEY-split regression
(10, logged) and silent resolve-aborts (30, no log).

## Coverage — two distinct failure modes

Classifying all 40 against the full OKEY-ORPHAN export **and** a bare-ID scan of every
other message:

- **10 of 40 tie to the OKEY-split regression:**
  - 7 as the direct `obsEntID` victim: `27162105`, `39813403`, `79747322`,
    `83228978`, `92153396`, `93316516`, `97821075`.
  - 3 as collateral in the same swap events: `24900385` (source), `49601388` and
    `70025591` (the "target destroyed" entity). The cluster is self-interlinked
    (`93316516`'s add targets `70025591`; `92153396`'s targets `49601388`).
- **30 of 40 have NO log line at all** — not in any OKEY-ORPHAN line, and a bare-ID
  search of every non-OKEY message returned nothing. They dropped **completely
  silently**.
- **0 of 40 appear in any `CORRUPTION_FOUND` or `INFINITE` line** — those 104 + 22
  events involve *other* entities and are **not** the mechanism for these 40.

**Interpretation — two modes, one trigger:** (1) 10 records reached the OKEY swap and
hit the split-commit regression (logged; the redo self-heal did not converge); (2)
30 records aborted *earlier* — most likely the resolve transaction rolled back on an
advisory-lock timeout (`55P03`) before any OKEY swap — leaving no log trace. Both
trace to advisory-lock contention as the trigger; only mode (1) is logged. **The
silent mode (30/40) is the larger and more concerning share.**

*Confirmed:* the OKEY-ORPHAN export is complete — 17 lines total, query capped at
7000 so not truncated — and the scan window was 2 days, covering the full run and
redo tail. The 30 silent drops are real.

## Questions for engineering

1. Are these 40 orphaned records the expected outcome of
   `oent-swap-okey-split-commit-regression`, or a distinct issue?
2. The message promises "placement self-heals via redo." **Under what conditions
   does that redo fail to converge?** Here the queue drained empty with the records
   still orphaned and no redo pending — is a redo supposed to be enqueued for these,
   and if so why wasn't it / why didn't it fix them?
3. **Why do ~30 of the 40 produce no log line at all?** Is a resolve abort (e.g. an
   advisory-lock `55P03` timeout) expected to leave a record permanently unresolved
   with no log, no redo, and no DLQ entry? This silent mode is the *majority* of the
   loss and is the bigger concern.
4. Is this **advisory-specific** (`ENTITY_LOCK_MODE=ADVISORY`) or does it reproduce
   under the default lock mode? (We will run **4.3.3 with advisory** next as an A/B.)
4. Are the **104 `CORRUPTION_FOUND`** and **22 INFINITE loops** the same root cause?
5. Is there a **fix / patch / recommended configuration** (lock mode, concurrency
   cap, redo settings) for 4.4 at ~100M / this concurrency?
6. **Severity:** the drop is silent and has no recovery path — `MISSING_RES_ENT_AND_OKEY`
   = 0, **not dead-lettered** (DLQ = 0), and no pending redo. Is there any signal an
   operator would see in production, or a supported reconciliation query?

## What we can provide

- The 40 `record_id` / `obs_ent_id` pairs, and the raw `JSON_DATA` for any of them.
- Full CloudWatch logs for the consumer + redoer log groups over the run window.
- The database is available (can snapshot the cluster on request).
- The CloudFormation template and full engine config used.
