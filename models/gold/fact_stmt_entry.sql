SELECT
    -- keys
    hk_stmt_entry                                   AS stmt_entry_key,
    stmt_entry_id,
    hk_account                                      AS account_key,
    hk_customer                                     AS customer_key,     -- NULL on internal rows
    TO_CHAR(value_date, 'YYYYMMDD')::INT            AS value_date_key,
    TO_CHAR(booking_date, 'YYYYMMDD')::INT          AS booking_date_key,

    -- descriptive bits of the transaction itself
    transaction_code,
    currency,

    -- numbers
    amount_lcy,
    amount_fcy,

    -- rule: direction comes from the sign
    CASE
        WHEN amount_lcy > 0 THEN 'IN'
        WHEN amount_lcy < 0 THEN 'OUT'
    END                                             AS direction

FROM {{ ref('link_stmt_entry') }}