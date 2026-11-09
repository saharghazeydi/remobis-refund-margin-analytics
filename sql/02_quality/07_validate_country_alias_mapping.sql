
-- ============================================================
-- REMOBIS | COUNTRY ALIAS MAPPING VALIDATION
-- ============================================================
-- Purpose:
--   Validate country-name aliases against DIM_COUNTRY
--   and verify that joins preserve the source grain.
--
-- Rules:
--   - Use explicit, verified country aliases.
--   - Match aliases by country code.
--   - Match other country names directly.
--   - Distinguish alias recognition from valid resolution.
--   - Detect missing and multiple country matches.
--   - Compare joined rows with original RAW rows.
--   - Do not modify RAW data.
--
-- Grain:
--   One validation summary for all RAW claim records.
-- ============================================================

WITH country_aliases AS (
    SELECT
        column1 AS alias_name,
        column2 AS canonical_country_code
    FROM VALUES
        ('CZECHIA', 'CZ'),
        ('DEUTSCHLAND', 'DE'),
        ('POLSKA', 'PL'),
        ('THE NETHERLANDS', 'NL')
),

country_dimension AS (
    SELECT
        NULLIF(UPPER(TRIM(COUNTRY_CODE)), '')
            AS country_code,

        NULLIF(UPPER(TRIM(COUNTRY_NAME)), '')
            AS country_name_key
    FROM REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY
),

source_claims AS (
    SELECT
        SOURCE_FILENAME,
        SOURCE_FILE_CONTENT_KEY,
        SOURCE_FILE_ROW_NUMBER,

        NULLIF(UPPER(TRIM(SERVICE_COUNTRY)), '')
            AS source_country_key
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
),

-- Apply alias-to-code mapping or direct country-name matching.
resolved_claims AS (
    SELECT
        f.SOURCE_FILENAME,
        f.SOURCE_FILE_CONTENT_KEY,
        f.SOURCE_FILE_ROW_NUMBER,

        a.alias_name AS matched_alias,
        d.country_code AS matched_country_code

    FROM source_claims f

    LEFT JOIN country_aliases a
        ON f.source_country_key = a.alias_name

    LEFT JOIN country_dimension d
        ON (
            a.alias_name IS NOT NULL
            AND d.country_code = a.canonical_country_code
        )
        OR (
            a.alias_name IS NULL
            AND d.country_name_key = f.source_country_key
        )
),

-- Count country matches for each physical source record.
-- Source provenance was checked for uniqueness during
-- RAW ingestion reconciliation.
per_source_record AS (
    SELECT
        SOURCE_FILENAME,
        SOURCE_FILE_CONTENT_KEY,
        SOURCE_FILE_ROW_NUMBER,

        COUNT(*) AS joined_rows,

        MAX(
            IFF(matched_alias IS NOT NULL, 1, 0)
        ) AS alias_recognized,

        COUNT(matched_country_code)
            AS country_matches

    FROM resolved_claims
    GROUP BY
        SOURCE_FILENAME,
        SOURCE_FILE_CONTENT_KEY,
        SOURCE_FILE_ROW_NUMBER
),

source_counts AS (
    SELECT
        COUNT(*) AS source_rows
    FROM source_claims
),

validation_summary AS (
    SELECT
        COUNT(*) AS distinct_source_rows,

        COALESCE(SUM(joined_rows), 0)
            AS resulting_rows,

        COALESCE(SUM(alias_recognized), 0)
            AS alias_recognized_rows,

        COALESCE(SUM(IFF(
            alias_recognized = 1
            AND country_matches = 1,
            1, 0
        )), 0) AS alias_resolved_rows,

        COALESCE(SUM(IFF(
            alias_recognized = 1
            AND country_matches = 0,
            1, 0
        )), 0) AS alias_unresolved_rows,

        COALESCE(SUM(IFF(
            country_matches = 0,
            1, 0
        )), 0) AS unmatched_rows,

        COALESCE(SUM(IFF(
            country_matches > 1,
            1, 0
        )), 0) AS multiple_match_rows

    FROM per_source_record
)

SELECT
    s.source_rows,
    v.resulting_rows,
    v.distinct_source_rows,

    s.source_rows - v.distinct_source_rows
        AS duplicate_source_identity_rows,

    v.alias_recognized_rows,
    v.alias_resolved_rows,
    v.alias_unresolved_rows,
    v.unmatched_rows,
    v.multiple_match_rows,

    v.resulting_rows - s.source_rows
        AS join_extra_rows,

    CASE
        WHEN v.distinct_source_rows = s.source_rows
         AND v.resulting_rows = s.source_rows
         AND v.alias_unresolved_rows = 0
         AND v.unmatched_rows = 0
         AND v.multiple_match_rows = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM source_counts s
CROSS JOIN validation_summary v;

