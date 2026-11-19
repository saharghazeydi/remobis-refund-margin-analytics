# Data Dictionary

**Project:** Refund Financial Analytics

**Dataset:** Synthetic fuel-tax refund claims data

**Source:** Four CSV files representing claims, customers, services, and countries.

## 1. Data Overview

The dataset represents a fictional refund services operation. Customers submit fuel invoices to recover VAT or excise duty paid on diesel purchases.

The source data contains four tables:

| Table | Description | Source rows |
| --- | --- | ---: |
| `FACT_REFUND_CLAIMS` | Individual refund claim records | 90,612 |
| `DIM_CUSTOMER` | Customer information | 1,200 |
| `DIM_SERVICE` | Refund service definitions | 3 |
| `DIM_COUNTRY` | Country and regional information | 14 |

The data covers claim submissions from 1 January 2025 to 17 September 2026.

The original data is preserved. Quality checks and transformations are implemented separately in SQL.

## 2. FACT_REFUND_CLAIMS

**Grain:** One logical record per refund claim, identified by `TRANSACTION_ID`. The supplied RAW extract contains duplicate records.

| Column | Data type | Business definition |
| --- | --- | --- |
| `TRANSACTION_ID` | VARCHAR | Unique claim identifier |
| `TRANSACTION_DATE` | DATE | Date the claim was submitted |
| `CUSTOMER_ID` | VARCHAR | Reference to the customer |
| `CUSTOMER_SEGMENT` | VARCHAR | Customer segment at the time of the claim: SME, Mid-Market, or Large |
| `SERVICE_CODE` | VARCHAR | Refund service used |
| `SERVICE_COUNTRY` | VARCHAR | Country where diesel was purchased and the refund claim was filed |
| `CHANNEL` | VARCHAR | Submission channel: Portal, API, or Partner |
| `INVOICE_COUNT` | NUMBER | Number of fuel invoices included in the claim |
| `GROSS_CLAIM_AMOUNT_EUR` | NUMBER(14,2) | Amount of the refund claimed, in EUR |
| `FEE_REVENUE_EUR` | NUMBER(14,2) | Success fee recorded for the claim; earned only if the claim is refunded |
| `PROCESSING_COST_EUR` | NUMBER(14,2) | Internal cost of processing the claim, in EUR |
| `CLAIM_STATUS` | VARCHAR | Claim status: Refunded, Rejected, or Pending |
| `PROCESSING_DAYS` | NUMBER | Number of days from submission to decision; may be empty for Pending claims |

## 3. DIM_CUSTOMER

**Grain:** One record per customer, identified by `CUSTOMER_ID`.

| Column | Data type | Business definition |
| --- | --- | --- |
| `CUSTOMER_ID` | VARCHAR | Unique customer reference |
| `CUSTOMER_NAME` | VARCHAR | Anonymized customer name |
| `CUSTOMER_SEGMENT` | VARCHAR | Current customer segment or size |
| `HOME_COUNTRY_CODE` | VARCHAR | Country code of the customer's headquarters |
| `ONBOARDING_DATE` | DATE | Customer contract start date |
| `ACCOUNT_STATUS` | VARCHAR | Current account status: Active or Inactive |

**Important:** The current customer segment in this dimension is not necessarily the historical segment recorded on an individual claim.

## 4. DIM_SERVICE

**Grain:** One record per service, identified by `SERVICE_CODE`.

| Column | Business definition |
| --- | --- |
| `SERVICE_CODE` | Unique service identifier |
| `SERVICE_NAME` | Descriptive service name |
| `SERVICE_CATEGORY` | Refund service category |
| `LAUNCH_DATE` | Date the service became available |
| `LIST_FEE_RATE_PCT` | Published success-fee rate, expressed as a percentage |

The original assignment provides the column names and an example service record but does not specify individual data types for this table.

**Important:** The published list fee rate does not necessarily equal the realized fee rate for an individual claim.

## 5. DIM_COUNTRY

**Grain:** One record per country, identified by `COUNTRY_CODE`.

| Column | Business definition |
| --- | --- |
| `COUNTRY_CODE` | Country identifier |
| `COUNTRY_NAME` | Country name |
| `REGION` | Geographic region: Western Europe, Southern Europe, Eastern Europe, or Nordics |

The original assignment supplies the column names and regional examples but does not specify individual data types for this table.

Country-name variants in the source fact table require normalization before joining to the country dimension.

## 6. Relationships

| Source field | Referenced field | Relationship |
| --- | --- | --- |
| `FACT_REFUND_CLAIMS.CUSTOMER_ID` | `DIM_CUSTOMER.CUSTOMER_ID` | Many claims to one customer |
| `FACT_REFUND_CLAIMS.SERVICE_CODE` | `DIM_SERVICE.SERVICE_CODE` | Many claims to one service |
| `FACT_REFUND_CLAIMS.SERVICE_COUNTRY` | `DIM_COUNTRY.COUNTRY_NAME` | Many claims to one country, after approved name normalization |
| `DIM_CUSTOMER.HOME_COUNTRY_CODE` | `DIM_COUNTRY.COUNTRY_CODE` | Many customers to one country |

Referential integrity and join cardinality are checked before producing the reporting dataset.

## 7. Financial Definitions

**Earned fee revenue:** The recorded success fee is included as earned revenue only for Refunded claims.

**Processing cost:** The internal claim processing cost, included for Refunded, Rejected, and Pending claims.

**Margin:** Earned fee revenue minus processing cost.

**Reporting month:** The month of `TRANSACTION_DATE`, representing the claim submission month.

**Historical customer segment:** The segment recorded on the claim at submission time, rather than the customer's current segment in `DIM_CUSTOMER`.

The reporting model produces submission-month cohort margins, not accounting-period recognized margins. Revenue-recognition dates are not available in the supplied source data.

## 8. Source and Reporting Considerations

- The source CSVs are preserved without modification.
- Source columns are ingested as text before controlled type conversion.
- Duplicate claim records are investigated before one-copy deduplication.
- Missing processing days can be valid for Pending claims.
- Negative processing costs remain signed unless a correction is approved.
- Missing historical customer segments are represented as `Unknown` in the reporting mart.
- Country-name aliases are normalized for reporting joins.
- All financial amounts are expressed in EUR unless otherwise stated.
- Data-quality findings and known limitations are documented separately.

See [Data Quality Findings](data_quality_findings.md) for the results of the validation checks.

See [Reporting Exports](../reports/README.md) for the reporting dataset, aggregation grain, and reconciled financial outputs.