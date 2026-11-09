
-- ============================================================
-- REMOBIS | CATEGORICAL DOMAIN PROFILING
-- ============================================================
-- Purpose:
--   Identify observed categorical values and frequencies.
--
-- Rules:
--   - Preserve original category spellings.
--   - Show missing values separately.
--   - Include all RAW records, including duplicates.
--   - Do not modify source data.
--
-- This profiles values; validity decisions come later.
-- ============================================================

WITH category_values AS (

    SELECT
        'FACT_REFUND_CLAIMS' AS table_name,
        column_name,
        raw_value
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
            CLAIM_STATUS,
            CHANNEL,
            CUSTOMER_SEGMENT
        )
    )

    UNION ALL

    SELECT
        'DIM_CUSTOMER',
        column_name,
        raw_value
    FROM REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
            CUSTOMER_SEGMENT,
            ACCOUNT_STATUS
        )
    )

    UNION ALL

    SELECT
        'DIM_SERVICE',
        column_name,
        raw_value
    FROM REMOBIS_CASE_STUDY.RAW.DIM_SERVICE
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
            SERVICE_CATEGORY
        )
    )

    UNION ALL

    SELECT
        'DIM_COUNTRY',
        column_name,
        raw_value
    FROM REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
            REGION
        )
    )
)

SELECT
    table_name,
    column_name,

    CASE
        WHEN raw_value IS NULL THEN '<SQL_NULL>'
        WHEN raw_value = '' THEN '<EMPTY_STRING>'
        WHEN TRIM(raw_value) = '' THEN '<WHITESPACE_ONLY>'
        ELSE raw_value
    END AS observed_value,

    COUNT(*) AS raw_rows

FROM category_values

GROUP BY 1, 2, 3

ORDER BY
    table_name,
    column_name,
    raw_rows DESC,
    observed_value;
