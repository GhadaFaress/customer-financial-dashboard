WITH staged AS (

    SELECT
        -- 1. which entry
        hk_stmt_entry,

        -- 2. which version, and when
        hd_stmt_entry,
        effective_from,
        ingested_ts            AS load_ts,
        record_source,

        -- 3. what it says (the less-used details)
        narrative, counterparty,
        our_reference, their_reference, trans_reference, reversal_marker,
        cheque_number, chq_type, exchange_rate,
        system_id, position_type, account_officer, company_code,
        processing_date, exposure_date, system_date_time

    FROM {{ ref('stg_stmt_entry') }}

),

latest AS (

    -- the newest version the satellite already holds, per entry
    {% if is_incremental() %}
    SELECT DISTINCT ON (hk_stmt_entry)
        hk_stmt_entry,
        hd_stmt_entry  AS latest_hd
    FROM {{ this }}
    ORDER BY hk_stmt_entry, load_ts DESC
    {% else %}
    -- first run: the satellite is empty
    SELECT NULL::TEXT AS hk_stmt_entry, NULL::TEXT AS latest_hd
    WHERE FALSE
    {% endif %}

)

-- one row per entry per file, so no LAG needed:
-- keep it if it is new, or different from what we stored
SELECT staged.*
FROM staged
LEFT JOIN latest ON latest.hk_stmt_entry = staged.hk_stmt_entry
WHERE staged.hd_stmt_entry IS DISTINCT FROM latest.latest_hd