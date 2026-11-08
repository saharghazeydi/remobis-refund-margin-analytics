
-- ============================================================
-- REMOBIS | RAW LOAD RECONCILIATION
-- ============================================================
-- Purpose:
--   Reconcile loaded RAW rows against the verified source
--   CSV snapshot and check physical record provenance.
--
-- The expected counts refer to the supplied fixed dataset.
-- Future ingestion batches require a dynamic source manifest.
--
-- Read-only. No source or target data is modified.
-- ============================================================

WITH expected AS (
    SELECT
        column1 AS table_name,
        column2::NUMBER AS expected_rows
    FROM VALUES
        ('FACT_REFUND_CLAIMS', 90612),
        ('DIM_CUSTOMER', 1200),
        ('DIM_SERVICE', 3),
        ('DIM_COUNTRY', 14)
),

actual AS (
    SELECT
        'FACT_REFUND_CLAIMS' AS table_name,
        COUNT(*) AS loaded_rows,
        COUNT(DISTINCT SOURCE_FILENAME) AS source_files,
        COUNT(DISTINCT SOURCE_FILE_CONTENT_KEY)
            AS file_versions,
        COUNT(DISTINCT
            SOURCE_FILENAME,
            SOURCE_FILE_CONTENT_KEY,
            SOURCE_FILE_ROW_NUMBER
        ) AS distinct_source_records
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS

    UNION ALL

    SELECT
        'DIM_CUSTOMER',
        COUNT(*),
        COUNT(DISTINCT SOURCE_FILENAME),
        COUNT(DISTINCT SOURCE_FILE_CONTENT_KEY),
        COUNT(DISTINCT
            SOURCE_FILENAME,
            SOURCE_FILE_CONTENT_KEY,
            SOURCE_FILE_ROW_NUMBER
        )
    FROM REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER

    UNION ALL

    SELECT
        'DIM_SERVICE',
        COUNT(*),
        COUNT(DISTINCT SOURCE_FILENAME),
        COUNT(DISTINCT SOURCE_FILE_CONTENT_KEY),
        COUNT(DISTINCT
            SOURCE_FILENAME,
            SOURCE_FILE_CONTENT_KEY,
            SOURCE_FILE_ROW_NUMBER
        )
    FROM REMOBIS_CASE_STUDY.RAW.DIM_SERVICE

    UNION ALL

    SELECT
        'DIM_COUNTRY',
        COUNT(*),
        COUNT(DISTINCT SOURCE_FILENAME),
        COUNT(DISTINCT SOURCE_FILE_CONTENT_KEY),
        COUNT(DISTINCT
            SOURCE_FILENAME,
            SOURCE_FILE_CONTENT_KEY,
            SOURCE_FILE_ROW_NUMBER
        )
    FROM REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY
)

SELECT
    e.table_name,
    e.expected_rows,
    a.loaded_rows,
    a.loaded_rows - e.expected_rows AS row_difference,
    a.source_files,
    a.file_versions,
    a.loaded_rows - a.distinct_source_records
        AS duplicate_source_records,

    CASE
        WHEN a.loaded_rows = e.expected_rows
         AND a.source_files = 1
         AND a.file_versions = 1
         AND a.distinct_source_records = a.loaded_rows
        THEN 'PASS'
        ELSE 'FAIL'
    END AS reconciliation_status

FROM expected e
LEFT JOIN actual a
    ON e.table_name = a.table_name

ORDER BY e.table_name;
