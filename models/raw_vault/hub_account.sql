WITH all_accounts AS (

    SELECT hk_account, account_number, ingested_ts, record_source
    FROM {{ ref('stg_account') }}

    UNION ALL

    SELECT hk_account, account_number, ingested_ts, record_source
    FROM {{ ref('stg_stmt_entry') }}

),

source AS (

    SELECT
        hk_account,
        account_number,
        MIN(ingested_ts)    AS load_ts,
        MIN(record_source)  AS record_source   -- one value if both files have it
    FROM all_accounts
    GROUP BY hk_account, account_number

)

SELECT *
FROM source

{% if is_incremental() %}
WHERE hk_account NOT IN (SELECT hk_account FROM {{ this }})
{% endif %}