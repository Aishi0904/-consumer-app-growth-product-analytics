
-- ============================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- FILE: 04_conversion_funnel.sql
-- TOOL: Google BigQuery
-- DATASET: GA4 Obfuscated Sample Ecommerce
-- ANALYSIS: Purchase Conversion Funnel
-- DATE RANGE: November 2020 - January 2021
-- ============================================================


-- OBJECTIVE:
-- Analyse user progression through the ecommerce purchase funnel.
-- Identify drop-offs and measure conversion rates at each stage.


-- FUNNEL STAGES:
-- 1. Product View
-- 2. Add to Cart
-- 3. Begin Checkout
-- 4. Purchase


-- STEP 1: FILTER RELEVANT FUNNEL EVENTS

WITH funnel_events AS (

    SELECT
        user_pseudo_id,
        event_name

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

        AND event_name IN (
            'view_item',
            'add_to_cart',
            'begin_checkout',
            'purchase'
        )

),


-- STEP 2: CALCULATE FUNNEL METRICS

funnel_metrics AS (

    SELECT

        -- Total events at each stage

        COUNTIF(event_name = 'view_item') AS product_view_events,

        COUNTIF(event_name = 'add_to_cart') AS add_to_cart_events,

        COUNTIF(event_name = 'begin_checkout') AS checkout_events,

        COUNTIF(event_name = 'purchase') AS purchase_events,


        -- Unique users at each stage

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS product_view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users,

        COUNT(DISTINCT IF(
            event_name = 'begin_checkout',
            user_pseudo_id,
            NULL
        )) AS checkout_users,

        COUNT(DISTINCT IF(
            event_name = 'purchase',
            user_pseudo_id,
            NULL
        )) AS purchasing_users

    FROM
        funnel_events

)


-- STEP 3: CALCULATE CONVERSION RATES

SELECT

    product_view_events,
    add_to_cart_events,
    checkout_events,
    purchase_events,

    product_view_users,
    cart_users,
    checkout_users,
    purchasing_users,

    -- View to Cart Conversion Rate

    ROUND(
        SAFE_DIVIDE(cart_users, product_view_users) * 100,
        2
    ) AS view_to_cart_conversion_pct,

    -- Cart to Checkout Conversion Rate

    ROUND(
        SAFE_DIVIDE(checkout_users, cart_users) * 100,
        2
    ) AS cart_to_checkout_conversion_pct,

    -- Checkout to Purchase Conversion Rate

    ROUND(
        SAFE_DIVIDE(purchasing_users, checkout_users) * 100,
        2
    ) AS checkout_to_purchase_conversion_pct

FROM
    funnel_metrics;


-- END OF PURCHASE FUNNEL ANALYSIS


-- =====================================================
-- QUERY 02: Overall Conversion and Funnel Drop-off Analysis
-- =====================================================

WITH funnel_users AS (

    SELECT

        COUNT(DISTINCT IF(
            event_name = 'view_item',
            user_pseudo_id,
            NULL
        )) AS product_view_users,

        COUNT(DISTINCT IF(
            event_name = 'add_to_cart',
            user_pseudo_id,
            NULL
        )) AS cart_users,

        COUNT(DISTINCT IF(
            event_name = 'begin_checkout',
            user_pseudo_id,
            NULL
        )) AS checkout_users,

        COUNT(DISTINCT IF(
            event_name = 'purchase',
            user_pseudo_id,
            NULL
        )) AS purchasing_users

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

        AND event_name IN (
            'view_item',
            'add_to_cart',
            'begin_checkout',
            'purchase'
        )
)

SELECT

    product_view_users,
    cart_users,
    checkout_users,
    purchasing_users,

    -- Overall Purchase Conversion Rate

    ROUND(
        SAFE_DIVIDE(
            purchasing_users,
            product_view_users
        ) * 100,
        2
    ) AS overall_conversion_pct,

    -- Absolute User Drop-offs

    product_view_users - cart_users
        AS view_to_cart_dropoff,

    cart_users - checkout_users
        AS cart_to_checkout_dropoff,

    checkout_users - purchasing_users
        AS checkout_to_purchase_dropoff,

    -- Percentage User Drop-offs

    ROUND(
        (1 - SAFE_DIVIDE(cart_users, product_view_users)) * 100,
        2
    ) AS view_to_cart_dropoff_pct,

    ROUND(
        (1 - SAFE_DIVIDE(checkout_users, cart_users)) * 100,
        2
    ) AS cart_to_checkout_dropoff_pct,

    ROUND(
        (1 - SAFE_DIVIDE(purchasing_users, checkout_users)) * 100,
        2
    ) AS checkout_to_purchase_dropoff_pct

FROM funnel_users;

-- END OF SUPPLEMENTARY FUNNEL ANALYSIS

