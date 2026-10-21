WITH source AS (

    SELECT
        hk_customer,
        customer_id,
        MIN(ingested_ts)  AS load_ts,
        record_source
    FROM {{ ref('stg_customer') }}
    GROUP BY hk_customer, customer_id, record_source

)

SELECT *
FROM source

{% if is_incremental() %}
-- only customers the hub has never seen
WHERE hk_customer NOT IN (SELECT hk_customer FROM {{ this }})
{% endif %}