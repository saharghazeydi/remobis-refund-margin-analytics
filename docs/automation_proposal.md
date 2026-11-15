# REMOBIS — Proposed Data Quality Automation

### When and how

After each new source batch is loaded into Snowflake, automated SQL checks would run before reporting publication. Results would be logged by batch ID, including check status, affected records and financial impact where measurable.

A controlled release process would preserve the last approved reporting snapshot if critical checks fail. Failed batches could be corrected and safely reprocessed without creating duplicates.

### What to check

- **Ingestion and integrity:** Missing files or columns, duplicate loads, missing claim IDs, conflicting duplicates, invalid values, unmatched references and unexpected join multiplication.
- **Business rules:** Earned fees only for Refunded claims; processing days required for decided claims. Flag negative costs, pre-onboarding claims and missing historical segments. Missing processing days for Pending claims are expected.
- **Financial reconciliation:** Account for verified identical duplicates when comparing RAW with staging. Reconcile claim counts, earned fees, processing costs and margin across staging, enrichment and monthly reporting.

### Notifications and actions

**PASS:** Approve the validated batch for publication.

**WARNING:** Log exceptions and notify the relevant owner. Technical issues go to the Data Owner, financial exceptions to Finance, and customer-related issues to the responsible operational owner. Publication follows an agreed policy.

**CRITICAL FAIL:** Block the new reporting release for critical issues, such as conflicting claim records or unexplained financial differences. Alert the technical Data Owner and notify the Finance Reporting Owner if financial reporting is affected.

Alert recipients, thresholds and escalation rules would be agreed with REMOBIS.

*Design proposal only; automation and publication controls have not been implemented.*
