-- ============================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- FILE: 02_data_cleaning.sql
-- TOOL: Google BigQuery
-- DATASET: GA4 Public Ecommerce Sample
-- PERIOD: November 2020 - January 2021
-- ============================================================

-- OBJECTIVE:
-- Clean and standardise raw GA4 ecommerce event data.
-- Extract relevant event parameters and prepare
-- structured fields for downstream analysis.

-- ============================================================
-- QUERY 01: Extract and Standardise Event-Level Data
-- ============================================================

SELECT

    -- Event identification
    event_name,
    event_date,

    -- Convert microsecond timestamp into standard timestamp
    TIMESTAMP_MICROS(event_timestamp) AS event_timestamp,

    -- User identification
    user_pseudo_id,

    -- Session identification
    (
        SELECT value.int_value
        FROM UNNEST(event_params)
        WHERE key = 'ga_session_id'
    ) AS session_id,

    -- Page information
    (
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'page_location'
    ) AS page_location,

    -- Transaction identification
    (
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'transaction_id'
    ) AS transaction_id,

    -- Purchase value standardisation
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

    -- Currency information
    (
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'currency'
    ) AS currency

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';

-- ============================================================
-- DATA QUALITY CONSIDERATIONS
-- ============================================================

-- 1. Missing user identifiers must be handled carefully.
-- 2. Transaction IDs may be missing or repeated.
-- 3. Purchase values may be NULL.
-- 4. Event timestamps are converted from microseconds.
-- 5. Currency values should be checked before revenue aggregation.
-- 6. Repeated transaction IDs must be investigated before
--    deduplication to avoid removing legitimate records.
