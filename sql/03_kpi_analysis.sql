-- ============================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- FILE: 03_kpi_analysis.sql
-- TOOL: Google BigQuery
-- DATASET: GA4 Public Ecommerce Sample
-- PERIOD: November 2020 - January 2021
-- ============================================================

-- OBJECTIVE:
-- Calculate key business performance indicators (KPIs)
-- to evaluate user activity, engagement and revenue.

-- ============================================================
-- QUERY 01: Overall Business Performance KPIs
-- ============================================================

WITH base_events AS (

    SELECT
        event_name,
        event_date,
        user_pseudo_id,

        (
            SELECT value.int_value
            FROM UNNEST(event_params)
            WHERE key = 'ga_session_id'
        ) AS session_id,

        (
            SELECT value.string_value
            FROM UNNEST(event_params)
            WHERE key = 'transaction_id'
        ) AS transaction_id,

        (
            SELECT COALESCE(
                value.double_value,
                CAST(value.float_value AS FLOAT64),
                CAST(value.int_value AS FLOAT64),
                SAFE_CAST(value.string_value AS FLOAT64)
            )
            FROM UNNEST(event_params)
            WHERE key = 'value'
        ) AS purchase_value,

        (
            SELECT value.string_value
            FROM UNNEST(event_params)
            WHERE key = 'currency'
        ) AS currency

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
),

-- ============================================================
-- QUERY 02: Session and User Metrics
-- ============================================================

user_metrics AS (

    SELECT
        COUNT(*) AS total_events,

        COUNT(DISTINCT user_pseudo_id) AS total_users,

        COUNT(DISTINCT
            CONCAT(
                user_pseudo_id,
                '-',
                CAST(session_id AS STRING)
            )
        ) AS total_sessions

    FROM base_events
),

-- ============================================================
-- QUERY 03: Purchase and Revenue Metrics
-- ============================================================

purchase_records AS (

    SELECT
        transaction_id,
        user_pseudo_id,
        purchase_value,
        currency,
        event_date

    FROM base_events

    WHERE event_name = 'purchase'
),

-- Keep one record per non-null transaction ID.
-- This avoids counting repeated transaction IDs
-- multiple times in transaction-level revenue.

deduplicated_purchases AS (

    SELECT *

    FROM purchase_records

    WHERE transaction_id IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY transaction_id
        ORDER BY event_date
    ) = 1
),

purchase_metrics AS (

    SELECT

        COUNT(*) AS purchase_events,

        COUNT(DISTINCT user_pseudo_id)
            AS purchasing_users,

        COUNT(DISTINCT transaction_id)
            AS unique_transactions,

        COUNTIF(transaction_id IS NULL)
            AS purchases_with_missing_transaction_id

    FROM purchase_records
),

revenue_metrics AS (

    SELECT

        COUNTIF(purchase_value IS NOT NULL)
            AS transactions_with_value,

        COUNTIF(purchase_value IS NULL)
            AS transactions_with_missing_value,

        COUNT(DISTINCT currency)
            AS distinct_currencies,

        SUM(purchase_value)
            AS total_revenue

    FROM deduplicated_purchases
)

-- ============================================================
-- QUERY 04: Final KPI Dashboard Metrics
-- ============================================================

SELECT

    u.total_events,
    u.total_users,
    u.total_sessions,

    p.purchase_events,
    p.purchasing_users,
    p.unique_transactions,

    p.purchases_with_missing_transaction_id,

    ROUND(
        SAFE_DIVIDE(
            p.purchasing_users,
            u.total_users
        ) * 100, 2
    ) AS purchase_conversion_rate_pct,

    r.transactions_with_value,
    r.transactions_with_missing_value,
    r.distinct_currencies,

    ROUND(r.total_revenue, 2)
        AS total_revenue,

    ROUND(
        SAFE_DIVIDE(
            r.total_revenue,
            p.unique_transactions
        ), 2
    ) AS average_order_value

FROM user_metrics u

CROSS JOIN purchase_metrics p

CROSS JOIN revenue_metrics r;
