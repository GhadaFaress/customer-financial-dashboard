WITH staged AS (

    SELECT
        -- 1. which customer
        hk_customer,

        -- 2. which version, and when
        hd_customer,
        curr_no,
        effective_from,
        ingested_ts            AS load_ts,
        record_source,

        -- 3. what it says
        short_name, arabic_name, gender, birth_incorp_date,
        nat_security_number, id_type, id_number, nationality,
        sector, profession, customer_status, risk_rate,
        account_officer, company_book, employee_no,
        telephone_1, telephone_2, sms_1, email_address, email_1,
        drmnt_code, drmnt_date, posting_restrict_1, posting_restrict_2,
        peps, commercial_registration_no, licence_expiry_date, opening_date

    FROM {{ ref('stg_customer') }}

),

latest AS (

    -- the newest version the satellite already holds, per customer
    {% if is_incremental() %}
    SELECT DISTINCT ON (hk_customer)
        hk_customer,
        curr_no      AS latest_curr_no,
        hd_customer  AS latest_hd
    FROM {{ this }}
    ORDER BY hk_customer, curr_no DESC
    {% else %}
    -- first run: the satellite is empty
    SELECT NULL::TEXT AS hk_customer, NULL::INT AS latest_curr_no, NULL::TEXT AS latest_hd
    WHERE FALSE
    {% endif %}

),

new_versions AS (

    -- idea 1: only versions newer than what we already stored
    SELECT staged.*, latest.latest_hd
    FROM staged
    LEFT JOIN latest ON latest.hk_customer = staged.hk_customer
    WHERE latest.latest_curr_no IS NULL
       OR staged.curr_no > latest.latest_curr_no

),

compared AS (

    SELECT
        new_versions.*,
        -- idea 2: previous = row before in this file,
        --         or the satellite's latest row if there is none
        COALESCE(
            LAG(hd_customer) OVER (PARTITION BY hk_customer ORDER BY curr_no),
            latest_hd
        ) AS prev_hd
    FROM new_versions

)

SELECT
    hk_customer, hd_customer, curr_no, effective_from, load_ts, record_source,
    short_name, arabic_name, gender, birth_incorp_date,
    nat_security_number, id_type, id_number, nationality,
    sector, profession, customer_status, risk_rate,
    account_officer, company_book, employee_no,
    telephone_1, telephone_2, sms_1, email_address, email_1,
    drmnt_code, drmnt_date, posting_restrict_1, posting_restrict_2,
    peps, commercial_registration_no, licence_expiry_date, opening_date
FROM compared
WHERE hd_customer IS DISTINCT FROM prev_hd