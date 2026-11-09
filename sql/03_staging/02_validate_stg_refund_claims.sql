

SELECT
    COUNT(*) AS staged_rows,

    COUNT(DISTINCT CLAIM_ID) AS distinct_claims,

    SUM(IFF(
        SOURCE_COPY_COUNT > 1, 1, 0
    )) AS deduplicated_claim_groups,

    SUM(IFF(
        HISTORICAL_CUSTOMER_SEGMENT IS NULL, 1, 0
    )) AS missing_historical_segments,

    SUM(IFF(
        PROCESSING_COST_EUR < 0, 1, 0
    )) AS negative_cost_claims,

    ROUND(SUM(EARNED_FEE_EUR), 2)
        AS earned_revenue_eur,

    ROUND(SUM(PROCESSING_COST_EUR), 2)
        AS processing_cost_eur,

    ROUND(
        SUM(EARNED_FEE_EUR - PROCESSING_COST_EUR),
        2
    ) AS margin_eur

FROM REMOBIS_CASE_STUDY.STAGING.STG_REFUND_CLAIMS;
