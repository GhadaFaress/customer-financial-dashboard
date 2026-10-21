{% macro hash_diff(columns) -%}
MD5(CONCAT_WS('||',
{%- for col in columns %}
    COALESCE({{ col }}::TEXT, ''){{ ',' if not loop.last }}
{%- endfor %}
))
{%- endmacro %}
 