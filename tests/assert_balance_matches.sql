-- Way B check: on every day T24 saved a balance,
-- our running total (Way A) must equal it.
-- Returns the days that do NOT match. 0 rows = pass.

SELECT
    s.hk_account,
    s.effective_from,
    s.online_actual_bal      AS t24_balance,
    f.balance_acct_ccy       AS our_balance
FROM {{ ref('sat_account_balance') }} s
JOIN {{ ref('fact_account_balance') }} f
    ON  f.account_key = s.hk_account
    AND f.date_key    = TO_CHAR(s.effective_from, 'YYYYMMDD')::INT
WHERE f.balance_acct_ccy <> s.online_actual_bal