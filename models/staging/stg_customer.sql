WITH source AS (

    SELECT * FROM {{ source('raw', 'fbnk_customer') }}

),

cleaned AS (

    SELECT
        -- key and version
        SPLIT_PART(recid, ';', 1)                           AS customer_id,
        NULLIF(TRIM(curr_no), '')::INT                      AS curr_no,

        -- descriptive columns
        NULLIF(TRIM(short_name), '')                        AS short_name,
        NULLIF(TRIM(arabic_name), '')                       AS arabic_name,
        NULLIF(TRIM(genders), '')                           AS gender,
        NULLIF(TRIM(birth_incorp_date), '')                 AS birth_incorp_date,   -- text: keeps 00000000
        NULLIF(TRIM(nat_security_number), '')               AS nat_security_number,
        NULLIF(TRIM(id_type), '')                           AS id_type,
        NULLIF(TRIM(id_number), '')                         AS id_number,
        NULLIF(TRIM(nationality), '')                       AS nationality,
        NULLIF(TRIM(sector), '')                            AS sector,
        NULLIF(TRIM(profession), '')                        AS profession,
        NULLIF(TRIM(customer_status), '')                   AS customer_status,
        NULLIF(TRIM(risk_rate), '')                         AS risk_rate,
        NULLIF(TRIM(account_officer), '')                   AS account_officer,
        NULLIF(TRIM(company_book), '')                      AS company_book,
        NULLIF(TRIM(emploee_no), '')                        AS employee_no,
        NULLIF(TRIM(telephone_1), '')                       AS telephone_1,
        NULLIF(TRIM(telephone_2), '')                       AS telephone_2,
        NULLIF(TRIM(sms_1), '')                             AS sms_1,
        NULLIF(TRIM(email_address), '')                     AS email_address,
        NULLIF(TRIM(email_1), '')                           AS email_1,
        NULLIF(TRIM(drmnt_code), '')                        AS drmnt_code,
        NULLIF(TRIM(drmnt_date), '')                        AS drmnt_date,
        NULLIF(TRIM(posting_restrict_1), '')                AS posting_restrict_1,
        NULLIF(TRIM(posting_restrict_2), '')                AS posting_restrict_2,
        NULLIF(TRIM(peps), '')                              AS peps,
        NULLIF(TRIM(commercial_registration_no), '')        AS commercial_registration_no,
        NULLIF(TRIM(licence_expiry_date), '')               AS licence_expiry_date,
        TO_DATE(NULLIF(TRIM(opening_date), ''), 'YYYYMMDD') AS opening_date,

        -- technical columns (not in the hash diff)
        TO_DATE(NULLIF(TRIM(update_date), ''), 'YYYYMMDD')  AS update_date,
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

    COALESCE(update_date, opening_date)                     AS effective_from,

    {{ hash_key(['customer_id']) }}                         AS hk_customer,

    {{ hash_diff([
        'short_name', 'arabic_name', 'gender', 'birth_incorp_date',
        'nat_security_number', 'id_type', 'id_number', 'nationality',
        'sector', 'profession', 'customer_status', 'risk_rate',
        'account_officer', 'company_book', 'employee_no',
        'telephone_1', 'telephone_2', 'sms_1', 'email_address', 'email_1',
        'drmnt_code', 'drmnt_date', 'posting_restrict_1', 'posting_restrict_2',
        'peps', 'commercial_registration_no', 'licence_expiry_date', 'opening_date'
    ]) }}                                                   AS hd_customer,

    'FBNK_CUSTOMER'                                         AS record_source

FROM cleaned