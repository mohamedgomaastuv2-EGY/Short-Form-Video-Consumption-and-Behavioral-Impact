-- ============================================================
--  SURVEY: Bronze → Silver Transformation
--  Source  : survey_3289_records  (raw Arabic, 3289 rows)
--  Target  : silver.survey_cleaned_english
--  Engine  : SQL Server 2016+
--  Notes   :
--    • Only the first 264 chronological responses are loaded
--      (responses up to 2026-03-25 – the original cleaned scope).
--      Remove or adjust the TOP / date filter to load all rows.
--    • The script is idempotent: it drops & recreates the target.
--    • Three computed columns are derived from the cleaned data:
--        watch_intensity_score  – 1-5 scale from daily watch hours
--        user_segment           – Light / Moderate / Heavy
--        content_count          – number of content categories chosen
-- ============================================================


-- ============================================================
-- 0. SCHEMA GUARD
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'silver')
    EXEC ('CREATE SCHEMA silver');
GO


-- ============================================================
-- 1. DROP & RECREATE TARGET TABLE
-- ============================================================
IF OBJECT_ID('silver.survey_cleaned_english', 'U') IS NOT NULL
    DROP TABLE silver.survey_cleaned_english;
GO

CREATE TABLE silver.survey_cleaned_english (
    timestamp                   DATETIME2,
    age_group                   NVARCHAR(20),
    gender                      NVARCHAR(10),
    region                      NVARCHAR(50),
    marital_status              NVARCHAR(30),
    occupation                  NVARCHAR(50),
    education_level             NVARCHAR(50),
    primary_platform            NVARCHAR(200),
    daily_watch_hours           NVARCHAR(20),
    content_type                NVARCHAR(500),
    peak_usage_time             NVARCHAR(50),
    daily_opens                 NVARCHAR(30),
    voice_msg_behavior          NVARCHAR(50),
    usage_duration_since        NVARCHAR(20),
    content_relevance           NVARCHAR(30),
    difficulty_closing_app      NVARCHAR(20),
    productivity_impact         NVARCHAR(50),
    sleep_impact                NVARCHAR(30),
    feeling_after_closing       NVARCHAR(30),
    watching_companion          NVARCHAR(50),
    behavior_while_watching     NVARCHAR(30),
    phone_during_family         NVARCHAR(40),
    family_opinion              NVARCHAR(40),
    reason_for_watching         NVARCHAR(30),
    social_media_without_reels  NVARCHAR(30),
    purchased_from_video        NVARCHAR(40),
    purchase_reason             NVARCHAR(40),
    purchase_influence_level    NVARCHAR(30),
    rewatched_before_purchase   NVARCHAR(15),
    watch_intensity_score       TINYINT,
    user_segment                NVARCHAR(15),
    content_count               TINYINT
);
GO


-- ============================================================
-- 2. HELPER: CONTENT-TYPE TRANSLATION FUNCTION
--    Translates every Arabic emoji-tag in the comma-separated
--    content list and re-joins with ' | ' to match silver format.
-- ============================================================
IF OBJECT_ID('silver.fn_translate_content_type', 'FN') IS NOT NULL
    DROP FUNCTION silver.fn_translate_content_type;
GO

CREATE FUNCTION silver.fn_translate_content_type (@raw NVARCHAR(500))
RETURNS NVARCHAR(500)
AS
BEGIN
    -- Strip leading/trailing spaces
    SET @raw = LTRIM(RTRIM(@raw));

    -- Strip emoji prefixes that precede the Arabic text token
    -- Each content tag is separated by ", " in the source.
    -- We replace each Arabic tag with its English label.

    DECLARE @out NVARCHAR(500) = @raw;

    -- News & Current Affairs
    SET @out = REPLACE(@out, N'🌍 أخبار وأحداث جارية',     N'News & Current Affairs');
    -- Religious
    SET @out = REPLACE(@out, N'🙏 ديني',                    N'Religious');
    -- Comedy & Entertainment
    SET @out = REPLACE(@out, N'😂 كوميدي وترفيهي',         N'Comedy & Entertainment');
    -- Educational & Cultural
    SET @out = REPLACE(@out, N'📚 تعليمي / ثقافي',          N'Educational & Cultural');
    -- Self-development
    SET @out = REPLACE(@out, N'✨ تطوير ذات وتحفيز',        N'Self-development');
    -- Sports
    SET @out = REPLACE(@out, N'⚽ رياضة',                   N'Sports');
    -- Cooking
    SET @out = REPLACE(@out, N'👩‍🍳 طبخ',                  N'Cooking');
    -- Fashion & Beauty
    SET @out = REPLACE(@out, N'💄 موضة / جمال',             N'Fashion & Beauty');
    -- Music & Dance
    SET @out = REPLACE(@out, N'🎵💃 موسيقى ورقص',           N'Music & Dance');
    -- Gaming
    SET @out = REPLACE(@out, N'🎮 ألعاب',                   N'Gaming');

    -- Swap the Arabic comma-separator for ' | '
    SET @out = REPLACE(@out, N', ', N' | ');

    RETURN LTRIM(RTRIM(@out));
END;
GO


-- ============================================================
-- 3. HELPER: PLATFORM TRANSLATION FUNCTION
--    The platform field has many free-text variants in Arabic
--    and mixed languages.  We normalise to a sorted
--    pipe-delimited list of known platform labels.
-- ============================================================
IF OBJECT_ID('silver.fn_translate_platform', 'FN') IS NOT NULL
    DROP FUNCTION silver.fn_translate_platform;
GO

CREATE FUNCTION silver.fn_translate_platform (@raw NVARCHAR(500))
RETURNS NVARCHAR(200)
AS
BEGIN
    DECLARE @r NVARCHAR(500) = LTRIM(RTRIM(@raw));

    -- Single-platform exact matches first (order matters – longest first)
    IF @r IN (N'🎵 TikTok', N'🎵 TikTok, ')                              RETURN N'TikTok';
    IF @r IN (N'📘 Facebook Reels', N'📘 Facebook Reels, ')              RETURN N'Facebook Reels';
    IF @r IN (N'📸 Instagram Reels')                                      RETURN N'Instagram Reels';
    IF @r IN (N'▶️ YouTube Shorts')                                       RETURN N'YouTube Shorts';
    IF @r IN (N'Whatsapp', N'واتساب', N'واتساب ', N'وتساب ', N'واتساب وفيسوك ')
                                                                          RETURN N'WhatsApp';
    IF @r IN (N'Telegram and WhatsApp ')                                  RETURN N'WhatsApp | Telegram';
    IF @r IN (N'X', N'Linkedin and Twitter')                              RETURN N'X/Twitter | LinkedIn';
    IF @r IN (N'Threads ', N'Threads')                                    RETURN N'Threads';
    IF @r IN (N'Reading')                                                 RETURN N'Reading';
    IF @r IN (N'محاضرات')                                                 RETURN N'Lectures';
    IF @r IN (N'تلفزيون')                                                 RETURN N'TV';
    IF @r IN (N'فيديوهات يوتيوب',
              N'يوتيوب بس قليل ما بحب مواقع السوشيال ميديا غير مهت',
              N'youtube vedio ')                                           RETURN N'YouTube';
    IF @r IN (N'Gaming or YouTube long videos')                           RETURN N'YouTube | Gaming';
    IF @r IN (N'▶️ YouTube Shorts, Youtube Videos')                       RETURN N'YouTube Shorts | YouTube';
    IF @r LIKE N'▶️ YouTube Shorts, دراسة%'                              RETURN N'YouTube Shorts | Study/Research';

    -- Multi-platform combinations (order matters)
    IF @r LIKE N'%TikTok%' AND @r LIKE N'%Instagram%'
       AND @r LIKE N'%YouTube%' AND @r LIKE N'%Facebook%'
       AND @r LIKE N'%Snapchat%'
                            RETURN N'Facebook Reels | Instagram Reels | TikTok | YouTube Shorts | Snapchat Spotlight';
    IF @r LIKE N'%TikTok%' AND @r LIKE N'%Instagram%'
       AND @r LIKE N'%YouTube%' AND @r LIKE N'%Facebook%'
                            RETURN N'Facebook Reels | Instagram Reels | TikTok | YouTube Shorts';
    IF @r LIKE N'%Instagram%' AND @r LIKE N'%YouTube%'
       AND @r LIKE N'%Facebook%' AND @r LIKE N'%Reddit%'
                            RETURN N'Facebook Reels | Instagram Reels | YouTube Shorts | Reddit | YouTube';
    IF @r LIKE N'%Instagram%' AND @r LIKE N'%YouTube%'
       AND @r LIKE N'%Facebook%'
                            RETURN N'Facebook Reels | Instagram Reels | YouTube Shorts';
    IF @r LIKE N'%TikTok%'  AND @r LIKE N'%YouTube%'
       AND @r LIKE N'%Facebook%'
                            RETURN N'Facebook Reels | TikTok | YouTube Shorts';
    IF @r LIKE N'%TikTok%'  AND @r LIKE N'%Instagram%'
       AND @r LIKE N'%Snapchat%'
                            RETURN N'Instagram Reels | TikTok | Snapchat Spotlight';
    IF @r LIKE N'%Instagram%' AND @r LIKE N'%Snapchat%'
                            RETURN N'Instagram Reels | Snapchat Spotlight';
    IF @r LIKE N'%Instagram%' AND @r LIKE N'%Facebook%'
       AND @r LIKE N'%Threads%'
                            RETURN N'Facebook Reels | Instagram Reels | Threads';
    IF @r LIKE N'%Instagram%' AND @r LIKE N'%Facebook%'
       AND @r LIKE N'%Whatsapp%'
                            RETURN N'Facebook Reels | Instagram Reels | WhatsApp';
    IF @r LIKE N'%Instagram%' AND @r LIKE N'%Facebook%'
       AND @r LIKE N'%GOOGLE%'
                            RETURN N'Instagram Reels | Google Search';
    IF @r LIKE N'%TikTok%'  AND @r LIKE N'%Instagram%'
                            RETURN N'Instagram Reels | TikTok';
    IF @r LIKE N'%TikTok%'  AND @r LIKE N'%Facebook%'
                            RETURN N'Facebook Reels | TikTok';
    IF @r LIKE N'%Instagram%' AND @r LIKE N'%YouTube%'
                            RETURN N'Instagram Reels | YouTube Shorts';
    IF @r LIKE N'%YouTube%' AND @r LIKE N'%Facebook%'
                            RETURN N'Facebook Reels | YouTube Shorts';
    IF @r LIKE N'%TikTok%'  AND @r LIKE N'%YouTube%'
                            RETURN N'TikTok | YouTube Shorts';
    IF @r LIKE N'%Instagram%' AND @r LIKE N'%Facebook%'
                            RETURN N'Facebook Reels | Instagram Reels';
    IF @r LIKE N'%واتساب%'  AND @r LIKE N'%فيسوك%'
                            RETURN N'WhatsApp | Facebook';

    -- Fallback
    RETURN N'Other';
END;
GO


-- ============================================================
-- 4. MAIN INSERT
--    Assumes the raw Bronze table is named:
--        bronze.survey_3289_records
--    with column order matching the original xlsx.
--    Adjust the FROM clause / column names if your Bronze layer
--    uses different naming conventions.
--
--    NOTE: The TOP 264 picks the first 264 chronological rows
--    (ordered by Timestamp), replicating the original cleaned
--    dataset scope.  Remove TOP + ORDER BY to process all rows.
-- ============================================================
INSERT INTO silver.survey_cleaned_english
(
    timestamp, age_group, gender, region, marital_status,
    occupation, education_level, primary_platform,
    daily_watch_hours, content_type, peak_usage_time,
    daily_opens, voice_msg_behavior, usage_duration_since,
    content_relevance, difficulty_closing_app, productivity_impact,
    sleep_impact, feeling_after_closing, watching_companion,
    behavior_while_watching, phone_during_family, family_opinion,
    reason_for_watching, social_media_without_reels,
    purchased_from_video, purchase_reason, purchase_influence_level,
    rewatched_before_purchase,
    watch_intensity_score, user_segment, content_count
)
SELECT TOP 264
    -- ── 1. TIMESTAMP ───────────────────────────────────────────
    src.[Timestamp]                                                 AS timestamp,

    -- ── 2. AGE GROUP ───────────────────────────────────────────
    CASE src.[Q1_Age]
        WHEN N'تحت الـ 18 👶'                        THEN N'< 18'
        WHEN N'18-24 (جيل الجامعة) 🎓'               THEN N'18-24'
        WHEN N'25-34 (الشغالين الجُداد) 💼'           THEN N'25-34'
        WHEN N'35-44 (أصحاب الخبرة) 👔'               THEN N'35-44'
        WHEN N'45-54 (الـ Pros) 🏆'                   THEN N'45-54'
        WHEN N'55+ (الكبار بتوعنا) 👑'                THEN N'55+'
        ELSE src.[Q1_Age]
    END                                                             AS age_group,

    -- ── 3. GENDER ──────────────────────────────────────────────
    CASE src.[Q2_Gender]
        WHEN N'شاب / رجل 🧔'  THEN N'Male'
        WHEN N'بنت/سيدة 👩'   THEN N'Female'
        ELSE src.[Q2_Gender]
    END                                                             AS gender,

    -- ── 4. REGION ──────────────────────────────────────────────
    CASE src.[Q3_Region]
        WHEN N'القاهرة الكبرى'           THEN N'Greater Cairo'
        WHEN N'الدلتا'                   THEN N'Delta'
        WHEN N'الصعيد'                   THEN N'Upper Egypt'
        WHEN N'الساحل / البحر الأحمر'   THEN N'North Coast / Red Sea'
        WHEN N'القناة وسيناء'            THEN N'Canal & Sinai'
        WHEN N'خارج مصر'                 THEN N'Outside Egypt'
        ELSE src.[Q3_Region]
    END                                                             AS region,

    -- ── 5. MARITAL STATUS ──────────────────────────────────────
    CASE src.[Q4_MaritalStatus]
        WHEN N'لأ لسه 💍'                          THEN N'Single'
        WHEN N'آه (مفيش عيال) 👫'                 THEN N'Married (no kids)'
        WHEN N'آه (وعندي عيال) 👨‍👩‍👧‍👦'           THEN N'Married (with kids)'
        WHEN N'كنت متجوز (مطلق/أرمل) 💔'          THEN N'Divorced / Widowed'
        ELSE src.[Q4_MaritalStatus]
    END                                                             AS marital_status,

    -- ── 6. OCCUPATION ──────────────────────────────────────────
    CASE src.[Q6_Occupation]
        WHEN N'موظف (حكومي/خاص)💼'                        THEN N'Employee'
        WHEN N'لسه بدرس 📚'                                THEN N'Student'
        WHEN N'عمل حر (Freelancer)💻'                     THEN N'Freelancer'
        WHEN N'قاعد في البيت (بدور على شغل/ربة منزل) 🏠' THEN N'Homemaker / Unemployed'
        WHEN N'متقاعد 😎'                                  THEN N'Retired'
        ELSE src.[Q6_Occupation]
    END                                                             AS occupation,

    -- ── 7. EDUCATION LEVEL ─────────────────────────────────────
    CASE src.[Q5_EducationLevel]
        WHEN N'📖 بفك الخط'              THEN N'Basic Literacy'
        WHEN N'🧒 طالب قبل الثانوي'      THEN N'Pre-Secondary'
        WHEN N'🏫 طالب ثانوي'            THEN N'Secondary Student'
        WHEN N'🛠️ تعليم متوسط / فني'    THEN N'Vocational / Technical'
        WHEN N'🎓 طالب جامعي'            THEN N'University Student'
        WHEN N'👨‍🎓 خريج (مؤهل عالي)'   THEN N'University Graduate'
        WHEN N'📚 دراسات عليا'           THEN N'Postgraduate'
        ELSE src.[Q5_EducationLevel]
    END                                                             AS education_level,

    -- ── 8. PRIMARY PLATFORM ────────────────────────────────────
    silver.fn_translate_platform(src.[Q7_PrimaryPlatform])         AS primary_platform,

    -- ── 9. DAILY WATCH HOURS ───────────────────────────────────
    CASE
        WHEN src.[Q8_DailyWatchHours] LIKE N'%أقل من 30%'
          OR src.[Q8_DailyWatchHours] LIKE N'%⚡%'               THEN N'< 30 min'
        WHEN src.[Q8_DailyWatchHours] LIKE N'%30%60%'
          OR src.[Q8_DailyWatchHours] LIKE N'%☕%'               THEN N'30-60 min'
        WHEN src.[Q8_DailyWatchHours] LIKE N'%1%2%ساعة%'
          OR src.[Q8_DailyWatchHours] LIKE N'%🎵 1%'             THEN N'1-2 hrs'
        WHEN src.[Q8_DailyWatchHours] LIKE N'%2%3%ساعة%'
          OR src.[Q8_DailyWatchHours] LIKE N'%⏰ 2%'             THEN N'2-3 hrs'
        WHEN src.[Q8_DailyWatchHours] LIKE N'%أكثر من 3%'
          OR src.[Q8_DailyWatchHours] LIKE N'%🔥%'               THEN N'3+ hrs'
        ELSE src.[Q8_DailyWatchHours]
    END                                                             AS daily_watch_hours,

    -- ── 10. CONTENT TYPE ───────────────────────────────────────
    silver.fn_translate_content_type(src.[Q9_ContentType])         AS content_type,

    -- ── 11. PEAK USAGE TIME ────────────────────────────────────
    CASE
        WHEN src.[Q10_PeakUsageTime] LIKE N'%قبل النوم%'          THEN N'Before sleep'
        WHEN src.[Q10_PeakUsageTime] LIKE N'%أول ما أصحى%'        THEN N'First thing AM'
        WHEN src.[Q10_PeakUsageTime] LIKE N'%أي وقت فاضي%'        THEN N'Any free moment'
        WHEN src.[Q10_PeakUsageTime] LIKE N'%البريك%'             THEN N'During breaks'
        WHEN src.[Q10_PeakUsageTime] LIKE N'%بأكل%'               THEN N'While eating'
        WHEN src.[Q10_PeakUsageTime] LIKE N'%مواصلات%'            THEN N'On commute'
        ELSE src.[Q10_PeakUsageTime]
    END                                                             AS peak_usage_time,

    -- ── 12. DAILY OPENS ────────────────────────────────────────
    CASE
        WHEN src.[Q11_DailyOpens] LIKE N'%مرة / مرتين%'
          OR src.[Q11_DailyOpens] LIKE N'%📱%'                    THEN N'1-2x/day'
        WHEN src.[Q11_DailyOpens] LIKE N'%3%5%'
          OR src.[Q11_DailyOpens] LIKE N'%🙂%'                    THEN N'3-5x/day'
        WHEN src.[Q11_DailyOpens] LIKE N'%6%10%'
          OR src.[Q11_DailyOpens] LIKE N'%😅%'                    THEN N'6-10x/day'
        WHEN src.[Q11_DailyOpens] LIKE N'%طول اليوم%'
          OR src.[Q11_DailyOpens] LIKE N'%Lost count%'
          OR src.[Q11_DailyOpens] LIKE N'%🔁%'                    THEN N'All day (lost count)'
        ELSE src.[Q11_DailyOpens]
    END                                                             AS daily_opens,

    -- ── 13. VOICE MESSAGE BEHAVIOR ─────────────────────────────
    CASE
        WHEN src.[Q12_VoiceMsgBehavior] LIKE N'%2×%'
          OR src.[Q12_VoiceMsgBehavior] LIKE N'%x2%'
          OR src.[Q12_VoiceMsgBehavior] LIKE N'%مرتين%'
          OR src.[Q12_VoiceMsgBehavior] LIKE N'%ضعف%'             THEN N'2x speed (no patience)'
        WHEN src.[Q12_VoiceMsgBehavior] LIKE N'%بأجل%'
          OR src.[Q12_VoiceMsgBehavior] LIKE N'%أجل%'             THEN N'Postpone listening'
        WHEN src.[Q12_VoiceMsgBehavior] LIKE N'%عادية%'           THEN N'Normal speed'
        WHEN src.[Q12_VoiceMsgBehavior] LIKE N'%جزء%'             THEN N'Partial listen (if long)'
        ELSE src.[Q12_VoiceMsgBehavior]
    END                                                             AS voice_msg_behavior,

    -- ── 14. USAGE DURATION SINCE ───────────────────────────────
    CASE
        WHEN src.[Q13_UsageDurationSince] LIKE N'%أقل من 6%'
          OR src.[Q13_UsageDurationSince] LIKE N'%🆕%'             THEN N'< 6 months'
        WHEN src.[Q13_UsageDurationSince] LIKE N'%6 شهور إلى سنة%'
          OR src.[Q13_UsageDurationSince] LIKE N'%🕒%'             THEN N'6-12 months'
        WHEN src.[Q13_UsageDurationSince] LIKE N'%سنة إلى سنتين%'
          OR src.[Q13_UsageDurationSince] LIKE N'%📅%'             THEN N'1-2 years'
        WHEN src.[Q13_UsageDurationSince] LIKE N'%سنتين إلى 4%'
          OR src.[Q13_UsageDurationSince] LIKE N'%⏳%'             THEN N'2-4 years'
        WHEN src.[Q13_UsageDurationSince] LIKE N'%أكثر من 4%'
          OR src.[Q13_UsageDurationSince] LIKE N'%🏆%'             THEN N'4+ years'
        ELSE src.[Q13_UsageDurationSince]
    END                                                             AS usage_duration_since,

    -- ── 15. CONTENT RELEVANCE ──────────────────────────────────
    CASE
        WHEN src.[Q14_ContentRelevance] LIKE N'%مش مناسبة%'
          OR src.[Q14_ContentRelevance] LIKE N'%❌%'               THEN N'Not relevant'
        WHEN src.[Q14_ContentRelevance] LIKE N'%أحيانًا%'
          OR src.[Q14_ContentRelevance] LIKE N'%🤔%'               THEN N'Sometimes relevant'
        WHEN src.[Q14_ContentRelevance] LIKE N'%غالبًا%'
          OR src.[Q14_ContentRelevance] LIKE N'%👍%'               THEN N'Mostly relevant'
        WHEN src.[Q14_ContentRelevance] LIKE N'%جدًا%'
          OR src.[Q14_ContentRelevance] LIKE N'%🎯%'               THEN N'Very relevant'
        ELSE src.[Q14_ContentRelevance]
    END                                                             AS content_relevance,

    -- ── 16. DIFFICULTY CLOSING APP ─────────────────────────────
    CASE
        WHEN src.[Q15_DifficultyClosingApp] LIKE N'%سهل جدًا%'
          OR src.[Q15_DifficultyClosingApp] LIKE N'%😄%'           THEN N'Very easy'
        WHEN src.[Q15_DifficultyClosingApp] LIKE N'%أحيانًا صعب%'
          OR src.[Q15_DifficultyClosingApp] LIKE N'%🤔%'           THEN N'Sometimes hard'
        WHEN src.[Q15_DifficultyClosingApp] LIKE N'%صعب غالبًا%'
          OR src.[Q15_DifficultyClosingApp] LIKE N'%😬%'           THEN N'Usually hard'
        WHEN src.[Q15_DifficultyClosingApp] LIKE N'%صعب جدًا%'
          OR src.[Q15_DifficultyClosingApp] LIKE N'%💀%'           THEN N'Very hard'
        ELSE src.[Q15_DifficultyClosingApp]
    END                                                             AS difficulty_closing_app,

    -- ── 17. PRODUCTIVITY IMPACT ────────────────────────────────
    CASE
        WHEN src.[Q16_ProductivityImpact] LIKE N'%مش مأثرة%'
          OR src.[Q16_ProductivityImpact] LIKE N'%🤷%'             THEN N'No impact'
        WHEN src.[Q16_ProductivityImpact] LIKE N'%بتشتتني%'
          OR src.[Q16_ProductivityImpact] LIKE N'%😕%'             THEN N'Slightly distracting'
        WHEN src.[Q16_ProductivityImpact] LIKE N'%بضيع وقت%'
          OR src.[Q16_ProductivityImpact] LIKE N'%📉%'             THEN N'Wastes productive time'
        WHEN src.[Q16_ProductivityImpact] LIKE N'%بريك%'
          OR src.[Q16_ProductivityImpact] LIKE N'%🎯%'             THEN N'Good break – refocus'
        ELSE src.[Q16_ProductivityImpact]
    END                                                             AS productivity_impact,

    -- ── 18. SLEEP IMPACT ───────────────────────────────────────
    CASE
        WHEN src.[Q17_SleepImpact] LIKE N'%بنام زي الفل%'
          OR src.[Q17_SleepImpact] LIKE N'%😴%'                   THEN N'No impact'
        WHEN src.[Q17_SleepImpact] LIKE N'%شوية زيادة%'
          OR src.[Q17_SleepImpact] LIKE N'%🌙%'                   THEN N'Slightly later (normal)'
        WHEN src.[Q17_SleepImpact] LIKE N'%لحد الفجر%'
          OR src.[Q17_SleepImpact] LIKE N'%😵%'                   THEN N'Very late (regret it)'
        WHEN src.[Q17_SleepImpact] LIKE N'%وحش قوي%'
          OR src.[Q17_SleepImpact] LIKE N'%💀%'                   THEN N'Severely disrupted'
        ELSE src.[Q17_SleepImpact]
    END                                                             AS sleep_impact,

    -- ── 19. FEELING AFTER CLOSING ──────────────────────────────
    CASE
        WHEN src.[Q18_FeelingAfterClosing] LIKE N'%مبسوط%'
          OR src.[Q18_FeelingAfterClosing] LIKE N'%😊%'            THEN N'Happy & refreshed'
        WHEN src.[Q18_FeelingAfterClosing] LIKE N'%ندمان%'
          OR src.[Q18_FeelingAfterClosing] LIKE N'%⏰%'             THEN N'Regret wasted time'
        WHEN src.[Q18_FeelingAfterClosing] LIKE N'%عادي%'
          OR src.[Q18_FeelingAfterClosing] LIKE N'%nothing%'
          OR src.[Q18_FeelingAfterClosing] LIKE N'%😐%'            THEN N'Neutral'
        ELSE src.[Q18_FeelingAfterClosing]
    END                                                             AS feeling_after_closing,

    -- ── 20. WATCHING COMPANION ─────────────────────────────────
    CASE
        WHEN src.[Q19_WatchingCompanion] LIKE N'%لوحدي%'
          OR src.[Q19_WatchingCompanion] LIKE N'%🤫%'              THEN N'Alone'
        WHEN src.[Q19_WatchingCompanion] LIKE N'%الصحاب%'
          OR src.[Q19_WatchingCompanion] LIKE N'%👯%'              THEN N'With friends'
        WHEN src.[Q19_WatchingCompanion] LIKE N'%شريك الحياة%'
          OR src.[Q19_WatchingCompanion] LIKE N'%💑%'              THEN N'With partner'
        WHEN src.[Q19_WatchingCompanion] LIKE N'%الأهل%'
          OR src.[Q19_WatchingCompanion] LIKE N'%👨‍👩‍👧%'         THEN N'With family'
        WHEN src.[Q19_WatchingCompanion] LIKE N'%الشغل%'
          OR src.[Q19_WatchingCompanion] LIKE N'%الجامعة%'
          OR src.[Q19_WatchingCompanion] LIKE N'%زمايل%'
          OR src.[Q19_WatchingCompanion] LIKE N'%☕%'               THEN N'With colleagues'
        ELSE src.[Q19_WatchingCompanion]
    END                                                             AS watching_companion,

    -- ── 21. BEHAVIOR WHILE WATCHING ────────────────────────────
    CASE
        WHEN src.[Q20_BehaviorWhileWatching] LIKE N'%أشاهد فقط%'
          OR src.[Q20_BehaviorWhileWatching] LIKE N'%👀%'          THEN N'Watch only'
        WHEN src.[Q20_BehaviorWhileWatching] LIKE N'%أشارك%'
          OR src.[Q20_BehaviorWhileWatching] LIKE N'%🔄%'          THEN N'Share videos'
        WHEN src.[Q20_BehaviorWhileWatching] LIKE N'%أحفظ%'
          OR src.[Q20_BehaviorWhileWatching] LIKE N'%💾%'          THEN N'Save videos'
        WHEN src.[Q20_BehaviorWhileWatching] LIKE N'%أبحث%'
          OR src.[Q20_BehaviorWhileWatching] LIKE N'%🔍%'          THEN N'Search topic'
        ELSE src.[Q20_BehaviorWhileWatching]
    END                                                             AS behavior_while_watching,

    -- ── 22. PHONE DURING FAMILY ────────────────────────────────
    CASE
        WHEN src.[Q21_PhoneDuringFamily] LIKE N'%بحترم%'
          OR src.[Q21_PhoneDuringFamily] LIKE N'%🤝%'              THEN N'No – respect family time'
        WHEN src.[Q21_PhoneDuringFamily] LIKE N'%معظم الوقت%'
          OR src.[Q21_PhoneDuringFamily] LIKE N'%📵%'              THEN N'Yes, mostly (addicted)'
        WHEN src.[Q21_PhoneDuringFamily] LIKE N'%بشارك الأهل%'
          OR src.[Q21_PhoneDuringFamily] LIKE N'%📱%'              THEN N'Share with family'
        WHEN src.[Q21_PhoneDuringFamily] LIKE N'%بسرعة%'
          OR src.[Q21_PhoneDuringFamily] LIKE N'%👀%'              THEN N'Quick check then back'
        ELSE src.[Q21_PhoneDuringFamily]
    END                                                             AS phone_during_family,

    -- ── 23. FAMILY OPINION ─────────────────────────────────────
    CASE
        WHEN src.[Q22_FamilyOpinion] LIKE N'%بيشجعوني%'
          OR src.[Q22_FamilyOpinion] LIKE N'%👍%'                  THEN N'Supportive'
        WHEN src.[Q22_FamilyOpinion] LIKE N'%بيشتكوا%'
          OR src.[Q22_FamilyOpinion] LIKE N'%⚠️%'                 THEN N'Complain – causes conflict'
        WHEN src.[Q22_FamilyOpinion] LIKE N'%بينصحوني أقلل%'
          OR src.[Q22_FamilyOpinion] LIKE N'%💡%'                  THEN N'Advise to reduce'
        WHEN src.[Q22_FamilyOpinion] LIKE N'%مش مهتمين%'
          OR src.[Q22_FamilyOpinion] LIKE N'%عادي%'
          OR src.[Q22_FamilyOpinion] LIKE N'%😐%'                  THEN N'Indifferent'
        ELSE src.[Q22_FamilyOpinion]
    END                                                             AS family_opinion,

    -- ── 24. REASON FOR WATCHING ────────────────────────────────
    CASE
        WHEN src.[Q23_ReasonForWatching] LIKE N'%تحسين المزاج%'
          OR src.[Q23_ReasonForWatching] LIKE N'%😊%'              THEN N'Mood improvement'
        WHEN src.[Q23_ReasonForWatching] LIKE N'%قتل الوقت%'
          OR src.[Q23_ReasonForWatching] LIKE N'%⏳%'              THEN N'Killing time'
        WHEN src.[Q23_ReasonForWatching] LIKE N'%الترفيه%'
          OR src.[Q23_ReasonForWatching] LIKE N'%🎉%'              THEN N'Entertainment'
        WHEN src.[Q23_ReasonForWatching] LIKE N'%التعلم%'
          OR src.[Q23_ReasonForWatching] LIKE N'%📚%'              THEN N'Learning'
        WHEN src.[Q23_ReasonForWatching] LIKE N'%الترند%'
          OR src.[Q23_ReasonForWatching] LIKE N'%🔥%'              THEN N'Trend following'
        ELSE src.[Q23_ReasonForWatching]
    END                                                             AS reason_for_watching,

    -- ── 25. SOCIAL MEDIA WITHOUT REELS ─────────────────────────
    CASE
        WHEN src.[Q24_SocialMediaWithoutReels] LIKE N'%أقل بكثير%'
          OR src.[Q24_SocialMediaWithoutReels] LIKE N'%⬇️%'        THEN N'Would decrease a lot'
        WHEN src.[Q24_SocialMediaWithoutReels] LIKE N'%أقل قليلاً%'
          OR src.[Q24_SocialMediaWithoutReels] LIKE N'%↘️%'        THEN N'Would decrease slightly'
        WHEN src.[Q24_SocialMediaWithoutReels] LIKE N'%لن يتغير%'
          OR src.[Q24_SocialMediaWithoutReels] LIKE N'%⚖️%'        THEN N'Would not change'
        WHEN src.[Q24_SocialMediaWithoutReels] LIKE N'%ربما يزيد%'
          OR src.[Q24_SocialMediaWithoutReels] LIKE N'%↗️%'        THEN N'Might increase slightly'
        WHEN src.[Q24_SocialMediaWithoutReels] LIKE N'%يزيد بمعدل%'
          OR src.[Q24_SocialMediaWithoutReels] LIKE N'%⬆️%'        THEN N'Would increase a lot'
        ELSE src.[Q24_SocialMediaWithoutReels]
    END                                                             AS social_media_without_reels,

    -- ── 26. PURCHASED FROM VIDEO ───────────────────────────────
    CASE
        WHEN src.[Q25_PurchasedFromVideo] LIKE N'%لأ خالص%'
          OR src.[Q25_PurchasedFromVideo] LIKE N'%لا خالص%'
          OR src.[Q25_PurchasedFromVideo] LIKE N'%🚫%'             THEN N'Never'
        WHEN src.[Q25_PurchasedFromVideo] LIKE N'%بتعجبني%'
          OR src.[Q25_PurchasedFromVideo] LIKE N'%مبشتريش%'
          OR src.[Q25_PurchasedFromVideo] LIKE N'%👀%'             THEN N'Like but never buy'
        WHEN src.[Q25_PurchasedFromVideo] LIKE N'%مرة أو اتنين%'
          OR src.[Q25_PurchasedFromVideo] LIKE N'%🛒%'             THEN N'Once or twice'
        WHEN src.[Q25_PurchasedFromVideo] LIKE N'%آه كتير%'
          OR src.[Q25_PurchasedFromVideo] LIKE N'%🛍️%'            THEN N'Yes, often (easily influenced)'
        ELSE src.[Q25_PurchasedFromVideo]
    END                                                             AS purchased_from_video,

    -- ── 27. PURCHASE REASON ────────────────────────────────────
    CASE
        WHEN src.[Q26_PurchaseReason] LIKE N'%لفتت انتباهي%'
          OR src.[Q26_PurchaseReason] LIKE N'%Visual%'
          OR src.[Q26_PurchaseReason] LIKE N'%👀%'                 THEN N'Visual attraction'
        WHEN src.[Q26_PurchaseReason] LIKE N'%محتوى الفيديو%'
          OR src.[Q26_PurchaseReason] LIKE N'%Persuasive%'
          OR src.[Q26_PurchaseReason] LIKE N'%مقنع%'
          OR src.[Q26_PurchaseReason] LIKE N'%📝%'                 THEN N'Persuasive content'
        WHEN src.[Q26_PurchaseReason] LIKE N'%محتاجها%'
          OR src.[Q26_PurchaseReason] LIKE N'%Need%'
          OR src.[Q26_PurchaseReason] LIKE N'%✅%'                  THEN N'Genuine need'
        WHEN src.[Q26_PurchaseReason] LIKE N'%ترند%'
          OR src.[Q26_PurchaseReason] LIKE N'%Social Proof%'
          OR src.[Q26_PurchaseReason] LIKE N'%🔥%'                 THEN N'Trend / Social proof'
        WHEN src.[Q26_PurchaseReason] LIKE N'%مشترتش%'
          OR src.[Q26_PurchaseReason] LIKE N'%😜%'                 THEN N'N/A – Never purchased'
        ELSE src.[Q26_PurchaseReason]
    END                                                             AS purchase_reason,

    -- ── 28. PURCHASE INFLUENCE LEVEL ───────────────────────────
    CASE
        WHEN src.[Q27_PurchaseInfluenceLevel] LIKE N'%أقل تأثير%'
          OR src.[Q27_PurchaseInfluenceLevel] LIKE N'%Low%'
          OR src.[Q27_PurchaseInfluenceLevel] LIKE N'%🛡️%'        THEN N'Low influence'
        WHEN src.[Q27_PurchaseInfluenceLevel] LIKE N'%أفكر شوية%'
          OR src.[Q27_PurchaseInfluenceLevel] LIKE N'%Moderate%'
          OR src.[Q27_PurchaseInfluenceLevel] LIKE N'%🤔%'         THEN N'Moderate influence'
        WHEN src.[Q27_PurchaseInfluenceLevel] LIKE N'%بسهولة%'
          OR src.[Q27_PurchaseInfluenceLevel] LIKE N'%Impulse%'
          OR src.[Q27_PurchaseInfluenceLevel] LIKE N'%⚡%'          THEN N'Impulse buyer'
        ELSE src.[Q27_PurchaseInfluenceLevel]
    END                                                             AS purchase_influence_level,

    -- ── 29. REWATCHED BEFORE PURCHASE ──────────────────────────
    CASE
        WHEN src.[Q28_RewatchedBeforePurchase] LIKE N'%أبدًا%'
          OR src.[Q28_RewatchedBeforePurchase] LIKE N'%🚫%'        THEN N'Never'
        WHEN src.[Q28_RewatchedBeforePurchase] LIKE N'%نادرًا%'
          OR src.[Q28_RewatchedBeforePurchase] LIKE N'%😐%'        THEN N'Rarely'
        WHEN src.[Q28_RewatchedBeforePurchase] LIKE N'%أحيانًا%'
          OR src.[Q28_RewatchedBeforePurchase] LIKE N'%🤔%'        THEN N'Sometimes'
        WHEN src.[Q28_RewatchedBeforePurchase] LIKE N'%غالبًا%'
          OR src.[Q28_RewatchedBeforePurchase] LIKE N'%🙂%'        THEN N'Usually'
        WHEN src.[Q28_RewatchedBeforePurchase] LIKE N'%دايمًا%'
          OR src.[Q28_RewatchedBeforePurchase] LIKE N'%🌟%'        THEN N'Always'
        ELSE src.[Q28_RewatchedBeforePurchase]
    END                                                             AS rewatched_before_purchase,

    -- ── 30. WATCH INTENSITY SCORE (computed) ───────────────────
    --    Derived purely from daily_watch_hours: < 30 min = 1 … 3+ hrs = 5
    CAST(
        CASE
            WHEN src.[Q8_DailyWatchHours] LIKE N'%أقل من 30%'
              OR src.[Q8_DailyWatchHours] LIKE N'%⚡%'             THEN 1
            WHEN src.[Q8_DailyWatchHours] LIKE N'%30%60%'
              OR src.[Q8_DailyWatchHours] LIKE N'%☕%'             THEN 2
            WHEN src.[Q8_DailyWatchHours] LIKE N'%1%2%ساعة%'
              OR src.[Q8_DailyWatchHours] LIKE N'%🎵 1%'           THEN 3
            WHEN src.[Q8_DailyWatchHours] LIKE N'%2%3%ساعة%'
              OR src.[Q8_DailyWatchHours] LIKE N'%⏰ 2%'           THEN 4
            WHEN src.[Q8_DailyWatchHours] LIKE N'%أكثر من 3%'
              OR src.[Q8_DailyWatchHours] LIKE N'%🔥%'             THEN 5
            ELSE NULL
        END
    AS TINYINT)                                                     AS watch_intensity_score,

    -- ── 31. USER SEGMENT (computed from score) ─────────────────
    CASE
        WHEN src.[Q8_DailyWatchHours] LIKE N'%أقل من 30%'
          OR src.[Q8_DailyWatchHours] LIKE N'%⚡%'
          OR src.[Q8_DailyWatchHours] LIKE N'%30%60%'
          OR src.[Q8_DailyWatchHours] LIKE N'%☕%'                 THEN N'Light User'
        WHEN src.[Q8_DailyWatchHours] LIKE N'%1%2%ساعة%'
          OR src.[Q8_DailyWatchHours] LIKE N'%🎵 1%'               THEN N'Moderate User'
        WHEN src.[Q8_DailyWatchHours] LIKE N'%2%3%ساعة%'
          OR src.[Q8_DailyWatchHours] LIKE N'%⏰ 2%'
          OR src.[Q8_DailyWatchHours] LIKE N'%أكثر من 3%'
          OR src.[Q8_DailyWatchHours] LIKE N'%🔥%'                 THEN N'Heavy User'
        ELSE NULL
    END                                                             AS user_segment,

    -- ── 32. CONTENT COUNT (computed) ───────────────────────────
    --    Count the pipe separators in the translated content_type
    --    = (LEN – LEN without '|') + 1 … handled post-insert
    --    We count the Arabic commas in the source instead (faster).
    CAST(
        LEN(LTRIM(RTRIM(src.[Q9_ContentType])))
        - LEN(REPLACE(LTRIM(RTRIM(src.[Q9_ContentType])), N',', N''))
        + 1
    AS TINYINT)                                                     AS content_count

FROM bronze.survey_3289_records AS src
ORDER BY src.[Timestamp]     -- ensures TOP 264 = earliest 264 rows
;
GO


-- ============================================================
-- 5. QUICK VALIDATION
-- ============================================================
SELECT
    COUNT(*)                                    AS total_rows,
    COUNT(DISTINCT age_group)                   AS distinct_age_groups,
    COUNT(DISTINCT gender)                      AS distinct_genders,
    COUNT(DISTINCT region)                      AS distinct_regions,
    MIN(watch_intensity_score)                  AS min_score,
    MAX(watch_intensity_score)                  AS max_score,
    SUM(CASE WHEN user_segment = 'Light User'    THEN 1 ELSE 0 END) AS light_users,
    SUM(CASE WHEN user_segment = 'Moderate User' THEN 1 ELSE 0 END) AS moderate_users,
    SUM(CASE WHEN user_segment = 'Heavy User'    THEN 1 ELSE 0 END) AS heavy_users
FROM silver.survey_cleaned_english;
GO


-- ============================================================
-- 6. SAMPLE OUTPUT
-- ============================================================
SELECT TOP 5 * FROM silver.survey_cleaned_english ORDER BY timestamp;
GO
