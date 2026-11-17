-- Quarterly doses administered by vaccine platform.
WITH quarterly AS (
    SELECT
        DATE_TRUNC('quarter', report_date) AS quarter,
        platform,
        SUM(dose_increment) AS doses
    FROM fct_increments
    WHERE report_date < DATE '2023-01-01'   -- reporting coverage thins sharply after 2022
    GROUP BY ALL
)
SELECT
    quarter,
    platform,
    ROUND(doses / 1e6, 2) AS doses_millions,
    ROUND(100 * doses / SUM(doses) OVER (PARTITION BY quarter), 1) AS share_of_quarter_pct
FROM quarterly
ORDER BY quarter, platform;
