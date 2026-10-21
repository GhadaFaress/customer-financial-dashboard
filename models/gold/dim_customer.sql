WITH latest AS (

    -- one row per customer: their newest version
    SELECT DISTINCT ON (hk_customer)
        hk_customer,
        short_name,
        gender,
        profession,
        email_address,
        opening_date,
        customer_status,
        risk_rate
    FROM {{ ref('sat_customer') }}
    ORDER BY hk_customer, curr_no DESC

)

SELECT
    h.hk_customer           AS customer_key,
    h.customer_id,
    l.short_name            AS customer_name,
    l.gender,
    l.profession,
    l.email_address,
    l.opening_date,
    l.customer_status,
    l.risk_rate
FROM {{ ref('hub_customer') }} h
JOIN latest l ON l.hk_customer = h.hk_customer