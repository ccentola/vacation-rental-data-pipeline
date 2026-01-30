{% set configs = [
    {
        "table" : "AIRBNB_DEMO.GOLD.OBT",
        "columns" : "gold_obt.BOOKING_ID, gold_obt.LISTING_ID, gold_obt.HOST_ID,gold_obt.TOTAL_AMOUNT, gold_obt.SERVICE_FEE, gold_obt.CLEANING_FEE, gold_obt.ACCOMMODATES, gold_obt.BEDROOMS, gold_obt.BATHROOMS, gold_obt.PRICE_PER_NIGHT, gold_obt.RESPONSE_RATE",
        "alias" : "gold_obt"
    },
    { 
        "table" : "AIRBNB_DEMO.GOLD.dim_listings",
        "columns" : "",
        "alias" : "dim_listings",
        "join_condition" : "gold_obt.listing_id = dim_listings.listing_id"
    },
    {
        "table" : "AIRBNB_DEMO.GOLD.dim_hosts",
        "columns" : "",
        "alias" : "dim_hosts",
        "join_condition" : "gold_obt.host_id = DIM_hosts.host_id"
    }
] %}



SELECT 
        {{ configs[0]['columns'] }}

FROM
    {% for config in configs %}
    {% if loop.first %}
      {{ config['table'] }} AS {{ config['alias'] }}
    {% else %}
        LEFT JOIN {{ config['table'] }} AS {{ config['alias'] }}
        ON {{ config['join_condition'] }}
        {% endif %}
        {% endfor %}