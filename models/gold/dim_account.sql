WITH latest AS (

    -- one row per account: its newest details
    SELECT DISTINCT ON (hk_account)
        hk_account,
        category,
        currency,
        opening_date,
        closure_date,
        short_title,
        alt_acct_id_1,
        inactiv_marker
    FROM {{ ref('sat_account_details') }}
    ORDER BY hk_account, curr_no DESC

)

SELECT
    h.hk_account            AS account_key,
    h.account_number,
    lca.hk_customer         AS customer_key,     -- NULL for internal 9999 accounts
    l.category,
    l.currency,
    l.opening_date,
    l.closure_date,
    l.short_title           AS account_title,
    l.alt_acct_id_1         AS iban,
    l.inactiv_marker,
    (l.category = '9999')   AS is_internal,

    -- readable labels for reports
    CASE l.category
        WHEN '1001' THEN 'CURRENT'
        WHEN '6001' THEN 'SAVINGS'
        WHEN '9999' THEN 'INTERNAL'
    END                     AS account_type,
    CASE
        WHEN l.closure_date   IS NOT NULL THEN 'CLOSED'
        WHEN l.inactiv_marker IS NOT NULL THEN 'INACTIVE'
        ELSE 'ACTIVE'
    END                     AS account_status
FROM {{ ref('hub_account') }} h
JOIN latest l
    ON l.hk_account = h.hk_account
LEFT JOIN {{ ref('link_customer_account') }} lca
    ON lca.hk_account = h.hk_account