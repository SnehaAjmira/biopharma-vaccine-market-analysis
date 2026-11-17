-- Staging layer: load raw OWID file, remove aggregate rows, map platforms,
-- and convert cumulative counts into period increments.

CREATE OR REPLACE TABLE raw_doses AS
SELECT location, CAST(date AS DATE) AS report_date, vaccine, total_vaccinations
FROM read_csv_auto('data/raw/vaccinations-by-manufacturer.csv');

-- "European Union" is an aggregate of member states already in the file.
-- Keeping it would double count roughly 900M doses.
CREATE OR REPLACE TABLE stg_doses AS
SELECT
    location,
    report_date,
    vaccine,
    total_vaccinations AS cumulative_doses,
    CASE
        WHEN vaccine IN ('Pfizer/BioNTech', 'Moderna') THEN 'mRNA'
        WHEN vaccine IN ('Oxford/AstraZeneca', 'Johnson&Johnson', 'Sputnik V',
                         'Sputnik Light', 'CanSino') THEN 'Viral vector'
        WHEN vaccine IN ('Sinopharm/Beijing', 'Sinovac', 'Covaxin', 'Valneva') THEN 'Inactivated'
        WHEN vaccine IN ('Novavax', 'Sanofi/GSK', 'SKYCovione', 'Medicago') THEN 'Protein-based'
        ELSE 'Unmapped'
    END AS platform
FROM raw_doses
WHERE location <> 'European Union';

-- Cumulative series can be revised downward by reporting agencies.
-- Increments are floored at zero and the revisions are counted in 01_data_quality.sql.
CREATE OR REPLACE TABLE fct_increments AS
SELECT
    *,
    cumulative_doses
      - COALESCE(LAG(cumulative_doses) OVER (PARTITION BY location, vaccine ORDER BY report_date), 0)
      AS raw_increment,
    GREATEST(
      cumulative_doses
      - COALESCE(LAG(cumulative_doses) OVER (PARTITION BY location, vaccine ORDER BY report_date), 0),
      0) AS dose_increment
FROM stg_doses;

-- Latest reported cumulative total per country and manufacturer.
CREATE OR REPLACE TABLE fct_latest AS
SELECT location, vaccine, platform,
       MAX_BY(cumulative_doses, report_date) AS doses,
       MAX(report_date) AS last_report
FROM stg_doses
GROUP BY ALL;
