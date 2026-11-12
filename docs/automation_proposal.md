
# Proposed Data Quality Automation

**When and how**

When a new source batch finishes loading into Snowflake, an automated workflow would run validation rules based on the existing SQL checks. The batch would be checked before approval for reporting. A controlled publication step would keep the last validated reporting dataset available if critical checks fail.

**What to check**

- **Ingestion:** Missing files or columns, unexpected row counts, and repeated batch loads.
- **Data integrity:** Missing claim IDs, conflicting duplicates, invalid numeric values, dates, and categories, and unmatched dimension references.
- **Business rules:** Success fees only for Refunded claims; processing days required for decided claims. Flag negative costs, pre-onboarding claims, and missing historical segments. Missing processing days for Pending claims are valid.
- **Financial reconciliation:** Account for confirmed duplicate copies when comparing RAW with deduplicated staging. Check that claim counts, revenue, costs, and margin remain consistent through enrichment and monthly aggregation, without extra rows from joins.

**Who is notified**

Critical failures would stop publication and alert the designated technical data owner or finance reporting owner, depending on the issue. Business warnings would go to the responsible finance owner without automatically blocking reporting.

Alerts would include the batch ID, affected record counts, financial impact where measurable, and details needed for investigation. The exact recipients and alert thresholds would be agreed with REMOBIS.
