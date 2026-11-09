
-- ============================================================
-- REMOBIS | STAGING: CLEAN REFUND CLAIMS
-- ============================================================
-- Grain: one row per transaction ID.
--
-- Preconditions:
--   Quality checks 02-04 confirm that claim IDs are present
--   and duplicate records are exact copies.
--
-- Rules:
--   - Preserve original RAW data.
--   - Keep historical customer segment.
--   - Earn success fees only for refunded claims.
--   - Retain negative processing costs.
--   - Use transaction date as submission date.
-- ============================================================

CREATE VIEW REMOBIS_CASE_STUDY.STAGING.STG_REFUND_CLAIMS AS

SELECT
    TRIM(TRANSACTION_ID) AS CLAIM_ID,

    TRY_TO_DATE(
        TRANSACTION_DATE, 'YYYY-MM-DD'
    ) AS SUBMISSION_DATE,

    UPPER(TRIM(CUSTOMER_ID)) AS CUSTOMER_ID,

    NULLIF(
        TRIM(CUSTOMER_SEGMENT), ''
    ) AS HISTORICAL_CUSTOMER_SEGMENT,

    UPPER(TRIM(SERVICE_CODE)) AS SERVICE_CODE,

    TRIM(SERVICE_COUNTRY) AS SOURCE_COUNTRY_NAME,

    CASE UPPER(TRIM(SERVICE_COUNTRY))
        WHEN 'CZECHIA' THEN 'CZECH REPUBLIC'
        WHEN 'DEUTSCHLAND' THEN 'GERMANY'
        WHEN 'POLSKA' THEN 'POLAND'
        WHEN 'THE NETHERLANDS' THEN 'NETHERLANDS'
        ELSE UPPER(TRIM(SERVICE_COUNTRY))
    END AS COUNTRY_NAME_KEY,

    NULLIF(TRIM(CHANNEL), '') AS CHANNEL,

    TRY_TO_DECIMAL(
        INVOICE_COUNT, 38, 0
    ) AS INVOICE_COUNT,

    TRY_TO_DECIMAL(
        GROSS_CLAIM_AMOUNT_EUR, 14, 2
    ) AS GROSS_CLAIM_AMOUNT_EUR,

    TRY_TO_DECIMAL(
        FEE_REVENUE_EUR, 14, 2
    ) AS RECORDED_FEE_EUR,

    CASE UPPER(TRIM(CLAIM_STATUS))
        WHEN 'REFUNDED'
            THEN TRY_TO_DECIMAL(FEE_REVENUE_EUR, 14, 2)
        ELSE 0
    END AS EARNED_FEE_EUR,

    TRY_TO_DECIMAL(
        PROCESSING_COST_EUR, 14, 2
    ) AS PROCESSING_COST_EUR,

    UPPER(TRIM(CLAIM_STATUS)) AS CLAIM_STATUS,

    TRY_TO_DECIMAL(
        NULLIF(TRIM(PROCESSING_DAYS), ''),
        38, 0
    ) AS PROCESSING_DAYS,

    COUNT(*) OVER (
        PARTITION BY TRIM(TRANSACTION_ID)
    ) AS SOURCE_COPY_COUNT,

    SOURCE_FILENAME,
    SOURCE_FILE_CONTENT_KEY,
    SOURCE_FILE_ROW_NUMBER

FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS

QUALIFY ROW_NUMBER() OVER (
    PARTITION BY TRIM(TRANSACTION_ID)
    ORDER BY
        SOURCE_FILENAME,
        SOURCE_FILE_CONTENT_KEY,
        SOURCE_FILE_ROW_NUMBER
) = 1;
