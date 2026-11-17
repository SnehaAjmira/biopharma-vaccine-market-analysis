-- Data quality profile reported in the README.
SELECT 'Raw rows' AS check_name, COUNT(*)::VARCHAR AS result FROM raw_doses
UNION ALL SELECT 'Rows after removing EU aggregate', COUNT(*)::VARCHAR FROM stg_doses
UNION ALL SELECT 'Countries / territories', COUNT(DISTINCT location)::VARCHAR FROM stg_doses
UNION ALL SELECT 'Manufacturers', COUNT(DISTINCT vaccine)::VARCHAR FROM stg_doses
UNION ALL SELECT 'Date range', MIN(report_date)::VARCHAR || ' to ' || MAX(report_date)::VARCHAR FROM stg_doses
UNION ALL SELECT 'Null dose values', COUNT(*)::VARCHAR FROM raw_doses WHERE total_vaccinations IS NULL
UNION ALL SELECT 'Duplicate country-date-vaccine keys',
    (COUNT(*) - COUNT(DISTINCT (location, report_date, vaccine)))::VARCHAR FROM raw_doses
UNION ALL SELECT 'Downward revisions in cumulative series', COUNT(*)::VARCHAR
    FROM fct_increments WHERE raw_increment < 0
UNION ALL SELECT 'Unmapped manufacturers', COUNT(DISTINCT vaccine)::VARCHAR
    FROM stg_doses WHERE platform = 'Unmapped';
