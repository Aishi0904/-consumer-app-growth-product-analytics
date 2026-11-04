
-- ============================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 11: Monthly New vs Returning Users
-- TOOL: Google BigQuery
-- DATASET: GA4 Public Ecommerce Sample
-- PERIOD: November 2020 - January 2021
-- ============================================================

-- OBJECTIVE:
-- Identify monthly active users and distinguish between
-- newly observed users and returning users.

WITH user_activity AS (

    SELECT
        user_pseudo_id,
        DATE(TIMESTAMP_MICROS(event_timestamp)) AS activity_date

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
        AND user_pseudo_id IS NOT NULL
),

first_activity AS (

    SELECT
        user_pseudo_id,
        MIN(activity_date) AS first_seen_date

    FROM user_activity

    GROUP BY user_pseudo_id
),

monthly_activity AS (

    SELECT DISTINCT
        user_pseudo_id,
        DATE_TRUNC(activity_date, MONTH) AS activity_month

    FROM user_activity
)

SELECT

    FORMAT_DATE('%Y-%m', ma.activity_month) AS activity_month,

    COUNT(DISTINCT ma.user_pseudo_id)
        AS monthly_active_users,

    COUNT(DISTINCT IF(
        DATE_TRUNC(fa.first_seen_date, MONTH) = ma.activity_month,
        ma.user_pseudo_id,
        NULL
    )) AS new_users,

    COUNT(DISTINCT IF(
        fa.first_seen_date < ma.activity_month,
        ma.user_pseudo_id,
        NULL
    )) AS returning_users

FROM monthly_activity ma

JOIN first_activity fa
    ON ma.user_pseudo_id = fa.user_pseudo_id

GROUP BY ma.activity_month

ORDER BY ma.activity_month;

-- ============================================================
-- END OF QUERY 11
-- ============================================================


-- ============================================================
-- BUSINESS INSIGHTS: MONTHLY USER ACTIVITY
-- ============================================================

-- 1. Monthly active users increased by approximately
--    31.34% from November to December 2020.

-- 2. New users represented the majority of monthly
--    active users across the observation period.

-- 3. Returning users declined from 4,651 in December
--    to 3,721 in January 2021.

-- 4. Further cohort analysis is required to understand
--    user retention patterns.

-- NOTE:
-- New users represent first observed users within
-- the available dataset period.


-- ============================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 12: Monthly Cohort Retention Analysis
-- TOOL: Google BigQuery
-- DATASET: GA4 Public Ecommerce Sample
-- PERIOD: November 2020 - January 2021
-- ============================================================

-- OBJECTIVE:
-- Analyse customer retention by acquisition cohort.
-- Measure how many users return in subsequent months.

WITH user_activity AS (

    SELECT DISTINCT
        user_pseudo_id,

        DATE(TIMESTAMP_MICROS(event_timestamp))
            AS activity_date,

        DATE_TRUNC(
            DATE(TIMESTAMP_MICROS(event_timestamp)),
            MONTH
        ) AS activity_month

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
        AND user_pseudo_id IS NOT NULL
),

first_activity AS (

    SELECT
        user_pseudo_id,

        DATE_TRUNC(
            MIN(activity_date),
            MONTH
        ) AS cohort_month

    FROM user_activity

    GROUP BY user_pseudo_id
),

cohort_data AS (

    SELECT
        fa.cohort_month,
        ua.activity_month,
        ua.user_pseudo_id,

        DATE_DIFF(
            ua.activity_month,
            fa.cohort_month,
            MONTH
        ) AS month_number

    FROM user_activity ua

    JOIN first_activity fa
        ON ua.user_pseudo_id = fa.user_pseudo_id
),

cohort_sizes AS (

    SELECT
        cohort_month,

        COUNT(DISTINCT user_pseudo_id)
            AS cohort_size

    FROM first_activity

    GROUP BY cohort_month
),

retention_metrics AS (

    SELECT
        cohort_month,
        month_number,

        COUNT(DISTINCT user_pseudo_id)
            AS retained_users

    FROM cohort_data

    GROUP BY
        cohort_month,
        month_number
)

SELECT
    FORMAT_DATE('%Y-%m', rm.cohort_month)
        AS cohort_month,

    rm.month_number,

    cs.cohort_size,

    rm.retained_users,

    ROUND(
        SAFE_DIVIDE(
            rm.retained_users,
            cs.cohort_size
        ) * 100,
        2
    ) AS retention_rate_pct

FROM retention_metrics rm

JOIN cohort_sizes cs
    ON rm.cohort_month = cs.cohort_month

ORDER BY
    rm.cohort_month,
    rm.month_number;

-- END OF COHORT RETENTION ANALYSIS

-- ============================================================
-- BUSINESS INSIGHTS: COHORT RETENTION ANALYSIS
-- ============================================================

-- 1. November 2020 cohort retention declined to
--    5.86% in December 2020.

-- 2. November cohort retention further declined
--    to 1.52% by January 2021.

-- 3. December 2020 cohort recorded 2.53%
--    retention in January 2021.

-- 4. The analysis indicates weak repeat engagement
--    despite substantial initial user acquisition.

-- 5. January cohort retention cannot be evaluated
--    beyond Month 0 due to the observation window.

-- BUSINESS RECOMMENDATIONS:
-- 1. Introduce personalised retention campaigns.
-- 2. Improve post-purchase engagement.
-- 3. Investigate reasons for declining repeat activity.
-- 4. Monitor cohort retention over longer periods.

-- NOTE:
-- Retention is measured using first-observed activity
-- within the available dataset period.


-- ============================================================
-- PROJECT: Consumer App Growth & Product Analytics
-- QUERY 13: Returning User Behaviour Analysis
-- TOOL: Google BigQuery
-- DATASET: GA4 Public Ecommerce Sample
-- PERIOD: November 2020 - January 2021
-- ============================================================

-- OBJECTIVE:
-- Analyse how frequently users return to the platform.
-- Measure the number of days between consecutive
-- active days for each user.

WITH daily_activity AS (

    SELECT DISTINCT
        user_pseudo_id,

        DATE(TIMESTAMP_MICROS(event_timestamp))
            AS activity_date

    FROM
        `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

    WHERE
        _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
        AND user_pseudo_id IS NOT NULL
),

user_activity_gaps AS (

    SELECT
        user_pseudo_id,
        activity_date,

        LAG(activity_date) OVER (
            PARTITION BY user_pseudo_id
            ORDER BY activity_date
        ) AS previous_activity_date

    FROM daily_activity
),

return_intervals AS (

    SELECT
        user_pseudo_id,
        activity_date,
        previous_activity_date,

        DATE_DIFF(
            activity_date,
            previous_activity_date,
            DAY
        ) AS days_between_visits

    FROM user_activity_gaps

    WHERE previous_activity_date IS NOT NULL
),

gap_categories AS (

    SELECT
        user_pseudo_id,
        days_between_visits,

        CASE
            WHEN days_between_visits BETWEEN 1 AND 7
                THEN '1-7 Days'

            WHEN days_between_visits BETWEEN 8 AND 30
                THEN '8-30 Days'

            ELSE '31+ Days'
        END AS return_frequency

    FROM return_intervals
)

SELECT
    return_frequency,

    COUNT(*) AS total_return_intervals,

    COUNT(DISTINCT user_pseudo_id)
        AS unique_returning_users,

    ROUND(
        AVG(days_between_visits),
        2
    ) AS average_days_between_visits,

    APPROX_QUANTILES(
        days_between_visits,
        100
    )[OFFSET(50)] AS median_days_between_visits

FROM gap_categories

GROUP BY return_frequency

ORDER BY
    CASE return_frequency
        WHEN '1-7 Days' THEN 1
        WHEN '8-30 Days' THEN 2
        ELSE 3
    END;

-- END OF RETURNING USER BEHAVIOUR ANALYSIS

-- ============================================================
-- BUSINESS INSIGHTS: RETURNING USER BEHAVIOUR
-- ============================================================

-- 1. Approximately 74.73% of observed return intervals
--    fall within the 1-7 day category.

-- 2. Approximately 21.38% of return intervals
--    fall within the 8-30 day category.

-- 3. Approximately 3.89% of return intervals
--    fall within the 31+ day category.

-- 4. Frequent return intervals have an average gap
--    of 2.36 days and a median of 1 day.

-- 5. Infrequent return intervals have an average
--    gap of 43.50 days.

-- BUSINESS RECOMMENDATIONS:
-- 1. Encourage repeat engagement through personalised
--    recommendations.
-- 2. Introduce targeted re-engagement campaigns.
-- 3. Investigate behavioural differences between
--    frequent and infrequent users.
-- 4. Monitor changes in return frequency over time.

-- NOTE:
-- Return intervals measure gaps between consecutive
-- active calendar days, not individual sessions.
-- Users may appear in multiple frequency categories.
