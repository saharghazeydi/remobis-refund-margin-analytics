
-- ============================================================
-- REMOBIS | DUPLICATE CLAIM CLASSIFICATION
-- ============================================================
-- Purpose:
--   Distinguish identical source records from conflicting
--   records that share the same transaction ID.
--
-- Grain:
--   One output row per duplicate classification.
--
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
        PROCESSING_DAYS
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
),

duplicate_keys AS (
    SELECT claim_key
    FROM source_claims
    WHERE claim_key IS NOT NULL
    GROUP BY claim_key
    HAVING COUNT(*) > 1
),

content_variants AS (
    SELECT
        s.claim_key,
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
        s.PROCESSING_DAYS,
        COUNT(*) AS rows_per_variant
    FROM source_claims s
    INNER JOIN duplicate_keys d
        ON s.claim_key = d.claim_key
    GROUP BY ALL
),

key_summary AS (
    SELECT
        claim_key,
        SUM(rows_per_variant) AS affected_rows,
        COUNT(*) AS distinct_content_versions,
        SUM(rows_per_variant - 1) AS identical_excess_rows
    FROM content_variants
    GROUP BY claim_key
)

SELECT
    CASE
        WHEN distinct_content_versions = 1
            THEN 'IDENTICAL_RECORDS'
        ELSE 'CONFLICTING_RECORDS'
    END AS duplicate_type,

    COUNT(*) AS duplicate_claim_ids,
    SUM(affected_rows) AS affected_rows,
    SUM(affected_rows - 1) AS excess_rows,
    SUM(identical_excess_rows) AS identical_excess_rows

FROM key_summary
GROUP BY 1
ORDER BY 1;
