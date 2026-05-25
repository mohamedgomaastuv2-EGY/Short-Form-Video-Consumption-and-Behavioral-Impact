INSERT INTO silver.reels_survey
SELECT

    -- Demographics
    LTRIM(RTRIM(age_group)) AS age_group,
    LTRIM(RTRIM(gender)) AS gender,
    LTRIM(RTRIM(region)) AS region,
    LTRIM(RTRIM(marital_status)) AS marital_status,
    LTRIM(RTRIM(occupation)) AS occupation,
    LTRIM(RTRIM(education_level)) AS education_level,

    -- Usage behavior
    LTRIM(RTRIM(daily_watch_hours)) AS daily_watch_hours,
    LTRIM(RTRIM(peak_usage_time)) AS peak_usage_time,
    LTRIM(RTRIM(daily_opens)) AS daily_opens,
    LTRIM(RTRIM(voice_msg_behavior)) AS voice_msg_behavior,
    LTRIM(RTRIM(usage_duration_since)) AS usage_duration_since,
    LTRIM(RTRIM(content_relevance)) AS content_relevance,
    LTRIM(RTRIM(difficulty_closing_app)) AS difficulty_closing_app,
    LTRIM(RTRIM(productivity_impact)) AS productivity_impact,
LTRIM(RTRIM(sleep_impact)) AS sleep_impact,
    LTRIM(RTRIM(feeling_after_closing)) AS feeling_after_closing,
    LTRIM(RTRIM(watching_companion)) AS watching_companion,
    LTRIM(RTRIM(behavior_while_watching)) AS behavior_while_watching,
    LTRIM(RTRIM(phone_during_family)) AS phone_during_family,
    LTRIM(RTRIM(family_opinion)) AS family_opinion,
    LTRIM(RTRIM(reason_for_watching)) AS reason_for_watching,
    LTRIM(RTRIM(social_media_without_reels)) AS social_media_without_reels,
    LTRIM(RTRIM(purchased_from_video)) AS purchased_from_video,
    LTRIM(RTRIM(purchase_reason)) AS purchase_reason,
    LTRIM(RTRIM(purchase_influence_level)) AS purchase_influence_level,
    LTRIM(RTRIM(rewatched_before_purchase)) AS rewatched_before_purchase,
 /*
    ====================================================
    watch_intensity_score Logic
    ====================================================
    Heavy usage indicators increase score.
    Final score matches the generated Reels.xlsx file.
    */

    (
        CASE
            WHEN daily_watch_hours = '3+ hrs' THEN 2
            WHEN daily_watch_hours = '1-2 hrs' THEN 1
            ELSE 0
        END

        +

        CASE
            WHEN daily_opens = 'All day (lost count)' THEN 2
            WHEN daily_opens = '6-10 times/day' THEN 1
  ELSE 0
        END

        +

        CASE
            WHEN difficulty_closing_app IN (
                'Yes frequently',
                'Always postpone'
            ) THEN 1
            ELSE 0
        END
    ) AS watch_intensity_score,

    /*
    ====================================================
    user_segment Classification
    ====================================================
    */
 CASE
        WHEN (
            CASE
                WHEN daily_watch_hours = '3+ hrs' THEN 2
                WHEN daily_watch_hours = '1-2 hrs' THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN daily_opens = 'All day (lost count)' THEN 2
                WHEN daily_opens = '6-10 times/day' THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN difficulty_closing_app IN ('Yes frequently',
                    'Always postpone'
                ) THEN 1
                ELSE 0
            END
        ) >= 5
        THEN 'Heavy User'

        WHEN (
            CASE
                WHEN daily_watch_hours = '3+ hrs' THEN 2
                WHEN daily_watch_hours = '1-2 hrs' THEN 1
                ELSE 0
            END
  +

            CASE
                WHEN daily_opens = 'All day (lost count)' THEN 2
                WHEN daily_opens = '6-10 times/day' THEN 1
                ELSE 0
            END

            +

            CASE
                WHEN difficulty_closing_app IN (
                    'Yes frequently',
                    'Always postpone'
                ) THEN 1
                ELSE 0
            END
        ) >= 3
        THEN 'Moderate User'
 ELSE 'Light User'
    END AS user_segment,

    /*
    ====================================================
    Count number of selected content categories
    Example:
    'Sports, Comedy, Educational' = 3
    ====================================================
    */

    LEN(content_type)
    - LEN(REPLACE(content_type, ',', ''))
    + 1 AS content_count,

    /*
    ====================================================
    Create Sequential User ID
    ====================================================
    */

    ROW_NUMBER() OVER (ORDER BY timestamp) - 1 AS user_id

FROM bronze.reels_survey;
GO