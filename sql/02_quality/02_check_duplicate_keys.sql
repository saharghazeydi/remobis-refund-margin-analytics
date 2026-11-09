
-- ============================================================
-- REMOBIS | BUSINESS KEY UNIQUENESS CHECK
-- ============================================================
-- Purpose:
--   Detect duplicate business keys across four RAW tables.
--
-- Rules:
--   - Normalize surrounding spaces for comparison only.
--   - Do not modify or delete source records.
--   - Distinguish affected rows from excess rows.
--   - Preserve original data for further investigation.
--   - Business keys are compared after TRIM.
--   - Key comparisons remain case-sensitive.
--   - Case-equivalent identifiers require separate validation.
--
-- Read-only.
-- ============================================================

WITH source_keys AS (

    SELECT
        'FACT_REFUND_CLAIMS' AS table_name,
        NULLIF(TRIM(TRANSACTION_ID), '') AS record_key
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS

    UNION ALL

    SELECT
        'DIM_CUSTOMER',
        NULLIF(TRIM(CUSTOMER_ID), '')
    FROM REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER

    UNION ALL

    SELECT
        'DIM_SERVICE',
        NULLIF(TRIM(SERVICE_CODE), '')
    FROM REMOBIS_CASE_STUDY.RAW.DIM_SERVICE

    UNION ALL

    SELECT
        'DIM_COUNTRY',
        NULLIF(TRIM(COUNTRY_CODE), '')
    FROM REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY
),

key_frequency AS (
    SELECT
        table_name,
        record_key,
        COUNT(*) AS rows_per_key
    FROM source_keys
    WHERE record_key IS NOT NULL
    GROUP BY table_name, record_key
),

table_summary AS (
    SELECT
        table_name,
        COUNT(*) AS total_rows,
        COUNT_IF(record_key IS NULL) AS missing_key_rows
    FROM source_keys
    GROUP BY table_name
),

duplicate_summary AS (
    SELECT
        table_name,
        COUNT(*) AS duplicate_key_groups,
        SUM(rows_per_key) AS affected_rows,
        SUM(rows_per_key - 1) AS excess_rows
    FROM key_frequency
    WHERE rows_per_key > 1
    GROUP BY table_name
)

SELECT
    t.table_name,
    t.total_rows,
    COALESCE(t.missing_key_rows, 0) AS missing_key_rows,
    COALESCE(d.duplicate_key_groups, 0)
        AS duplicate_key_groups,
    COALESCE(d.affected_rows, 0) AS affected_rows,
    COALESCE(d.excess_rows, 0) AS excess_rows
FROM table_summary t
LEFT JOIN duplicate_summary d
    ON t.table_name = d.table_name
ORDER BY t.table_name;
