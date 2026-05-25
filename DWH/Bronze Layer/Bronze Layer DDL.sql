-- Bronze Layer DDL 

IF OBJECT_ID('bronze.reels_survey', 'U') IS NOT NULL
    DROP TABLE bronze.reels_survey;
GO

CREATE TABLE bronze.reels_survey (

-- ── Surrogate key ────────────────────────────────────────
    survey_id               INT             IDENTITY(1,1)   NOT NULL,  ---- Surrogate Key (Enforced as Clustered Index via PK constraint below)

-- ── Meta ─────────────────────────────────────────────────
    [timestamp]               NVARCHAR(50)    NULL,               -- raw form timestamp

 -- ── Demographics ─────────────────────────────────────────
    age_group               NVARCHAR(50)    NULL,
    gender                  NVARCHAR(50)    NULL,
    region                  NVARCHAR(50)    NULL,
    marital_status          NVARCHAR(50)    NULL,
    occupation              NVARCHAR(100)   NULL,
    education_level         NVARCHAR(50)    NULL,

 -- ── Platform & Consumption ───────────────────────────────
    primary_platform        NVARCHAR(200)   NULL,               -- may contain multiple values
    daily_watch_hours       NVARCHAR(50)    NULL,
    content_type            NVARCHAR(500)   NULL,               -- multi-select; up to 3 answers
    peak_usage_time         NVARCHAR(100)   NULL,
    daily_opens             NVARCHAR(100)   NULL,

 -- ── Behaviour & Habits ───────────────────────────────────
    voice_msg_behavior      NVARCHAR(100)   NULL,
    usage_duration_since    NVARCHAR(100)   NULL,
    content_relevance       NVARCHAR(100)   NULL,
    difficulty_closing_app  NVARCHAR(50)    NULL,
    productivity_impact     NVARCHAR(100)   NULL,
    sleep_impact            NVARCHAR(100)   NULL,
    feeling_after_closing   NVARCHAR(100)   NULL,
    watching_companion      NVARCHAR(100)   NULL,
    behavior_while_watching NVARCHAR(100)   NULL,
    phone_during_family     NVARCHAR(100)   NULL,
    family_opinion          NVARCHAR(200)   NULL,
    reason_for_watching     NVARCHAR(100)   NULL,
    social_media_without_reels NVARCHAR(50) NULL,

-- ── Purchase Influence ───────────────────────────────────
    purchased_from_video    NVARCHAR(100)   NULL,
    purchase_reason         NVARCHAR(200)   NULL,
    purchase_influence_level NVARCHAR(200)  NULL,
    rewatched_before_purchase NVARCHAR(50)  NULL,

-- ── Audit ────────────────────────────────────────────────
    ingested_at             DATETIME2(0)    NOT NULL
        CONSTRAINT df_reels_survey_ingested_at DEFAULT SYSUTCDATETIME(),
 
-- ── PK ───────────────────────────────────────────────────
    CONSTRAINT pk_reels_survey PRIMARY KEY CLUSTERED (survey_id)

);