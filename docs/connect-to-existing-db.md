# Connecting a separate stack/app to an existing perf-test 100M database

How to stand up a *second* stack (API server, query tools, analysis, ad-hoc psql)
that talks to the Aurora PostgreSQL database created by a perf-test stack —
**without re-loading 100M records.**

> **Secrets:** fill the blanks below at run time from the source stack's
> **Outputs** tab / Secrets Manager. Never commit real endpoints, passwords, or
> resource IDs to this file.

---

## ⚠️ STEP 0 (do this FIRST) — keep the database alive

The perf-test template creates the Aurora cluster with **`DeletionPolicy: Delete`
and the final snapshot skipped** (it's built to be ephemeral). **Deleting the
perf-test stack destroys the 100M database with no snapshot.** Before you tear
anything down, pick one:

- [ ] **A — Leave the perf stack running.** Simplest; but you keep paying for the
      whole ECS fleet + DB.
- [ ] **B — Retain on delete.** Update the perf stack, change the cluster's
      `DeletionPolicy` (and instances') to `Retain` (or `Snapshot`), *then* delete
      the stack. The cluster is left behind for the new stack to use.
- [ ] **C — Snapshot + restore (cleanest for "later").** Take a manual cluster
      snapshot now, delete the perf stack, then restore the snapshot into a new
      cluster the separate stack owns:
      ```bash
      REGION=us-east-2
      SRC_CLUSTER=<fill-in: source cluster id, e.g. {stackname}-aurora-senzing-core-cluster>
      SNAP_ID=<fill-in: e.g. senzing-100m-4.4.0.26167-YYYYMMDD>
      aws rds create-db-cluster-snapshot --region $REGION \
        --db-cluster-identifier "$SRC_CLUSTER" --db-cluster-snapshot-identifier "$SNAP_ID"
      # ... after the perf stack is deleted, restore:
      aws rds restore-db-cluster-from-snapshot --region $REGION \
        --db-cluster-identifier <fill-in: new cluster id> \
        --snapshot-identifier "$SNAP_ID" --engine aurora-postgresql
      # then create a db instance in the restored cluster (class of your choice)
      ```

**Chosen approach:** `<fill-in: A / B / C>`

---

## STEP 1 — connection details (from the source stack's Outputs tab)

Constants for these templates are pre-filled; fill the per-stack blanks.

| Field | Value | Source |
|---|---|---|
| Region | `us-east-2` (verify) | — |
| Writer endpoint (host) | `<fill-in>` | Output **`DatabaseHostCore`** |
| Reader endpoint (host) | `<fill-in / n/a>` | Output **`DatabaseHostReader`** *(only if read-offload was enabled; OFF on the 4.4/4.3.3 runs → use the writer)* |
| Port | `5432` | Output `DatabasePortCore` |
| Database name | `G2` | Output `DatabaseName` |
| Username | `senzing` | Output `DatabaseUsername` |
| Password | `<fill-in — per-stack, randomly generated>` | Output **`DatabasePassword`** |

Quick connectivity test (from inside the VPC — see Step 2):
```bash
export PGPASSWORD='<fill-in: DatabasePassword>'
psql -h <fill-in: DatabaseHostCore> -p 5432 -U senzing -d G2 -c 'select count(*) from dsrc_record;'
```

---

## STEP 2 — network access (the DB is private, VPC-internal only)

The cluster is **not publicly accessible**; its security group
(`Ec2SecurityGroupInternal`) only allows **TCP 5432 from within the VPC's
subnets**. So the new stack's compute must live in the same VPC and be reachable
by the DB's SG.

| Field | Value | Source |
|---|---|---|
| VPC id | `<fill-in>` | Output **`Ec2Vpc`** |
| VPC CIDR | `<fill-in>` | Output `Ec2VpcCidrBlock` |
| Private subnet 1 | `<fill-in>` | Output `SubnetPrivate1` |
| Private subnet 2 | `<fill-in>` | Output `SubnetPrivate2` |
| DB security group | `<fill-in>` | Output `Ec2SecurityGroupInternal` |

Then, one of:
- [ ] Launch the new stack's compute **into the private subnets** and attach the
      **same `Ec2SecurityGroupInternal`** (it already permits 5432 within the VPC), or
- [ ] Give the new compute its own SG and **add an ingress rule to the DB's SG**
      allowing that SG on TCP 5432.
- Avoid a brand-new VPC (would require peering) — reuse the source VPC.

---

## STEP 3 — Senzing engine config (only if the new stack runs Senzing components)

If it's just psql/analytics, skip this. If it runs Senzing (API server, tools):

- **`SENZING_ENGINE_CONFIGURATION_JSON`** pointing at the same DB:
  ```json
  {
    "PIPELINE": { "CONFIGPATH": "/etc/opt/senzing", "RESOURCEPATH": "/opt/senzing/er/resources",
                  "SUPPORTPATH": "/opt/senzing/data", "LICENSESTRINGBASE64": "<fill-in>" },
    "SQL": { "BACKEND": "SQL",
             "CONNECTION": "postgresql://senzing:<fill-in-pw>@<fill-in-DatabaseHostCore>:5432:G2" }
  }
  ```
  (Add `"ER": {"ENTITY_LOCK_MODE": "ADVISORY"}` only if you need to match the write-side config; for read/query it's irrelevant.)
- **Match the Senzing engine version** that built the DB — `<fill-in: e.g. 4.4.0.26167>` (pin the image tag/digest). The on-DB config/schema (`SYS_CFG`, feature tables) is version-tied; a mismatched *major* version can be incompatible.
- **License**: `SenzingLicenseAsBase64` (required for >100k records).

---

## Gather-it checklist (copy from the source stack's Outputs tab)

- [ ] `DatabaseHostCore` (writer endpoint)
- [ ] `DatabaseHostReader` (if read-offload was on)
- [ ] `DatabasePassword`
- [ ] `Ec2Vpc`, `Ec2VpcCidrBlock`
- [ ] `SubnetPrivate1`, `SubnetPrivate2`
- [ ] `Ec2SecurityGroupInternal`
- [ ] Senzing image tag/digest that built the DB (for version match)
- [ ] Senzing license (base64)

Constants (don't change unless the template changed): DB name `G2`, user `senzing`, port `5432`, engine `aurora-postgresql`.
