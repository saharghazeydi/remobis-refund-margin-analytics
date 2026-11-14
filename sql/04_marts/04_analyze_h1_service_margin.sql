
-- ============================================================
-- REMOBIS | H1 SERVICE MARGIN ANALYSIS
-- ============================================================
-- Compare January-June 2025 with January-June 2026.
-- Calculate margin changes by service.
-- Measure VAT_EXPRESS share of net cost growth.
-- Read-only.
-- ============================================================

WITH service_h1 AS (

    SELECT
        SERVICE_CODE,

        SUM(CASE
            WHEN YEAR(SUBMISSION_MONTH) = 2025
            THEN MARGIN_EUR
        END) AS MARGIN_2025_EUR,

        SUM(CASE
            WHEN YEAR(SUBMISSION_MONTH) = 2026
            THEN MARGIN_EUR ELSE 0
        END) AS MARGIN_2026_EUR,

        SUM(CASE
            WHEN YEAR(SUBMISSION_MONTH) = 2026
            THEN EARNED_REVENUE_EUR ELSE 0
        END) AS REVENUE_2026_EUR,

        SUM(CASE
            WHEN YEAR(SUBMISSION_MONTH) = 2025
            THEN PROCESSING_COST_EUR ELSE 0
        END) AS COST_2025_EUR,

        SUM(CASE
            WHEN YEAR(SUBMISSION_MONTH) = 2026
            THEN PROCESSING_COST_EUR ELSE 0
        END) AS COST_2026_EUR

    FROM REMOBIS_CASE_STUDY.ANALYTICS.MART_MONTHLY_CLAIM_MARGIN

    WHERE MONTH(SUBMISSION_MONTH) BETWEEN 1 AND 6
      AND YEAR(SUBMISSION_MONTH) IN (2025, 2026)

    GROUP BY SERVICE_CODE
)

SELECT
    SERVICE_CODE,

    MARGIN_2025_EUR,
    MARGIN_2026_EUR,

    MARGIN_2026_EUR
        - COALESCE(MARGIN_2025_EUR, 0)
        AS MARGIN_CHANGE_EUR,

    REVENUE_2026_EUR,
    COST_2025_EUR,
    COST_2026_EUR,

    CASE
        WHEN SERVICE_CODE = 'VAT_EXPRESS'
        THEN ROUND(
            100.0 * COST_2026_EUR
            / NULLIF(
                SUM(COST_2026_EUR - COST_2025_EUR) OVER (),
                0
            ),
            2
        )
    END AS VAT_EXPRESS_COST_INCREASE_SHARE_PCT

FROM service_h1

ORDER BY MARGIN_CHANGE_EUR;
