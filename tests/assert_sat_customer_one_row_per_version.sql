-- A satellite must never store the same version twice
-- (this is the bug we hit before adding the incremental logic).
-- Returns duplicates. 0 rows = pass.

SELECT hk_customer, curr_no, COUNT(*) AS n
FROM {{ ref('sat_customer') }}
GROUP BY hk_customer, curr_no
HAVING COUNT(*) > 1