-- The grain of fact_account_balance: one row per account per day.
-- Returns duplicates. 0 rows = pass.

SELECT account_key, date_key, COUNT(*) AS n
FROM {{ ref('fact_account_balance') }}
GROUP BY account_key, date_key
HAVING COUNT(*) > 1