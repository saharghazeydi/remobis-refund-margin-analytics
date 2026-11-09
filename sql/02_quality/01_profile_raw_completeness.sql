
-- ============================================================
-- REMOBIS | RAW COMPLETENESS PROFILING
-- ============================================================
-- Purpose:
--   Profile missing values across all original CSV columns.
--
-- Scope:
--   Four RAW tables; source metadata is excluded.
--
-- Rules:
--   - Distinguish SQL NULL from empty strings.
--   - Detect whitespace-only values.
--   - Do not classify missing values as errors yet.
--   - Do not modify RAW data.
--
-- Grain:
--   One output row per source table and column.
-- ============================================================

WITH field_values AS (

    -- 1. Refund claims
    SELECT
        'FACT_REFUND_CLAIMS' AS table_name,
        column_name,
        raw_value
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
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
        )
    )

    UNION ALL

    -- 2. Customer dimension
    SELECT
        'DIM_CUSTOMER',
        column_name,
        raw_value
    FROM REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
            CUSTOMER_ID,
            CUSTOMER_NAME,
            CUSTOMER_SEGMENT,
            HOME_COUNTRY_CODE,
            ONBOARDING_DATE,
            ACCOUNT_STATUS
        )
    )

    UNION ALL

    -- 3. Service dimension
    SELECT
        'DIM_SERVICE',
        column_name,
        raw_value
    FROM REMOBIS_CASE_STUDY.RAW.DIM_SERVICE
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
            SERVICE_CODE,
            SERVICE_NAME,
            SERVICE_CATEGORY,
            LAUNCH_DATE,
            LIST_FEE_RATE_PCT
        )
    )

    UNION ALL

    -- 4. Country dimension
    SELECT
        'DIM_COUNTRY',
        column_name,
        raw_value
    FROM REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
            COUNTRY_CODE,
            COUNTRY_NAME,
            REGION
        )
    )
),

field_profile AS (
    SELECT
        table_name,
        column_name,

        COUNT(*) AS total_records,

        SUM(IFF(
            raw_value IS NULL, 1, 0
        )) AS null_count,

        SUM(IFF(
            raw_value = '', 1, 0
        )) AS empty_string_count,

        SUM(IFF(
            raw_value IS NOT NULL
            AND raw_value <> ''
            AND REGEXP_LIKE(
                raw_value, '[[:space:]]+'
            ),
            1, 0
        )) AS whitespace_only_count

    FROM field_values
    GROUP BY
        table_name,
        column_name
)

SELECT
    table_name,
    column_name,
    total_records,
    null_count,
    empty_string_count,
    whitespace_only_count,

    (
        null_count
        + empty_string_count
        + whitespace_only_count
    ) AS missing_like_count,

    ROUND(
        100.0 * (
            null_count
            + empty_string_count
            + whitespace_only_count
        ) / NULLIF(total_records, 0),
        2
    ) AS missing_pct

FROM field_profile
ORDER BY
    table_name,
    missing_like_count DESC,
    column_name;
