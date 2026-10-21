WITH source AS (

    SELECT
        hk_customer_account,
        hk_customer,
        hk_account,
        MIN(ingested_ts)  AS load_ts,
        record_source
    FROM {{ ref('stg_account') }}
    WHERE hk_customer IS NOT NULL          -- skip internal 9999 accounts
    GROUP BY hk_customer_account, hk_customer, hk_account, record_source

)

SELECT *
FROM source

{% if is_incremental() %}
WHERE hk_customer_account NOT IN (SELECT hk_customer_account FROM {{ this }})
{% endif %}