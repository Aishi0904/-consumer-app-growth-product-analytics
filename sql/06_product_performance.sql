
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



-- =========================================================
-- QUERY 14F: Product Event Coverage & Identifier Analysis
-- PROJECT: Consumer App Growth & Product Analytics
-- TOOL: Google BigQuery
-- DATASET: GA4 Public Ecommerce Sample
-- PERIOD: November 2020 - January 2021
-- =========================================================

WITH product_events AS (

    SELECT
        item.item_id AS product_id,
        item.item_name AS product_name,
        event_name,
        user_pseudo_id

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
),

product_summary AS (

    SELECT
        product_id,

        COUNT(DISTINCT product_name)
            AS distinct_product_names,

        COUNTIF(event_name = 'view_item')
            AS view_events,

        COUNTIF(event_name = 'add_to_cart')
            AS cart_events,

        COUNTIF(event_name = 'purchase')
            AS purchase_events,

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id, NULL
        )) AS viewing_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id, NULL
        )) AS cart_users,

        COUNT(DISTINCT IF(
            event_name = 'purchase',
            user_pseudo_id, NULL
        )) AS purchasing_users

    FROM product_events

    GROUP BY product_id
)

SELECT

    product_id,

    CASE
        WHEN REGEXP_CONTAINS(product_id, r'^[0-9]+$')
            THEN 'Numeric ID'
        ELSE 'Alphanumeric ID'
    END AS identifier_format,

    distinct_product_names,

    view_events,
    cart_events,
    purchase_events,

    viewing_users,
    cart_users,
    purchasing_users,

    CASE
        WHEN view_events > 0
         AND cart_events > 0
         AND purchase_events > 0
            THEN 'Present in all three events'

        WHEN view_events > 0
         AND cart_events > 0
            THEN 'View and cart only'

        WHEN cart_events > 0
         AND purchase_events > 0
            THEN 'Cart and purchase only'

        WHEN view_events > 0
         AND purchase_events > 0
            THEN 'View and purchase only'

        WHEN view_events > 0
            THEN 'View only'

        WHEN cart_events > 0
            THEN 'Cart only'

        ELSE 'Purchase only'
    END AS event_coverage

FROM product_summary

ORDER BY
    purchase_events DESC,
    cart_events DESC

LIMIT 100;

-- END OF QUERY 14F


-- =========================================================
-- BUSINESS INSIGHTS: PRODUCT EVENT COVERAGE
-- =========================================================

-- 1. Product identifiers were found in different formats,
--    including numeric and alphanumeric identifiers.

-- 2. Certain products recorded purchase events without
--    corresponding view events in the selected period.

-- 3. Product-level event coverage varies across products.

-- 4. Missing product identifiers require further validation.

-- 5. Event coverage should be checked before calculating
--    product-level conversion rates.

-- NOTE:
-- Event counts do not represent unique customers.
-- Observed event gaps do not establish tracking failures
-- or prove that users purchased without viewing products.

-- END OF BUSINESS INSIGHTS
