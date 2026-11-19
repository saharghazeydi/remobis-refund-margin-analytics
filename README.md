# Refund Financial Analytics

**Snowflake SQL | Data Quality | Financial Reconciliation | Monthly Margin Reporting**

An end-to-end SQL analytics case study that transforms raw refund-claim data into a validated monthly financial reporting dataset using Snowflake.

The project demonstrates data-quality investigation, financial reconciliation, dimensional enrichment, reporting model development, and business analysis.

> **Dataset:** This project uses synthetic data representing a fictional fuel-tax refund operation. All financial results are illustrative and do not represent the actual performance of any company.

## 1. Business Problem

A fuel-tax refund services business processes claims for VAT and excise duty paid on diesel purchases across European countries.

The business earns success fees from refunded claims and incurs processing costs when handling claims.

Reliable monthly margin reporting requires accurate claims data, consistent reference information, correct financial calculations, and controls against reporting errors.

This project addresses three business questions:

1. Can the raw claims data be trusted for financial reporting?
2. How can the data be transformed into a validated monthly margin dataset?
3. What do the financial results reveal about business performance and reporting risks?

**Primary deliverable:** A Snowflake reporting view at the following grain:

**Submission month × Service × Service country × Historical customer segment**

Reporting is based on claim submission dates, not accounting revenue-recognition dates.

## 2. Technology Stack

| Technology | Purpose |
| --- | --- |
| Snowflake | Data warehouse, SQL transformations, and reporting views |
| SQL | Data-quality validation, deduplication, financial calculations, and aggregation |
| VS Code | SQL development and project organization |
| Git & GitHub | Version control, documentation, and source management |
| CSV | Raw source datasets and validated reporting exports |

The reporting implementation uses Snowflake SQL views. Automated scheduling, alerting, and controlled publication are proposed future enhancements rather than implemented features.

## 3. Dataset

The repository contains four synthetic source CSV files in [`data/raw/`](data/raw/).

| Source table | Description | Raw records |
| --- | --- | ---: |
| [`FACT_REFUND_CLAIMS.csv`](data/raw/FACT_REFUND_CLAIMS.csv) | Refund claim transactions | 90,612 |
| [`DIM_CUSTOMER.csv`](data/raw/DIM_CUSTOMER.csv) | Customer reference information | 1,200 |
| [`DIM_SERVICE.csv`](data/raw/DIM_SERVICE.csv) | Refund service definitions | 3 |
| [`DIM_COUNTRY.csv`](data/raw/DIM_COUNTRY.csv) | Country and geographic region information | 14 |

The fact dataset covers claims submitted between **1 January 2025 and 17 September 2026**.

The raw extract includes duplicate claim records, inconsistent country names, missing attributes, and financial exceptions.

The original CSV contents are preserved. Data-quality checks and transformations are performed separately in Snowflake.

For field definitions, relationships, and business rules, see the [Data Dictionary](docs/data_dictionary.md).

## 4. Data Architecture

```text
Synthetic Source CSVs
         |
         v
RAW LAYER
- Source-preserving ingestion
- Original field values and provenance
         |
         v
DATA QUALITY CHECKS
- Completeness and uniqueness
- Numeric and categorical validation
- Referential integrity
- Financial and business rules
         |
         v
STAGING LAYER
- Type conversion
- Validated duplicate handling
- Standardized reference values
         |
         v
ENRICHED STAGING
- Customer and service enrichment
- Country mapping
- Business exception flags
         |
         v
ANALYTICS MART
- Monthly claim aggregation
- Earned revenue
- Processing costs
- Submission-cohort margin
         |
         v
REPORTING EXPORTS
- Detailed monthly margin
- Monthly trends
- Financial reconciliation
- H1 service comparison
```

The design separates source ingestion, quality investigation, data preparation, and business reporting.

Source records are not silently removed or modified.

## 5. Data Quality Findings

The project includes 18 SQL files dedicated to data-quality profiling, validation, and financial checks.

Key findings from the supplied snapshot:

| Finding | Validated result | Treatment |
| --- | --- | --- |
| Duplicate claims | 1,136 excess identical copies | Retain one copy per claim in staging |
| Country-name inconsistencies | 3,714 affected RAW records across four aliases | Standardize country references for joins |
| Missing processing days | 4,277 Pending claims | Preserve as expected missingness |
| Negative processing costs | 72 claims, totaling −€7,293.06 | Retain and flag for business review |
| Claims before onboarding | 435 unique claims | Retain and flag for review |
| Historical customer segment differences | 2,601 claims differ from current segments | Preserve historical segments |
| Missing historical segments | 2,573 unique claims | Represent as `Unknown` in reporting |

The duplicate records would produce a **€128,980.01 difference in reported margin** if all raw copies were counted instead of one validated copy per claim.

Financial exposure estimates can overlap and must not be added together as independent losses.

The data-quality assessment also confirmed that the validated staging and reporting joins did not create additional claim rows.

For detection logic, detailed affected counts, financial implications, and remaining risks, see [Data Quality Findings](docs/data_quality_findings.md).

**Validation scope:** The completed checks focus on structural integrity, business rules, reference relationships, and financial reconciliation. A dedicated statistical outlier and distribution-impact analysis remains a future improvement.

## 6. Financial Definitions

The reporting model applies the following rules:

**Earned success-fee revenue**

Success-fee revenue is counted only for claims with `CLAIM_STATUS = 'Refunded'`.

**Processing costs**

Processing costs are included for all claim statuses, including Refunded, Rejected, and Pending.

**Margin**

`Margin = Earned Revenue - Processing Cost`

**Reporting month**

The reporting month is derived from `TRANSACTION_DATE`, representing the claim submission date.

**Historical customer segment**

The historical customer segment recorded in the claim fact is used for reporting. The current customer dimension segment is not used to replace historical values.

**Financial exceptions**

Negative processing costs and pre-onboarding claims remain included in financial totals while their business meaning is under review.

> **Important:** The reported margin is a submission-cohort measure. It should not be interpreted as accounting-period recognized margin because revenue-recognition dates are not available in the source data.

## 7. Validated Reporting Results

The reporting model contains 89,476 unique claims across 2,182 reporting groups and 21 submission months.

| Financial KPI | Validated result |
| --- | ---: |
| Raw claim records | 90,612 |
| Unique claims | 89,476 |
| Reporting groups | 2,182 |
| Earned success-fee revenue | €17,567,448.40 |
| Processing costs | €7,860,558.99 |
| **Submission-cohort margin** | **€9,706,889.41** |

Counts and financial totals reconcile across the validated one-copy-per-claim staging layer, enriched staging, and monthly reporting output.

The detailed reporting dataset has no duplicate reporting-grain combinations in the validated snapshot.

## 8. Reporting Outputs

Four CSV reporting exports are included in [`reports/`](reports/).

| File | Purpose |
| --- | --- |
| [`monthly_claim_margin.csv`](reports/monthly_claim_margin.csv) | Detailed reporting dataset by month, service, country, and historical customer segment |
| [`monthly_margin_trends.csv`](reports/monthly_margin_trends.csv) | Monthly claim counts, earned revenue, processing costs, and margin trends |
| [`monthly_margin_reconciliation.csv`](reports/monthly_margin_reconciliation.csv) | Claim-count and financial reconciliation |
| [`h1_service_margin_comparison.csv`](reports/h1_service_margin_comparison.csv) | Service-level financial comparison between H1 2025 and H1 2026 |

These CSV files are static exports from Snowflake, not automatically refreshed datasets.

The detailed monthly export is generated by selecting from the reporting mart view.

See the [Reporting Export Guide](reports/README.md) for the SQL lineage and instructions to reproduce each file.

## 9. Business Insights

### H1 2026 versus H1 2025

Comparing January–June 2026 with the same six-month period in 2025:

| KPI | Year-over-year result |
| --- | ---: |
| Earned success-fee revenue | +12.8% |
| Processing costs | +38.5% |
| Submitted claim volume | −3.1% |
| Processing cost per submitted claim | +42.9% |
| Total submission-cohort margin | −2.7% |
| Margin rate | −8.6 percentage points |

Average processing cost per submitted claim increased from **€71.54 to €102.20**.

Total margin decreased from **€3,264,516.22 to €3,175,395.26**, a decline of **€89,120.96**.

The increase in processing costs exceeded revenue growth, reducing the overall margin rate from approximately **62.4% to 53.8%**.

### Service-level margin contribution

The two established services, `VAT_DIESEL` and `EXCISE_DIESEL`, improved their combined H1 margin by **€347,156.14**.

However, `VAT_EXPRESS`, launched in September 2025, generated **−€436,277.10** in H1 2026 submission-cohort margin. It had no H1 2025 operating baseline in the supplied data.

Its negative contribution offset the improvement in the established services.

This identifies service-level performance as an area for further investigation. The underlying causes have not been confirmed.

Potential areas for business review include pricing, processing efficiency, service mix, and cost allocation.

### Recent submission cohorts

August and September 2026 show negative submission-cohort margins. However, recent cohorts include many Pending claims, with processing costs recorded before the related success fees are earned.

These results should not be interpreted as confirmed final losses.

September 2026 is also incomplete, with source submissions ending on 17 September.

See the [Finance Director Summary](docs/finance_director_summary.md) for the business interpretation and recommendations.

## 10. Repository Structure

| Path | Description |
| --- | --- |
| [`data/raw/`](data/raw/) | Four original synthetic source CSV files |
| [`docs/data_dictionary.md`](docs/data_dictionary.md) | Source fields, definitions, and table relationships |
| [`sql/01_setup/`](sql/01_setup/) | Snowflake database setup, ingestion, and raw-load validation |
| [`sql/02_quality/`](sql/02_quality/) | Data-quality and financial validation SQL |
| [`sql/03_staging/`](sql/03_staging/) | Claim staging, enrichment, and validation |
| [`sql/04_marts/`](sql/04_marts/) | Monthly margin reporting mart, reconciliation, and business analysis |
| [`reports/`](reports/) | Four reporting CSV exports and reproduction instructions |
| [`docs/data_quality_findings.md`](docs/data_quality_findings.md) | Detailed data-quality findings and treatments |
| [`docs/finance_director_summary.md`](docs/finance_director_summary.md) | Financial insights, risks, and recommended actions |
| [`docs/automation_proposal.md`](docs/automation_proposal.md) | Proposed future validation automation and reporting controls |

## 11. Reproducing the Analysis

### Prerequisites

- Access to a Snowflake account with permission to create database objects
- An available Snowflake warehouse
- The four source CSV files included in [`data/raw/`](data/raw/)
- The [Data Dictionary](docs/data_dictionary.md)
- The SQL scripts included in this repository

### Execution sequence

**1. Review the source data**

Review the [Data Dictionary](docs/data_dictionary.md) and inspect the four source CSV files.

**2. Set up Snowflake**

Review and run the setup scripts in [`sql/01_setup/`](sql/01_setup/) in filename order for a fresh environment.

The current scripts use the original database, warehouse, and ingestion-object identifiers from the validated development environment. A different Snowflake environment may require consistent configuration changes.

Create the required stage and upload the four CSV files before running the source-load validation and ingestion steps.

Do not blindly rerun ingestion against existing populated tables.

**3. Validate the raw data**

Run the read-only checks in [`sql/02_quality/`](sql/02_quality/).

Confirm duplicate classification, reference integrity, business rules, and financial baseline figures before applying downstream transformations.

**4. Create the staging views**

Run the staging scripts in [`sql/03_staging/`](sql/03_staging/) in filename order.

Validate claim uniqueness, join cardinality, reference resolution, and financial totals.

**5. Create and validate the monthly reporting mart**

Create the reporting view using:

[`01_create_monthly_claim_margin.sql`](sql/04_marts/01_create_monthly_claim_margin.sql)

Run the reconciliation and reporting-grain uniqueness checks:

[`02_validate_monthly_claim_margin.sql`](sql/04_marts/02_validate_monthly_claim_margin.sql)

The first validation query produces the monthly reconciliation export. The second checks for duplicate reporting groups.

**6. Generate reporting exports**

- Export the detailed monthly dataset from a `SELECT` on the reporting mart view.
- Generate monthly trends using [`03_analyze_monthly_margin_trends.sql`](sql/04_marts/03_analyze_monthly_margin_trends.sql).
- Generate the H1 service comparison using [`04_analyze_h1_service_margin.sql`](sql/04_marts/04_analyze_h1_service_margin.sql).
- Compare the results against the four supplied reporting exports.

For the validated source snapshot, the reconciliation checkpoints are:

**90,612 RAW rows → 89,476 unique claims → 89,476 enriched claims → 2,182 monthly reporting groups.**

The sum of claim counts across the reporting groups must equal 89,476. Earned revenue, processing costs, and margin must reconcile with the validated financial baseline.

If the underlying source snapshot changes, rerun validation and update the documented results rather than relying on these fixed figures.

## 12. Limitations and Future Improvements

- The source data is synthetic.
- September 2026 is a partial reporting month.
- Submission-cohort margin is not equivalent to accounting-period recognized margin.
- Negative processing costs and claims submitted before onboarding require business confirmation.
- Country-name normalization rules remain subject to business approval.
- Missing historical segments limit segment-level reporting.
- A dedicated statistical outlier and distribution-impact assessment has not yet been completed.
- Automated scheduling, notifications, and controlled publication have not been implemented.
- SQL reporting views do not automatically prevent unvalidated future data from appearing in query results.
- New datasets require fresh quality checks and financial reconciliation.

## 13. Future Automation Proposal

A future workflow could run data-quality and financial validation checks after each source batch is loaded into Snowflake.

Results could be recorded by batch ID, including the check status, affected records, and measurable financial impact.

A controlled publication process could distinguish:

- **PASS:** Publish validated data.
- **WARNING:** Log exceptions and notify the responsible owner under agreed policies.
- **CRITICAL FAIL:** Block the new reporting release and preserve the last approved snapshot.

This is a design proposal only.

See [Proposed Data Quality Automation](docs/automation_proposal.md).

## 14. Project Summary

This project demonstrates practical SQL analytics engineering and financial reporting through:

- Structured data-quality investigation
- Validated claim-level deduplication
- Controlled dimensional enrichment
- Financial reconciliation across reporting layers
- Monthly margin reporting
- Service-level business analysis
- Transparent documentation of assumptions and limitations

The result is a documented Snowflake analytics solution designed to support reliable submission-cohort margin analysis and further financial investigation.