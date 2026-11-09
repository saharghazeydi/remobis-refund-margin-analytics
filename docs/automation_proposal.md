# Proposed Data Quality Automation

**Trigger and timing**

Run the data-quality pipeline after each new source batch lands in Snowflake, before refreshing reporting views or downstream dashboards. Use an orchestrated, repeatable process. No scheduler is implemented in this case study.

**Automated checks**

1. **Ingestion:** Verify expected files, schema, column names, row counts, and source metadata. Detect incomplete or repeated loads.
2. **Data integrity:** Check required keys, exact duplicates, conflicting claim versions, numeric types, date formats, valid categories, and dimension references.
3. **Business rules:** Check fee eligibility by claim status, missing processing days on completed claims, negative costs, and claims dated before customer onboarding. Treat missing processing days on Pending claims as valid.
4. **Financial reconciliation:** Compare RAW, deduplicated STAGING, enriched STAGING, and monthly reporting totals. Check claim counts, earned fees, processing costs, margin, and join cardinality.

**Failure handling and notifications**

Block publication when critical checks fail, such as conflicting claim IDs, invalid financial values, unresolved required references, or unexplained reconciliation differences. Keep affected records in an exception log with source lineage; do not silently delete or change them.

Send critical alerts to Data Engineering and Finance Operations. Send noncritical warnings, such as negative costs and pre-onboarding claims, to the Finance Controller for review. Include affected counts, financial exposure, batch identifier, and links to diagnostic results.

**Monitoring**

Review warnings after each batch. Review quality trends and repeated exceptions weekly. Keep execution logs and reconciliation results for audit and troubleshooting.