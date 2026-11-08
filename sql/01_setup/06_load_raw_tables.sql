
-- ============================================================
-- REMOBIS | RAW DATA LOADING
-- ============================================================
-- Purpose:
--   Load source CSV records into RAW tables.
--
-- Rules:
--   Preserve source values and file metadata.
--   Abort loading if an ingestion error occurs.
--   Do not purge staged files.
--   Do not force previously loaded files to reload.
--
-- Prerequisites:
--   RAW tables and CSV file format must already exist.
--   The target table must be empty before its initial load.
-- ============================================================


-- ------------------------------------------------------------
-- 1. LOAD FACT_REFUND_CLAIMS
-- ------------------------------------------------------------

COPY INTO REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS (
    TRANSACTION_ID,
    TRANSACTION_DATE,
    CUSTOMER_ID,
    CUSTOMER_SEGMENT,
    SERVICE_CODE,
    SERVICE_COUNTRY,
    CHANNEL,
    INVOICE_COUNT,
    GROSS_CLAIM_AMOUNT_EUR,
    FEE_REVENUE_EUR,
    PROCESSING_COST_EUR,
    CLAIM_STATUS,
    PROCESSING_DAYS,
    SOURCE_FILENAME,
    SOURCE_FILE_ROW_NUMBER,
    SOURCE_FILE_CONTENT_KEY
)
FROM (
    SELECT
        t.$1,
        t.$2,
        t.$3,
        t.$4,
        t.$5,
        t.$6,
        t.$7,
        t.$8,
        t.$9,
        t.$10,
        t.$11,
        t.$12,
        t.$13,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY
    FROM @REMOBIS_CASE_STUDY.RAW.STAGE_SOURCE_CSV/FACT_REFUND_CLAIMS.csv
        (FILE_FORMAT => 'REMOBIS_CASE_STUDY.RAW.FF_REMOBIS_CSV') t
)
ON_ERROR = ABORT_STATEMENT
FORCE = FALSE
PURGE = FALSE;



-- ------------------------------------------------------------
-- 2. LOAD DIM_CUSTOMER
-- ------------------------------------------------------------
-- Preserve the six original source fields and provenance.
-- Abort on ingestion errors and retain staged files.

COPY INTO REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER (
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CUSTOMER_SEGMENT,
    HOME_COUNTRY_CODE,
    ONBOARDING_DATE,
    ACCOUNT_STATUS,
    SOURCE_FILENAME,
    SOURCE_FILE_ROW_NUMBER,
    SOURCE_FILE_CONTENT_KEY
)
FROM (
    SELECT
        t.$1,
        t.$2,
        t.$3,
        t.$4,
        t.$5,
        t.$6,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY
    FROM @REMOBIS_CASE_STUDY.RAW.STAGE_SOURCE_CSV/DIM_CUSTOMER.csv
        (FILE_FORMAT => 'REMOBIS_CASE_STUDY.RAW.FF_REMOBIS_CSV') t
)
ON_ERROR = ABORT_STATEMENT
FORCE = FALSE
PURGE = FALSE;



-- ------------------------------------------------------------
-- 3. LOAD DIM_SERVICE
-- ------------------------------------------------------------
-- Preserve five source fields and file provenance.
-- Abort on errors; retain staged source files.

COPY INTO REMOBIS_CASE_STUDY.RAW.DIM_SERVICE (
    SERVICE_CODE,
    SERVICE_NAME,
    SERVICE_CATEGORY,
    LAUNCH_DATE,
    LIST_FEE_RATE_PCT,
    SOURCE_FILENAME,
    SOURCE_FILE_ROW_NUMBER,
    SOURCE_FILE_CONTENT_KEY
)
FROM (
    SELECT
        t.$1,
        t.$2,
        t.$3,
        t.$4,
        t.$5,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY
    FROM @REMOBIS_CASE_STUDY.RAW.STAGE_SOURCE_CSV/DIM_SERVICE.csv
        (FILE_FORMAT => 'REMOBIS_CASE_STUDY.RAW.FF_REMOBIS_CSV') t
)
ON_ERROR = ABORT_STATEMENT
FORCE = FALSE
PURGE = FALSE;


-- ------------------------------------------------------------
-- 4. LOAD DIM_COUNTRY
-- ------------------------------------------------------------
-- Preserve the three original source fields and provenance.
-- Abort on errors and retain staged source files.

COPY INTO REMOBIS_CASE_STUDY.RAW.DIM_COUNTRY (
    COUNTRY_CODE,
    COUNTRY_NAME,
    REGION,
    SOURCE_FILENAME,
    SOURCE_FILE_ROW_NUMBER,
    SOURCE_FILE_CONTENT_KEY
)
FROM (
    SELECT
        t.$1,
        t.$2,
        t.$3,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY
    FROM @REMOBIS_CASE_STUDY.RAW.STAGE_SOURCE_CSV/DIM_COUNTRY.csv
        (FILE_FORMAT => 'REMOBIS_CASE_STUDY.RAW.FF_REMOBIS_CSV') t
)
ON_ERROR = ABORT_STATEMENT
FORCE = FALSE
PURGE = FALSE;
