
-- ============================================================
-- REMOBIS | PRE-ONBOARDING CLAIM DIAGNOSTICS
-- ============================================================
-- Purpose:
--   Investigate claims submitted before customer onboarding.
--
-- Rules:
--   - Compare normalized customer IDs.
--   - Count RAW rows and distinct claims separately.
--   - Do not treat anomalies as confirmed errors.
--   - Do not modify source data.
-- ============================================================

WITH early_claims AS (
    SELECT
        NULLIF(TRIM(f.TRANSACTION_ID), '') AS claim_id,
        UPPER(TRIM(f.CUSTOMER_ID)) AS customer_key,
        UPPER(TRIM(f.CLAIM_STATUS)) AS claim_status,

        DATEDIFF(
            'day',
            TRY_TO_DATE(f.TRANSACTION_DATE, 'YYYY-MM-DD'),
            TRY_TO_DATE(c.ONBOARDING_DATE, 'YYYY-MM-DD')
        ) AS days_before_onboarding

    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS f

    INNER JOIN REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER c
        ON UPPER(TRIM(f.CUSTOMER_ID))
         = UPPER(TRIM(c.CUSTOMER_ID))

    WHERE
        TRY_TO_DATE(f.TRANSACTION_DATE, 'YYYY-MM-DD')
        < TRY_TO_DATE(c.ONBOARDING_DATE, 'YYYY-MM-DD')
)

SELECT
    claim_status,
    COUNT(*) AS raw_rows,
    COUNT(DISTINCT claim_id) AS distinct_claims,
    COUNT(DISTINCT customer_key) AS affected_customers,

    MIN(days_before_onboarding) AS min_days_early,
    MAX(days_before_onboarding) AS max_days_early,
    ROUND(AVG(days_before_onboarding), 1) AS avg_days_early

FROM early_claims
GROUP BY claim_status
ORDER BY raw_rows DESC;
