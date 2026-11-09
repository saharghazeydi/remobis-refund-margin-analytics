
-- ============================================================
-- REMOBIS | ENRICHED CLAIMS STAGING VIEW
-- ============================================================
-- Grain: one row per claim ID.
--
-- Join rules:
--   - Preserve all staging claims with LEFT JOIN.
--   - Match customer and service using normalized IDs.
--   - Match country using the validated canonical name.
--   - Never use current segment as historical segment.
--   - Preserve original financial amounts.
--
-- Preconditions:
--   Dimension join keys must resolve to at most one row.
--   Validate join cardinality after creation.
-- ============================================================

CREATE VIEW REMOBIS_CASE_STUDY.STAGING.STG_REFUND_CLAIMS_ENRICHED AS

SELECT
    f.CLAIM_ID,
    f.SUBMISSION_DATE,

    -- Customer attributes
    f.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    f.HISTORICAL_CUSTOMER_SEGMENT,

    NULLIF(
        TRIM(c.CUSTOMER_SEGMENT), ''
    ) AS CURRENT_CUSTOMER_SEGMENT,

    UPPER(TRIM(c.HOME_COUNTRY_CODE))
        AS CUSTOMER_HOME_COUNTRY_CODE,

    c.ACCOUNT_STATUS,

    TRY_TO_DATE(
        c.ONBOARDING_DATE, 'YYYY-MM-DD'
    ) AS CUSTOMER_ONBOARDING_DATE,

    -- Service attributes
    f.SERVICE_CODE,
    s.SERVICE_NAME,
    s.SERVICE_CATEGORY,

    TRY_TO_DATE(
        s.LAUNCH_DATE, 'YYYY-MM-DD'
    ) AS SERVICE_LAUNCH_DATE,

    -- Service country attributes
    f.SOURCE_COUNTRY_NAME,
    f.COUNTRY_NAME_KEY,

    UPPER(TRIM(co.COUNTRY_CODE))
        AS SERVICE_COUNTRY_CODE,

    co.COUNTRY_NAME AS SERVICE_COUNTRY_NAME,
    co.REGION AS SERVICE_REGION,

    -- Claim attributes
    f.CHANNEL,
    f.CLAIM_STATUS,
    f.INVOICE_COUNT,
    f.PROCESSING_DAYS,

    -- Financial measures
    f.GROSS_CLAIM_AMOUNT_EUR,
    f.RECORDED_FEE_EUR,
    f.EARNED_FEE_EUR,
    f.PROCESSING_COST_EUR,

    f.EARNED_FEE_EUR - f.PROCESSING_COST_EUR
        AS CLAIM_MARGIN_EUR,

    -- Review flags: preserve affected claims
    IFF(
        f.PROCESSING_COST_EUR < 0,
        TRUE, FALSE
    ) AS NEGATIVE_COST_FLAG,

    IFF(
        f.SUBMISSION_DATE <
            TRY_TO_DATE(c.ONBOARDING_DATE, 'YYYY-MM-DD'),
        TRUE, FALSE
    ) AS PRE_ONBOARDING_FLAG,

    -- Source lineage
    f.SOURCE_COPY_COUNT,
    f.SOURCE_FILENAME,
    f.SOURCE_FILE_CONTENT_KEY,
    f.SOURCE_FILE_ROW_NUMBER

FROM REMOBIS_CASE_STUDY.STAGING.STG_REFUND_CLAIMS f

LEFT JOIN REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER c
    ON f.CUSTOMER_ID = UPPER(TRIM(c.CUSTOMER_ID))

LEFT JOIN REMOBIS_CASE_STUDY.RAW.DIM_SERVICE s
    ON f.SERVICE_CODE = UPPER(TRIM(s.SERVICE_CODE))

LEFT JOIN REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY co
    ON f.COUNTRY_NAME_KEY = UPPER(TRIM(co.COUNTRY_NAME));
