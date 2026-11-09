# REMOBIS Refund Services — Data Analyst Technical Case Study

**Snowflake SQL | Data quality | Financial reconciliation | Reporting-ready monthly margin**

> This is an analysis of **synthetic assignment data**. The figures below do not describe REMOBIS's actual business performance.

## Business problem

The Finance Director wants a dependable monthly margin report from an unclean claims extract. This project assesses whether the source can be trusted, documents material issues, prepares a reporting-ready dataset, and proposes controls for future loads.

The primary output is a Snowflake view at **submission month × service × service country × historical customer segment** grain. The report groups claims by their **submission dates**, not by accounting revenue-recognition dates.

## Validated result — supplied snapshot

| Metric | Result |
| --- | ---: |
| RAW claim records | 90,612 |
| Unique claims after identical-copy deduplication | 89,476 |
| Monthly reporting groups | 2,182 |
| Submission months | 21 (January 2025–September 2026) |
| Earned success-fee revenue | EUR 17,567,448.40 |
| Processing costs | EUR 7,860,558.99 |
| **Submission-cohort margin** | **EUR 9,706,889.41** |

The three static exports reconcile to the one-copy-per-claim baseline. Local checks against the source CSVs reproduced zero unmatched customer, service, or country references and zero join-generated rows after deduplication. The detailed export has zero duplicate reporting keys.

## Business and financial rules

- **Earned revenue:** The success fee is counted only when `CLAIM_STATUS = 'Refunded'`.
- **Costs:** Processing costs apply to all claim statuses, including `Pending` and `Rejected`.
- **Margin:** Earned success-fee revenue minus processing cost.
- **Time basis:** `TRANSACTION_DATE` is the claim submission date. The output is **submission-month cohort margin**, not recognized accounting-period margin.
- **Customer segment:** The fact table contains the historical segment at claim time; the customer dimension contains the current segment. The historical value is used for reporting. Missing historical segments appear as `Unknown` in the mart.
- **Country:** Known spelling/language aliases are standardized for joins; original source country values remain available in staging.
- **Exceptions:** Negative costs and claims submitted before customer onboarding remain in financial totals. The enriched staging view flags both for business review.

## Architecture and lineage

```text
Source CSVs (preserved)
        |
        v
REMOBIS_CASE_STUDY.RAW          -- text-preserving ingestion and source provenance
        |
        v
REMOBIS_CASE_STUDY.STAGING.STG_REFUND_CLAIMS
        |                         -- typed fields; one copy per validated claim ID
        v
REMOBIS_CASE_STUDY.STAGING.STG_REFUND_CLAIMS_ENRICHED
        |                         -- row-preserving customer, service, country joins
        v
REMOBIS_CASE_STUDY.ANALYTICS.MART_MONTHLY_CLAIM_MARGIN
                                  -- submission-month aggregation
        |
        v
reports/*.csv                   -- validated static Snowflake exports
```

The reporting logic is implemented as Snowflake views. Automation, scheduling, and notifications are proposal only. dbt is a future option.

## Repository structure

| Path | Purpose |
| --- | --- |
| Official assignment and data dictionary | Supplied separately and not distributed in this repository |
| [`sql/01_setup/`](sql/01_setup/) | Database objects, source load, and RAW reconciliation |
| [`sql/02_quality/`](sql/02_quality/) | 18 read-only data-quality and financial checks |
| [`sql/03_staging/`](sql/03_staging/) | Typed claim views, dimension enrichment, and validations |
| [`sql/04_marts/`](sql/04_marts/) | Monthly margin view, reconciliation, and trend query |
| [`docs/data_quality_findings.md`](docs/data_quality_findings.md) | Findings, affected counts, treatment, and business risks |
| [Automation Proposal](docs/automation_proposal.md) | Proposed checks, publication gates, and alert recipients |
| [Finance Director Summary](docs/finance_director_summary.md) | Snapshot results, business observations, and outstanding decisions |
| [`reports/`](reports/) | [Export guide](reports/README.md), [detailed margin CSV](reports/monthly_claim_margin.csv), [reconciliation CSV](reports/monthly_margin_reconciliation.csv), and [monthly trends CSV](reports/monthly_margin_trends.csv) |

Other directories may be reserved for future work; their presence does not indicate implemented Python, testing-framework, dbt, or orchestration functionality.

## Data-quality highlights

| Finding | Validated observation | Treatment / status |
| --- | --- | --- |
| Exact duplicate claim records | 1,136 excess copies; potential EUR 128,980.01 margin difference | One deterministic copy per claim in staging; original RAW preserved |
| Country-name aliases | 3,714 RAW rows across four aliases | Canonical keys; enriched country joins validated in current snapshot |
| Missing processing days | 4,277, all on Pending claims | Expected missingness, retained |
| Negative processing costs | 72 claims; EUR -7,293.06 total | Retained and flagged; business meaning unconfirmed |
| Claims before onboarding | 435 unique claims | Retained and flagged; contract-date policy unconfirmed |
| Historical versus current customer segment | 2,601 claims differ; 2,573 claims lack historical segment | Preserve historical values and explicit unknowns |

The listed exposures can overlap. **Do not add them as though they were independent financial losses.** The full detection logic and limitations are in the [data-quality register](docs/data_quality_findings.md).

## Reproduce in Snowflake

**Prerequisites:** An authorized Snowflake role and warehouse, access to the supplied CSVs, and permission to create objects in the `REMOBIS_CASE_STUDY` database. Scripts use the named database and schemas; adapt these names only if reproducing in a different environment.

1. Inspect the original assignment, schema definitions, source files, and [`sql/01_setup/`](sql/01_setup/) scripts. For a **fresh** environment, run setup scripts in numeric order and upload the four source CSVs to the RAW stage after creating it and before validating staged files. Existing environments require checking current objects and load state first; do not blindly rerun a load or overwrite source data.
2. Run the read-only checks in [`sql/02_quality/`](sql/02_quality/) and review exceptions. In particular, confirm key completeness and that repeated IDs have **identical** source values before applying one-copy deduplication.
3. Create and validate the staging views in [`sql/03_staging/`](sql/03_staging/) in numeric order. Check claim uniqueness, dimension join cardinality, unmatched references, and financial totals.
4. Create the monthly mart with [`01_create_monthly_claim_margin.sql`](sql/04_marts/01_create_monthly_claim_margin.sql). Run [`02_validate_monthly_claim_margin.sql`](sql/04_marts/02_validate_monthly_claim_margin.sql) and check for duplicate groups on submission month, service code, service country code, and historical customer segment.
5. Run [`03_analyze_monthly_margin_trends.sql`](sql/04_marts/03_analyze_monthly_margin_trends.sql). Export a SELECT from the mart view, the reconciliation query result, and the monthly trend query result. See [`reports/README.md`](reports/README.md) for file names and definitions.

**Snapshot reconciliation checkpoints:** 90,612 RAW claims → 89,476 unique staging claims → 89,476 enriched claims → 89,476 claims across 2,182 monthly groups. Earned revenue, cost, and margin after deduplication must agree with the values above. New source snapshots require fresh checks; the constants are evidence for this supplied snapshot, not universal rules.

## Interpretation and limitations

- **September 2026 is incomplete:** The source only includes submissions through **17 September 2026**. It must not be compared directly to complete months.
- **Cohort maturity matters:** Recent submission months contain many Pending claims; costs can exist before success fees are earned. Current negative cohort margins do not by themselves establish final losses.
- **Accounting recognition is not supported:** No confirmed revenue-recognition date is provided.
- **Unresolved business questions:** Whether negative processing costs are valid reversals/adjustments, why some claims predate onboarding, and whether the proposed alias policy is formally approved.
- **Evidence scope:** Validation applies to the supplied snapshot. The static exports support the downstream results. The data-quality register records an earlier checkpoint that predates the enriched staging and mart exports.

## Assignment deliverables

- [x] Data-quality investigations and findings register
- [x] Reporting-ready submission-cohort monthly margin mart and reconciled CSV exports
- [x] [Automation Proposal](docs/automation_proposal.md) drafted. The half-page limit remains open in the layout review.
- [x] [Finance Director Summary](docs/finance_director_summary.md)
