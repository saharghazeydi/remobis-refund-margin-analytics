
-- ============================================================
-- REMOBIS | PRE-ONBOARDING FINANCIAL EXPOSURE
-- ============================================================
-- Purpose:
--   Measure financial values linked to claims submitted
--   before customer onboarding.
--
-- Scenarios:
--   1. All affected RAW rows.
--   2. One copy per claim ID.
--
-- Deduplication scenario relies on quality check 03,
-- which confirmed identical duplicates in this snapshot.
--
-- This is reporting exposure, not confirmed financial loss.
-- RAW data is not modified.
-- ============================================================

WITH early_claims AS (
    SELECT
        NULLIF(TRIM(f.TRANSACTION_ID), '') AS claim_id,
        UPPER(TRIM(f.CLAIM_STATUS)) AS claim_status,

        TRY_CAST(
            f.FEE_REVENUE_EUR AS NUMBER(38,10)
        ) AS fee_eur,

        TRY_CAST(
            f.PROCESSING_COST_EUR AS NUMBER(38,10)
        ) AS cost_eur,

        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(f.TRANSACTION_ID), '')
            ORDER BY
                f.SOURCE_FILENAME,
                f.SOURCE_FILE_CONTENT_KEY,
                f.SOURCE_FILE_ROW_NUMBER
        ) AS copy_number

    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS f

    INNER JOIN REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER c
        ON UPPER(TRIM(f.CUSTOMER_ID))
         = UPPER(TRIM(c.CUSTOMER_ID))

    WHERE TRY_TO_DATE(
        f.TRANSACTION_DATE, 'YYYY-MM-DD'
    ) < TRY_TO_DATE(
        c.ONBOARDING_DATE, 'YYYY-MM-DD'
    )
),

financial_summary AS (
    SELECT
        COUNT(*) AS raw_rows,
        COUNT(DISTINCT claim_id) AS distinct_claims,

        SUM(IFF(
            claim_id IS NULL
            OR claim_status IS NULL
            OR claim_status NOT IN (
                'REFUNDED', 'REJECTED', 'PENDING'
            )
            OR fee_eur IS NULL
            OR cost_eur IS NULL,
            1, 0
        )) AS invalid_rows,

        SUM(IFF(
            claim_status = 'REFUNDED', fee_eur, 0
        )) AS raw_revenue,

        SUM(cost_eur) AS raw_cost,

        SUM(IFF(
            copy_number = 1
            AND claim_status = 'REFUNDED',
            fee_eur, 0
        )) AS unique_revenue,

        SUM(IFF(
            copy_number = 1, cost_eur, 0
        )) AS unique_cost

    FROM early_claims
)

SELECT
    raw_rows,
    distinct_claims,
    raw_rows - distinct_claims AS excess_rows,
    invalid_rows,

    CASE WHEN invalid_rows = 0
        THEN ROUND(raw_revenue, 2)
    END AS raw_earned_fee_eur,

    CASE WHEN invalid_rows = 0
        THEN ROUND(raw_cost, 2)
    END AS raw_cost_eur,

    CASE WHEN invalid_rows = 0
        THEN ROUND(raw_revenue - raw_cost, 2)
    END AS raw_margin_eur,

    CASE WHEN invalid_rows = 0
        THEN ROUND(unique_revenue, 2)
    END AS unique_earned_fee_eur,

    CASE WHEN invalid_rows = 0
        THEN ROUND(unique_cost, 2)
    END AS unique_cost_eur,

    CASE WHEN invalid_rows = 0
        THEN ROUND(unique_revenue - unique_cost, 2)
    END AS unique_margin_eur

FROM financial_summary;
