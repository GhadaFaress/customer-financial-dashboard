WITH source AS (

    SELECT
        -- keys: which entry, on which account, for which customer
        hk_stmt_entry,
        hk_account,
        hk_customer,                -- NULL on internal 9999 rows
        stmt_entry_id,

        -- what dashboards sum, group by and filter on (no join needed)
        amount_lcy,
        amount_fcy,
        currency,
        transaction_code,
        product_category,
        value_date,
        booking_date,

        -- when and where from
        ingested_ts            AS load_ts,
        record_source

    FROM {{ ref('stg_stmt_entry') }}

)

SELECT *
FROM source

{% if is_incremental() %}
-- only entries we have never seen
WHERE hk_stmt_entry NOT IN (SELECT hk_stmt_entry FROM {{ this }})
{% endif %}