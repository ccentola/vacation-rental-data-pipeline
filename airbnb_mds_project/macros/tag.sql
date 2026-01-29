{% macro tag(col) %}
    CASE
        WHEN {{ col }} < 100 then 'LOW'
        WHEN {{ col }} < 200 then 'MEDIUM'
        ELSE 'HIGH'
    END
{% endmacro %}