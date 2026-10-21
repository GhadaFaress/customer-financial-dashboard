WITH accounts AS (

    SELECT
        account_key,
        customer_key,
        currency,
        opening_date,
        -- stop at closure, otherwise run up to today
        LEAST(COALESCE(closure_date, CURRENT_DATE), CURRENT_DATE)  AS last_date
    FROM {{ ref('dim_account') }}

),

account_days AS (

    -- step 1: one row per account per day it was open
    SELECT
        a.account_key,
        a.customer_key,
        a.currency,
        d.date_key,
        d.full_date
    FROM accounts a
    JOIN {{ ref('dim_date') }} d
        ON d.full_date BETWEEN a.opening_date AND a.last_date

),

daily_movement AS (

    -- step 2: how much moved on each account on each day
    SELECT
        account_key,
        value_date_key        AS date_key,
        SUM(amount_lcy)       AS moved_lcy,
        SUM(amount_fcy)       AS moved_fcy
    FROM {{ ref('fact_stmt_entry') }}
    GROUP BY account_key, value_date_key

)

-- step 3: running total = balance at the end of each day
SELECT
    ad.account_key,
    ad.customer_key,
    ad.date_key,
    ad.currency,

    COALESCE(m.moved_lcy, 0)                                    AS moved_lcy,

    -- balance in EGP (each transaction at its own day's rate)
    SUM(COALESCE(m.moved_lcy, 0))
        OVER (PARTITION BY ad.account_key ORDER BY ad.date_key) AS balance_lcy,

    -- balance in the account's own currency (USD accounts in dollars)
    CASE WHEN ad.currency = 'EGP'
         THEN SUM(COALESCE(m.moved_lcy, 0))
                  OVER (PARTITION BY ad.account_key ORDER BY ad.date_key)
         ELSE SUM(COALESCE(m.moved_fcy, 0))
                  OVER (PARTITION BY ad.account_key ORDER BY ad.date_key)
    END                                                         AS balance_acct_ccy

FROM account_days ad
LEFT JOIN daily_movement m
    ON  m.account_key = ad.account_key
    AND m.date_key    = ad.date_key