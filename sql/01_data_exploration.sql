
-- PROJECT: Consumer App Growth & Product Analytics
-- SQL FILE 01: Initial Data Exploration
-- TOOL: Google BigQuery

-- OBJECTIVE:
-- Understand the overall scale of user activity
-- across the GA4 ecommerce dataset.

SELECT
    COUNT(*) AS total_events,

    COUNT(DISTINCT user_pseudo_id)
        AS unique_users,

    COUNT(DISTINCT event_date)
        AS active_days

FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20210131';
