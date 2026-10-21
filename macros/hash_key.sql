{% macro hash_key(columns) -%}
MD5(CONCAT_WS('||',
{%- for col in columns %}
    COALESCE(UPPER(TRIM({{ col }}::TEXT)), ''){{ ',' if not loop.last }}
{%- endfor %}
))
{%- endmacro %}
 