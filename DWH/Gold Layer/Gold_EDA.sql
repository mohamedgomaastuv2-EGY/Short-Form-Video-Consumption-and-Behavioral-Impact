/* ============================================================
   EXPLORATORY DATA ANALYSIS  (EDA)
   Database  : Reels_Pulse_Warehouse
   Layer     : Gold
   Topic     : Short-Form Video (Reels) Behaviour Study
   Audience  : Presentation
   ============================================================ */

USE Reels_Pulse_Warehouse;
GO


/* ============================================================
   SECTION 1  |  DATASET OVERVIEW
   How many records do we have across all tables?
   ============================================================ */

-- Total row count per table
SELECT 'DIM_RESPONDENT' AS table_name, COUNT(*) AS total_rows FROM gold.DIM_RESPONDENT
UNION ALL
SELECT 'DIM_PLATFORM',                 COUNT(*)               FROM gold.DIM_PLATFORM
UNION ALL
SELECT 'DIM_CONTENT',                  COUNT(*)               FROM gold.DIM_CONTENT
UNION ALL
SELECT 'DIM_BEHAVIOR',                 COUNT(*)               FROM gold.DIM_BEHAVIOR
UNION ALL
SELECT 'FACT_RESPONSE',                COUNT(*)               FROM gold.FACT_RESPONSE;
GO


/* ============================================================
   SECTION 2  |  WHO ARE THE RESPONDENTS?
   Demographic breakdown of all survey participants
   ============================================================ */

-- 2.1  How many respondents per Age Group?
SELECT
    age_group,
    COUNT(*)                                    AS respondent_count,
    -- percentage out of total respondents
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_RESPONDENT
GROUP BY age_group
ORDER BY respondent_count DESC;
GO

-- 2.2  Gender split
SELECT
    gender,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_RESPONDENT
GROUP BY gender
ORDER BY respondent_count DESC;
GO

-- 2.3  Where are they from? (Top regions)
SELECT
    region,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_RESPONDENT
GROUP BY region
ORDER BY respondent_count DESC;
GO

-- 2.4  What do they do? (Occupation breakdown)
SELECT
    occupation,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_RESPONDENT
GROUP BY occupation
ORDER BY respondent_count DESC;
GO

-- 2.5  Education level breakdown
SELECT
    education_level,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_RESPONDENT
GROUP BY education_level
ORDER BY respondent_count DESC;
GO

-- 2.6  User Segment — Light / Moderate / Heavy users
SELECT
    user_segment,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_RESPONDENT
GROUP BY user_segment
ORDER BY respondent_count DESC;
GO


/* ============================================================
   SECTION 3  |  PLATFORM ANALYSIS
   Which platforms are most used?
   ============================================================ */

-- 3.1  How many respondents use each platform?
SELECT
    dp.platform_name,
    dp.platform_category,
    COUNT(DISTINCT f.respondent_id)             AS unique_users,
    CAST(COUNT(DISTINCT f.respondent_id) * 100.0
         / SUM(COUNT(DISTINCT f.respondent_id)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_PLATFORM   dp ON dp.platform_id = f.platform_id
GROUP BY dp.platform_name, dp.platform_category
ORDER BY unique_users DESC;
GO

-- 3.2  Average watch intensity score per platform
--      (score 1-5: higher = more addictive usage)
SELECT
    dp.platform_name,
    ROUND(AVG(CAST(f.watch_intensity_score AS FLOAT)), 2)   AS avg_watch_intensity,
    COUNT(DISTINCT f.respondent_id)                         AS unique_users
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_PLATFORM   dp ON dp.platform_id = f.platform_id
GROUP BY dp.platform_name
ORDER BY avg_watch_intensity DESC;
GO

-- 3.3  Platform usage by user segment
--      Who uses which platform — Heavy, Moderate or Light users?
SELECT
    dp.platform_name,
    dr.user_segment,
    COUNT(DISTINCT f.respondent_id)             AS unique_users
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_PLATFORM   dp ON dp.platform_id   = f.platform_id
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
GROUP BY dp.platform_name, dr.user_segment
ORDER BY dp.platform_name, unique_users DESC;
GO


/* ============================================================
   SECTION 4  |  CONTENT ANALYSIS
   What type of content do people watch most?
   ============================================================ */

-- 4.1  Most popular content types overall
SELECT
    dc.content_type,
    COUNT(*)                                    AS total_views,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.FACT_RESPONSE      f
INNER JOIN gold.DIM_CONTENT  dc ON dc.content_id = f.content_id
GROUP BY dc.content_type
ORDER BY total_views DESC;
GO

-- 4.2  Content preferences by gender
SELECT
    dr.gender,
    dc.content_type,
    COUNT(*)                                    AS total_views
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_CONTENT    dc ON dc.content_id    = f.content_id
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
GROUP BY dr.gender, dc.content_type
ORDER BY dr.gender, total_views DESC;
GO

-- 4.3  Content preferences by age group
SELECT
    dr.age_group,
    dc.content_type,
    COUNT(*)                                    AS total_views
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_CONTENT    dc ON dc.content_id    = f.content_id
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
GROUP BY dr.age_group, dc.content_type
ORDER BY dr.age_group, total_views DESC;
GO

-- 4.4  Average number of content types per respondent
--      (how diverse is their content consumption?)
SELECT
    ROUND(AVG(CAST(f.content_count AS FLOAT)), 2)   AS avg_content_types_per_user,
    MIN(f.content_count)                             AS min_content_types,
    MAX(f.content_count)                             AS max_content_types
FROM gold.FACT_RESPONSE f
WHERE f.content_count IS NOT NULL;
GO


/* ============================================================
   SECTION 5  |  BEHAVIOUR ANALYSIS
   How do people actually use these platforms?
   ============================================================ */

-- 5.1  Daily watch hours distribution
--      How long do people spend watching per day?
SELECT
    db.daily_watch_hours,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_BEHAVIOR db
GROUP BY db.daily_watch_hours
ORDER BY respondent_count DESC;
GO

-- 5.2  How often do they open the app per day?
SELECT
    db.daily_opens,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_BEHAVIOR db
GROUP BY db.daily_opens
ORDER BY respondent_count DESC;
GO

-- 5.3  When do they peak? (most common usage time)
SELECT
    db.peak_usage_time,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_BEHAVIOR db
GROUP BY db.peak_usage_time
ORDER BY respondent_count DESC;
GO

-- 5.4  Sleep impact — are reels affecting sleep?
SELECT
    db.sleep_impact,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_BEHAVIOR db
GROUP BY db.sleep_impact
ORDER BY respondent_count DESC;
GO

-- 5.5  Productivity impact — are reels affecting work/study?
SELECT
    db.productivity_impact,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_BEHAVIOR db
GROUP BY db.productivity_impact
ORDER BY respondent_count DESC;
GO

-- 5.6  How do people feel after closing the app?
SELECT
    db.feeling_after_closing,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_BEHAVIOR db
GROUP BY db.feeling_after_closing
ORDER BY respondent_count DESC;
GO

-- 5.7  Can they stop? (difficulty closing the app)
SELECT
    db.difficulty_closing_app,
    COUNT(*)                                    AS respondent_count,
    CAST(COUNT(*) * 100.0
         / SUM(COUNT(*)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.DIM_BEHAVIOR db
GROUP BY db.difficulty_closing_app
ORDER BY respondent_count DESC;
GO


/* ============================================================
   SECTION 6  |  WATCH INTENSITY SCORE
   Score 1-5 assigned to each respondent.
   Higher = heavier / more addictive usage pattern.
   ============================================================ */

-- 6.1  Score distribution across all respondents
SELECT
    watch_intensity_score                       AS score,
    COUNT(DISTINCT respondent_id)               AS respondent_count,
    CAST(COUNT(DISTINCT respondent_id) * 100.0
         / SUM(COUNT(DISTINCT respondent_id)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.FACT_RESPONSE
WHERE watch_intensity_score IS NOT NULL
GROUP BY watch_intensity_score
ORDER BY score;
GO

-- 6.2  Average score by age group
SELECT
    dr.age_group,
    ROUND(AVG(CAST(f.watch_intensity_score AS FLOAT)), 2)   AS avg_score
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
WHERE f.watch_intensity_score IS NOT NULL
GROUP BY dr.age_group
ORDER BY avg_score DESC;
GO

-- 6.3  Average score by gender
SELECT
    dr.gender,
    ROUND(AVG(CAST(f.watch_intensity_score AS FLOAT)), 2)   AS avg_score
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
WHERE f.watch_intensity_score IS NOT NULL
GROUP BY dr.gender
ORDER BY avg_score DESC;
GO

-- 6.4  Average score by user segment
SELECT
    dr.user_segment,
    ROUND(AVG(CAST(f.watch_intensity_score AS FLOAT)), 2)   AS avg_score,
    COUNT(DISTINCT f.respondent_id)                         AS respondent_count
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
WHERE f.watch_intensity_score IS NOT NULL
GROUP BY dr.user_segment
ORDER BY avg_score DESC;
GO


/* ============================================================
   SECTION 7  |  PURCHASING BEHAVIOUR
   Did watching reels lead to actual purchases?
   ============================================================ */

-- 7.1  Did respondents ever buy something from a video?
SELECT
    purchased_from_video,
    COUNT(DISTINCT respondent_id)               AS respondent_count,
    CAST(COUNT(DISTINCT respondent_id) * 100.0
         / SUM(COUNT(DISTINCT respondent_id)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.FACT_RESPONSE
WHERE purchased_from_video IS NOT NULL
GROUP BY purchased_from_video
ORDER BY respondent_count DESC;
GO

-- 7.2  How much did the video influence their purchase decision?
SELECT
    purchase_influence_level,
    COUNT(DISTINCT respondent_id)               AS respondent_count,
    CAST(COUNT(DISTINCT respondent_id) * 100.0
         / SUM(COUNT(DISTINCT respondent_id)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.FACT_RESPONSE
WHERE purchase_influence_level IS NOT NULL
GROUP BY purchase_influence_level
ORDER BY respondent_count DESC;
GO

-- 7.3  Purchase behaviour by age group
--      Which age group is most influenced to buy?
SELECT
    dr.age_group,
    f.purchased_from_video,
    COUNT(DISTINCT f.respondent_id)             AS respondent_count
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
WHERE f.purchased_from_video IS NOT NULL
GROUP BY dr.age_group, f.purchased_from_video
ORDER BY dr.age_group, respondent_count DESC;
GO


/* ============================================================
   SECTION 8  |  KEY CROSS ANALYSIS
   Combining dimensions to find meaningful patterns
   ============================================================ */

-- 8.1  Heavy users — what platform + content do they prefer?
SELECT
    dp.platform_name,
    dc.content_type,
    COUNT(DISTINCT f.respondent_id)             AS heavy_users
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
INNER JOIN gold.DIM_PLATFORM   dp ON dp.platform_id   = f.platform_id
INNER JOIN gold.DIM_CONTENT    dc ON dc.content_id    = f.content_id
WHERE dr.user_segment = 'Heavy User'            -- filter to heavy users only
GROUP BY dp.platform_name, dc.content_type
ORDER BY heavy_users DESC;
GO

-- 8.2  Does more watch time = worse sleep?
SELECT
    db.daily_watch_hours,
    db.sleep_impact,
    COUNT(*)                                    AS respondent_count
FROM gold.FACT_RESPONSE      f
INNER JOIN gold.DIM_BEHAVIOR db ON db.behavior_id = f.behavior_id
GROUP BY db.daily_watch_hours, db.sleep_impact
ORDER BY db.daily_watch_hours, respondent_count DESC;
GO

-- 8.3  Reason for watching vs feeling after closing
--      Do people who watch for mood feel better or worse after?
SELECT
    f.reason_for_watching,
    db.feeling_after_closing,
    COUNT(DISTINCT f.respondent_id)             AS respondent_count
FROM gold.FACT_RESPONSE      f
INNER JOIN gold.DIM_BEHAVIOR db ON db.behavior_id = f.behavior_id
WHERE f.reason_for_watching     IS NOT NULL
  AND db.feeling_after_closing  IS NOT NULL
GROUP BY f.reason_for_watching, db.feeling_after_closing
ORDER BY f.reason_for_watching, respondent_count DESC;
GO

-- 8.4  Would they use social media less if reels didn't exist?
SELECT
    social_media_without_reels,
    COUNT(DISTINCT respondent_id)               AS respondent_count,
    CAST(COUNT(DISTINCT respondent_id) * 100.0
         / SUM(COUNT(DISTINCT respondent_id)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.FACT_RESPONSE
WHERE social_media_without_reels IS NOT NULL
GROUP BY social_media_without_reels
ORDER BY respondent_count DESC;
GO

-- 8.5  Content relevance — how well does the algorithm know them?
SELECT
    content_relevance,
    COUNT(DISTINCT respondent_id)               AS respondent_count,
    CAST(COUNT(DISTINCT respondent_id) * 100.0
         / SUM(COUNT(DISTINCT respondent_id)) OVER ()
         AS DECIMAL(5,2))                       AS pct
FROM gold.FACT_RESPONSE
WHERE content_relevance IS NOT NULL
GROUP BY content_relevance
ORDER BY respondent_count DESC;
GO
