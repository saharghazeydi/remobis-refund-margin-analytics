
-- ============================================================
-- REMOBIS | PROCESSING DAYS COMPLETENESS BY STATUS
-- ============================================================
-- Purpose:
--   Check whether missing processing days are consistent
--   with claim status.
--
-- Business rule:
--   Pending claims may have no processing days because
--   a final decision has not yet been made.
--
-- Read-only.
-- ============================================================

SELECT
    CLAIM_STATUS,

    COUNT(*) AS total_claims,

    SUM(IFF(
        NULLIF(TRIM(PROCESSING_DAYS), '') IS NULL,
        1, 0
    )) AS missing_processing_days,

    SUM(IFF(
        NULLIF(TRIM(PROCESSING_DAYS), '') IS NOT NULL,
        1, 0
    )) AS populated_processing_days

FROM REMOBIS_CASE_STUDY.RAW.FACT_REFUND_CLAIMS

GROUP BY CLAIM_STATUS

ORDER BY CLAIM_STATUS;
