
-- ============================================================
-- REMOBIS | FEE AND NEGATIVE COST VALIDATION
-- ============================================================
-- Purpose:
--   Validate fee behavior by claim status and investigate
--   negative processing costs.
--
-- Rules:
--   - Success fees are earned only for Refunded claims.
--   - Processing costs can apply to all claim statuses.
--   - Negative costs are flagged, not automatically corrected.
--   - All counts include RAW duplicate records.
--
-- Read-only.
-- ============================================================

WITH claims AS (
    SELECT
        NULLIF(TRIM(TRANSACTION_ID), '') AS claim_id,
        UPPER(TRIM(CLAIM_STATUS)) AS claim_status,

        TRY_CAST(
            FEE_REVENUE_EUR AS NUMBER(38,10)
        ) AS fee_eur,

        TRY_CAST(
            PROCESSING_COST_EUR AS NUMBER(38,10)
        ) AS cost_eur

    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
)

SELECT
    claim_status,
    COUNT(*) AS raw_rows,

    SUM(IFF(
        fee_eur = 0, 1, 0
    )) AS zero_fee_rows,

    SUM(IFF(
        claim_status = 'REFUNDED'
        AND fee_eur = 0,
        1, 0
    )) AS refunded_zero_fee_rows,

    SUM(IFF(
        claim_status IN ('REJECTED', 'PENDING')
        AND fee_eur <> 0,
        1, 0
    )) AS non_refunded_nonzero_fee_rows,

    SUM(IFF(
        cost_eur < 0, 1, 0
    )) AS negative_cost_rows,

    COUNT(DISTINCT IFF(
        cost_eur < 0, claim_id, NULL
    )) AS negative_cost_claim_ids,

    ROUND(SUM(
        IFF(cost_eur < 0, cost_eur, 0)
    ), 2) AS total_negative_cost_eur

FROM claims
GROUP BY claim_status
ORDER BY claim_status;
