WITH source AS (

    SELECT * FROM {{ source('raw', 'fbnk_account') }}

),

cleaned AS (

    SELECT
        -- keys and version
        SPLIT_PART(recid, ';', 1)                           AS account_number,
        NULLIF(TRIM(customer), '')                          AS customer_id,         -- NULL on internal 9999 accounts
        NULLIF(TRIM(curr_no), '')::INT                      AS curr_no,

        -- descriptive columns: account details
        NULLIF(TRIM(category), '')                          AS category,
        NULLIF(TRIM(currency), '')                          AS currency,
        TO_DATE(NULLIF(TRIM(opening_date), ''), 'YYYYMMDD') AS opening_date,
        TO_DATE(NULLIF(TRIM(closure_date), ''), 'YYYYMMDD') AS closure_date,
        NULLIF(TRIM(short_title), '')                       AS short_title,
        NULLIF(TRIM(account_title_1), '')                   AS account_title_1,
        NULLIF(TRIM(arabic_title), '')                      AS arabic_title,
        NULLIF(TRIM(alt_acct_id_1), '')                     AS alt_acct_id_1,
        NULLIF(TRIM(alt_acct_type_1), '')                   AS alt_acct_type_1,
        NULLIF(TRIM(alt_acct_id_2), '')                     AS alt_acct_id_2,
        NULLIF(TRIM(alt_acct_type_2), '')                   AS alt_acct_type_2,
        NULLIF(TRIM(account_officer), '')                   AS account_officer,
        NULLIF(TRIM(co_code), '')                           AS co_code,
        NULLIF(TRIM(limit_ref), '')                         AS limit_ref,
        NULLIF(TRIM(record_status), '')                     AS record_status,
        NULLIF(TRIM(closed_online), '')                     AS closed_online,
        NULLIF(TRIM(inactiv_marker), '')                    AS inactiv_marker,
        NULLIF(TRIM(posting_restrict), '')                  AS posting_restrict,

        -- descriptive columns: balances
        NULLIF(TRIM(online_actual_bal), '')::NUMERIC(18,2)  AS online_actual_bal,
        NULLIF(TRIM(online_cleared_bal), '')::NUMERIC(18,2) AS online_cleared_bal,
        NULLIF(TRIM(open_actual_bal), '')::NUMERIC(18,2)    AS open_actual_bal,
        NULLIF(TRIM(working_balance), '')::NUMERIC(18,2)    AS working_balance,
        NULLIF(TRIM(prev_bal), '')::NUMERIC(18,2)           AS prev_bal,

        -- technical columns (not in the hash diff)
        TO_DATE(NULLIF(TRIM(date_last_update), ''), 'YYYYMMDD') AS date_last_update,
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

    COALESCE(date_last_update, opening_date)                AS effective_from,

    -- hub keys
    {{ hash_key(['account_number']) }}                      AS hk_account,
    CASE WHEN customer_id IS NOT NULL
         THEN {{ hash_key(['customer_id']) }}
    END                                                     AS hk_customer,

    -- link key: customer owns account (NULL for internal accounts)
    CASE WHEN customer_id IS NOT NULL
         THEN {{ hash_key(['customer_id', 'account_number']) }}
    END                                                     AS hk_customer_account,

    -- hash diff 1: account details (change rarely)
    {{ hash_diff([
        'category', 'currency', 'opening_date', 'closure_date',
        'short_title', 'account_title_1', 'arabic_title',
        'alt_acct_id_1', 'alt_acct_type_1', 'alt_acct_id_2', 'alt_acct_type_2',
        'account_officer', 'co_code', 'limit_ref',
        'record_status', 'closed_online', 'inactiv_marker', 'posting_restrict'
    ]) }}                                                   AS hd_account_details,

    -- hash diff 2: balances (change on almost every version)
    {{ hash_diff([
        'online_actual_bal', 'online_cleared_bal', 'open_actual_bal',
        'working_balance', 'prev_bal'
    ]) }}                                                   AS hd_account_balance,

    'FBNK_ACCOUNT'                                          AS record_source

FROM cleaned