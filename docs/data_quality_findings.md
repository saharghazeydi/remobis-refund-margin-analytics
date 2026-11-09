# REMOBIS — Data Quality Findings

## Scope and evidence

This register covers the fixed synthetic assignment snapshot. The 18 read-only SQL checks are stored in [`sql/02_quality`](../sql/02_quality). The original RAW tables and source CSV files remain unchanged.

- Checks 01–08 were reviewed against previously supplied Snowflake results. Checks 09–18 were reviewed using user-supplied Snowflake CSV exports; ChatGPT Work also reproduced their findings from the local source CSVs. The exports are not yet archived in the repository.
- The `STAGING.STG_REFUND_CLAIMS` view was created successfully in Snowflake. Its user-supplied validation export was reviewed and reconciled to check 18. ChatGPT Work did not execute the Snowflake deployment.
- Findings apply to this snapshot. They do not prove that future loads are valid. Source filename, file content key, and file row number provide provenance for RAW records and the retained staging copies.
- Financial exposures are **scenario comparisons, not confirmed losses or approved accounting adjustments**. Several affected populations overlap; do not add their exposure amounts.

## Findings at a glance

| ID | Finding | Affected population | Current decision |
| --- | --- | --- | --- |
| DQ-01 | Missing fields | 7,772 field occurrences | Preserve; distinguish expected missingness |
| DQ-02 | Exact duplicate claims | 1,136 excess RAW copies | One-copy staging view validated |
| DQ-03 | Country-name aliases | 3,714 RAW rows | Canonical key in staging; dimension join pending |
| DQ-04 | Other reference relationships | No unmatched references in tested joins | Keep cardinality tests |
| DQ-05 | Categorical domains | No additional invalid observed labels | Monitor new labels and blanks |
| DQ-06 | Numeric integrity and fee eligibility | No violations in tested rules | Preserve recorded and earned fees separately |
| DQ-07 | Negative processing costs | 72 claims | Retain; Finance review required |
| DQ-08 | Date validity and service launch | No violations in tested rules | Recheck on each new load |
| DQ-09 | Claims before customer onboarding | 442 RAW rows; 435 unique claims | Retain; business review required |
| DQ-10 | Historical versus current segments | 2,601 differing claims; 2,573 claims missing both | Use historical segment; retain unknowns |

## Detailed findings

### DQ-01 — Completeness

**Detection:** Profile all 27 source fields, distinguishing SQL `NULL`, empty strings, and whitespace-only values. Confirm missing `PROCESSING_DAYS` by claim status.

**Affected population:** 7,772 missing **field occurrences**, not necessarily distinct rows:

- `FACT_REFUND_CLAIMS.PROCESSING_DAYS`: 4,277
- `FACT_REFUND_CLAIMS.CUSTOMER_SEGMENT`: 2,607
- `FACT_REFUND_CLAIMS.CHANNEL`: 853
- `DIM_CUSTOMER.CUSTOMER_SEGMENT`: 35

All 4,277 missing processing-day values occur on Pending claims. No Refunded or Rejected claim has missing processing days.

**Business impact:** Missing segment and channel values limit breakdowns. Missing processing days on Pending claims are allowed by the dictionary; the completeness total is **not** a defect count. Monetary impact was not quantified.

**Treatment/status:** Preserve missing source values. Treat Pending processing days as expected missingness. Flag missing processing days on future decided claims. Use an `Unknown` reporting bucket where necessary, without backfilling historical segment from the current dimension. The causes of other missing values remain open.

**SQL:** [Completeness profile](../sql/02_quality/01_profile_raw_completeness.sql) · [Processing days by status](../sql/02_quality/10_validate_processing_days_by_status.sql)

### DQ-02 — Exact duplicate claims

**Detection:** Group by nonblank, trimmed, case-sensitive `TRANSACTION_ID`; compare all 13 original source fields within each repeated-ID group.

**Affected population:** 1,136 repeated-ID groups; 2,272 affected RAW rows; **1,136 excess identical copies**; zero conflicting groups.

**Business impact:** Comparing all RAW copies with one copy per claim gives differences of **EUR 240,219.96 earned fee**, **EUR 111,239.95 processing cost**, and **EUR 128,980.01 margin**. These differences do not establish an accounting loss.

**Treatment/status:** The deployed `STAGING.STG_REFUND_CLAIMS` view selects one deterministic copy per claim ID using source provenance. Its validation export confirms 89,476 unique claims and reconciled financial totals. This treatment is justified for the current snapshot because duplicate versions are identical. Future missing IDs or conflicting versions must be quarantined or reviewed before applying the same rule. The complete rejected-copy audit trail is not yet implemented.

**SQL:** [Duplicate-key check](../sql/02_quality/02_check_duplicate_keys.sql) · [Exact-copy classification](../sql/02_quality/03_classify_duplicate_claims.sql) · [Financial impact](../sql/02_quality/04_assess_duplicate_financial_impact.sql)

### DQ-03 — Country-name aliases

**Detection:** Compare normalized `FACT_REFUND_CLAIMS.SERVICE_COUNTRY` names with `DIM_COUNTRY.COUNTRY_NAME`; investigate unmatched names and test the proposed mappings for resolution and join cardinality.

**Affected population:** 3,714 RAW rows across 3,619 distinct claim IDs. Four observed aliases were validated:

| Source name | Canonical country | Country code |
| --- | --- | --- |
| `Czechia` | Czech Republic | `CZ` |
| `Deutschland` | Germany | `DE` |
| `Polska` | Poland | `PL` |
| `The Netherlands` | Netherlands | `NL` |

The mapping test resolved all 3,714 rows to exactly one country reference, with zero unmatched rows and zero join-extra rows **in that test**.

**Business impact:** An incorrect pre-mapping `INNER JOIN` could exclude **EUR 329,782.41 RAW-row margin**, or **EUR 318,662.94 one-copy margin**. These are alternative reporting-exclusion scenarios, not losses. They overlap the duplicate population.

**Treatment/status:** The deployed staging view preserves source country text and derives a canonical country-name key for these four aliases. The **downstream dimension join and country-level financial attribution have not yet been validated**. Use a row-preserving join and test target uniqueness, unresolved values, row counts, and financial totals before approving the country breakdown.

**SQL:** [Reference integrity](../sql/02_quality/05_check_referential_integrity.sql) · [Unmatched countries](../sql/02_quality/06_diagnose_unmatched_countries.sql) · [Mapping validation](../sql/02_quality/07_validate_country_alias_mapping.sql) · [Financial exposure](../sql/02_quality/08_assess_country_mapping_financial_exposure.sql)

### DQ-04 — Other reference relationships

**Detection:** Test normalized claim-to-customer, claim-to-service, and customer-to-home-country keys. Count unmatched references and predicted join multiplication.

**Affected population:** Zero unmatched rows and zero predicted extra rows for the three tested relationships, under case and surrounding-space normalization.

**Business impact:** No unmatched-key exclusion or join multiplication was observed for these relationships in the current checks. This does not establish that every future reference is valid or that all blank-key checks passed.

**Treatment/status:** Apply the same key normalization in reporting joins and verify cardinality again after joining the dimensions.

**SQL:** [Reference integrity](../sql/02_quality/05_check_referential_integrity.sql)

### DQ-05 — Categorical domains

**Detection:** Profile RAW categorical values, retaining original spellings and separating blanks.

**Affected population:** Claim status counts: **81,589 Refunded**, **4,746 Rejected**, and **4,277 Pending**. Nonblank channels, customer segments, account statuses, and regions match documented labels. Observed service categories are `VAT Refund` and `Excise Refund`.

**Business impact:** No additional out-of-domain labels were found where the dictionary defines allowed labels. The observed service categories do not establish an exhaustive list of valid future categories.

**Treatment/status:** Preserve existing labels and blanks. Check future loads for new or unexpected values.

**SQL:** [Categorical profile](../sql/02_quality/09_profile_categorical_domains.sql)

### DQ-06 — Numeric integrity and fee eligibility

**Detection:** Check numeric parsing, integer fields, currency precision, value ranges, and fee eligibility by claim status.

**Affected population:** Zero malformed numeric values, fractional counts, sub-cent values, or out-of-range amounts. The only missing numeric fields are the 4,277 expected Pending processing-day values. No Pending or Rejected row has a nonzero fee; no Refunded row has a zero fee.

**Business impact:** Tested values support typed financial reporting. Correct contractual fee amounts cannot be established from the list fee rate alone.

**Treatment/status:** Preserve `RECORDED_FEE_EUR` separately from `EARNED_FEE_EUR`. Recognize fees in the reporting calculation only for Refunded claims, and include processing costs for every status. Continue to test casts and fee eligibility.

**SQL:** [Numeric integrity](../sql/02_quality/11_validate_numeric_values.sql) · [Fee and cost validation](../sql/02_quality/12_validate_fee_and_negative_costs.sql)

### DQ-07 — Negative processing costs

**Detection:** Count negative processing costs by claim status and calculate their signed total.

**Affected population:** **72 RAW rows and 72 distinct claims**: 67 Refunded rows (EUR -6,812.07), five Rejected rows (EUR -480.99), and zero Pending rows.

**Business impact:** Total signed costs are **EUR -7,293.06** at both RAW and one-copy grain. Keeping these costs increases calculated margin by EUR 7,293.06 compared with setting them to zero. That comparison is a sensitivity, not an approved adjustment.

**Treatment/status:** The staging view preserves signed costs. Their business meaning is not confirmed; Finance must determine whether they are valid reversals, adjustments, or source errors. An explicit review flag is proposed, but it is not yet implemented in the staging view.

**SQL:** [Fee and cost validation](../sql/02_quality/12_validate_fee_and_negative_costs.sql)

### DQ-08 — Dates and service launch

**Detection:** Validate ISO date formats and date parsing. Compare claim submission dates with service launch dates through normalized service keys.

**Affected population:** No missing, malformed, or nonstandard submission, customer onboarding, or service launch dates. Submission dates run from **2025-01-01 through 2026-09-17**. No claims precede service launch, and no service-launch comparison was unevaluable.

**Business impact:** No formatting or service-launch violation was identified. Date validity does not prove that the source dates reflect the correct business events.

**Treatment/status:** Retain parsed dates. Recheck formats and chronology when new batches arrive.

**SQL:** [Date fields](../sql/02_quality/13_validate_date_fields.sql) · [Temporal relationships](../sql/02_quality/14_validate_temporal_relationships.sql)

### DQ-09 — Claims before customer onboarding

**Detection:** Join claims to customers on normalized customer IDs. Compare submission dates with customer contract-start dates, then calculate financial totals for RAW and one-copy populations.

**Affected population:** **442 RAW rows**, **435 distinct claims**, and **167 customers**. Claims were submitted **1–30 days before onboarding**. Of the RAW rows, 426 were Refunded and 16 Rejected; seven rows are excess duplicate copies. No comparison was unevaluable.

**Business impact:** RAW affected margin is **EUR 43,204.87** (EUR 77,993.51 earned fees minus EUR 34,788.64 costs). One-copy affected margin is **EUR 41,900.62** (EUR 76,416.38 minus EUR 34,515.76). This is exposure associated with an anomaly, **not a confirmed loss**. The two populations are alternatives; do not add them.

**Treatment/status:** Keep the claims and retain their dates. Confirm the contract-date definition and business policy before any correction or exclusion. A pre-onboarding review flag is proposed but is not yet included in the staging view.

**SQL:** [Temporal relationships](../sql/02_quality/14_validate_temporal_relationships.sql) · [Onboarding diagnosis](../sql/02_quality/15_diagnose_pre_onboarding_claims.sql) · [Financial exposure](../sql/02_quality/16_assess_pre_onboarding_financial_exposure.sql)

### DQ-10 — Historical versus current customer segments

**Detection:** Compare the historical segment in the claim fact with the current segment in the customer dimension after normalized customer joins.

**Affected population:** **85,404 matching RAW rows** (84,302 claims); **2,601 differing RAW rows** (2,601 claims); and **2,607 rows with both values missing** (2,573 claims). Neither one-sided missing category has rows. The 35 missing current-segment values in DQ-01 are dimension records, not claim rows.

**Business impact:** Historical and current segments answer different questions. Replacing the historical attribute with the current one could distort historical margin reporting. A difference alone is not evidence of incorrect data.

**Treatment/status:** Preserve the claim-time segment. The staging view keeps missing historical values as `NULL`; display them as `Unknown` only in a reporting layer if needed. Do not backfill them from the current dimension.

**SQL:** [Segment comparison](../sql/02_quality/17_check_customer_segment_consistency.sql)

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

**Evidence boundary:** The staging view creation was confirmed by a user-supplied Snowflake screenshot. Its values were checked against the user-supplied validation CSV and check 18. ChatGPT Work did not rerun these Snowflake statements, and the exports have not been stored in the repository. Downstream dimension enrichment and monthly margin aggregation remain unvalidated.

**SQL:** [Financial baseline](../sql/02_quality/18_reconcile_financial_baseline.sql) · [Create staging view](../sql/03_staging/01_create_stg_refund_claims.sql) · [Validate staging view](../sql/03_staging/02_validate_stg_refund_claims.sql)

## Reporting rules and outstanding decisions

- **Margin:** `EARNED_FEE_EUR - PROCESSING_COST_EUR`, with earned fees only for Refunded claims and costs for all statuses.
- **Reporting period:** `TRANSACTION_DATE` is the claim submission date. Monthly aggregation by this field is **submission-month cohort margin**, not accounting-period revenue recognition. Recognition dates were not supplied.
- **Customer segments:** Use the historical fact segment for claim-time analysis. Keep the current dimension segment separate.
- **Country:** Preserve the original submitted country value and map observed aliases to a canonical country reference. Validate the final country join and any country-level report totals.
- **Unresolved Finance questions:** Meaning of negative costs; treatment of pre-onboarding claims; approval of alias mappings; and any accounting-period recognition policy.
- **Reconciliation:** Verify row counts, key uniqueness, earned revenue, processing costs, margin, and join cardinality at each reporting layer. Do not silently drop claims or add overlapping exposure estimates.

**Source of business definitions:** [Official assignment and data dictionary](assignment/Data_Analyst_Assignment.docx).
