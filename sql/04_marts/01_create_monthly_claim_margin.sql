
-- ============================================================
-- REMOBIS | MONTHLY CLAIM MARGIN MART
-- ============================================================
-- Grain:
--   Submission month x service x service country
--   x historical customer segment.
--
-- Financial rules:
--   - Earned fees belong only to Refunded claims.
--   - Processing costs apply to all statuses.
--   - Preserve negative costs and flagged claims.
--   - Unknown historical segments remain in the totals.
--
-- Important:
--   This is submission-month cohort margin,
--   NOT accounting-period recognized margin.
-- ============================================================

CREATE VIEW REMOBIS_CASE_STUDY.ANALYTICS.MART_MONTHLY_CLAIM_MARGIN AS

SELECT
    DATE_TRUNC('MONTH', SUBMISSION_DATE)::DATE
        AS SUBMISSION_MONTH,

    SERVICE_CODE,
    SERVICE_NAME,

    SERVICE_COUNTRY_CODE,
    SERVICE_COUNTRY_NAME,
    SERVICE_REGION,

    COALESCE(
        HISTORICAL_CUSTOMER_SEGMENT, 'Unknown'
    ) AS HISTORICAL_CUSTOMER_SEGMENT,

    COUNT(*) AS CLAIM_COUNT,

    SUM(IFF(CLAIM_STATUS = 'REFUNDED', 1, 0))
        AS REFUNDED_CLAIMS,

    SUM(IFF(CLAIM_STATUS = 'REJECTED', 1, 0))
        AS REJECTED_CLAIMS,

    SUM(IFF(CLAIM_STATUS = 'PENDING', 1, 0))
        AS PENDING_CLAIMS,

    SUM(IFF(NEGATIVE_COST_FLAG, 1, 0))
        AS NEGATIVE_COST_CLAIMS,

    SUM(IFF(PRE_ONBOARDING_FLAG, 1, 0))
        AS PRE_ONBOARDING_CLAIMS,

    SUM(EARNED_FEE_EUR)
        AS EARNED_REVENUE_EUR,

    SUM(PROCESSING_COST_EUR)
        AS PROCESSING_COST_EUR,

    SUM(CLAIM_MARGIN_EUR)
        AS MARGIN_EUR

FROM REMOBIS_CASE_STUDY.STAGING.STG_REFUND_CLAIMS_ENRICHED

GROUP BY
    SUBMISSION_MONTH,
    SERVICE_CODE,
    SERVICE_NAME,
    SERVICE_COUNTRY_CODE,
    SERVICE_COUNTRY_NAME,
    SERVICE_REGION,
    HISTORICAL_CUSTOMER_SEGMENT;
