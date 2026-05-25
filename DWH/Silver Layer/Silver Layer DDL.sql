-- Drop table if exists (optional during development)
DROP TABLE IF EXISTS silver.reels_survey;
GO

-- Create cleaned reels survey table
CREATE TABLE silver.reels_survey (
    age_group NVARCHAR(50),
    gender NVARCHAR(20),
    region NVARCHAR(100),
    marital_status NVARCHAR(50),
    occupation NVARCHAR(100),
    education_level NVARCHAR(100),
    daily_watch_hours NVARCHAR(50),
    peak_usage_time NVARCHAR(100),
    daily_opens NVARCHAR(100),
    voice_msg_behavior NVARCHAR(100),
    usage_duration_since NVARCHAR(100),
    content_relevance NVARCHAR(100),
    difficulty_closing_app NVARCHAR(100),
    productivity_impact NVARCHAR(100),
    sleep_impact NVARCHAR(100),
    feeling_after_closing NVARCHAR(100),
    watching_companion NVARCHAR(100),
    behavior_while_watching NVARCHAR(100),
    phone_during_family NVARCHAR(100),
    family_opinion NVARCHAR(100),
    reason_for_watching NVARCHAR(100),
    social_media_without_reels NVARCHAR(100),
    purchased_from_video NVARCHAR(100),
    purchase_reason NVARCHAR(100),
    purchase_influence_level NVARCHAR(100),
    rewatched_before_purchase NVARCHAR(100),
    watch_intensity_score INT,
    user_segment NVARCHAR(50),
    content_count INT,
    user_id INT
);
GO