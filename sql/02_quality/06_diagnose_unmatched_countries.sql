
-- ============================================================
-- REMOBIS | UNMATCHED COUNTRY DIAGNOSTICS
-- ============================================================
-- Purpose:
--   Identify claim country names that do not match
--   the country dimension.
--
-- Rules:
--   - Normalize country names using UPPER(TRIM()).
--   - Compare claim IDs using TRIM() only.
--   - Preserve original country spellings for investigation.
--   - Exclude blank country references (checked separately).
--   - Do not apply unverified country mappings.
--
-- Grain:
--   One row per normalized unmatched country name.
--
-- Read-only. RAW data is not modified.
-- ============================================================

WITH country_reference AS (
    SELECT DISTINCT
        NULLIF(UPPER(TRIM(COUNTRY_NAME)), '')
            AS country_name_key

    FROM REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY
),

unmatched_claims AS (
    SELECT
        NULLIF(UPPER(TRIM(f.SERVICE_COUNTRY)), '')
            AS source_country_key,

        TRIM(f.SERVICE_COUNTRY)
            AS source_country_name,

        NULLIF(TRIM(f.TRANSACTION_ID), '')
            AS claim_key,

        f.TRANSACTION_ID

    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS f

    LEFT JOIN country_reference c
        ON NULLIF(UPPER(TRIM(f.SERVICE_COUNTRY)), '')
           = c.country_name_key

    WHERE
        NULLIF(TRIM(f.SERVICE_COUNTRY), '') IS NOT NULL
        AND c.country_name_key IS NULL
)

SELECT
    source_country_key,

    LISTAGG(DISTINCT source_country_name, ' | ')
        WITHIN GROUP (ORDER BY source_country_name)
        AS observed_spellings,

    COUNT(*) AS unmatched_raw_rows,

    COUNT(DISTINCT claim_key)
        AS distinct_claim_ids,

    MIN(TRANSACTION_ID)
        AS sample_claim_id

FROM unmatched_claims

GROUP BY source_country_key

ORDER BY
    unmatched_raw_rows DESC,
    source_country_key;
