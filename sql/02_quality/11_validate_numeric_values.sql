
-- ============================================================
-- REMOBIS | NUMERIC DATA QUALITY VALIDATION
-- ============================================================
-- Purpose:
--   Profile numeric fields for missing, invalid,
--   negative, fractional, and out-of-range values.
--
-- Rules:
--   - Invoice count and processing days should be integers.
--   - Financial amounts follow NUMBER(14,2).
--   - Report anomalies without modifying RAW data.
--   - Business-rule decisions are handled separately.
-- ============================================================

WITH numeric_fields AS (
    SELECT
        column_name,
        NULLIF(TRIM(raw_value), '') AS value_text
    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS
    UNPIVOT INCLUDE NULLS (
        raw_value FOR column_name IN (
            INVOICE_COUNT,
            GROSS_CLAIM_AMOUNT_EUR,
            FEE_REVENUE_EUR,
            PROCESSING_COST_EUR,
            PROCESSING_DAYS
        )
    )
),

parsed_values AS (
    SELECT
        column_name,
        value_text,
        TRY_CAST(value_text AS NUMBER(38,10))
            AS numeric_value
    FROM numeric_fields
)

SELECT
    column_name,
    COUNT(*) AS total_rows,

    SUM(IFF(
        value_text IS NULL, 1, 0
    )) AS missing_rows,

    SUM(IFF(
        value_text IS NOT NULL
        AND numeric_value IS NULL, 1, 0
    )) AS invalid_numeric_rows,

    SUM(IFF(
        numeric_value < 0, 1, 0
    )) AS negative_rows,

    SUM(IFF(
        numeric_value = 0, 1, 0
    )) AS zero_rows,

    SUM(IFF(
        column_name IN ('INVOICE_COUNT', 'PROCESSING_DAYS')
        AND numeric_value <> TRUNC(numeric_value),
        1, 0
    )) AS non_integer_rows,

    SUM(IFF(
        column_name IN (
            'GROSS_CLAIM_AMOUNT_EUR',
            'FEE_REVENUE_EUR',
            'PROCESSING_COST_EUR'
        )
        AND numeric_value <> ROUND(numeric_value, 2),
        1, 0
    )) AS sub_cent_precision_rows,

    SUM(IFF(
        column_name IN (
            'GROSS_CLAIM_AMOUNT_EUR',
            'FEE_REVENUE_EUR',
            'PROCESSING_COST_EUR'
        )
        AND ABS(numeric_value) >= 1000000000000,
        1, 0
    )) AS out_of_range_amount_rows,

    MIN(numeric_value) AS min_valid_value,
    MAX(numeric_value) AS max_valid_value

FROM parsed_values
GROUP BY column_name
ORDER BY column_name;
