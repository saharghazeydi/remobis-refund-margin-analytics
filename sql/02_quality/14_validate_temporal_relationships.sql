
-- ============================================================
-- REMOBIS | TEMPORAL RELATIONSHIP VALIDATION
-- ============================================================
-- Purpose:
--   Detect claims submitted before customer onboarding
--   or before the associated service launch date.
--
-- Rules:
--   - Use the claim submission date for comparisons.
--   - Preserve all RAW claims, including duplicates.
--   - Report anomalies without automatic correction.
--   - Use normalized keys for dimension joins.
--
-- Read-only.
-- ============================================================

WITH claim_dates AS (
    SELECT
        NULLIF(TRIM(f.TRANSACTION_ID), '') AS claim_id,

        TRY_TO_DATE(
            f.TRANSACTION_DATE, 'YYYY-MM-DD'
        ) AS submission_date,

        TRY_TO_DATE(
            c.ONBOARDING_DATE, 'YYYY-MM-DD'
        ) AS onboarding_date,

        TRY_TO_DATE(
            s.LAUNCH_DATE, 'YYYY-MM-DD'
        ) AS service_launch_date

    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS f

    LEFT JOIN REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER c
        ON UPPER(TRIM(f.CUSTOMER_ID))
         = UPPER(TRIM(c.CUSTOMER_ID))

    LEFT JOIN REMOBIS_CASE_STUDY.RAW.DIM_SERVICE s
        ON UPPER(TRIM(f.SERVICE_CODE))
         = UPPER(TRIM(s.SERVICE_CODE))
)

SELECT
    COUNT(*) AS joined_claim_rows,

    -- Claims submitted before customer contract start
    SUM(IFF(
        submission_date < onboarding_date,
        1, 0
    )) AS before_onboarding_raw_rows,

    COUNT(DISTINCT IFF(
        submission_date < onboarding_date,
        claim_id, NULL
    )) AS before_onboarding_distinct_claims,

    -- Claims submitted before service launch
    SUM(IFF(
        submission_date < service_launch_date,
        1, 0
    )) AS before_launch_raw_rows,

    COUNT(DISTINCT IFF(
        submission_date < service_launch_date,
        claim_id, NULL
    )) AS before_launch_distinct_claims,

    -- Records that cannot be evaluated
    SUM(IFF(
        submission_date IS NULL
        OR onboarding_date IS NULL,
        1, 0
    )) AS onboarding_not_evaluable_rows,

    SUM(IFF(
        submission_date IS NULL
        OR service_launch_date IS NULL,
        1, 0
    )) AS launch_not_evaluable_rows

FROM claim_dates;
