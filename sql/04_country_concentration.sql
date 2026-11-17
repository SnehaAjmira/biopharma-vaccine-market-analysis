-- Supplier concentration per country using the Herfindahl-Hirschman Index (HHI).
-- HHI = sum of squared percentage shares. Above 2,500 is considered highly concentrated.
WITH shares AS (
    SELECT location, vaccine, platform,
           100.0 * doses / SUM(doses) OVER (PARTITION BY location) AS share_pct,
           SUM(doses) OVER (PARTITION BY location) AS country_doses
    FROM fct_latest
    WHERE doses > 0
)
SELECT
    location AS country,
    ROUND(MAX(country_doses) / 1e6, 1) AS doses_millions,
    COUNT(*) AS manufacturers_used,
    ARG_MAX(vaccine, share_pct) AS lead_manufacturer,
    ROUND(MAX(share_pct), 1) AS lead_share_pct,
    ROUND(SUM(share_pct) FILTER (WHERE platform = 'mRNA'), 1) AS mrna_share_pct,
    ROUND(SUM(share_pct * share_pct)) AS hhi
FROM shares
GROUP BY location
HAVING MAX(country_doses) >= 1e6     -- exclude micro-states with very small volumes
ORDER BY hhi DESC;
