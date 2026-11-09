
-- ============================================================
-- REMOBIS | COUNTRY MAPPING FINANCIAL EXPOSURE
-- ============================================================
-- Purpose:
--   Estimate financial values that an incorrect INNER JOIN
--   could exclude when country aliases are not mapped.
--
-- Scenarios:
--   1. All RAW rows with country aliases.
--   2. One copy per claim, only when duplicates are identical.
--
-- Rules:
--   - Rank claims before filtering to country aliases.
--   - Flag missing IDs and conflicting claim versions.
--   - Earn fees only for Refunded claims.
--   - Include processing costs for all claim statuses.
--   - Withhold incomplete or unsafe financial results.
--   - Use aliases validated in quality check 07.
--
-- This is reporting exposure, not an actual financial loss.
-- RAW data is not modified.
-- ============================================================

WITH country_aliases AS (
    SELECT
        column1 AS alias_name,
        column2 AS country_code
    FROM VALUES
        ('CZECHIA', 'CZ'),
        ('DEUTSCHLAND', 'DE'),
        ('POLSKA', 'PL'),
        ('THE NETHERLANDS', 'NL')
),

source_claims AS (
    SELECT
        NULLIF(TRIM(TRANSACTION_ID), '') AS claim_id,

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

ranked_claims AS (
    SELECT
        s.claim_id,

        NULLIF(UPPER(TRIM(s.SERVICE_COUNTRY)), '')
            AS country_name_key,

        NULLIF(UPPER(TRIM(s.CLAIM_STATUS)), '')
            AS claim_status,

        TRY_CAST(
            NULLIF(TRIM(s.FEE_REVENUE_EUR), '')
            AS NUMBER(38,10)
        ) AS fee_eur,

        TRY_CAST(
            NULLIF(TRIM(s.PROCESSING_COST_EUR), '')
            AS NUMBER(38,10)
        ) AS cost_eur,

        -- Number of records sharing the claim ID.
        COUNT(*) OVER (
            PARTITION BY s.claim_id
        ) AS claim_copies,

        -- Number of copies with identical source content.
        -- All 13 original fields are compared.
        COUNT(*) OVER (
            PARTITION BY
                s.claim_id,
                s.TRANSACTION_ID,
                s.TRANSACTION_DATE,
                s.CUSTOMER_ID,
                s.CUSTOMER_SEGMENT,
                s.SERVICE_CODE,
                s.SERVICE_COUNTRY,
                s.CHANNEL,
                s.INVOICE_COUNT,
                s.GROSS_CLAIM_AMOUNT_EUR,
                s.FEE_REVENUE_EUR,
                s.PROCESSING_COST_EUR,
                s.CLAIM_STATUS,
                s.PROCESSING_DAYS
        ) AS identical_copies,

        -- Select a reproducible copy using source provenance.
        ROW_NUMBER() OVER (
            PARTITION BY s.claim_id
            ORDER BY
                s.SOURCE_FILENAME,
                s.SOURCE_FILE_CONTENT_KEY,
                s.SOURCE_FILE_ROW_NUMBER
        ) AS copy_number

    FROM source_claims s
),

alias_claims AS (
    SELECT
        a.alias_name,
        a.country_code,

        r.claim_id,
        r.claim_status,
        r.fee_eur,
        r.cost_eur,
        r.claim_copies,
        r.identical_copies,
        r.copy_number

    FROM ranked_claims r
    INNER JOIN country_aliases a
        ON r.country_name_key = a.alias_name
),

financial_summary AS (
    SELECT
        alias_name,
        country_code,

        COUNT(*) AS raw_rows,
        COUNT(DISTINCT claim_id) AS distinct_claims,

        SUM(IFF(
            claim_id IS NULL
            OR claim_copies <> identical_copies,
            1, 0
        )) AS unsafe_dedupe_rows,

        SUM(IFF(
            claim_status IS NULL
            OR claim_status NOT IN (
                'REFUNDED', 'REJECTED', 'PENDING'
            ),
            1, 0
        )) AS invalid_status_rows,

        SUM(IFF(
            fee_eur IS NULL, 1, 0
        )) AS invalid_fee_rows,

        SUM(IFF(
            cost_eur IS NULL, 1, 0
        )) AS invalid_cost_rows,

        SUM(IFF(
            claim_status IN ('REJECTED', 'PENDING')
            AND fee_eur <> 0,
            1, 0
        )) AS unearned_fee_rows,

        -- Financial amounts from every RAW row.
        SUM(IFF(
            claim_status = 'REFUNDED', fee_eur, 0
        )) AS raw_earned_fee,

        SUM(cost_eur) AS raw_cost,

        -- Financial amounts from one copy per claim.
        SUM(IFF(
            copy_number = 1
            AND claim_status = 'REFUNDED',
            fee_eur,
            0
        )) AS unique_earned_fee,

        SUM(IFF(
            copy_number = 1, cost_eur, 0
        )) AS unique_cost

    FROM alias_claims
    GROUP BY
        alias_name,
        country_code
)

SELECT
    alias_name,
    country_code,
    raw_rows,
    distinct_claims,

    unsafe_dedupe_rows,
    invalid_status_rows,
    invalid_fee_rows,
    invalid_cost_rows,
    unearned_fee_rows,

    CASE
        WHEN invalid_status_rows = 0
         AND invalid_fee_rows = 0
         AND unearned_fee_rows = 0
        THEN ROUND(raw_earned_fee, 2)
    END AS raw_earned_fee_at_risk_eur,

    CASE
        WHEN invalid_cost_rows = 0
        THEN ROUND(raw_cost, 2)
    END AS raw_cost_at_risk_eur,

    CASE
        WHEN invalid_status_rows = 0
         AND invalid_fee_rows = 0
         AND invalid_cost_rows = 0
         AND unearned_fee_rows = 0
        THEN ROUND(raw_earned_fee - raw_cost, 2)
    END AS raw_margin_at_risk_eur,

    CASE
        WHEN unsafe_dedupe_rows = 0
         AND invalid_status_rows = 0
         AND invalid_fee_rows = 0
         AND invalid_cost_rows = 0
         AND unearned_fee_rows = 0
        THEN ROUND(unique_earned_fee - unique_cost, 2)
    END AS unique_claim_margin_at_risk_eur

FROM financial_summary
ORDER BY
    raw_rows DESC,
    alias_name;

