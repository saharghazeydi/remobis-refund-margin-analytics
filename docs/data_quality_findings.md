# Data Quality Findings

## Scope and validation

This analysis covers the supplied synthetic dataset. Data quality was assessed using 18 read-only SQL checks across four source tables. The original source files and RAW tables remain unchanged.

The checks were reviewed against recorded Snowflake results and exported validation outputs. The staging and monthly reporting results were checked for claim counts, duplicate records, join accuracy, and financial totals. Source file metadata supports record-level traceability.

These findings apply to the supplied dataset, not future loads. New data must be validated before reporting.

Financial impact estimates show **potential reporting differences, not confirmed financial losses or approved accounting adjustments**. Some affected records overlap, so their estimated impacts must not be added together.

## Findings at a glance

| ID | Finding | Affected records or result | Action taken / current status |
| --- | --- | --- | --- |
| DQ-01 | Missing values | 7,772 missing field values (not distinct rows) | Preserved; identified expected missing values |
| DQ-02 | Exact duplicate claims | 1,136 extra RAW copies | Kept one copy per claim in staging |
| DQ-03 | Inconsistent country names | 3,714 RAW rows | Standardized country names for joins; original values preserved |
| DQ-04 | Customer, service, and home-country references | 0 unmatched records in tested relationships | Verified matches and join row counts |
| DQ-05 | Category values | 0 additional invalid labels detected in tested fields | Preserved values; monitor future changes |
| DQ-06 | Numeric values and fee rules | 0 violations in tested rules | Validated amounts; separated recorded and earned fees |
| DQ-07 | Negative processing costs | 72 claims | Preserved and flagged for Finance review |
| DQ-08 | Dates and service launch | 0 violations in tested rules | Kept valid dates; recheck future loads |
| DQ-09 | Claims before customer onboarding | 442 RAW rows; 435 unique claims | Preserved and flagged for business review |
| DQ-10 | Historical versus current customer segments | 2,601 differing claims; 2,573 claims missing both | Kept historical values; report missing segments as Unknown |

## Detailed findings

### DQ-01 — Completeness

**Detection:** Profile all 27 source fields, distinguishing SQL `NULL`, empty strings, and whitespace-only values. Confirm missing `PROCESSING_DAYS` by claim status.

**Affected count:** 7,772 missing **field occurrences**, not necessarily distinct rows:

- `FACT_REFUND_CLAIMS.PROCESSING_DAYS`: 4,277
- `FACT_REFUND_CLAIMS.CUSTOMER_SEGMENT`: 2,607
- `FACT_REFUND_CLAIMS.CHANNEL`: 853
- `DIM_CUSTOMER.CUSTOMER_SEGMENT`: 35

All 4,277 missing processing-day values occur on Pending claims. No Refunded or Rejected claim has missing processing days.

**Business impact:** Missing segment and channel values limit breakdowns. Missing processing days on Pending claims are allowed by the dictionary; the completeness total is **not** a defect count. Monetary impact was not quantified.

**Action taken:** Preserve missing source values. Treat Pending processing days as expected missingness. Flag missing processing days on future decided claims. Use an `Unknown` reporting bucket where necessary, without backfilling historical segment from the current dimension. The causes of other missing values remain open.

**SQL:** [01_profile_raw_completeness.sql](../sql/02_quality/01_profile_raw_completeness.sql) · [10_validate_processing_days_by_status.sql](../sql/02_quality/10_validate_processing_days_by_status.sql)

### DQ-02 — Exact duplicate claims

**Detection:** Group by nonblank, trimmed, case-sensitive `TRANSACTION_ID`; compare all 13 original source fields within each repeated-ID group.

**Affected count:** 1,136 repeated-ID groups; 2,272 affected RAW rows; **1,136 excess identical copies**; zero conflicting groups.

**Business impact:** Comparing all RAW copies with one copy per claim gives differences of **EUR 240,219.96 earned fee**, **EUR 111,239.95 processing cost**, and **EUR 128,980.01 margin**. These differences do not establish an accounting loss.

**Action taken:** The deployed `STAGING.STG_REFUND_CLAIMS` view selects one deterministic copy per claim ID using source provenance. Its validation export confirms 89,476 unique claims and reconciled financial totals. This treatment is justified for the current snapshot because duplicate versions are identical. Future missing IDs or conflicting versions must be quarantined or reviewed before applying the same rule. The complete rejected-copy audit trail is not yet implemented.

**SQL:** [02_check_duplicate_keys.sql](../sql/02_quality/02_check_duplicate_keys.sql) · [03_classify_duplicate_claims.sql](../sql/02_quality/03_classify_duplicate_claims.sql) · [04_assess_duplicate_financial_impact.sql](../sql/02_quality/04_assess_duplicate_financial_impact.sql)

### DQ-03 — Country-name aliases

**Detection:** Compare normalized `FACT_REFUND_CLAIMS.SERVICE_COUNTRY` names with `DIM_COUNTRY.COUNTRY_NAME`; investigate unmatched names and test the proposed mappings for resolution and join cardinality.

**Affected count:** 3,714 RAW rows across 3,619 distinct claim IDs. Four observed aliases were validated:

| Source name | Canonical country | Country code |
| --- | --- | --- |
| `Czechia` | Czech Republic | `CZ` |
| `Deutschland` | Germany | `DE` |
| `Polska` | Poland | `PL` |
| `The Netherlands` | Netherlands | `NL` |

The mapping test resolved all 3,714 rows to exactly one country reference, with zero unmatched rows and zero extra rows caused by the join **in that test**.

**Business impact:** An incorrect pre-mapping `INNER JOIN` could exclude **EUR 329,782.41 RAW-row margin**, or **EUR 318,662.94 one-copy margin**. These are alternative reporting-exclusion scenarios, not losses. They overlap the duplicate population.

**Action taken:** The deployed staging view preserves source country text and derives a canonical country-name key for these four aliases. The alias mapping check and the enriched country join confirmed that all staged claims matched a country without creating extra rows. Formal approval of the alias policy remains open.

**SQL:** [05_check_referential_integrity.sql](../sql/02_quality/05_check_referential_integrity.sql) · [06_diagnose_unmatched_countries.sql](../sql/02_quality/06_diagnose_unmatched_countries.sql) · [07_validate_country_alias_mapping.sql](../sql/02_quality/07_validate_country_alias_mapping.sql) · [08_assess_country_mapping_financial_exposure.sql](../sql/02_quality/08_assess_country_mapping_financial_exposure.sql)

### DQ-04 — Other reference relationships

**Detection:** Test normalized claim-to-customer, claim-to-service, and customer-to-home-country keys. Count unmatched references and predicted join multiplication.

**Affected count:** Zero unmatched rows and zero predicted extra rows for the three tested relationships, under case and surrounding-space normalization.

**Business impact:** No missing reference matches or extra rows from joins were observed for these relationships in the current checks. This does not establish that every future reference is valid or that all blank-key checks passed.

**Action taken:** Enriched staging applies the same normalization to the claim-to-customer and claim-to-service joins. Both joins passed the snapshot validation. Retest cardinality and unmatched references for each new batch.

**SQL:** [05_check_referential_integrity.sql](../sql/02_quality/05_check_referential_integrity.sql)

### DQ-05 — Categorical domains

**Detection:** Profile RAW categorical values, retaining original spellings and separating blanks.

**Affected count:** Claim status counts: **81,589 Refunded**, **4,746 Rejected**, and **4,277 Pending**. Nonblank channels, customer segments, account statuses, and regions match documented labels. Observed service categories are `VAT Refund` and `Excise Refund`.

**Business impact:** No additional out-of-domain labels were found where the dictionary defines allowed labels. The observed service categories do not establish an exhaustive list of valid future categories.

**Action taken:** Preserve existing labels and blanks. Check future loads for new or unexpected values.

**SQL:** [09_profile_categorical_domains.sql](../sql/02_quality/09_profile_categorical_domains.sql)

### DQ-06 — Numeric integrity and fee eligibility

**Detection:** Check numeric parsing, integer fields, currency precision, value ranges, and fee eligibility by claim status.

**Affected count:** Zero malformed numeric values, fractional counts, sub-cent values, or out-of-range amounts. The only missing numeric fields are the 4,277 expected Pending processing-day values. No Pending or Rejected row has a nonzero fee; no Refunded row has a zero fee.

**Business impact:** Tested values support typed financial reporting. Correct contractual fee amounts cannot be established from the list fee rate alone.

**Action taken:** Preserve `RECORDED_FEE_EUR` separately from `EARNED_FEE_EUR`. Recognize fees in the reporting calculation only for Refunded claims, and include processing costs for every status. Continue to test casts and fee eligibility.

**SQL:** [11_validate_numeric_values.sql](../sql/02_quality/11_validate_numeric_values.sql) · [12_validate_fee_and_negative_costs.sql](../sql/02_quality/12_validate_fee_and_negative_costs.sql)

### DQ-07 — Negative processing costs

**Detection:** Count negative processing costs by claim status and calculate their signed total.

**Affected count:** **72 RAW rows and 72 distinct claims**: 67 Refunded rows (EUR -6,812.07), five Rejected rows (EUR -480.99), and zero Pending rows.

**Business impact:** Total signed costs are **EUR -7,293.06** at both RAW and one-copy grain. Keeping these costs increases calculated margin by EUR 7,293.06 compared with setting them to zero. That comparison is a sensitivity, not an approved adjustment.

**Action taken:** The staging view preserves signed costs. Their business meaning is not confirmed; Finance must determine whether they are valid reversals, adjustments, or source errors. The enriched staging view implements `NEGATIVE_COST_FLAG` for review. No cost adjustment has been approved.

**SQL:** [12_validate_fee_and_negative_costs.sql](../sql/02_quality/12_validate_fee_and_negative_costs.sql)

### DQ-08 — Dates and service launch

**Detection:** Validate ISO date formats and date parsing. Compare claim submission dates with service launch dates through normalized service keys.

**Affected count:** No missing, malformed, or nonstandard submission, customer onboarding, or service launch dates. Submission dates run from **2025-01-01 through 2026-09-17**. No claims precede service launch, and no service-launch comparison was unevaluable.

**Business impact:** No invalid date formats or claims before service launch were identified. Date validity does not prove that the source dates reflect the correct business events.

**Action taken:** Retain parsed dates. Recheck formats and chronology when new batches arrive.

**SQL:** [13_validate_date_fields.sql](../sql/02_quality/13_validate_date_fields.sql) · [14_validate_temporal_relationships.sql](../sql/02_quality/14_validate_temporal_relationships.sql)

### DQ-09 — Claims before customer onboarding

**Detection:** Join claims to customers on normalized customer IDs. Compare submission dates with customer contract-start dates, then calculate financial totals for RAW and one-copy populations.

**Affected count:** **442 RAW rows**, **435 distinct claims**, and **167 customers**. Claims were submitted **1–30 days before onboarding**. Of the RAW rows, 426 were Refunded and 16 Rejected; seven rows are excess duplicate copies. All comparisons could be completed.

**Business impact:** RAW affected margin is **EUR 43,204.87** (EUR 77,993.51 earned fees minus EUR 34,788.64 costs). One-copy affected margin is **EUR 41,900.62** (EUR 76,416.38 minus EUR 34,515.76). This is the margin linked to the flagged claims, **not a confirmed loss**. The two populations are alternatives; do not add them.

**Action taken:** Keep the claims and retain their dates. Confirm the contract-date definition and business policy before any correction or exclusion. The enriched staging view implements `PRE_ONBOARDING_FLAG` for review. No correction or exclusion has been approved.

**SQL:** [14_validate_temporal_relationships.sql](../sql/02_quality/14_validate_temporal_relationships.sql) · [15_diagnose_pre_onboarding_claims.sql](../sql/02_quality/15_diagnose_pre_onboarding_claims.sql) · [16_assess_pre_onboarding_financial_exposure.sql](../sql/02_quality/16_assess_pre_onboarding_financial_exposure.sql)

### DQ-10 — Historical versus current customer segments

**Detection:** Compare the historical segment in the claim fact with the current segment in the customer dimension after normalized customer joins.

**Affected count:** **85,404 matching RAW rows** (84,302 claims); **2,601 differing RAW rows** (2,601 claims); and **2,607 rows with both values missing** (2,573 claims). Neither one-sided missing category has rows. The 35 missing current-segment values in DQ-01 are dimension records, not claim rows.

**Business impact:** Historical and current segments answer different questions. Replacing the historical attribute with the current one could distort historical margin reporting. A difference alone is not evidence of incorrect data.

**Action taken:** Preserve the claim-time segment. The staging view keeps missing historical values as `NULL`, and the monthly mart displays them as `Unknown`. Do not backfill them from the current dimension.

**SQL:** [17_check_customer_segment_consistency.sql](../sql/02_quality/17_check_customer_segment_consistency.sql)

## Financial baseline and staging reconciliation

The baseline uses exact-decimal calculations. Fees are earned only on Refunded claims; processing costs apply to all statuses, including negative costs. Pre-onboarding claims remain included.

| Population | Claim rows | Earned fee (EUR) | Processing cost (EUR) | Margin (EUR) |
| --- | ---: | ---: | ---: | ---: |
| All RAW rows | 90,612 | 17,807,668.36 | 7,971,798.94 | 9,835,869.42 |
| One copy per claim | 89,476 | 17,567,448.40 | 7,860,558.99 | 9,706,889.41 |
| RAW less one-copy | 1,136 | 240,219.96 | 111,239.95 | 128,980.01 |

The Snowflake validation export for `STAGING.STG_REFUND_CLAIMS` confirms:

| Staging check | Result |
| --- | ---: |
| Staged rows | 89,476 |
| Distinct claim IDs | 89,476 |
| Claim groups with duplicate RAW copies | 1,136 |
| Missing historical segments | 2,573 |
| Claims with negative processing cost | 72 |
| Earned fee (EUR) | 17,567,448.40 |
| Processing cost (EUR) | 7,860,558.99 |
| Margin (EUR) | 9,706,889.41 |

**Enriched staging and monthly mart.** Snowflake validation results confirmed that the customer, service, and country joins preserved all **89,476 unique claims**, with **zero extra rows caused by joins** and **zero unmatched references** for each of the three dimensions. The enriched view and monthly mart reconcile to **EUR 17,567,448.40 earned revenue**, **EUR 7,860,558.99 processing cost**, and **EUR 9,706,889.41 margin**.

The mart contains **2,182 groups across 21 submission months**. A uniqueness check at `SUBMISSION_MONTH`, `SERVICE_CODE`, `SERVICE_COUNTRY_CODE`, and `HISTORICAL_CUSTOMER_SEGMENT` grain returned zero duplicate groups in Snowflake. September 2026 is partial through September 17. The [reconciliation export](../reports/monthly_margin_reconciliation.csv) records the snapshot totals.

**SQL:** [18_reconcile_financial_baseline.sql](../sql/02_quality/18_reconcile_financial_baseline.sql) · [01_create_stg_refund_claims.sql](../sql/03_staging/01_create_stg_refund_claims.sql) · [02_validate_stg_refund_claims.sql](../sql/03_staging/02_validate_stg_refund_claims.sql) · [04_validate_stg_refund_claims_enriched.sql](../sql/03_staging/04_validate_stg_refund_claims_enriched.sql) · [02_validate_monthly_claim_margin.sql](../sql/04_marts/02_validate_monthly_claim_margin.sql)

## Reporting rules and outstanding decisions

- **Margin:** `EARNED_FEE_EUR - PROCESSING_COST_EUR`, with earned fees only for Refunded claims and costs for all statuses.
- **Reporting period:** `TRANSACTION_DATE` is the claim submission date. Monthly aggregation by this field is **submission-month cohort margin**, not accounting-period revenue recognition. Recognition dates were not supplied.
- **Customer segments:** Use the historical fact segment for claim-time analysis. Keep the current dimension segment separate.
- **Country:** Preserve the original submitted country value and map observed aliases to a canonical country reference. The enriched country join passed for this snapshot. Recheck resolution and cardinality on future loads.
- **Unresolved Finance questions:** Meaning of negative costs; treatment of pre-onboarding claims; approval of alias mappings; and any accounting-period recognition policy.
- **Reconciliation:** Verify row counts, key uniqueness, earned revenue, processing costs, margin, and join cardinality at each reporting layer. Do not silently drop claims or add overlapping exposure estimates.

**Source of business definitions.** The official assignment and data dictionary were supplied separately and are not distributed in this repository.
