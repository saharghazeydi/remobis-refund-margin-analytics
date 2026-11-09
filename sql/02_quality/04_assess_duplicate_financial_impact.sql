
-- ============================================================
-- REMOBIS | DUPLICATE CLAIM FINANCIAL IMPACT
-- ============================================================
-- Purpose:
--   Estimate the financial effect of exact duplicate
--   claim records in the RAW dataset.
--
-- Rules:
--   - Compare all 13 original fields for exact equality.
--   - Include only nonblank claim IDs with identical copies.
--   - Exclude conflicting claim IDs from this scenario.
--   - Keep one copy per eligible claim ID.
--   - Earn revenue only for Refunded claims.
--   - Include processing costs for all statuses.
--   - Report invalid values instead of hiding them.
--
-- This is a reporting scenario, not an approved adjustment.
-- RAW data is not modified.
-- ============================================================

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
        PROCESSING_DAYS,

        SOURCE_FILENAME,
        SOURCE_FILE_CONTENT_KEY,
        SOURCE_FILE_ROW_NUMBER

    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
),

-- Count distinct record contents for each claim ID.
-- Provenance columns are excluded from content comparison.
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

-- Only claim IDs with multiple identical copies qualify.
-- Conflicting versions are not automatically deduplicated.
identical_duplicate_keys AS (
    SELECT
        claim_key
    FROM content_variants
    GROUP BY claim_key
    HAVING COUNT(*) = 1
       AND SUM(copies_per_variant) > 1
),

-- Rank physical copies using deterministic source metadata.
ranked_copies AS (
    SELECT
        NULLIF(UPPER(TRIM(s.CLAIM_STATUS)), '')
            AS claim_status,

        s.GROSS_CLAIM_AMOUNT_EUR,
        s.FEE_REVENUE_EUR,
        s.PROCESSING_COST_EUR,

        ROW_NUMBER() OVER (
            PARTITION BY s.claim_key
            ORDER BY
                s.SOURCE_FILENAME,
                s.SOURCE_FILE_CONTENT_KEY,
                s.SOURCE_FILE_ROW_NUMBER
        ) AS copy_number

    FROM source_claims s
    INNER JOIN identical_duplicate_keys d
        ON s.claim_key = d.claim_key
),

-- Financial values belonging to additional copies only.
excess_copies AS (
    SELECT
        claim_status,

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

    FROM ranked_copies
    WHERE copy_number > 1
),

-- Calculate validation counts and financial subtotals.
impact_summary AS (
    SELECT
        CASE
            WHEN GROUPING(claim_status) = 1
                THEN 'ALL_STATUSES'
            ELSE COALESCE(claim_status, '<BLANK>')
        END AS status_group,

        COUNT(*) AS excess_rows,

        COALESCE(SUM(IFF(
            claim_status IS NULL
            OR claim_status NOT IN (
                'REFUNDED', 'REJECTED', 'PENDING'
            ), 1, 0
        )), 0) AS invalid_status_rows,

        COALESCE(SUM(IFF(
            gross_claim_eur IS NULL, 1, 0
        )), 0) AS invalid_gross_rows,

        COALESCE(SUM(IFF(
            fee_eur IS NULL, 1, 0
        )), 0) AS invalid_fee_rows,

        COALESCE(SUM(IFF(
            cost_eur IS NULL, 1, 0
        )), 0) AS invalid_cost_rows,

        COALESCE(SUM(IFF(
            claim_status = 'REFUNDED'
            AND fee_eur IS NULL, 1, 0
        )), 0) AS invalid_earned_fee_rows,

        COALESCE(SUM(gross_claim_eur), 0)
            AS gross_claim_sum,

        COALESCE(SUM(fee_eur), 0)
            AS raw_fee_sum,

        COALESCE(SUM(
            IFF(claim_status = 'REFUNDED', fee_eur, 0)
        ), 0) AS earned_fee_sum,

        COALESCE(SUM(cost_eur), 0)
            AS cost_sum

    FROM excess_copies
    GROUP BY ROLLUP(claim_status)
)

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
    CASE WHEN status_group = 'ALL_STATUSES'
        THEN 1 ELSE 0 END,
    status_group;
