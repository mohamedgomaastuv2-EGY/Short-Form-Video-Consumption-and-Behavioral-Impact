/* ============================================================
   GOLD LAYER  –  Star Schema for Reels Behaviour Study
   Database    : Reels_Pulse_Warehouse
   Source      : silver.reels_survey  &  silver.platform_survey
   Target      : gold.DIM_* & gold.FACT_RESPONSE
   ============================================================ */

/* ─────────────────────────────────────────────────────────────
   STEP 0  –  Use the correct database
   ───────────────────────────────────────────────────────────── */
USE Reels_Pulse_Warehouse;
GO


/* ─────────────────────────────────────────────────────────────
   STEP 1  –  Drop tables (reverse FK order)
   ───────────────────────────────────────────────────────────── */
IF OBJECT_ID('gold.FACT_RESPONSE',  'U') IS NOT NULL DROP TABLE gold.FACT_RESPONSE;
IF OBJECT_ID('gold.DIM_BEHAVIOR',   'U') IS NOT NULL DROP TABLE gold.DIM_BEHAVIOR;
IF OBJECT_ID('gold.DIM_CONTENT',    'U') IS NOT NULL DROP TABLE gold.DIM_CONTENT;
IF OBJECT_ID('gold.DIM_PLATFORM',   'U') IS NOT NULL DROP TABLE gold.DIM_PLATFORM;
IF OBJECT_ID('gold.DIM_RESPONDENT', 'U') IS NOT NULL DROP TABLE gold.DIM_RESPONDENT;
GO

/* ─────────────────────────────────────────────────────────────
   STEP 1B  –  Create gold schema if it doesn't exist
   ───────────────────────────────────────────────────────────── */
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO


/* ─────────────────────────────────────────────────────────────
   STEP 2  –  Create Dimension Tables
   ───────────────────────────────────────────────────────────── */

/* ── 2.1  DIM_RESPONDENT ──────────────────────────────────── */
CREATE TABLE gold.DIM_RESPONDENT (
    respondent_id       INT             NOT NULL,   -- maps to user_id in silver.reels_survey
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

/* ── 2.2  DIM_PLATFORM ───────────────────────────────────── */
CREATE TABLE gold.DIM_PLATFORM (
    platform_id         INT             NOT NULL IDENTITY(1,1),
    platform_name       NVARCHAR(100)   NOT NULL,   -- e.g. "TikTok", "Facebook Reels"
    platform_category   NVARCHAR(50)    NOT NULL,   -- e.g. "Short-form Video"
    etl_load_date       DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DIM_PLATFORM     PRIMARY KEY (platform_id),
    CONSTRAINT UQ_DIM_PLATFORM_name UNIQUE (platform_name)
);
GO

/* ── 2.3  DIM_CONTENT ────────────────────────────────────── */
CREATE TABLE gold.DIM_CONTENT (
    content_id          INT             NOT NULL IDENTITY(1,1),
    content_type        NVARCHAR(500)   NOT NULL,   -- unique content-type combination string
    etl_load_date       DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DIM_CONTENT      PRIMARY KEY (content_id),
    CONSTRAINT UQ_DIM_CONTENT_type  UNIQUE (content_type)
);
GO

/* ── 2.4  DIM_BEHAVIOR ───────────────────────────────────── */
CREATE TABLE gold.DIM_BEHAVIOR (
    behavior_id_Sk          INT             NOT NULL IDENTITY(1,1),
    behavior_id_Bk          INT             NOT NULL,   -- business key = user_id from silver
    daily_watch_hours       NVARCHAR(50)    NOT NULL,
    daily_opens             NVARCHAR(50)    NOT NULL,
    peak_usage_time         NVARCHAR(100)   NOT NULL,
    usage_duration_since    NVARCHAR(50)    NOT NULL,
    sleep_impact            NVARCHAR(100)   NOT NULL,
    productivity_impact     NVARCHAR(100)   NOT NULL,
    difficulty_closing_app  NVARCHAR(100)   NOT NULL,
    feeling_after_closing   NVARCHAR(100)   NOT NULL,
    etl_load_date           DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_DIM_BEHAVIOR PRIMARY KEY (behavior_id_Sk)
);
GO


/* ─────────────────────────────────────────────────────────────
   STEP 3  –  Create Fact Table
   ───────────────────────────────────────────────────────────── */
CREATE TABLE gold.FACT_RESPONSE (
    response_id_Sk              INT             NOT NULL IDENTITY(1,1),

    -- Foreign Keys
    respondent_id_Fk            INT             NOT NULL,
    platform_id_Fk              INT             NOT NULL,
    content_id_Fk               INT             NOT NULL,
    behavior_id_Fk              INT             NOT NULL,

    -- Measures / Degenerate Dimensions
    watch_intensity_score       TINYINT         NULL,
    content_count               TINYINT         NULL,
    purchased_from_video        NVARCHAR(100)   NULL,
    purchase_influence_level    NVARCHAR(100)   NULL,
    rewatched_before_purchase   NVARCHAR(50)    NULL,
    social_media_without_reels  NVARCHAR(100)   NULL,
    reason_for_watching         NVARCHAR(100)   NULL,
    content_relevance           NVARCHAR(100)   NULL,

    etl_load_date               DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_FACT_RESPONSE   PRIMARY KEY (response_id_Sk),
    CONSTRAINT FK_FACT_RESPONDENT FOREIGN KEY (respondent_id_Fk) REFERENCES gold.DIM_RESPONDENT (respondent_id),
    CONSTRAINT FK_FACT_PLATFORM   FOREIGN KEY (platform_id_Fk)   REFERENCES gold.DIM_PLATFORM   (platform_id),
    CONSTRAINT FK_FACT_CONTENT    FOREIGN KEY (content_id_Fk)    REFERENCES gold.DIM_CONTENT    (content_id),
    CONSTRAINT FK_FACT_BEHAVIOR   FOREIGN KEY (behavior_id_Fk)   REFERENCES gold.DIM_BEHAVIOR   (behavior_id_Sk)
);
GO


/* ─────────────────────────────────────────────────────────────
   STEP 4  –  ETL: Load Dimension Tables
   Source: Reels_Pulse_Warehouse.silver.reels_survey
           Reels_Pulse_Warehouse.silver.platform_survey
   ───────────────────────────────────────────────────────────── */

/* ── 4.1  Load gold.DIM_RESPONDENT ────────────────────────── */
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
    r.user_id                           AS respondent_id,
    LTRIM(RTRIM(r.age_group))           AS age_group,
    LTRIM(RTRIM(r.gender))              AS gender,
    LTRIM(RTRIM(r.region))              AS region,
    LTRIM(RTRIM(r.marital_status))      AS marital_status,
    LTRIM(RTRIM(r.occupation))          AS occupation,
    LTRIM(RTRIM(r.education_level))     AS education_level,
    LTRIM(RTRIM(r.user_segment))        AS user_segment
FROM silver.reels_survey AS r
WHERE r.user_id IS NOT NULL;
GO


/* ── 4.2  Load gold.DIM_PLATFORM ─────────────────────────── */
-- Source: silver.platform_survey — already one row per platform per user
-- We extract distinct platform names and assign surrogate keys via IDENTITY
INSERT INTO gold.DIM_PLATFORM (
    platform_name,
    platform_category
)
SELECT DISTINCT
    LTRIM(RTRIM(p.primary_platform))    AS platform_name,
    LTRIM(RTRIM(p.platform_category))   AS platform_category
FROM silver.platform_survey AS p
WHERE p.primary_platform IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM gold.DIM_PLATFORM dp
      WHERE dp.platform_name = LTRIM(RTRIM(p.primary_platform))
  );
GO


/* ── 4.3  Load gold.DIM_CONTENT ──────────────────────────── */
-- Source: silver.platform_survey — unique content_type combination strings
INSERT INTO gold.DIM_CONTENT (
    content_type
)
SELECT DISTINCT
    LTRIM(RTRIM(p.content_type))        AS content_type
FROM silver.platform_survey AS p
WHERE p.content_type IS NOT NULL
  AND LTRIM(RTRIM(p.content_type)) <> ''
  AND NOT EXISTS (
      SELECT 1 FROM gold.DIM_CONTENT dc
      WHERE dc.content_type = LTRIM(RTRIM(p.content_type))
  );
GO


/* ── 4.4  Load gold.DIM_BEHAVIOR ─────────────────────────── */
-- Source: silver.reels_survey — behavioral profile per respondent
INSERT INTO gold.DIM_BEHAVIOR (
    behavior_id_Bk,
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
    r.user_id                               AS behavior_id_Bk,
    LTRIM(RTRIM(r.daily_watch_hours))       AS daily_watch_hours,
    LTRIM(RTRIM(r.daily_opens))             AS daily_opens,
    LTRIM(RTRIM(r.peak_usage_time))         AS peak_usage_time,
    LTRIM(RTRIM(r.usage_duration_since))    AS usage_duration_since,
    LTRIM(RTRIM(r.sleep_impact))            AS sleep_impact,
    LTRIM(RTRIM(r.productivity_impact))     AS productivity_impact,
    LTRIM(RTRIM(r.difficulty_closing_app))  AS difficulty_closing_app,
    LTRIM(RTRIM(r.feeling_after_closing))   AS feeling_after_closing
FROM silver.reels_survey AS r
WHERE r.user_id IS NOT NULL;
GO


/* ─────────────────────────────────────────────────────────────
   STEP 5  –  ETL: Load gold.FACT_RESPONSE
   Grain: one row per (respondent × platform × content)
   ───────────────────────────────────────────────────────────── */
INSERT INTO gold.FACT_RESPONSE (
    respondent_id_Fk,
    platform_id_Fk,
    content_id_Fk,
    behavior_id_Fk,
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
    p.user_id                                       AS respondent_id_Fk,
    dp.platform_id                                  AS platform_id_Fk,
    dc.content_id                                   AS content_id_Fk,
    db.behavior_id_Sk                               AS behavior_id_Fk,
    TRY_CAST(r.watch_intensity_score AS TINYINT)    AS watch_intensity_score,
    TRY_CAST(r.content_count         AS TINYINT)    AS content_count,
    LTRIM(RTRIM(r.purchased_from_video))            AS purchased_from_video,
    LTRIM(RTRIM(r.purchase_influence_level))        AS purchase_influence_level,
    LTRIM(RTRIM(r.rewatched_before_purchase))       AS rewatched_before_purchase,
    LTRIM(RTRIM(r.social_media_without_reels))      AS social_media_without_reels,
    LTRIM(RTRIM(r.reason_for_watching))             AS reason_for_watching,
    LTRIM(RTRIM(r.content_relevance))               AS content_relevance

FROM silver.platform_survey AS p

-- Resolve platform FK
INNER JOIN gold.DIM_PLATFORM AS dp
    ON dp.platform_name = LTRIM(RTRIM(p.primary_platform))

-- Resolve content FK
INNER JOIN gold.DIM_CONTENT AS dc
    ON dc.content_type = LTRIM(RTRIM(p.content_type))

-- Bring in measures from silver.reels_survey
INNER JOIN silver.reels_survey AS r
    ON r.user_id = p.user_id

-- Resolve behavior FK
INNER JOIN gold.DIM_BEHAVIOR AS db
    ON db.behavior_id_Bk = p.user_id

-- Ensure respondent exists in gold dim
INNER JOIN gold.DIM_RESPONDENT AS dr
    ON dr.respondent_id = p.user_id

WHERE p.user_id          IS NOT NULL
  AND p.primary_platform IS NOT NULL
  AND p.content_type     IS NOT NULL;
GO


/* ─────────────────────────────────────────────────────────────
   STEP 6  –  Verification Queries
   ───────────────────────────────────────────────────────────── */

-- Row counts per table
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

-- Referential integrity check — all values must be 0
SELECT
    SUM(CASE WHEN dr.respondent_id   IS NULL THEN 1 ELSE 0 END) AS orphan_respondent,
    SUM(CASE WHEN dp.platform_id     IS NULL THEN 1 ELSE 0 END) AS orphan_platform,
    SUM(CASE WHEN dc.content_id      IS NULL THEN 1 ELSE 0 END) AS orphan_content,
    SUM(CASE WHEN db.behavior_id_Sk  IS NULL THEN 1 ELSE 0 END) AS orphan_behavior
FROM gold.FACT_RESPONSE f
LEFT JOIN gold.DIM_RESPONDENT dr ON dr.respondent_id  = f.respondent_id_Fk
LEFT JOIN gold.DIM_PLATFORM   dp ON dp.platform_id    = f.platform_id_Fk
LEFT JOIN gold.DIM_CONTENT    dc ON dc.content_id     = f.content_id_Fk
LEFT JOIN gold.DIM_BEHAVIOR   db ON db.behavior_id_Sk = f.behavior_id_Fk;
GO

-- Sample analyst query — full star join
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
FROM gold.FACT_RESPONSE         f
INNER JOIN gold.DIM_RESPONDENT  dr ON dr.respondent_id  = f.respondent_id_Fk
INNER JOIN gold.DIM_PLATFORM    dp ON dp.platform_id    = f.platform_id_Fk
INNER JOIN gold.DIM_CONTENT     dc ON dc.content_id     = f.content_id_Fk
INNER JOIN gold.DIM_BEHAVIOR    db ON db.behavior_id_Sk = f.behavior_id_Fk
ORDER BY f.response_id_Sk;
GO
