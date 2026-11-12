
-- ============================================================
-- REMOBIS | DUPLICATE CLAIM CLASSIFICATION
-- Purpose: Classify duplicate transaction IDs as identical
--          or conflicting based on full source record content.
-- Read-only. RAW data is not modified.
-- ============================================================

-- Step 1: Prepare claims and normalize transaction IDs.
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

-- Step 2: Count identical versions of each claim.
content_variants AS (
    SELECT
        *,
        COUNT(*) AS rows_per_variant
    FROM source_claims
    WHERE claim_key IS NOT NULL
    GROUP BY ALL
),

-- Step 3: Summarize claims that have duplicate IDs.
key_summary AS (
    SELECT
        claim_key,
        SUM(rows_per_variant) AS affected_rows,
        COUNT(*) AS distinct_content_versions,
        SUM(rows_per_variant - 1) AS identical_excess_rows
    FROM content_variants
    GROUP BY claim_key
    HAVING SUM(rows_per_variant) > 1
)

-- Step 4: Classify and report duplicate claims.
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
