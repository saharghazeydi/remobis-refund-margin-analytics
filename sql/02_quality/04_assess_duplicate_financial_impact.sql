
-- ============================================================
-- REMOBIS | DUPLICATE CLAIM FINANCIAL IMPACT
-- ============================================================
-- Purpose:
--   Estimate the financial contribution of excess copies
--   belonging to identical duplicate claims.
--
-- Rules:
--   - Compare all 13 original business fields.
--   - Exclude blank transaction IDs.
--   - Exclude claim IDs with conflicting content versions.
--   - Retain one copy per eligible claim ID.
--   - Recognize fee revenue only for Refunded claims.
--   - Include processing costs for all statuses.
--   - Report invalid values without hiding them.
--
-- Reporting scenario only. RAW data is not modified.
-- ============================================================

-- Step 1: Prepare source data and normalize claim IDs.
WITH source_claims AS (
    SELECT
        NULLIF(TRIM(TRANSACTION_ID), '') AS claim_key,
        TRANSACTION_ID,
        TRANSACTION_DATE,
        CUSTOMER_ID,
        CUSTOMER_SEGMENT,
        SERVICE_CODE,
        SERVICE_COUNTRY,
        CHANNEL,
        INVOICE_COUNT,
        GROSS_CLAIM_AMOUNT_EUR,
        FEE_REVENUE_EUR,
        PROCESSING_COST_EUR,
        CLAIM_STATUS,
        PROCESSING_DAYS
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
),

-- Step 2: Count identical copies of each content version.
content_variants AS (
    SELECT
        claim_key,
        TRANSACTION_ID,
        TRANSACTION_DATE,
        CUSTOMER_ID,
        CUSTOMER_SEGMENT,
        SERVICE_CODE,
        SERVICE_COUNTRY,
        CHANNEL,
        INVOICE_COUNT,
        GROSS_CLAIM_AMOUNT_EUR,
        FEE_REVENUE_EUR,
        PROCESSING_COST_EUR,
        CLAIM_STATUS,
        PROCESSING_DAYS,
        COUNT(*) AS copies_per_variant
    FROM source_claims
    WHERE claim_key IS NOT NULL
    GROUP BY ALL
),

-- Step 3: Keep only fully identical duplicate claims.
eligible_copies AS (
    SELECT
        copies_per_variant - 1 AS excess_copies,

        NULLIF(UPPER(TRIM(CLAIM_STATUS)), '')
            AS claim_status,

        TRY_CAST(
            NULLIF(TRIM(GROSS_CLAIM_AMOUNT_EUR), '')
            AS NUMBER(38,10)
        ) AS gross_claim_eur,

        TRY_CAST(
            NULLIF(TRIM(FEE_REVENUE_EUR), '')
            AS NUMBER(38,10)
        ) AS fee_eur,

        TRY_CAST(
            NULLIF(TRIM(PROCESSING_COST_EUR), '')
            AS NUMBER(38,10)
        ) AS cost_eur

    FROM content_variants
    QUALIFY
        COUNT(*) OVER (PARTITION BY claim_key) = 1
        AND copies_per_variant > 1
),

-- Step 4: Calculate validation counts and financial totals.
impact_summary AS (
    SELECT
        CASE
            WHEN GROUPING(claim_status) = 1
                THEN 'ALL_STATUSES'
            ELSE COALESCE(claim_status, '<BLANK>')
        END AS status_group,

        SUM(excess_copies) AS excess_rows,

        SUM(IFF(
            claim_status IS NULL
            OR claim_status NOT IN (
                'REFUNDED', 'REJECTED', 'PENDING'
            ), excess_copies, 0
        )) AS invalid_status_rows,

        SUM(IFF(
            gross_claim_eur IS NULL,
            excess_copies, 0
        )) AS invalid_gross_rows,

        SUM(IFF(
            fee_eur IS NULL,
            excess_copies, 0
        )) AS invalid_fee_rows,

        SUM(IFF(
            cost_eur IS NULL,
            excess_copies, 0
        )) AS invalid_cost_rows,

        SUM(IFF(
            claim_status = 'REFUNDED'
            AND fee_eur IS NULL,
            excess_copies, 0
        )) AS invalid_earned_fee_rows,

        COALESCE(
            SUM(gross_claim_eur * excess_copies), 0
        ) AS gross_claim_sum,

        COALESCE(
            SUM(fee_eur * excess_copies), 0
        ) AS raw_fee_sum,

        COALESCE(
            SUM(
                IFF(
                    claim_status = 'REFUNDED',
                    fee_eur * excess_copies,
                    0
                )
            ), 0
        ) AS earned_fee_sum,

        COALESCE(
            SUM(cost_eur * excess_copies), 0
        ) AS cost_sum

    FROM eligible_copies
    GROUP BY ROLLUP(claim_status)
)

-- Final report: show financial values only when valid.
SELECT
    status_group,
    excess_rows,
    invalid_status_rows,
    invalid_gross_rows,
    invalid_fee_rows,
    invalid_cost_rows,

    CASE
        WHEN invalid_gross_rows = 0
            THEN ROUND(gross_claim_sum, 2)
    END AS duplicate_gross_claim_eur,

    CASE
        WHEN invalid_fee_rows = 0
            THEN ROUND(raw_fee_sum, 2)
    END AS duplicate_raw_fee_eur,

    CASE
        WHEN invalid_status_rows = 0
         AND invalid_earned_fee_rows = 0
            THEN ROUND(earned_fee_sum, 2)
    END AS duplicate_earned_fee_eur,

    CASE
        WHEN invalid_cost_rows = 0
            THEN ROUND(cost_sum, 2)
    END AS duplicate_cost_eur,

    CASE
        WHEN invalid_status_rows = 0
         AND invalid_earned_fee_rows = 0
         AND invalid_cost_rows = 0
            THEN ROUND(earned_fee_sum - cost_sum, 2)
    END AS potential_margin_difference_eur

FROM impact_summary
ORDER BY
    CASE
        WHEN status_group = 'ALL_STATUSES'
            THEN 1 ELSE 0
    END,
    status_group;
