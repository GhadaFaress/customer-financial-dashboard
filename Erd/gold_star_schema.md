# Gold layer: star schema

Schema `dv_gold`. Facts hold the numbers, dimensions describe them.

```mermaid
erDiagram
    dim_customer ||--o{ dim_account : "owns"
    dim_account  ||--o{ fact_stmt_entry : "account"
    dim_customer |o--o{ fact_stmt_entry : "customer"
    dim_date     ||--o{ fact_stmt_entry : "value / booking date"
    dim_account  ||--o{ fact_account_balance : "account"
    dim_customer |o--o{ fact_account_balance : "customer"
    dim_date     ||--o{ fact_account_balance : "day"
    dim_customer {
        text customer_key PK
        text customer_id
        text customer_name
        text gender
        text profession
        text email_address
        date opening_date
        text customer_status
        text risk_rate
    }
    dim_account {
        text account_key PK
        text account_number
        text customer_key FK
        text category
        text currency
        date opening_date
        date closure_date
        text account_title
        text iban
        text inactiv_marker
        bool is_internal
        text account_type
        text account_status
    }
    dim_date {
        int date_key PK
        date full_date
        int year
        int month
        text month_name
        int day_of_month
        text day_name
        bool is_weekend
        date month_start
    }
    fact_stmt_entry {
        text stmt_entry_key PK
        text stmt_entry_id
        text account_key FK
        text customer_key FK
        int value_date_key FK
        int booking_date_key FK
        text transaction_code
        text currency
        numeric amount_lcy
        numeric amount_fcy
        text direction
    }
    fact_account_balance {
        text account_key PK,FK
        text customer_key FK
        int date_key PK,FK
        text currency
        numeric moved_lcy
        numeric balance_lcy
        numeric balance_acct_ccy
    }
```

- `fact_stmt_entry` grain: one row per statement entry
- `fact_account_balance` grain: one row per account per day
