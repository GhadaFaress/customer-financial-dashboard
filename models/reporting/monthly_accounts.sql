WITH as_of AS (
    SELECT TO_DATE(MAX(value_date_key)::TEXT, 'YYYYMMDD') AS as_of_date
    FROM {{ ref('fact_stmt_entry') }}
),

monthly_transactions AS (
    SELECT
        ft.account_key,
        dd.month_start,
        SUM(CASE WHEN ft.direction = 'IN'  THEN ft.amount_lcy      ELSE 0 END) AS inflow,
        SUM(CASE WHEN ft.direction = 'OUT' THEN ABS(ft.amount_lcy) ELSE 0 END) AS outflow
    FROM {{ ref('fact_stmt_entry') }} AS ft
    INNER JOIN {{ ref('dim_date') }} AS dd
        ON dd.date_key = ft.value_date_key
    GROUP BY ft.account_key, dd.month_start
),

monthly_balances AS (
    -- closing balance = the balance on the last day of each month
    -- (for the current month: the as-of date)
    SELECT DISTINCT ON (fb.account_key, dd.month_start)
        fb.account_key,
        dd.month_start,
        fb.balance_lcy   AS closing_balance,
        dd.full_date     AS closing_balance_date
    FROM {{ ref('fact_account_balance') }} AS fb
    INNER JOIN {{ ref('dim_date') }} AS dd
        ON dd.date_key = fb.date_key
    CROSS JOIN as_of AS a
    WHERE dd.full_date <= a.as_of_date
    ORDER BY fb.account_key, dd.month_start, dd.full_date DESC
)

SELECT
    dc.customer_id,
    dc.customer_name,

    da.account_number      AS account_id,
    da.account_type,
    da.account_status,

    mb.month_start,
    dm.year                AS year_num,
    dm.month               AS month_num,
    dm.month_name,

    COALESCE(mt.inflow, 0)                           AS inflow,
    COALESCE(mt.outflow, 0)                          AS outflow,
    COALESCE(mt.inflow, 0) - COALESCE(mt.outflow, 0) AS net_cash_flow,

    mb.closing_balance,
    mb.closing_balance_date,

    -- which month is this, relative to the as-of date?
    CASE
        WHEN mb.month_start = DATE_TRUNC('month', a.as_of_date)
            THEN 'current'                    -- Oct: still running
        WHEN mb.month_start = DATE_TRUNC('month', a.as_of_date) - INTERVAL '1 month'
            THEN 'previous'                   -- Sep: last closed month
    END                                                   AS month_period,

    (mb.month_start < DATE_TRUNC('month', a.as_of_date))  AS is_closed_month

FROM monthly_balances AS mb
CROSS JOIN as_of AS a
LEFT JOIN monthly_transactions AS mt
    ON  mt.account_key = mb.account_key
    AND mt.month_start = mb.month_start
INNER JOIN {{ ref('dim_account') }} AS da
    ON da.account_key = mb.account_key
INNER JOIN {{ ref('dim_customer') }} AS dc
    ON dc.customer_key = da.customer_key
INNER JOIN {{ ref('dim_date') }} AS dm
    ON dm.full_date = mb.month_start

WHERE NOT da.is_internal