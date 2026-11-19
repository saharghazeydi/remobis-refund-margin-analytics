# Reporting Exports

## Purpose

These CSV files are reporting snapshots exported from Snowflake for a synthetic refund-claims financial analytics project. They are **not live datasets** and do not refresh automatically.


## Files and lineage

The three monthly exports cover the full snapshot. The additional H1 export compares January-June 2025 with January-June 2026.

| File | Source SQL | Grain | Rows |
| --- | --- | --- | ---: |
| [`monthly_claim_margin.csv`](monthly_claim_margin.csv) | `SELECT` from the mart view defined in [`01_create_monthly_claim_margin.sql`](../sql/04_marts/01_create_monthly_claim_margin.sql) | Submission month × service × service country × historical customer segment | 2,182 |
| [`monthly_margin_trends.csv`](monthly_margin_trends.csv) | [`03_analyze_monthly_margin_trends.sql`](../sql/04_marts/03_analyze_monthly_margin_trends.sql) | One row per submission month | 21 |
| [`monthly_margin_reconciliation.csv`](monthly_margin_reconciliation.csv) | First query in [`02_validate_monthly_claim_margin.sql`](../sql/04_marts/02_validate_monthly_claim_margin.sql) | One reconciliation row for the full extract | 1 |
| [`h1_service_margin_comparison.csv`](h1_service_margin_comparison.csv) | [`04_analyze_h1_service_margin.sql`](../sql/04_marts/04_analyze_h1_service_margin.sql) | One row per reporting group | 3 |

The monthly margin view is defined in [`01_create_monthly_claim_margin.sql`](../sql/04_marts/01_create_monthly_claim_margin.sql). It depends on the two staging views defined in [`sql/03_staging`](../sql/03_staging), which prepare one row per claim and enrich it with customer, service, and country attributes.

## Financial definitions

- **Earned fee revenue:** `FEE_REVENUE_EUR` for `Refunded` claims only. The source's recorded fee is kept separately in staging.
- **Processing cost:** Cost for **all** claim statuses, including Pending and Rejected. Negative processing costs remain signed pending Finance review.
- **Margin:** Earned fee revenue minus processing cost.
- **Reporting month:** Month of `TRANSACTION_DATE`, which is the **claim submission date**. Results are submission-month cohort margins, **not accounting-period recognized revenue or margin**.
- **Historical customer segment:** Taken from the claim fact. Missing values are shown as `Unknown` in the mart; the current customer dimension segment is not used to backfill them.
- **Duplicate handling:** The staging view keeps one deterministic copy per claim ID for this validated snapshot. Source duplicates were confirmed to be exact copies.

## Reconciled snapshot totals

| Metric | Validated value |
| --- | ---: |
| Distinct claims | 89,476 |
| Refunded / Rejected / Pending | 80,530 / 4,669 / 4,277 |
| Earned fee revenue | EUR 17,567,448.40 |
| Processing cost | EUR 7,860,558.99 |
| Margin | **EUR 9,706,889.41** |
| Missing historical segment (`Unknown`) | 2,573 claims |
| Negative processing cost | 72 claims |
| Submitted before customer onboarding | 435 claims |

The detailed export contains **2,182** unique reporting-grain combinations across **21** submission months (January 2025–September 2026). A separate grain-uniqueness check returned zero duplicate combinations. The reconciliation export agrees with the staging financial baseline.

## Interpretation limits

- September 2026 covers submissions **only through September 17** and is not a full month.
- Recent submission cohorts have many Pending claims: processing costs can be recorded before related success fees are earned. Their current margins can change as claims are resolved.
- Negative costs, claims submitted before customer onboarding, and country aliases are documented in [`data_quality_findings.md`](../docs/data_quality_findings.md). Their financial exposure figures can overlap and must not be added together.
- The source contains synthetic case-study data. The reported figures do not represent the actual financial performance of any company.

## Reproduce the exports

1. Follow the SQL setup and RAW ingestion scripts in [`sql/01_setup`](../sql/01_setup) for a fresh environment, and run the quality controls in [`sql/02_quality`](../sql/02_quality).
2. Create the staging views in [`sql/03_staging`](../sql/03_staging) in filename order. Run their validation queries; check claim uniqueness, country resolution, join cardinality, and unchanged financial totals.
3. Create the analytics view using `sql/04_marts/01_create_monthly_claim_margin.sql`. Export the result of a `SELECT` from the mart view as `monthly_claim_margin.csv`.
4. Run `sql/04_marts/02_validate_monthly_claim_margin.sql`. Confirm the totals above and export the first query result as `monthly_margin_reconciliation.csv`. The second query checks reporting-grain uniqueness and should return zero rows.
5. Run `sql/04_marts/03_analyze_monthly_margin_trends.sql` and export its result as `monthly_margin_trends.csv`.
6. Run `sql/04_marts/04_analyze_h1_service_margin.sql` and export its result as `h1_service_margin_comparison.csv`. Keep the H1 2025 margin blank for `VAT_EXPRESS` because it has no baseline for that period.

Save the four CSV files in this folder. Preserve CSV text and numeric formats. Do not resave exports through Excel.

If the underlying snapshot changes, **rerun validation and update the documented counts** rather than assuming these fixed results still apply.
