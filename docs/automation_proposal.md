# Proposed Data Quality Automation

## When and how

After each new source batch is loaded into Snowflake, an automated workflow would run the existing SQL validation checks before approving the data for reporting. Results would be logged by batch ID, including check status, affected rows, and financial impact where measurable.

A controlled publication step would preserve the last validated reporting snapshot if critical checks fail. Failed batches could be investigated and reprocessed safely without creating duplicate records.

## What to check

- **Ingestion:** Missing files or columns, unexpected row counts, and duplicate batch loads.
- **Data integrity:** Missing claim IDs, conflicting duplicates, invalid numeric values, dates or categories, and unmatched dimension references.
- **Business rules:** Success fees only for Refunded claims; processing days required for decided claims. Flag negative costs, pre-onboarding claims, and missing historical segments. Missing processing days for Pending claims are valid.
- **Financial reconciliation:** Account for verified duplicate copies when comparing RAW with deduplicated staging. Reconcile claim counts, earned revenue, processing costs, and margin across staging, enrichment, and monthly aggregation. Detect unexpected row multiplication from joins.

## Who is notified

**Critical failures** would block publication and notify the responsible technical data owner or finance reporting owner.

**Business warnings** would be logged and sent to the responsible finance owner without automatically blocking reporting.

Alerts would identify the batch, failed check, affected record counts, and financial impact where measurable. Alert thresholds and recipients would be agreed with REMOBIS.
