# REMOBIS — Finance Director Summary

## Can we trust the data?

**The original extract should not be used directly for monthly margin reporting.** However, the cleaned dataset is suitable for submission-month cohort analysis for the validated snapshot, subject to the outstanding business risks below.

The original claims extract contained 90,612 rows, including 1,136 excess exact duplicate copies. Counting all copies would increase reported margin by **€128,980.01** compared with one claim per transaction ID. In addition, 3,714 source rows used nonstandard country names that could cause incorrect country attribution or exclusion during joins.

## What has been delivered?

A validated reporting dataset now contains **89,476 unique claims**, with:

| Financial metric | Validated total |
|---|---:|
| Earned success fees | €17,567,448.40 |
| Processing costs | €7,860,558.99 |
| **Margin** | **€9,706,889.41** |

The monthly reporting dataset contains 2,182 groups across 21 submission months. Reconciliation confirms that dimension joins preserve claim counts and financial totals, with no duplicate reporting keys.

## What risks remain?

- **Negative processing costs:** 72 claims contain €7,293.06 in negative costs. Finance must confirm whether these are valid adjustments.
- **Pre-onboarding claims:** 435 unique claims were submitted before their customers' recorded contract start dates. The business explanation remains unconfirmed.
- **Historical classifications:** Missing customer segments remain explicitly unknown. Current customer segments are not substituted for historical values.
- **Accounting timing:** The available transaction date is the claim submission date, not a confirmed revenue-recognition date. This report must not be described as accounting-period margin.

## Business observations

In the first half of 2026, processing costs increased faster than earned revenue compared with the first half of 2025. This warrants investigation into service mix, country mix, and cost drivers.

August and September 2026 show negative submission-cohort margins alongside a high proportion of Pending claims. This does not establish a permanent loss: success fees are earned only after refunds, while processing costs can already be recorded. September is also incomplete, with data ending on 17 September.

**Recommendation:** Use the validated dataset for submission-cohort reporting, monitor the identified exceptions, and confirm the outstanding financial rules before relying on these figures for formal accounting decisions.

*All figures relate to synthetic case-study data, not REMOBIS's actual financial performance.*