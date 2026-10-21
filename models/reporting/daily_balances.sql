WITH as_of AS (
    -- latest day we have data for (15 Oct in the demo)
    SELECT TO_DATE(MAX(value_date_key)::TEXT, 'YYYYMMDD') AS as_of_date
    FROM {{ ref('fact_stmt_entry') }}
),

daily_flows AS (
    -- money in / out per account per day
    SELECT
        account_key,
        value_date_key                                              AS date_key,
        SUM(CASE WHEN direction = 'IN'  THEN amount_lcy      ELSE 0 END) AS inflow,
        SUM(CASE WHEN direction = 'OUT' THEN ABS(amount_lcy) ELSE 0 END) AS outflow,
        SUM(amount_lcy)                                             AS net_cash_flow
    FROM {{ ref('fact_stmt_entry') }}
    GROUP BY account_key, value_date_key
)

SELECT
    dc.customer_id,
    dc.customer_name,

    da.account_number      AS account_id,
    da.account_type,
    da.currency,
    da.account_status,

    dd.full_date,
    dd.month_start,
    dd.day_of_month        AS day_num,

    COALESCE(f.inflow, 0)        AS inflow,
    COALESCE(f.outflow, 0)       AS outflow,
    COALESCE(f.net_cash_flow, 0) AS net_cash_flow,
    fb.balance_lcy               AS balance,      -- already a running total in gold

    a.as_of_date,

    -- money out card: 1..N this month vs 1..N last month
    CASE
        WHEN dd.month_start = DATE_TRUNC('month', a.as_of_date)
            THEN 'current'
        WHEN dd.month_start = DATE_TRUNC('month', a.as_of_date) - INTERVAL '1 month'
         AND dd.day_of_month <= EXTRACT(DAY FROM a.as_of_date)
            THEN 'previous'
    END AS mtd_period,

    -- balance card: as-of date vs same date last month
    CASE
        WHEN dd.full_date = a.as_of_date
            THEN 'current'
        WHEN dd.full_date = (a.as_of_date - INTERVAL '1 month')::DATE
            THEN 'previous'
    END AS balance_point

FROM {{ ref('fact_account_balance') }} AS fb
CROSS JOIN as_of AS a
INNER JOIN {{ ref('dim_date') }} AS dd
    ON dd.date_key = fb.date_key
INNER JOIN {{ ref('dim_account') }} AS da
    ON da.account_key = fb.account_key
INNER JOIN {{ ref('dim_customer') }} AS dc
    ON dc.customer_key = da.customer_key
LEFT JOIN daily_flows AS f
    ON  f.account_key = fb.account_key
    AND f.date_key    = fb.date_key

WHERE NOT da.is_internal
  AND dd.full_date <= a.as_of_date