
-- ============================================================
-- REMOBIS | HISTORICAL VS CURRENT CUSTOMER SEGMENT
-- ============================================================
-- Purpose:
--   Compare historical claim segments with current
--   customer segments and identify missing values.
--
-- Rules:
--   - Fact segment represents the time of the claim.
--   - Dimension segment represents the current customer.
--   - Differences are not automatically data errors.
--   - Preserve RAW data and historical classifications.
-- ============================================================

WITH segment_comparison AS (
    SELECT
        f.TRANSACTION_ID,

        CASE
            WHEN NULLIF(TRIM(f.CUSTOMER_SEGMENT), '') IS NULL
             AND NULLIF(TRIM(c.CUSTOMER_SEGMENT), '') IS NULL
                THEN 'BOTH_MISSING'

            WHEN NULLIF(TRIM(f.CUSTOMER_SEGMENT), '') IS NULL
                THEN 'HISTORICAL_MISSING'

            WHEN NULLIF(TRIM(c.CUSTOMER_SEGMENT), '') IS NULL
                THEN 'CURRENT_MISSING'

            WHEN UPPER(TRIM(f.CUSTOMER_SEGMENT))
              <> UPPER(TRIM(c.CUSTOMER_SEGMENT))
                THEN 'HISTORICAL_CURRENT_DIFFER'

            ELSE 'MATCH'
        END AS segment_status

    FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS f

    LEFT JOIN REMOBIS_CASE_STUDY.RAW.DIM_CUSTOMER c
        ON UPPER(TRIM(f.CUSTOMER_ID))
         = UPPER(TRIM(c.CUSTOMER_ID))
)

SELECT
    segment_status,
    COUNT(*) AS raw_rows,

    COUNT(DISTINCT
        NULLIF(TRIM(TRANSACTION_ID), '')
    ) AS distinct_claim_ids

FROM segment_comparison
GROUP BY segment_status
ORDER BY raw_rows DESC, segment_status;
