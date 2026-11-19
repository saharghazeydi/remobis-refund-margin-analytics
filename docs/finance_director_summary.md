# Finance Director Summary

## Can we trust the data?

**The original extract should not be used for reporting without validation.** The validated dataset is suitable for **margin analysis by claim submission month** for the supplied snapshot.

It is **not an accounting-period margin report**, because revenue-recognition dates were not provided. These validation results apply to the supplied snapshot, not automatically to future data loads.

## What was fixed?

The RAW extract contained **90,612 claim rows**, including **1,136 excess identical copies**. Keeping one copy per claim in staging prevented a **€128,980.01 overstatement of reported margin**.

Four inconsistent country-name variations affecting **3,714 RAW rows** were standardized for reference joins. All country references matched after standardization, without adding or losing claims through joins. The original source data was preserved.

The validated reporting dataset contains **89,476 unique claims**, with:

- **€17,567,448.40** in earned success fees.
- **€7,860,558.99** in processing costs.
- **€9,706,889.41** in margin.

Claim counts and financial totals reconcile across staging, enriched staging, and monthly reporting, with no join-generated extra rows.

## What risks remain?

- **Business exceptions:** **72 claims** have negative processing costs totaling **−€7,293.06**, and **435 claims** were submitted before customer onboarding. These records were retained and flagged for review. Their business meaning still needs confirmation.

- **Reporting limitations:** **2,573 claims** have missing historical customer segments and appear as `Unknown` in the reporting dataset. These claims remain in the financial totals, but the missing values limit segment-level analysis. The four country-name mappings also require formal business approval.

- **Timing and recognition:** Submission dates are not revenue-recognition dates. Recent cohorts contain many Pending claims, and September 2026 includes submissions only through **17 September**. The negative margins observed in recent cohorts are **not confirmed final losses**.

## What stands out, and what should we do?

### H1 2026 versus H1 2025

Comparing January–June 2026 with the same period in 2025:

- Earned success fees increased **12.8%**.
- Processing costs increased **38.5%**.
- Submitted claim volume decreased **3.1%**.
- Processing cost per submitted claim increased from **€71.54 to €102.20 (+42.9%)**.

Total portfolio margin decreased from **€3,264,516.22 to €3,175,395.26**, a decline of **€89,120.96 (−2.7%)**.

Margin as a percentage of earned revenue fell from **62.4% to 53.8%**, a decrease of **8.6 percentage points**.

### Service-level margin analysis

The two established services, **VAT_DIESEL** and **EXCISE_DIESEL**, improved their combined H1 margin by **€347,156.14**.

However, **VAT_EXPRESS**, launched in September 2025 and therefore without an H1 2025 baseline, contributed **−€436,277.10** in H1 2026 submission-cohort margin.

For VAT_EXPRESS in H1 2026:

- **2,254 claims**
- **€207,731.52** in earned success fees
- **€644,008.62** in processing costs
- **−€436,277.10** in margin

The negative margin from VAT_EXPRESS offset the improvements in the established services, resulting in the **€89,120.96 decline in total portfolio margin**.

This analysis identifies VAT_EXPRESS as a priority for further investigation. However, **the root cause of its negative margin has not been confirmed**. Pricing, processing efficiency, service mix, and cost allocation may require further analysis.

### Finance priorities

1. **USE:** Use the validated dataset for submission-cohort management analysis and margin monitoring. Do not treat it as an accounting-period margin report.

2. **INVESTIGATE:** Review VAT_EXPRESS pricing, processing costs, and cost allocation. Analyze cost per claim and differences by service and country to identify possible drivers.

3. **CONFIRM:** Review negative-cost adjustments, pre-onboarding claims, country mappings, and revenue-recognition rules. Obtain the required accounting dates and approvals before producing accounting-period financial reports.

## Supporting evidence

- [Monthly Margin Reconciliation](../reports/monthly_margin_reconciliation.csv)
- [H1 Portfolio Margin Analysis — SQL](../sql/04_marts/04_analyze_h1_service_margin.sql)
- [H1 Portfolio Margin Comparison — CSV](../reports/h1_service_margin_comparison.csv)
- [Data Quality Findings](data_quality_findings.md)

---

*All figures are based on synthetic data and do not represent the actual financial performance of any company.*