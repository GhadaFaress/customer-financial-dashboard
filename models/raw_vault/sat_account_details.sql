WITH staged AS (

    SELECT
        -- 1. which account
        hk_account,

        -- 2. which version, and when
        hd_account_details,
        curr_no,
        effective_from,
        ingested_ts            AS load_ts,
        record_source,

        -- 3. what it says
        category, currency, opening_date, closure_date,
        short_title, account_title_1, arabic_title,
        alt_acct_id_1, alt_acct_type_1, alt_acct_id_2, alt_acct_type_2,
        account_officer, co_code, limit_ref,
        record_status, closed_online, inactiv_marker, posting_restrict

    FROM {{ ref('stg_account') }}

),

latest AS (

    -- the newest version the satellite already holds, per account
    {% if is_incremental() %}
    SELECT DISTINCT ON (hk_account)
        hk_account,
        curr_no  AS latest_curr_no,
        hd_account_details  AS latest_hd
    FROM {{ this }}
    ORDER BY hk_account, curr_no DESC
    {% else %}
    -- first run: the satellite is empty
    SELECT NULL::TEXT AS hk_account, NULL::INT AS latest_curr_no, NULL::TEXT AS latest_hd
    WHERE FALSE
    {% endif %}

),

new_versions AS (

    -- only versions newer than what we already stored
    SELECT staged.*, latest.latest_hd
    FROM staged
    LEFT JOIN latest ON latest.hk_account = staged.hk_account
    WHERE latest.latest_curr_no IS NULL
       OR staged.curr_no > latest.latest_curr_no

),

compared AS (

    SELECT
        new_versions.*,
        COALESCE(
            LAG(hd_account_details) OVER (PARTITION BY hk_account ORDER BY curr_no),
            latest_hd
        ) AS prev_hd
    FROM new_versions

)

SELECT
    hk_account, hd_account_details, curr_no, effective_from, load_ts, record_source,
        category, currency, opening_date, closure_date,
        short_title, account_title_1, arabic_title,
        alt_acct_id_1, alt_acct_type_1, alt_acct_id_2, alt_acct_type_2,
        account_officer, co_code, limit_ref,
        record_status, closed_online, inactiv_marker, posting_restrict
FROM compared
WHERE hd_account_details IS DISTINCT FROM prev_hd