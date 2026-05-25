/* ============================================================
   GOLD LAYER  –  Full Clean Rebuild
   Database   : Reels_Pulse_Warehouse
   Change     : Remove all SK / BK naming conventions.
                Tables use simple clean PK & FK column names only.

   Clean Key Mapping:
     DIM_RESPONDENT  PK → respondent_id
     DIM_PLATFORM    PK → platform_id
     DIM_CONTENT     PK → content_id
     DIM_BEHAVIOR    PK → behavior_id
     FACT_RESPONSE   PK → response_id
                     FK → respondent_id, platform_id,
                          content_id,   behavior_id
   ============================================================ */

USE Reels_Pulse_Warehouse;
GO


/* ─────────────────────────────────────────────────────────────
   STEP 1  –  Drop existing gold tables (reverse FK order)
   ───────────────────────────────────────────────────────────── */
IF OBJECT_ID('gold.FACT_RESPONSE',  'U') IS NOT NULL DROP TABLE gold.FACT_RESPONSE;
IF OBJECT_ID('gold.DIM_BEHAVIOR',   'U') IS NOT NULL DROP TABLE gold.DIM_BEHAVIOR;
IF OBJECT_ID('gold.DIM_CONTENT',    'U') IS NOT NULL DROP TABLE gold.DIM_CONTENT;
IF OBJECT_ID('gold.DIM_PLATFORM',   'U') IS NOT NULL DROP TABLE gold.DIM_PLATFORM;
IF OBJECT_ID('gold.DIM_RESPONDENT', 'U') IS NOT NULL DROP TABLE gold.DIM_RESPONDENT;
GO

/* ─────────────────────────────────────────────────────────────
   STEP 2  –  Create gold schema if it doesn't exist
   ───────────────────────────────────────────────────────────── */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO


/* ─────────────────────────────────────────────────────────────
   STEP 3  –  Create Dimension Tables (clean PK only)
   ───────────────────────────────────────────────────────────── */

/* ── DIM_RESPONDENT ─────────────────────────────────────────── */
CREATE TABLE gold.DIM_RESPONDENT (
    respondent_id       INT             NOT NULL,
    age_group           NVARCHAR(20)    NOT NULL,
    gender              NVARCHAR(20)    NOT NULL,
    region              NVARCHAR(100)   NOT NULL,
    marital_status      NVARCHAR(50)    NOT NULL,
    occupation          NVARCHAR(100)   NOT NULL,
    education_level     NVARCHAR(100)   NOT NULL,
    user_segment        NVARCHAR(50)    NOT NULL,
    etl_load_date       DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DIM_RESPONDENT PRIMARY KEY (respondent_id)
);
GO

/* ── DIM_PLATFORM ───────────────────────────────────────────── */
CREATE TABLE gold.DIM_PLATFORM (
    platform_id         INT             NOT NULL IDENTITY(1,1),
    platform_name       NVARCHAR(100)   NOT NULL,
    platform_category   NVARCHAR(50)    NOT NULL,
    etl_load_date       DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DIM_PLATFORM      PRIMARY KEY (platform_id),
    CONSTRAINT UQ_DIM_PLATFORM_name UNIQUE      (platform_name)
);
GO

/* ── DIM_CONTENT ────────────────────────────────────────────── */
CREATE TABLE gold.DIM_CONTENT (
    content_id          INT             NOT NULL IDENTITY(1,1),
    content_type        NVARCHAR(200)   NOT NULL,
    etl_load_date       DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DIM_CONTENT      PRIMARY KEY (content_id),
    CONSTRAINT UQ_DIM_CONTENT_type UNIQUE      (content_type)
);
GO

/* ── DIM_BEHAVIOR ───────────────────────────────────────────── */
CREATE TABLE gold.DIM_BEHAVIOR (
    behavior_id             INT             NOT NULL,
    daily_watch_hours       NVARCHAR(50)    NOT NULL,
    daily_opens             NVARCHAR(50)    NOT NULL,
    peak_usage_time         NVARCHAR(100)   NOT NULL,
    usage_duration_since    NVARCHAR(50)    NOT NULL,
    sleep_impact            NVARCHAR(100)   NOT NULL,
    productivity_impact     NVARCHAR(100)   NOT NULL,
    difficulty_closing_app  NVARCHAR(100)   NOT NULL,
    feeling_after_closing   NVARCHAR(100)   NOT NULL,
    etl_load_date           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DIM_BEHAVIOR PRIMARY KEY (behavior_id)
);
GO


/* ─────────────────────────────────────────────────────────────
   STEP 4  –  Create Fact Table (clean PK & FK only)
   ───────────────────────────────────────────────────────────── */
CREATE TABLE gold.FACT_RESPONSE (
    response_id                 INT             NOT NULL IDENTITY(1,1),

    -- Foreign Keys (clean names, no _Fk suffix)
    respondent_id               INT             NOT NULL,
    platform_id                 INT             NOT NULL,
    content_id                  INT             NOT NULL,
    behavior_id                 INT             NOT NULL,

    -- Measures
    watch_intensity_score       TINYINT         NULL,
    content_count               TINYINT         NULL,
    purchased_from_video        NVARCHAR(100)   NULL,
    purchase_influence_level    NVARCHAR(100)   NULL,
    rewatched_before_purchase   NVARCHAR(50)    NULL,
    social_media_without_reels  NVARCHAR(100)   NULL,
    reason_for_watching         NVARCHAR(100)   NULL,
    content_relevance           NVARCHAR(100)   NULL,
    etl_load_date               DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_FACT_RESPONSE   PRIMARY KEY (response_id),
    CONSTRAINT FK_FACT_RESPONDENT FOREIGN KEY (respondent_id) REFERENCES gold.DIM_RESPONDENT (respondent_id),
    CONSTRAINT FK_FACT_PLATFORM   FOREIGN KEY (platform_id)   REFERENCES gold.DIM_PLATFORM   (platform_id),
    CONSTRAINT FK_FACT_CONTENT    FOREIGN KEY (content_id)    REFERENCES gold.DIM_CONTENT    (content_id),
    CONSTRAINT FK_FACT_BEHAVIOR   FOREIGN KEY (behavior_id)   REFERENCES gold.DIM_BEHAVIOR   (behavior_id)
);
GO


/* ─────────────────────────────────────────────────────────────
   STEP 5  –  Load DIM_RESPONDENT
   Source : silver.reels_survey
   ───────────────────────────────────────────────────────────── */
INSERT INTO gold.DIM_RESPONDENT (
    respondent_id,
    age_group,
    gender,
    region,
    marital_status,
    occupation,
    education_level,
    user_segment
)
SELECT DISTINCT
    r.user_id,
    LTRIM(RTRIM(r.age_group)),
    LTRIM(RTRIM(r.gender)),
    LTRIM(RTRIM(r.region)),
    LTRIM(RTRIM(r.marital_status)),
    LTRIM(RTRIM(r.occupation)),
    LTRIM(RTRIM(r.education_level)),
    LTRIM(RTRIM(r.user_segment))
FROM silver.reels_survey AS r
WHERE r.user_id IS NOT NULL;
GO


/* ─────────────────────────────────────────────────────────────
   STEP 6  –  Load DIM_PLATFORM
   Source : silver.platform_survey (primary_platform column)
   Note   : No platform_category in silver — derived via CASE
   ───────────────────────────────────────────────────────────── */
INSERT INTO gold.DIM_PLATFORM (
    platform_name,
    platform_category
)
SELECT
    platform_name,
    CASE platform_name
        WHEN 'TikTok'             THEN 'Short-form Video'
        WHEN 'Facebook Reels'     THEN 'Short-form Video'
        WHEN 'Instagram Reels'    THEN 'Short-form Video'
        WHEN 'YouTube Shorts'     THEN 'Short-form Video'
        WHEN 'Snapchat Spotlight' THEN 'Short-form Video'
        ELSE                           'Other'
    END AS platform_category
FROM (
    SELECT DISTINCT LTRIM(RTRIM(p.primary_platform)) AS platform_name
    FROM silver.platform_survey AS p
    WHERE p.primary_platform IS NOT NULL
) AS src;
GO


/* ─────────────────────────────────────────────────────────────
   STEP 7  –  Load DIM_CONTENT
   Source : silver.platform_survey (content_type already exploded)
   ───────────────────────────────────────────────────────────── */
INSERT INTO gold.DIM_CONTENT (
    content_type
)
SELECT DISTINCT
    LTRIM(RTRIM(p.content_type))
FROM silver.platform_survey AS p
WHERE p.content_type IS NOT NULL
  AND LTRIM(RTRIM(p.content_type)) <> '';
GO


/* ─────────────────────────────────────────────────────────────
   STEP 8  –  Load DIM_BEHAVIOR
   Source : silver.reels_survey
   PK     : behavior_id = user_id (one behavior profile per respondent)
   ───────────────────────────────────────────────────────────── */
INSERT INTO gold.DIM_BEHAVIOR (
    behavior_id,
    daily_watch_hours,
    daily_opens,
    peak_usage_time,
    usage_duration_since,
    sleep_impact,
    productivity_impact,
    difficulty_closing_app,
    feeling_after_closing
)
SELECT
    r.user_id,
    LTRIM(RTRIM(r.daily_watch_hours)),
    LTRIM(RTRIM(r.daily_opens)),
    LTRIM(RTRIM(r.peak_usage_time)),
    LTRIM(RTRIM(r.usage_duration_since)),
    LTRIM(RTRIM(r.sleep_impact)),
    LTRIM(RTRIM(r.productivity_impact)),
    LTRIM(RTRIM(r.difficulty_closing_app)),
    LTRIM(RTRIM(r.feeling_after_closing))
FROM silver.reels_survey AS r
WHERE r.user_id IS NOT NULL;
GO


/* ─────────────────────────────────────────────────────────────
   STEP 9  –  Load FACT_RESPONSE
   Grain  : one row per (respondent x platform x content type)
   Source : silver.platform_survey  JOIN  silver.reels_survey
   ───────────────────────────────────────────────────────────── */
INSERT INTO gold.FACT_RESPONSE (
    respondent_id,
    platform_id,
    content_id,
    behavior_id,
    watch_intensity_score,
    content_count,
    purchased_from_video,
    purchase_influence_level,
    rewatched_before_purchase,
    social_media_without_reels,
    reason_for_watching,
    content_relevance
)
SELECT
    p.user_id                                       AS respondent_id,
    dp.platform_id,
    dc.content_id,
    db.behavior_id,
    TRY_CAST(r.watch_intensity_score AS TINYINT),
    TRY_CAST(r.content_count         AS TINYINT),
    LTRIM(RTRIM(r.purchased_from_video)),
    LTRIM(RTRIM(r.purchase_influence_level)),
    LTRIM(RTRIM(r.rewatched_before_purchase)),
    LTRIM(RTRIM(r.social_media_without_reels)),
    LTRIM(RTRIM(r.reason_for_watching)),
    LTRIM(RTRIM(r.content_relevance))

FROM silver.platform_survey        AS p
INNER JOIN gold.DIM_PLATFORM       AS dp ON dp.platform_name = LTRIM(RTRIM(p.primary_platform))
INNER JOIN gold.DIM_CONTENT        AS dc ON dc.content_type  = LTRIM(RTRIM(p.content_type))
INNER JOIN silver.reels_survey     AS r  ON r.user_id        = p.user_id
INNER JOIN gold.DIM_BEHAVIOR       AS db ON db.behavior_id   = p.user_id
INNER JOIN gold.DIM_RESPONDENT     AS dr ON dr.respondent_id = p.user_id

WHERE p.user_id          IS NOT NULL
  AND p.primary_platform IS NOT NULL
  AND p.content_type     IS NOT NULL;
GO


/* ─────────────────────────────────────────────────────────────
   STEP 10  –  Verification
   ───────────────────────────────────────────────────────────── */

-- Row counts (expected: 3289 / 6 / 10 / 3289 / 12731)
SELECT 'gold.DIM_RESPONDENT' AS table_name, COUNT(*) AS row_count FROM gold.DIM_RESPONDENT
UNION ALL
SELECT 'gold.DIM_PLATFORM',  COUNT(*) FROM gold.DIM_PLATFORM
UNION ALL
SELECT 'gold.DIM_CONTENT',   COUNT(*) FROM gold.DIM_CONTENT
UNION ALL
SELECT 'gold.DIM_BEHAVIOR',  COUNT(*) FROM gold.DIM_BEHAVIOR
UNION ALL
SELECT 'gold.FACT_RESPONSE', COUNT(*) FROM gold.FACT_RESPONSE;
GO

-- Orphan check — all values must be 0
SELECT
    SUM(CASE WHEN dr.respondent_id IS NULL THEN 1 ELSE 0 END) AS orphan_respondent,
    SUM(CASE WHEN dp.platform_id   IS NULL THEN 1 ELSE 0 END) AS orphan_platform,
    SUM(CASE WHEN dc.content_id    IS NULL THEN 1 ELSE 0 END) AS orphan_content,
    SUM(CASE WHEN db.behavior_id   IS NULL THEN 1 ELSE 0 END) AS orphan_behavior
FROM gold.FACT_RESPONSE f
LEFT JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
LEFT JOIN gold.DIM_PLATFORM   dp ON dp.platform_id   = f.platform_id
LEFT JOIN gold.DIM_CONTENT    dc ON dc.content_id    = f.content_id
LEFT JOIN gold.DIM_BEHAVIOR   db ON db.behavior_id   = f.behavior_id;
GO

-- Sample star join
SELECT TOP 10
    dr.age_group,
    dr.gender,
    dr.region,
    dr.user_segment,
    dp.platform_name,
    dp.platform_category,
    dc.content_type,
    db.daily_watch_hours,
    db.sleep_impact,
    db.productivity_impact,
    f.watch_intensity_score,
    f.content_count,
    f.purchased_from_video,
    f.purchase_influence_level,
    f.reason_for_watching,
    f.content_relevance
FROM gold.FACT_RESPONSE        f
INNER JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id = f.respondent_id
INNER JOIN gold.DIM_PLATFORM   dp ON dp.platform_id   = f.platform_id
INNER JOIN gold.DIM_CONTENT    dc ON dc.content_id    = f.content_id
INNER JOIN gold.DIM_BEHAVIOR   db ON db.behavior_id   = f.behavior_id
ORDER BY f.response_id;
GO
