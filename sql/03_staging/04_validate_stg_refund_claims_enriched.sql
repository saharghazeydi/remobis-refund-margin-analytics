
-- ============================================================
-- REMOBIS | ENRICHED STAGING RECONCILIATION
-- ============================================================
-- Verify claim preservation, dimension coverage,
-- review flags, and unchanged financial totals.
-- ============================================================

SELECT
    COUNT(*) AS enriched_rows,

    COUNT(DISTINCT CLAIM_ID) AS distinct_claims,

    COUNT(*) - COUNT(DISTINCT CLAIM_ID)
        AS duplicate_join_rows,

    SUM(IFF(
        CUSTOMER_NAME IS NULL, 1, 0
    )) AS unmatched_customer_rows,

    SUM(IFF(
        SERVICE_NAME IS NULL, 1, 0
    )) AS unmatched_service_rows,

    SUM(IFF(
        SERVICE_COUNTRY_CODE IS NULL, 1, 0
    )) AS unmatched_country_rows,

    SUM(IFF(
        PRE_ONBOARDING_FLAG, 1, 0
    )) AS pre_onboarding_claims,

    SUM(IFF(
        NEGATIVE_COST_FLAG, 1, 0
    )) AS negative_cost_claims,

    SUM(IFF(
        HISTORICAL_CUSTOMER_SEGMENT IS NULL, 1, 0
    )) AS missing_historical_segments,

    ROUND(SUM(EARNED_FEE_EUR), 2)
        AS earned_revenue_eur,

    ROUND(SUM(PROCESSING_COST_EUR), 2)
        AS processing_cost_eur,

    ROUND(SUM(CLAIM_MARGIN_EUR), 2)
        AS margin_eur

FROM REMOBIS_CASE_STUDY.STAGING.STG_REFUND_CLAIMS_ENRICHED;
