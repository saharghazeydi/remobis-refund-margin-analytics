
-- ============================================================
-- REMOBIS | MONTHLY MARGIN RECONCILIATION
-- ============================================================

SELECT
    COUNT(*) AS monthly_groups,

    MIN(SUBMISSION_MONTH) AS first_month,
    MAX(SUBMISSION_MONTH) AS last_month,

    SUM(CLAIM_COUNT) AS total_claims,

    SUM(REFUNDED_CLAIMS) AS refunded_claims,
    SUM(REJECTED_CLAIMS) AS rejected_claims,
    SUM(PENDING_CLAIMS) AS pending_claims,

    SUM(IFF(
        HISTORICAL_CUSTOMER_SEGMENT = 'Unknown',
        CLAIM_COUNT, 0
    )) AS unknown_segment_claims,

    SUM(NEGATIVE_COST_CLAIMS) AS negative_cost_claims,
    SUM(PRE_ONBOARDING_CLAIMS) AS pre_onboarding_claims,

    ROUND(SUM(EARNED_REVENUE_EUR), 2)
        AS earned_revenue_eur,

    ROUND(SUM(PROCESSING_COST_EUR), 2)
        AS processing_cost_eur,

    ROUND(SUM(MARGIN_EUR), 2)
        AS margin_eur

FROM REMOBIS_CASE_STUDY.ANALYTICS.MART_MONTHLY_CLAIM_MARGIN;
