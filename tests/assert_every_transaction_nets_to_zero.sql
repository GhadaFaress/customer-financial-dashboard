-- Double entry: the rows of each transaction (same our_reference)
-- must add up to zero, e.g. +5000 customer / -5000 contra.
-- Returns the references that do NOT. 0 rows = pass.

SELECT
    s.our_reference,
    SUM(l.amount_lcy) AS net
FROM {{ ref('link_stmt_entry') }} l
JOIN {{ ref('sat_stmt_entry') }} s
    ON s.hk_stmt_entry = l.hk_stmt_entry
GROUP BY s.our_reference
HAVING SUM(l.amount_lcy) <> 0