
-- ============================================================
-- REMOBIS | FINANCIAL BASELINE RECONCILIATION
-- ============================================================
-- Purpose:
--   Compare financial totals across all RAW claim rows
--   and one-copy-per-claim reporting scenario.
--
-- Prerequisites:
--   Quality checks 02-04 have confirmed no missing claim
--   IDs and only identical duplicate records.
--
-- Business rules:
--   - Earn fee revenue only for Refunded claims.
--   - Include processing costs for all claim statuses.
--   - Preserve negative costs pending business review.
--   - Do not modify RAW data.
--
-- These are submission-cohort financial totals,
-- not accounting-period revenue recognition.
-- ============================================================

WITH ranked_claims AS (
    SELECT
        NULLIF(TRIM(TRANSACTION_ID), '') AS claim_id,
        UPPER(TRIM(CLAIM_STATUS)) AS claim_status,

        TRY_CAST(
            FEE_REVENUE_EUR AS NUMBER(38,10)
        ) AS fee_eur,

        TRY_CAST(
            PROCESSING_COST_EUR AS NUMBER(38,10)
        ) AS cost_eur,

        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(TRANSACTION_ID), '')
            ORDER BY
                SOURCE_FILENAME,
                SOURCE_FILE_CONTENT_KEY,
                SOURCE_FILE_ROW_NUMBER
        ) AS copy_number

    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
),

financial_totals AS (
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

    FROM ranked_claims
)

SELECT
    raw_rows,
    distinct_claims,
    raw_rows - distinct_claims AS excess_rows,
    invalid_rows,

    IFF(invalid_rows = 0,
        ROUND(raw_revenue, 2), NULL
    ) AS raw_revenue_eur,

    IFF(invalid_rows = 0,
        ROUND(raw_cost, 2), NULL
    ) AS raw_cost_eur,

    IFF(invalid_rows = 0,
        ROUND(raw_revenue - raw_cost, 2), NULL
    ) AS raw_margin_eur,

    IFF(invalid_rows = 0,
        ROUND(unique_revenue, 2), NULL
    ) AS unique_revenue_eur,

    IFF(invalid_rows = 0,
        ROUND(unique_cost, 2), NULL
    ) AS unique_cost_eur,

    IFF(invalid_rows = 0,
        ROUND(unique_revenue - unique_cost, 2), NULL
    ) AS unique_margin_eur,

    IFF(invalid_rows = 0,
        ROUND(
            (raw_revenue - raw_cost)
            - (unique_revenue - unique_cost),
            2
        ), NULL
    ) AS duplicate_margin_difference_eur

FROM financial_totals;
