
-- =========================================================
-- QUERY 14E: Reverse Product ID Mapping Analysis
-- OBJECTIVE: Check whether product IDs map to multiple names
-- =========================================================

SELECT

    item.item_id AS product_id,

    COUNT(DISTINCT LOWER(TRIM(item.item_name)))
        AS distinct_product_names,

    ARRAY_AGG(
        DISTINCT item.item_name
        IGNORE NULLS
        LIMIT 10
    ) AS product_names,

    COUNTIF(event_name = 'view_item')
        AS view_events,

    COUNTIF(event_name = 'add_to_cart')
        AS cart_events,

    COUNTIF(event_name = 'purchase')
        AS purchase_events

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item

WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

    AND event_name IN (
        'view_item',
        'add_to_cart',
        'purchase'
    )

    AND item.item_id IS NOT NULL

GROUP BY
    product_id

HAVING
    COUNT(DISTINCT LOWER(TRIM(item.item_name))) > 1

ORDER BY
    distinct_product_names DESC

LIMIT 30;

-- END OF REVERSE PRODUCT ID MAPPING ANALYSIS



-- BUSINESS INSIGHT: PRODUCT IDENTIFIER CONSISTENCY
--
-- Six product IDs were associated with two distinct
-- product names each.
--
-- Examples include product naming variations and
-- inconsistent HTML encoding.
--
-- Product names should be standardised before reporting.
-- Product IDs should be validated across event types
-- before calculating product-level conversion metrics.
--
-- These findings describe data quality issues and
-- do not establish the underlying causes.
