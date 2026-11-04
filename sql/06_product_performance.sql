
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



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14K: Product Name-Based Event Coverage
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Examine product-level event coverage using
-- normalised product names instead of product IDs.
-- Compare name-based overlap across event categories.

WITH product_name_events AS (
    SELECT
        LOWER(TRIM(item.item_name)) AS product_name,

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
        AND item.item_name IS NOT NULL
        AND TRIM(item.item_name) != ''

    GROUP BY
        product_name
)

SELECT
    COUNT(*) AS total_identifiable_product_names,

    COUNTIF(view_events > 0) AS names_with_views,

    COUNTIF(cart_events > 0) AS names_with_cart_additions,

    COUNTIF(purchase_events > 0) AS names_with_purchases,

    COUNTIF(
        view_events > 0
        AND cart_events > 0
        AND purchase_events > 0
    ) AS names_in_all_three_stages,

    COUNTIF(
        view_events > 0
        AND cart_events = 0
        AND purchase_events = 0
    ) AS names_with_views_only,

    COUNTIF(
        view_events = 0
        AND cart_events > 0
        AND purchase_events = 0
    ) AS names_with_cart_only,

    COUNTIF(
        view_events = 0
        AND cart_events = 0
        AND purchase_events > 0
    ) AS names_with_purchases_only

FROM
    product_name_events;

-- END OF QUERY 14K


-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. Identified 430 distinct normalised product names
--    across the selected product event categories.
--
-- 2. A total of 422 names appeared in product views,
--    414 in cart additions and 396 in purchases.
--
-- 3. A total of 386 product names appeared across
--    all three event categories, representing
--    approximately 89.77% of identifiable names.
--
-- 4. Only 6 product names appeared exclusively
--    in product view events.
--
-- 5. No product names appeared exclusively
--    in cart addition events.
--
-- 6. Only 8 product names appeared exclusively
--    in purchase events.
--
-- 7. Name-based matching produced substantially
--    greater cross-stage overlap than product-ID
--    matching in this dataset.
--
-- 8. However, previous analysis identified multiple
--    product IDs associated with individual names.
--    Therefore, product names should not be assumed
--    to be unique product identifiers.
--
-- 9. Further validation is required before using
--    product names for product-level conversion metrics.
--
-- NOTE:
-- Event presence is measured across the full
-- observation window, not through chronological
-- user-level purchase journeys.
--
-- =========================================================

-- END OF QUERY 14K



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14L: Product Name-to-ID Mapping Reliability
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Evaluate whether normalised product names map
-- consistently to unique product identifiers.
-- Measure one-to-one and one-to-many mappings.

WITH product_mapping AS (

    SELECT
        LOWER(TRIM(item.item_name)) AS product_name,

        COUNT(DISTINCT item.item_id) AS distinct_product_ids

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

        AND item.item_name IS NOT NULL
        AND TRIM(item.item_name) != ''

        AND item.item_id IS NOT NULL
        AND TRIM(item.item_id) != ''

        AND LOWER(TRIM(item.item_id)) NOT IN (
            '(not set)',
            'not set',
            'unknown',
            'null'
        )

    GROUP BY
        product_name
)

SELECT

    COUNT(*) AS total_product_names,

    COUNTIF(
        distinct_product_ids = 1
    ) AS names_with_one_product_id,

    COUNTIF(
        distinct_product_ids > 1
    ) AS names_with_multiple_product_ids,

    MAX(
        distinct_product_ids
    ) AS maximum_ids_per_product_name,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(distinct_product_ids = 1),
            COUNT(*)
        ) * 100,
        2
    ) AS one_to_one_mapping_pct,

    ROUND(
        SAFE_DIVIDE(
            COUNTIF(distinct_product_ids > 1),
            COUNT(*)
        ) * 100,
        2
    ) AS one_to_many_mapping_pct

FROM
    product_mapping;

-- END OF QUERY 14L


-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. Identified 429 distinct product names associated
--    with valid product identifiers.
--
-- 2. Only 15 product names mapped to exactly one
--    distinct product ID, representing 3.50%.
--
-- 3. A total of 414 product names mapped to multiple
--    product IDs, representing 96.50%.
--
-- 4. The maximum number of distinct product IDs
--    associated with a single product name was 13.
--
-- 5. The results indicate substantial one-to-many
--    mapping between product names and product IDs.
--
-- 6. Product names cannot be assumed to represent
--    unique products in the analytical dataset.
--
-- 7. Although name-based matching improves event
--    overlap, it may combine multiple product IDs
--    into a single analytical category.
--
-- 8. Neither product ID nor product name should
--    independently be treated as a fully reliable
--    product-level matching key without further
--    validation.
--
-- =========================================================

-- END OF QUERY 14L



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14M: Detailed Product Identifier Mapping Exceptions
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Identify product names associated with multiple IDs.
-- Examine the distribution of product events across
-- these inconsistent product mappings.

WITH product_mapping AS (

    SELECT
        LOWER(TRIM(item.item_name)) AS product_name,

        COUNT(DISTINCT item.item_id) AS distinct_product_ids,

        ARRAY_AGG(
            DISTINCT item.item_id
            IGNORE NULLS
            LIMIT 20
        ) AS associated_product_ids,

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

        AND item.item_name IS NOT NULL
        AND TRIM(item.item_name) != ''

        AND item.item_id IS NOT NULL
        AND TRIM(item.item_id) != ''

        AND LOWER(TRIM(item.item_id)) NOT IN (
            '(not set)',
            'not set',
            'unknown',
            'null'
        )

    GROUP BY
        product_name
)

SELECT
    product_name,

    distinct_product_ids,

    associated_product_ids,

    view_events,

    cart_events,

    purchase_events,

    view_events + cart_events + purchase_events
        AS total_item_events

FROM
    product_mapping

WHERE
    distinct_product_ids > 1

ORDER BY
    distinct_product_ids DESC,
    total_item_events DESC

LIMIT 100;

-- END OF QUERY 14M


-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. The analysis identified product names associated
--    with multiple distinct product identifiers.
--
-- 2. Google Land & Sea French Terry was associated
--    with 13 distinct product IDs in the returned results.
--
-- 3. Google Zip Hoodie F/C was associated with
--    9 distinct product IDs.
--
-- 4. Both examples demonstrated substantial
--    product-view and cart-addition activity.
--
-- 5. The Google Land & Sea French Terry example
--    recorded 31,068 views, 5,180 cart additions
--    and 30 purchase item events.
--
-- 6. The Google Zip Hoodie F/C example recorded
--    49,795 views, 13,011 cart additions
--    and 256 purchase item events.
--
-- 7. Multiple product IDs associated with one
--    product name may complicate product-level
--    performance attribution.
--
-- 8. Further investigation is required to determine
--    whether these mappings reflect product variants,
--    catalog inconsistencies or other identifier issues.
--
-- NOTE:
-- This query returns only the top 100 mapping exceptions.
-- The observations should not be treated as a complete
-- inventory of all product-name mapping exceptions.
--
-- =========================================================

-- END OF QUERY 14M



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14N: Product ID Format and Mapping Pattern Analysis
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Examine product ID formats associated with
-- product names having multiple identifiers.
-- Identify numeric and alphanumeric ID patterns.

WITH product_id_mapping AS (

    SELECT
        LOWER(TRIM(item.item_name)) AS product_name,
        TRIM(item.item_id) AS product_id,

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

        AND item.item_name IS NOT NULL
        AND TRIM(item.item_name) != ''

        AND item.item_id IS NOT NULL
        AND TRIM(item.item_id) != ''

        AND LOWER(TRIM(item.item_id)) NOT IN (
            '(not set)',
            'not set',
            'unknown',
            'null'
        )

    GROUP BY
        product_name,
        product_id
),

product_name_summary AS (

    SELECT
        product_name,

        COUNT(*) AS distinct_product_ids,

        COUNTIF(
            REGEXP_CONTAINS(product_id, r'^[0-9]+$')
        ) AS numeric_ids,

        COUNTIF(
            REGEXP_CONTAINS(product_id, r'[A-Za-z]')
            AND REGEXP_CONTAINS(product_id, r'[0-9]')
        ) AS alphanumeric_ids,

        COUNTIF(
            NOT REGEXP_CONTAINS(product_id, r'^[0-9]+$')
            AND NOT (
                REGEXP_CONTAINS(product_id, r'[A-Za-z]')
                AND REGEXP_CONTAINS(product_id, r'[0-9]')
            )
        ) AS other_format_ids,

        ARRAY_AGG(
            DISTINCT product_id
            IGNORE NULLS
            LIMIT 10
        ) AS sample_product_ids

    FROM
        product_id_mapping

    GROUP BY
        product_name
)

SELECT
    product_name,
    distinct_product_ids,
    numeric_ids,
    alphanumeric_ids,
    other_format_ids,
    sample_product_ids

FROM
    product_name_summary

WHERE
    distinct_product_ids > 1

ORDER BY
    distinct_product_ids DESC

LIMIT 100;

-- END OF QUERY 14N


-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. The analysis examined product names associated
--    with multiple distinct product identifiers.
--
-- 2. Google Land & Sea French Terry was associated
--    with 13 IDs: 11 numeric and 2 alphanumeric.
--
-- 3. Android Garden Tee Orange was associated
--    with 9 IDs: 8 numeric and 1 alphanumeric.
--
-- 4. Both examples demonstrate mixed identifier
--    formats within individual product-name mappings.
--
-- 5. Numeric identifiers were more frequent than
--    alphanumeric identifiers in these two examples.
--
-- 6. Different identifier formats may reflect
--    different catalog conventions or product
--    distinctions; the format alone does not establish
--    whether identifiers are duplicates or variants.
--
-- 7. Further product-level mapping validation is
--    required before selecting a reliable product key.
--
-- NOTE:
-- The query returns a maximum of 100 product-name
-- mapping exceptions. The observations above describe
-- the examples visible in the returned results.
--
-- =========================================================

-- END OF QUERY 14N



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14O: Reverse Product ID-to-Name Mapping Investigation
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Identify product IDs associated with multiple
-- distinct normalised product names.
-- Examine the event distribution of these mappings.

WITH product_id_name_mapping AS (

    SELECT
        TRIM(item.item_id) AS product_id,

        COUNT(
            DISTINCT LOWER(TRIM(item.item_name))
        ) AS distinct_product_names,

        ARRAY_AGG(
            DISTINCT LOWER(TRIM(item.item_name))
            IGNORE NULLS
            LIMIT 10
        ) AS associated_product_names,

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

        AND item.item_name IS NOT NULL
        AND TRIM(item.item_name) != ''

    GROUP BY
        product_id
)

SELECT
    product_id,

    distinct_product_names,

    associated_product_names,

    view_events,

    cart_events,

    purchase_events,

    view_events + cart_events + purchase_events
        AS total_item_events

FROM
    product_id_name_mapping

WHERE
    distinct_product_names > 1

ORDER BY
    distinct_product_names DESC,
    total_item_events DESC;

-- END OF QUERY 14O


-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. Identified 6 product IDs associated with
--    multiple distinct product names.
--
-- 2. Each identified product ID was associated
--    with 2 distinct normalised product names.
--
-- 3. GGOECXXX1630 was associated with Google Cloud
--    Unisex Zip Hoodie and Google Black Cloud Zip Hoodie.
--
-- 4. GGOECDHQ163999 was associated with White Google
--    Shoreline Bottle and Google Shoreline Water Bottle.
--
-- 5. GGOEAFKQ130599 was associated with two naming
--    formats for Android Iconic 4-inch Decal.
--
-- 6. The decal naming variation included an HTML
--    encoding difference: a quotation mark versus
--    the encoded entity '&quot;'.
--
-- 7. The remaining identified product IDs also
--    demonstrated multiple product-name associations.
--
-- 8. These inconsistencies may affect product
--    categorisation, reporting and product attribution.
--
-- 9. Further validation is required before treating
--    these product-name variations as equivalent.
--
-- NOTE:
-- Event counts represent item-event records,
-- not unique users or unique transactions.
--
-- =========================================================

-- END OF QUERY 14O



-- =========================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 14P: Product Identifier Consistency Validation
-- TOOL: Google BigQuery
-- PERIOD: November 2020 - January 2021
-- =========================================================

-- OBJECTIVE:
-- Consolidate product identifier mapping checks.
-- Evaluate the reliability of product IDs and names.

WITH product_mapping AS (

    SELECT DISTINCT
        TRIM(item.item_id) AS product_id,
        LOWER(TRIM(item.item_name)) AS product_name

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

        AND item.item_name IS NOT NULL
        AND TRIM(item.item_name) != ''
),

id_summary AS (

    SELECT
        product_id,
        COUNT(DISTINCT product_name) AS distinct_names

    FROM product_mapping
    GROUP BY product_id
),

name_summary AS (

    SELECT
        product_name,
        COUNT(DISTINCT product_id) AS distinct_ids

    FROM product_mapping
    GROUP BY product_name
),

id_metrics AS (

    SELECT
        COUNT(*) AS total_product_ids,

        COUNTIF(distinct_names = 1)
            AS ids_with_one_name,

        COUNTIF(distinct_names > 1)
            AS ids_with_multiple_names,

        COUNTIF(
            REGEXP_CONTAINS(product_id, r'^[0-9]+$')
        ) AS numeric_product_ids,

        COUNTIF(
            REGEXP_CONTAINS(product_id, r'[A-Za-z]')
            AND REGEXP_CONTAINS(product_id, r'[0-9]')
        ) AS alphanumeric_product_ids

    FROM id_summary
),

name_metrics AS (

    SELECT
        COUNT(*) AS total_product_names,

        COUNTIF(distinct_ids = 1)
            AS names_with_one_id,

        COUNTIF(distinct_ids > 1)
            AS names_with_multiple_ids

    FROM name_summary
)

SELECT
    i.total_product_ids,
    n.total_product_names,

    i.ids_with_one_name,
    i.ids_with_multiple_names,

    n.names_with_one_id,
    n.names_with_multiple_ids,

    i.numeric_product_ids,
    i.alphanumeric_product_ids

FROM id_metrics i
CROSS JOIN name_metrics n;

-- END OF QUERY 14P


-- =========================================================
-- BUSINESS INSIGHTS:
--
-- 1. Identified 1,374 distinct valid product IDs
--    and 429 distinct normalised product names.
--
-- 2. A total of 1,368 product IDs mapped to one
--    product name, while 6 mapped to multiple names.
--
-- 3. Only 15 product names mapped to exactly one
--    product ID.
--
-- 4. A total of 414 product names mapped to multiple
--    product IDs, representing 96.50%.
--
-- 5. Numeric identifiers accounted for 953 IDs,
--    while alphanumeric identifiers accounted for 421.
--
-- 6. Product IDs demonstrated substantially greater
--    consistency when mapped to names than product
--    names demonstrated when mapped back to IDs.
--
-- 7. Product names should not independently be used
--    as unique product identifiers.
--
-- 8. Product-level analysis should preserve product IDs
--    while accounting for the six identified ID-to-name
--    inconsistencies.
--
-- =========================================================

-- END OF QUERY 14P
