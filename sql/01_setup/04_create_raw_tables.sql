
-- ============================================================
-- REMOBIS | RAW SOURCE TABLES
-- ============================================================
-- Purpose:
--   Create source-aligned RAW tables.
--
-- Grain:
--   One physical source CSV record per table row.
--
-- Rules:
--   - Preserve source fields as VARCHAR.
--   - Preserve duplicate and invalid business records.
--   - Capture source provenance during COPY INTO.
--   - Do not replace existing tables.
-- ============================================================


-- 1. REFUND CLAIMS

CREATE TABLE IF NOT EXISTS
    REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS (
        TRANSACTION_ID          VARCHAR,
        TRANSACTION_DATE        VARCHAR,
        CUSTOMER_ID             VARCHAR,
        CUSTOMER_SEGMENT        VARCHAR,
        SERVICE_CODE            VARCHAR,
        SERVICE_COUNTRY         VARCHAR,
        CHANNEL                 VARCHAR,
        INVOICE_COUNT           VARCHAR,
        GROSS_CLAIM_AMOUNT_EUR  VARCHAR,
        FEE_REVENUE_EUR         VARCHAR,
        PROCESSING_COST_EUR     VARCHAR,
        CLAIM_STATUS            VARCHAR,
        PROCESSING_DAYS         VARCHAR,
        SOURCE_FILENAME         VARCHAR NOT NULL,
        SOURCE_FILE_ROW_NUMBER  NUMBER(38,0) NOT NULL,
        SOURCE_FILE_CONTENT_KEY VARCHAR NOT NULL
    );


-- 2. CUSTOMER DIMENSION

CREATE TABLE IF NOT EXISTS
    REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER (
        CUSTOMER_ID             VARCHAR,
        CUSTOMER_NAME           VARCHAR,
        CUSTOMER_SEGMENT        VARCHAR,
        HOME_COUNTRY_CODE       VARCHAR,
        ONBOARDING_DATE         VARCHAR,
        ACCOUNT_STATUS          VARCHAR,
        SOURCE_FILENAME         VARCHAR NOT NULL,
        SOURCE_FILE_ROW_NUMBER  NUMBER(38,0) NOT NULL,
        SOURCE_FILE_CONTENT_KEY VARCHAR NOT NULL
    );


-- 3. SERVICE DIMENSION

CREATE TABLE IF NOT EXISTS
    REMOBIS_CASE_STUDY.RAW.DIM_SERVICE (
        SERVICE_CODE            VARCHAR,
        SERVICE_NAME            VARCHAR,
        SERVICE_CATEGORY        VARCHAR,
        LAUNCH_DATE             VARCHAR,
        LIST_FEE_RATE_PCT       VARCHAR,
        SOURCE_FILENAME         VARCHAR NOT NULL,
        SOURCE_FILE_ROW_NUMBER  NUMBER(38,0) NOT NULL,
        SOURCE_FILE_CONTENT_KEY VARCHAR NOT NULL
    );


-- 4. COUNTRY DIMENSION

CREATE TABLE IF NOT EXISTS
    REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY (
        COUNTRY_CODE            VARCHAR,
        COUNTRY_NAME            VARCHAR,
        REGION                  VARCHAR,
        SOURCE_FILENAME         VARCHAR NOT NULL,
        SOURCE_FILE_ROW_NUMBER  NUMBER(38,0) NOT NULL,
        SOURCE_FILE_CONTENT_KEY VARCHAR NOT NULL
    );
