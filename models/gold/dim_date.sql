WITH days AS (

    -- one row per calendar day, whether anything happened or not
    SELECT d::DATE AS full_date
    FROM GENERATE_SERIES('2024-01-01'::DATE, '2027-12-31'::DATE, INTERVAL '1 day') AS d

)

SELECT
    TO_CHAR(full_date, 'YYYYMMDD')::INT          AS date_key,
    full_date,
    EXTRACT(YEAR  FROM full_date)::INT           AS year,
    EXTRACT(MONTH FROM full_date)::INT           AS month,
    TO_CHAR(full_date, 'Mon YYYY')               AS month_name,
    EXTRACT(DAY   FROM full_date)::INT           AS day_of_month,
    TO_CHAR(full_date, 'Dy')                     AS day_name,
    EXTRACT(ISODOW FROM full_date) IN (5, 6)     AS is_weekend,       -- Fri/Sat in Egypt
    DATE_TRUNC('month', full_date)::DATE         AS month_start
FROM days