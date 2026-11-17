-- Share of all reported doses by manufacturer (latest cumulative totals).
SELECT
    vaccine AS manufacturer,
    platform,
    ROUND(SUM(doses) / 1e6, 1) AS doses_millions,
    ROUND(100 * SUM(doses) / SUM(SUM(doses)) OVER (), 2) AS share_pct,
    COUNT(DISTINCT location) FILTER (WHERE doses > 0) AS countries_used
FROM fct_latest
GROUP BY ALL
ORDER BY doses_millions DESC;
