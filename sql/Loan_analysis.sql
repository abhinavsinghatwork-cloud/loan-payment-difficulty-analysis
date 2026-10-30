CREATE DATABASE IF NOT EXISTS loan_default_project;

USE loan_default_project;

RENAME TABLE application_train
TO stg_application_train;

USE loan_default_project;

SELECT COUNT(*)
FROM stg_application_train;

SELECT *
FROM stg_application_train
LIMIT 10;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT SK_ID_CURR) AS unique_applications
FROM stg_application_train;

SELECT
    SUM(SK_ID_CURR IS NULL) AS missing_ids,
    SUM(TARGET IS NULL) AS missing_targets,
    SUM(AMT_INCOME_TOTAL IS NULL) AS missing_income,
    SUM(AMT_CREDIT IS NULL) AS missing_credit,
    SUM(AMT_ANNUITY IS NULL) AS missing_annuity
FROM stg_application_train;

SELECT
    TARGET,
    COUNT(*) AS total_applications,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM stg_application_train),
        2
    ) AS percentage
FROM stg_application_train
GROUP BY TARGET;

SELECT
    DAYS_EMPLOYED,
    COUNT(*) AS total
FROM stg_application_train
GROUP BY DAYS_EMPLOYED
ORDER BY total DESC
LIMIT 10;




SELECT
    CASE
        WHEN AMT_INCOME_TOTAL < 100000
            THEN 'Low Income'
        WHEN AMT_INCOME_TOTAL < 200000
            THEN 'Lower-Middle Income'
        WHEN AMT_INCOME_TOTAL < 300000
            THEN 'Upper-Middle Income'
        ELSE 'High Income'
    END AS income_bracket,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS payment_difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train

WHERE TARGET IN (0, 1)
  AND AMT_INCOME_TOTAL IS NOT NULL

GROUP BY income_bracket

ORDER BY difficulty_rate_pct DESC;


SELECT
    NAME_CONTRACT_TYPE AS loan_type,
    COUNT(*) AS total_applications,
    SUM(TARGET = 1) AS difficulty_cases,
    ROUND(
        SUM(TARGET = 1) * 100.0 / COUNT(*),
        2
    ) AS difficulty_rate_pct
FROM stg_application_train
WHERE TARGET IN (0, 1)
GROUP BY NAME_CONTRACT_TYPE
ORDER BY difficulty_rate_pct DESC;


SELECT
    CASE
        WHEN DAYS_EMPLOYED = 365243
            THEN 'Employment data unavailable'
        WHEN DAYS_EMPLOYED >= 0
            THEN 'Invalid or special value'
        WHEN -DAYS_EMPLOYED / 365.0 < 1
            THEN 'Less than 1 year'
        WHEN -DAYS_EMPLOYED / 365.0 < 3
            THEN '1 to 3 years'
        WHEN -DAYS_EMPLOYED / 365.0 < 5
            THEN '3 to 5 years'
        ELSE '5+ years'
    END AS employment_group,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train

WHERE TARGET IN (0, 1)

GROUP BY employment_group

ORDER BY difficulty_rate_pct DESC;

SELECT
    REGION_RATING_CLIENT AS regional_rating,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train

WHERE TARGET IN (0, 1)
  AND REGION_RATING_CLIENT IS NOT NULL

GROUP BY REGION_RATING_CLIENT

ORDER BY difficulty_rate_pct DESC;

SELECT
    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    SUM(TARGET = 0) AS no_recorded_difficulty,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS overall_difficulty_rate_pct,

    ROUND(
        AVG(AMT_INCOME_TOTAL),
        2
    ) AS average_income,

    ROUND(
        AVG(AMT_CREDIT),
        2
    ) AS average_credit_amount

FROM stg_application_train
WHERE TARGET IN (0, 1);

SELECT
    CASE
        WHEN AMT_INCOME_TOTAL < 100000 THEN 'Low Income'
        WHEN AMT_INCOME_TOTAL < 200000 THEN 'Lower-Middle Income'
        WHEN AMT_INCOME_TOTAL < 300000 THEN 'Upper-Middle Income'
        ELSE 'High Income'
    END AS income_bracket,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train
WHERE TARGET IN (0, 1)
GROUP BY income_bracket
ORDER BY difficulty_rate_pct DESC;

CREATE OR REPLACE VIEW vw_loan_kpi_summary AS
SELECT
    COUNT(*) AS total_applications,
    SUM(TARGET = 1) AS difficulty_cases,
    SUM(TARGET = 0) AS no_recorded_difficulty,
    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct,
    ROUND(AVG(AMT_INCOME_TOTAL), 2) AS average_income,
    ROUND(AVG(AMT_CREDIT), 2) AS average_credit_amount
FROM stg_application_train
WHERE TARGET IN (0, 1);

SELECT * FROM vw_loan_kpi_summary;

USE loan_default_project;

CREATE OR REPLACE VIEW vw_income_risk AS
SELECT
    CASE
        WHEN AMT_INCOME_TOTAL < 100000
            THEN 'Low Income'
        WHEN AMT_INCOME_TOTAL < 200000
            THEN 'Lower-Middle Income'
        WHEN AMT_INCOME_TOTAL < 300000
            THEN 'Upper-Middle Income'
        ELSE 'High Income'
    END AS income_bracket,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train

WHERE TARGET IN (0, 1)

GROUP BY income_bracket;

SELECT *
FROM vw_income_risk
ORDER BY difficulty_rate_pct DESC;

USE loan_default_project;

CREATE OR REPLACE VIEW vw_loan_type_risk AS
SELECT
    NAME_CONTRACT_TYPE AS loan_type,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train

WHERE TARGET IN (0, 1)

GROUP BY NAME_CONTRACT_TYPE;
SELECT *
FROM vw_loan_type_risk
ORDER BY difficulty_rate_pct DESC;


USE loan_default_project;

CREATE OR REPLACE VIEW vw_employment_risk AS
SELECT
    CASE
        WHEN DAYS_EMPLOYED = 365243
            THEN 'Employment data unavailable'
        WHEN DAYS_EMPLOYED >= 0
            THEN 'Invalid or special value'
        WHEN -DAYS_EMPLOYED / 365.0 < 1
            THEN 'Less than 1 year'
        WHEN -DAYS_EMPLOYED / 365.0 < 3
            THEN '1 to 3 years'
        WHEN -DAYS_EMPLOYED / 365.0 < 5
            THEN '3 to 5 years'
        ELSE '5+ years'
    END AS employment_group,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train

WHERE TARGET IN (0, 1)

GROUP BY employment_group;

SELECT *
FROM vw_employment_risk
ORDER BY difficulty_rate_pct DESC;

USE loan_default_project;

CREATE OR REPLACE VIEW vw_employment_risk AS
SELECT
    CASE
        WHEN DAYS_EMPLOYED = 365243
            THEN 'Employment data unavailable'
        WHEN DAYS_EMPLOYED >= 0
            THEN 'Invalid or special value'
        WHEN -DAYS_EMPLOYED / 365.0 < 1
            THEN 'Less than 1 year'
        WHEN -DAYS_EMPLOYED / 365.0 < 3
            THEN '1 to 3 years'
        WHEN -DAYS_EMPLOYED / 365.0 < 5
            THEN '3 to 5 years'
        ELSE '5+ years'
    END AS employment_group,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train

WHERE TARGET IN (0, 1)

GROUP BY employment_group;

USE loan_default_project;

CREATE OR REPLACE VIEW vw_regional_risk AS
SELECT
    REGION_RATING_CLIENT AS regional_rating,

    COUNT(*) AS total_applications,

    SUM(TARGET = 1) AS difficulty_cases,

    ROUND(
        100.0 * SUM(TARGET = 1) / COUNT(*),
        2
    ) AS difficulty_rate_pct

FROM stg_application_train

WHERE TARGET IN (0, 1)
  AND REGION_RATING_CLIENT IS NOT NULL

GROUP BY REGION_RATING_CLIENT;
SELECT *
FROM vw_regional_risk
ORDER BY difficulty_rate_pct DESC;


select * from vw_employment_risk;
select * from vw_income_risk;
select * from vw_loan_kpi_summary;
select * from vw_loan_type_risk;
select * from vw_regional_risk;


