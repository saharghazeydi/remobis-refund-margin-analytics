
-- ============================================================
-- REMOBIS | DATE FIELD VALIDATION
-- ============================================================
-- Purpose:
--   Validate source dates in the Fact and Dimensions.
--
-- Checks:
--   - Missing dates
--   - Invalid date values
--   - Non-standard date formats
--   - Minimum and maximum valid dates
--
-- Expected format: YYYY-MM-DD
-- Read-only. RAW data is not modified.
-- ============================================================

WITH date_fields AS (
    SELECT
        'FACT_REFUND_CLAIMS' AS table_name,
        'TRANSACTION_DATE' AS column_name,
        TRANSACTION_DATE AS raw_date
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS

    UNION ALL

    SELECT
        'DIM_CUSTOMER',
        'ONBOARDING_DATE',
        ONBOARDING_DATE
    FROM REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER

    UNION ALL

    SELECT
        'DIM_SERVICE',
        'LAUNCH_DATE',
        LAUNCH_DATE
    FROM REMOBIS_CASE_STUDY.RAW.DIM_SERVICE
),

parsed_dates AS (
    SELECT
        table_name,
        column_name,
        NULLIF(TRIM(raw_date), '') AS date_text,

        TRY_TO_DATE(
            NULLIF(TRIM(raw_date), ''),
            'YYYY-MM-DD'
        ) AS date_value

    FROM date_fields
)

SELECT
    table_name,
    column_name,

    COUNT(*) AS total_rows,

    SUM(IFF(
        date_text IS NULL, 1, 0
    )) AS missing_dates,

    SUM(IFF(
        date_text IS NOT NULL
        AND date_value IS NULL,
        1, 0
    )) AS invalid_dates,

    SUM(IFF(
        date_text IS NOT NULL
        AND NOT REGEXP_LIKE(
            date_text, '[0-9]{4}-[0-9]{2}-[0-9]{2}'
        ),
        1, 0
    )) AS invalid_format_rows,

    MIN(date_value) AS earliest_date,
    MAX(date_value) AS latest_date

FROM parsed_dates
GROUP BY table_name, column_name
ORDER BY table_name, column_name;
