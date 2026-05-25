TRUNCATE TABLE silver.platform_survey;
WITH bronze_numbered AS (

    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY timestamp) - 1 AS user_id
    FROM bronze.reels_survey

)

INSERT INTO silver.platform_survey
SELECT
    b.user_id,

    CASE
        WHEN b.primary_platform LIKE '%TikTok%' THEN 'TikTok'
        WHEN b.primary_platform LIKE '%Instagram%' THEN 'Instagram Reels'
        WHEN b.primary_platform LIKE '%Facebook%' THEN 'Facebook Reels'
        WHEN b.primary_platform LIKE '%YouTube%' THEN 'YouTube Shorts'
        ELSE 'Other'
    END AS primary_platform,

    LTRIM(RTRIM(value)) AS content_type

FROM bronze_numbered b

CROSS APPLY STRING_SPLIT(

    REPLACE(
        REPLACE(
            REPLACE(
                REPLACE(b.content_type, '،', ','),
            ';', ','),
        '/', ','),
    CHAR(10), ','),

',');