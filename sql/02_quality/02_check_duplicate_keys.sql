
-- REMOBIS | BUSINESS KEY UNIQUENESS CHECK
-- Read-only. RAW data is not modified.

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
    GROUP BY table_name, record_key
)

SELECT
    table_name,

    SUM(rows_per_key) AS total_rows,

    SUM(IFF(record_key IS NULL,
        rows_per_key, 0)) AS missing_key_rows,

    SUM(IFF(record_key IS NOT NULL AND rows_per_key > 1,
        1, 0)) AS duplicate_key_groups,

    SUM(IFF(record_key IS NOT NULL AND rows_per_key > 1,
        rows_per_key, 0)) AS affected_rows,

    SUM(IFF(record_key IS NOT NULL AND rows_per_key > 1,
        rows_per_key - 1, 0)) AS excess_rows

FROM key_frequency
GROUP BY table_name
ORDER BY table_name;
