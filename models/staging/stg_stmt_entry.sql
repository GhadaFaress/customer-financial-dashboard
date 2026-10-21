WITH source AS (

    SELECT * FROM {{ source('raw', 'fbnk_stmt_entry') }}

),

cleaned AS (

    SELECT
        -- keys
        NULLIF(TRIM(recid), '')                             AS stmt_entry_id,
        NULLIF(TRIM(account_number), '')                    AS account_number,
        NULLIF(TRIM(customer_id), '')                       AS customer_id,          -- NULL on internal 9999 rows

        -- codes (kept as text)
        NULLIF(TRIM(product_category), '')                  AS product_category,
        NULLIF(TRIM(transaction_code), '')                  AS transaction_code,
        NULLIF(TRIM(currency), '')                          AS currency,
        NULLIF(TRIM(system_id), '')                         AS system_id,
        NULLIF(TRIM(position_type), '')                     AS position_type,

        -- amounts
        NULLIF(TRIM(amount_lcy), '')::NUMERIC(18,2)         AS amount_lcy,
        NULLIF(TRIM(amount_fcy), '')::NUMERIC(18,2)         AS amount_fcy,
        NULLIF(TRIM(exchange_rate), '')::NUMERIC(18,6)      AS exchange_rate,

        -- dates
        TO_DATE(NULLIF(TRIM(booking_date), ''), 'YYYYMMDD')    AS booking_date,
        TO_DATE(NULLIF(TRIM(value_date), ''), 'YYYYMMDD')      AS value_date,
        TO_DATE(NULLIF(TRIM(processing_date), ''), 'YYYYMMDD') AS processing_date,
        TO_DATE(NULLIF(TRIM(exposure_date), ''), 'YYYYMMDD')   AS exposure_date,
        TO_TIMESTAMP(NULLIF(TRIM(system_date_time), ''), 'YYMMDDHH24MI')::TIMESTAMP AS system_date_time,

        -- references and text
        NULLIF(TRIM(our_reference), '')                     AS our_reference,
        NULLIF(TRIM(their_reference), '')                   AS their_reference,
        NULLIF(TRIM(trans_reference), '')                   AS trans_reference,
        NULLIF(TRIM(reversal_marker), '')                   AS reversal_marker,
        NULLIF(TRIM(narrative), '')                         AS narrative,
        NULLIF(TRIM(cheque_number), '')                     AS cheque_number,
        NULLIF(TRIM(chq_type), '')                          AS chq_type,
        NULLIF(TRIM(counterparty), '')                      AS counterparty,
        NULLIF(TRIM(account_officer), '')                   AS account_officer,
        NULLIF(TRIM(company_code), '')                      AS company_code,

        -- technical columns
        NULLIF(TRIM(inputter), '')                          AS inputter,
        NULLIF(TRIM(authoriser), '')                        AS authoriser,
        NULLIF(TRIM(source_system), '')                     AS source_system,
        NULLIF(TRIM(source_table), '')                      AS source_table,
        NULLIF(TRIM(ingested_ts), '')::TIMESTAMP            AS ingested_ts,
        NULLIF(TRIM(created_ts), '')::TIMESTAMP             AS created_ts,
        NULLIF(TRIM(created_dt), '')::DATE                  AS created_dt

    FROM source

)

SELECT
    cleaned.*,

    booking_date                                            AS effective_from,

    -- entry key + the keys it connects to
    {{ hash_key(['stmt_entry_id']) }}                       AS hk_stmt_entry,
    {{ hash_key(['account_number']) }}                      AS hk_account,
    CASE WHEN customer_id IS NOT NULL
         THEN {{ hash_key(['customer_id']) }}
    END                                                     AS hk_customer,

    -- hash diff: only the columns that live in sat_stmt_entry
    {{ hash_diff([
        'narrative', 'counterparty',
        'our_reference', 'their_reference', 'trans_reference', 'reversal_marker',
        'cheque_number', 'chq_type', 'exchange_rate',
        'system_id', 'position_type', 'account_officer', 'company_code',
        'processing_date', 'exposure_date', 'system_date_time'
    ]) }}                                                   AS hd_stmt_entry,

    'FBNK_STMT_ENTRY'                                       AS record_source

FROM cleaned