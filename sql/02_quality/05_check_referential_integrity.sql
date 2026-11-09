
-- ============================================================
-- REMOBIS | REFERENTIAL INTEGRITY PROFILING
-- ============================================================
-- Purpose:
--   Detect missing references, unmatched dimension keys,
--   and potential row multiplication from dimension joins.
--
-- Grain:
--   One output row per source-to-dimension relationship.
--
-- Business relationships:
--   FACT.CUSTOMER_ID       -> DIM_CUSTOMER.CUSTOMER_ID
--   FACT.SERVICE_CODE      -> DIM_SERVICE.SERVICE_CODE
--   FACT.SERVICE_COUNTRY   -> DIM_COUNTRY.COUNTRY_NAME
--   CUSTOMER.HOME_COUNTRY_CODE -> DIM_COUNTRY.COUNTRY_CODE
--
-- Rules:
--   - Normalize case and surrounding spaces for comparison.
--   - Do not apply unverified country-name mappings.
--   - Count all RAW rows, including duplicate claims.
--   - Detect potential row multiplication from joins.
--   - Do not modify source data.
--
-- Read-only.
-- ============================================================

WITH dimension_keys AS (

    -- Customer business keys
    SELECT
        'DIM_CUSTOMER' AS lookup_domain,
        NULLIF(UPPER(TRIM(CUSTOMER_ID)), '')
            AS dimension_key
    FROM REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER

    UNION ALL

    -- Service business keys
    SELECT
        'DIM_SERVICE',
        NULLIF(UPPER(TRIM(SERVICE_CODE)), '')
    FROM REMOBIS_CASE_STUDY.RAW.DIM_SERVICE

    UNION ALL

    -- Country names used by FACT_REFUND_CLAIMS
    SELECT
        'DIM_COUNTRY_NAME',
        NULLIF(UPPER(TRIM(COUNTRY_NAME)), '')
    FROM REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY

    UNION ALL

    -- Country codes used by DIM_CUSTOMER
    SELECT
        'DIM_COUNTRY_CODE',
        NULLIF(UPPER(TRIM(COUNTRY_CODE)), '')
    FROM REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY
),

dimension_key_counts AS (
    SELECT
        lookup_domain,
        dimension_key,
        COUNT(*) AS key_occurrences
    FROM dimension_keys
    WHERE dimension_key IS NOT NULL
    GROUP BY
        lookup_domain,
        dimension_key
),

source_references AS (

    -- Claim -> Customer ID
    SELECT
        'CLAIM_TO_CUSTOMER' AS relationship_name,
        'DIM_CUSTOMER' AS lookup_domain,
        NULLIF(UPPER(TRIM(CUSTOMER_ID)), '')
            AS source_key
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS

    UNION ALL

    -- Claim -> Service code
    SELECT
        'CLAIM_TO_SERVICE',
        'DIM_SERVICE',
        NULLIF(UPPER(TRIM(SERVICE_CODE)), '')
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS

    UNION ALL

    -- Claim -> Country name (not country code)
    SELECT
        'CLAIM_TO_COUNTRY',
        'DIM_COUNTRY_NAME',
        NULLIF(UPPER(TRIM(SERVICE_COUNTRY)), '')
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS

    UNION ALL

    -- Customer -> Headquarters country code
    SELECT
        'CUSTOMER_TO_HOME_COUNTRY',
        'DIM_COUNTRY_CODE',
        NULLIF(UPPER(TRIM(HOME_COUNTRY_CODE)), '')
    FROM REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER
),

evaluated AS (
    SELECT
        s.relationship_name,
        s.source_key,
        COALESCE(d.key_occurrences, 0)
            AS dimension_matches
    FROM source_references s
    LEFT JOIN dimension_key_counts d
        ON s.lookup_domain = d.lookup_domain
       AND s.source_key = d.dimension_key
)

SELECT
    relationship_name,

    COUNT(*) AS source_rows,

    -- Missing or blank source references
    SUM(
        IFF(source_key IS NULL, 1, 0)
    ) AS missing_reference_rows,

    -- Nonblank references with no matching dimension key
    SUM(
        IFF(
            source_key IS NOT NULL
            AND dimension_matches = 0,
            1,
            0
        )
    ) AS unmatched_reference_rows,

    -- Number of distinct unmatched source keys
    COUNT(DISTINCT
        IFF(
            source_key IS NOT NULL
            AND dimension_matches = 0,
            source_key,
            NULL
        )
    ) AS unmatched_distinct_keys,

    -- Source rows with at least one dimension match
    SUM(
        IFF(dimension_matches > 0, 1, 0)
    ) AS matched_reference_rows,

    -- Extra rows a LEFT JOIN would create
    -- when a dimension key is not unique
    SUM(
        GREATEST(dimension_matches - 1, 0)
    ) AS potential_join_extra_rows,

    -- Predicted row count after a LEFT JOIN
    SUM(
        GREATEST(dimension_matches, 1)
    ) AS predicted_left_join_rows

FROM evaluated
GROUP BY relationship_name
ORDER BY relationship_name;
