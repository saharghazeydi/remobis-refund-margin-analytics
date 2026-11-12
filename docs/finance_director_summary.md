# REMOBIS — Finance Director Summary

## Can we trust the data?

**The original extract should not be used for reporting without validation.** The cleaned dataset is suitable for **margin analysis by claim submission month** for the supplied snapshot. It is not an accounting-period margin report because revenue-recognition dates were not provided.

## What was fixed?

The source contained **90,612 claim rows**, including **1,136 excess identical copies**. Counting those copies would overstate reported margin by **€128,980.01** compared with one record per claim. We also standardized four country-name variations affecting **3,714 RAW rows**. All country references matched after standardization in the validated dataset.

The reporting dataset contains **89,476 unique claims**, with **€17,567,448.40** in earned success fees, **€7,860,558.99** in processing costs, and **€9,706,889.41** in margin. Claim counts and financial totals reconcile across staging, dimension joins, and monthly reporting. Original source records remain unchanged.

## What risks remain?

- **72 claims** have negative processing costs totaling **−€7,293.06**; Finance must confirm whether these are valid adjustments.
- **435 claims** were submitted before customer onboarding; the business reason remains unconfirmed.
- **2,573 claims** lack historical customer segments and appear as `Unknown`. This limits segment-level analysis but does not exclude these claims from overall financial totals. Country-name mappings also require business approval.
- Submission dates are not revenue-recognition dates. Recent cohorts contain Pending claims, and September 2026 includes submissions only through **17 September**.

## What stands out, and what should we do?

In **January–June 2026**, processing costs rose **38.5%** compared with the same six months in 2025, while earned fees rose **12.8%**. Submitted claim volume fell **3.1%**, but **average processing cost per submitted claim** increased from **€71.54 to €102.20 (+42.9%)**.

Total margin **fell 2.7%**, while margin as a share of earned fees declined from **62.4% to 53.8%**—a drop of **8.6 percentage points**. The increase in processing costs cannot be explained by a higher number of submitted claims alone. Service mix, country mix, and other cost drivers require investigation; the cause is not yet established.

August and September 2026 show negative submission-cohort margins, but many claims remain Pending. These are not confirmed final losses.

**Recommendation:** Use the validated data for submission-cohort reporting. Prioritize a review of processing cost per submitted claim by service and country, investigate flagged exceptions, and confirm outstanding financial rules before using these figures for formal accounting.

*All figures are from synthetic case-study data, not REMOBIS's actual financial performance.*
