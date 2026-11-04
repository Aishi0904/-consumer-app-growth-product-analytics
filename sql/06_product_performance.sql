
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



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14G: Missing Product ID Validation
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Identify NULL and blank product identifiers.
-- Measure product identifier completeness.

SELECT

    COUNT(*) AS total_item_events,

    COUNTIF(item.item_id IS NULL)
        AS null_product_ids,

    COUNTIF(TRIM(item.item_id) = '')
        AS blank_product_ids,

    COUNTIF(
        item.item_id IS NOT NULL
        AND TRIM(item.item_id) != ''
    ) AS valid_product_ids,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                item.item_id IS NOT NULL
                AND TRIM(item.item_id) != ''
            ),
            COUNT(*)
        ) * 100,
        2
    ) AS valid_product_id_pct

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item

WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'

    AND event_name IN (
        'view_item',
        'add_to_cart',
        'purchase'
    );

-- END OF QUERY 14G


-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14G: Missing Product ID Validation
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Identify missing product identifiers.
-- Measure product identifier completeness.

SELECT
    COUNT(*) AS total_item_events,
    COUNTIF(item.item_id IS NULL) AS null_product_ids,
    COUNTIF(TRIM(item.item_id) = '') AS blank_product_ids,
    COUNTIF(
        item.item_id IS NOT NULL
        AND TRIM(item.item_id) != ''
    ) AS valid_product_ids,
    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                item.item_id IS NOT NULL
                AND TRIM(item.item_id) != ''
            ),
            COUNT(*)
        ) * 100,
        2
    ) AS valid_product_id_pct
FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item
WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('view_item','add_to_cart','purchase');

-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. The analysis identified 3,431,675 item-event records.
--
-- 2. No NULL product identifiers were observed.
--
-- 3. No blank product identifiers were observed.
--
-- 4. All observed records contained non-NULL,
--    non-empty product identifiers, resulting in
--    100% identifier completeness under this definition.
--
-- 5. This validation does not rule out placeholder
--    identifiers such as '(not set)' or 'unknown'.
--    These require a separate investigation.
--
-- =========================================================

-- END OF QUERY 14G


-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14H: Placeholder Product ID Investigation
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Identify placeholder product identifiers.
-- Evaluate their presence across product events.
-- Assess their impact on product-level analysis.

SELECT
    LOWER(TRIM(item.item_id)) AS product_id_value,
    COUNT(*) AS item_event_count,
    COUNT(DISTINCT user_pseudo_id) AS unique_users,
    COUNTIF(event_name = 'view_item') AS view_events,
    COUNTIF(event_name = 'add_to_cart') AS cart_events,
    COUNTIF(event_name = 'purchase') AS purchase_events

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`,
    UNNEST(items) AS item

WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
    AND event_name IN ('view_item', 'add_to_cart', 'purchase')
    AND LOWER(TRIM(item.item_id)) IN (
        '(not set)',
        'not set',
        'unknown',
        'null',
        ''
    )

GROUP BY
    product_id_value

ORDER BY
    item_event_count DESC;

-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. Identified 601 item-event records containing
--    the placeholder product ID '(not set)'.
--
-- 2. These records involved 537 distinct users.
--
-- 3. The placeholder appeared across all three
--    product event categories:
--    product views, cart additions and purchases.
--
-- 4. A total of 448 purchase item-event records
--    contained the placeholder identifier.
--
-- 5. These records cannot be reliably attributed
--    to individual products using item_id.
--
-- 6. Product-level performance analysis should
--    account for these unidentified product records
--    to avoid misleading attribution.
--
-- =========================================================

-- END OF QUERY 14H



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14I: Product Identifier Reliability Assessment
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Assess product identifier reliability across
-- views, cart additions and purchases.
-- Quantify the share of identifiable item events.

SELECT
    event_name,

    COUNT(*) AS total_item_events,

    COUNTIF(
        item.item_id IS NOT NULL
        AND TRIM(item.item_id) != ''
        AND LOWER(TRIM(item.item_id)) NOT IN (
            '(not set)',
            'not set',
            'unknown',
            'null'
        )
    ) AS identifiable_item_events,

    COUNTIF(
        item.item_id IS NULL
        OR TRIM(item.item_id) = ''
        OR LOWER(TRIM(item.item_id)) IN (
            '(not set)',
            'not set',
            'unknown',
            'null'
        )
    ) AS unidentified_item_events,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                item.item_id IS NOT NULL
                AND TRIM(item.item_id) != ''
                AND LOWER(TRIM(item.item_id)) NOT IN (
                    '(not set)',
                    'not set',
                    'unknown',
                    'null'
                )
            ),
            COUNT(*)
        ) * 100,
        2
    ) AS identifier_reliability_pct,

    COUNT(DISTINCT user_pseudo_id) AS unique_users

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

GROUP BY
    event_name

ORDER BY
    event_name;

-- END OF QUERY 14I



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14I: Product Identifier Reliability Assessment
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Assess product identifier reliability across
-- views, cart additions and purchases.
-- Quantify the share of identifiable item events.

SELECT
    event_name,

    COUNT(*) AS total_item_events,

    COUNTIF(
        item.item_id IS NOT NULL
        AND TRIM(item.item_id) != ''
        AND LOWER(TRIM(item.item_id)) NOT IN (
            '(not set)',
            'not set',
            'unknown',
            'null'
        )
    ) AS identifiable_item_events,

    COUNTIF(
        item.item_id IS NULL
        OR TRIM(item.item_id) = ''
        OR LOWER(TRIM(item.item_id)) IN (
            '(not set)',
            'not set',
            'unknown',
            'null'
        )
    ) AS unidentified_item_events,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(
                item.item_id IS NOT NULL
                AND TRIM(item.item_id) != ''
                AND LOWER(TRIM(item.item_id)) NOT IN (
                    '(not set)',
                    'not set',
                    'unknown',
                    'null'
                )
            ),
            COUNT(*)
        ) * 100,
        2
    ) AS identifier_reliability_pct,

    COUNT(DISTINCT user_pseudo_id) AS unique_users

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

GROUP BY
    event_name

ORDER BY
    event_name;

-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. Product views recorded 2,748,246 item events,
--    with only 9 unidentified product IDs.
--    Identifier reliability was approximately 100%.
--
-- 2. Add-to-cart events recorded 667,426 item events,
--    with 144 unidentified product IDs.
--    Identifier reliability was 99.98%.
--
-- 3. Purchase events recorded 16,003 item events,
--    with 448 unidentified product IDs.
--    Identifier reliability was 97.20%.
--
-- 4. Purchase events demonstrated the weakest
--    identifier coverage among the three event types.
--
-- 5. Unidentified purchase records may affect
--    product-level purchase attribution and revenue
--    analysis.
--
-- 6. Product-level conversion analysis should account
--    for identifier inconsistencies before drawing
--    conclusions about individual product performance.
--
-- =========================================================

-- END OF QUERY 14I



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14J: Product-Level Event Coverage Summary
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Measure product-level coverage across views,
-- cart additions and purchases.
-- Identify products appearing across multiple stages.

WITH product_events AS (
    SELECT
        item.item_id AS product_id,

        COUNTIF(event_name = 'view_item') AS view_events,

        COUNTIF(event_name = 'add_to_cart') AS cart_events,

        COUNTIF(event_name = 'purchase') AS purchase_events

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
        AND TRIM(item.item_id) != ''
        AND LOWER(TRIM(item.item_id)) NOT IN (
            '(not set)',
            'not set',
            'unknown',
            'null'
        )

    GROUP BY
        product_id
)

SELECT
    COUNT(*) AS total_identifiable_products,

    COUNTIF(view_events > 0) AS products_with_views,

    COUNTIF(cart_events > 0) AS products_with_cart_additions,

    COUNTIF(purchase_events > 0) AS products_with_purchases,

    COUNTIF(
        view_events > 0
        AND cart_events > 0
        AND purchase_events > 0
    ) AS products_in_all_three_stages,

    COUNTIF(
        view_events > 0
        AND cart_events = 0
        AND purchase_events = 0
    ) AS products_with_views_only,

    COUNTIF(
        view_events = 0
        AND cart_events > 0
        AND purchase_events = 0
    ) AS products_with_cart_only,

    COUNTIF(
        view_events = 0
        AND cart_events = 0
        AND purchase_events > 0
    ) AS products_with_purchases_only

FROM
    product_events;

-- END OF QUERY 14J


-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. Identified 1,374 distinct products with valid
--    product identifiers across the selected events.
--
-- 2. A total of 426 products appeared in product views,
--    805 in cart additions and 809 in purchases.
--
-- 3. Only 4 products appeared across all three
--    event categories, representing approximately
--    0.29% of identifiable products.
--
-- 4. A total of 558 products appeared exclusively
--    in purchase events under the current product ID.
--
-- 5. Another 143 products appeared exclusively
--    in cart addition events.
--
-- 6. The limited overlap indicates that product IDs
--    may not provide a consistent linking key across
--    the customer journey.
--
-- 7. Product-level conversion metrics should not be
--    interpreted as reliable until identifier
--    inconsistencies are investigated further.
--
-- NOTE:
-- Event presence is measured over the full observation
-- window. Absence of an event does not establish that
-- the event never occurred outside this period or
-- under another product identifier.
--
-- =========================================================

-- END OF QUERY 14J
