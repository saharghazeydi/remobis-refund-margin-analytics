
-- ============================================================
-- REMOBIS | RAW INGESTION INFRASTRUCTURE
-- ============================================================
-- Purpose:
--   Configure CSV parsing and create the internal source stage.
--
-- Design principles:
--   1. Preserve original source values in the RAW layer.
--   2. Preserve empty strings and disable backslash escaping.
--   3. Support repeatable infrastructure setup.
--   4. Keep source files and existing staged files unchanged.
--
-- Source validation:
--   The supplied CSV files contain no backslash characters
--   or literal \N values. The default NULL_IF marker is
--   therefore not expected to affect these source files.
--
-- Database : REMOBIS_CASE_STUDY
-- Schema   : RAW
-- ============================================================


-- ------------------------------------------------------------
-- 1. CREATE CSV FILE FORMAT
-- ------------------------------------------------------------
-- Creates the file format only if it does not already exist.
-- Existing objects are not replaced.

CREATE FILE FORMAT IF NOT EXISTS
    REMOBIS_CASE_STUDY.RAW.FF_REMOBIS_CSV
    TYPE = CSV
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = FALSE
    ESCAPE_UNENCLOSED_FIELD = NONE
    TRIM_SPACE = FALSE
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    REPLACE_INVALID_CHARACTERS = FALSE
    SKIP_BYTE_ORDER_MARK = TRUE
    ENCODING = UTF8;


-- ------------------------------------------------------------
-- 2. SYNCHRONIZE EXISTING FILE FORMAT
-- ------------------------------------------------------------
-- CREATE IF NOT EXISTS does not update an existing object.
-- Apply the required RAW ingestion settings explicitly.
-- This operation does not modify source or staged CSV files.

ALTER FILE FORMAT
    REMOBIS_CASE_STUDY.RAW.FF_REMOBIS_CSV
SET
    EMPTY_FIELD_AS_NULL = FALSE
    ESCAPE_UNENCLOSED_FIELD = NONE
    RECORD_DELIMITER = '\n';


-- ------------------------------------------------------------
-- 3. CREATE INTERNAL STAGE
-- ------------------------------------------------------------
-- Stores uploaded source CSV files before loading them into
-- RAW tables.
-- The existing stage and its files are preserved.

CREATE STAGE IF NOT EXISTS
    REMOBIS_CASE_STUDY.RAW.STAGE_SOURCE_CSV
    FILE_FORMAT = (
        FORMAT_NAME = 'REMOBIS_CASE_STUDY.RAW.FF_REMOBIS_CSV'
    );


-- ------------------------------------------------------------
-- 4. VERIFY FILE FORMAT CONFIGURATION
-- ------------------------------------------------------------

DESCRIBE FILE FORMAT
    REMOBIS_CASE_STUDY.RAW.FF_REMOBIS_CSV;


-- ------------------------------------------------------------
-- 5. VERIFY STAGED SOURCE FILES
-- ------------------------------------------------------------

LIST @REMOBIS_CASE_STUDY.RAW.STAGE_SOURCE_CSV;
