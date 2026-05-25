/* ============================================================
   SILVER LAYER — silver.reels_survey
   ============================================================
   Source  : bronze.reels_survey  (3,289 rows loaded from CSV)
   Target  : silver.reels_survey
   Purpose : Clean, normalise, and enrich the raw survey data
             so that it matches the shape produced by the
             reference files  Reels.xlsx  and  df_platform.xlsx

   Transformation steps performed
   ───────────────────────────────
   1.  DDL  – create the silver table with correct data types
   2.  CLEAN – strip Arabic text, emojis, markdown decorators
               and map every raw response to a clean English label
   3.  ENRICH – derive the four calculated columns:
               watch_intensity_score, user_segment,
               content_count, user_id
   ============================================================ */


/* ============================================================
   STEP 1 — DROP & CREATE  silver.reels_survey
   ============================================================
   Column order and types mirror Reels.xlsx exactly.
   Nullable columns are those that allow NULLs in the source.
   ============================================================ */

IF OBJECT_ID('silver.reels_survey', 'U') IS NOT NULL
    DROP TABLE silver.reels_survey;
GO

CREATE TABLE silver.reels_survey
(
    /* ── Demographic columns ──────────────────────────────── */
    age_group                   NVARCHAR(20)    NOT NULL,
    gender                      NVARCHAR(10)    NOT NULL,
    region                      NVARCHAR(60)    NOT NULL,
    marital_status              NVARCHAR(40)    NOT NULL,
    occupation                  NVARCHAR(50)    NOT NULL,
    education_level             NVARCHAR(50)    NOT NULL,

    /* ── Platform & content columns ──────────────────────── */
    primary_platform            NVARCHAR(200)   NOT NULL,
    daily_watch_hours           NVARCHAR(20)    NOT NULL,  -- cleaned label: '< 30 min', '30-60 min', etc.
    content_type                NVARCHAR(500)   NOT NULL,  -- stored as Python-list string, e.g. "['Comedy & Entertainment']"
    peak_usage_time             NVARCHAR(50)    NOT NULL,
    daily_opens                 NVARCHAR(30)    NOT NULL,  -- cleaned label: '1-2 times/day', etc.

    /* ── Behaviour columns ────────────────────────────────── */
    voice_msg_behavior          NVARCHAR(100)   NULL,      -- NULL when respondent skipped
    usage_duration_since        NVARCHAR(30)    NOT NULL,
    content_relevance           NVARCHAR(50)    NOT NULL,
    difficulty_closing_app      NVARCHAR(20)    NOT NULL,
    productivity_impact         NVARCHAR(60)    NOT NULL,
    sleep_impact                NVARCHAR(50)    NOT NULL,
    feeling_after_closing       NVARCHAR(50)    NOT NULL,
    watching_companion          NVARCHAR(40)    NOT NULL,
    behavior_while_watching     NVARCHAR(30)    NOT NULL,
    phone_during_family         NVARCHAR(60)    NOT NULL,
    family_opinion              NVARCHAR(50)    NOT NULL,
    reason_for_watching         NVARCHAR(30)    NOT NULL,
    social_media_without_reels  NVARCHAR(30)    NOT NULL,

    /* ── Purchase behaviour columns ──────────────────────── */
    purchased_from_video        NVARCHAR(40)    NOT NULL,
    purchase_reason             NVARCHAR(40)    NOT NULL,
    purchase_influence_level    NVARCHAR(50)    NOT NULL,
    rewatched_before_purchase   NVARCHAR(20)    NOT NULL,

    /* ── Derived / enriched columns ──────────────────────── */
    watch_intensity_score       TINYINT         NOT NULL,  -- 1-5 ordinal score (see derivation logic below)
    user_segment                NVARCHAR(15)    NOT NULL,  -- 'Light User' | 'Moderate User' | 'Heavy User'
    content_count               TINYINT         NOT NULL,  -- number of content types selected
    user_id                     INT             NOT NULL    -- zero-based row index (surrogate key)
);
GO


/* ============================================================
   STEP 2 — POPULATE  silver.reels_survey
   ============================================================
   All cleaning is done inline via CASE expressions.

   Cleaning strategy
   ─────────────────
   The raw CSV contains three formatting variants per answer:
     a) Plain Arabic  e.g.  '😄 سهل جدًا'
     b) Markdown bold  e.g.  '* 😄 **سهل جدًا**'
     c) Enriched (already mapped by the Python pipeline) – only
        appears in Reels.xlsx, not in the bronze table.

   We collapse variants (a) and (b) to a single clean English
   label that matches what Reels.xlsx contains.
   ============================================================ */

INSERT INTO silver.reels_survey
(
    age_group, gender, region, marital_status, occupation, education_level,
    primary_platform, daily_watch_hours, content_type, peak_usage_time, daily_opens,
    voice_msg_behavior, usage_duration_since, content_relevance, difficulty_closing_app,
    productivity_impact, sleep_impact, feeling_after_closing, watching_companion,
    behavior_while_watching, phone_during_family, family_opinion, reason_for_watching,
    social_media_without_reels, purchased_from_video, purchase_reason,
    purchase_influence_level, rewatched_before_purchase,
    watch_intensity_score, user_segment, content_count, user_id
)
SELECT
    /* ── age_group ─────────────────────────────────────────
       Raw values already in English; pass through directly.    */
    age_group,

    /* ── gender ────────────────────────────────────────────
       Raw values already in English; pass through directly.    */
    gender,

    /* ── region ────────────────────────────────────────────
       Raw values already in English; pass through directly.    */
    region,

    /* ── marital_status ────────────────────────────────────
       Raw values already in English; pass through directly.    */
    marital_status,

    /* ── occupation ────────────────────────────────────────
       Raw values already in English; pass through directly.    */
    occupation,

    /* ── education_level ───────────────────────────────────
       Raw values already in English; pass through directly.    */
    education_level,

    /* ── primary_platform ──────────────────────────────────
       Raw values already in English; pass through directly.    */
    primary_platform,

    /* ── daily_watch_hours ─────────────────────────────────
       Maps five Arabic/emoji variants to short English labels.
       These labels are used later to derive watch_intensity_score. */
    CASE
        WHEN daily_watch_hours LIKE N'%أقل من 30%'          THEN '< 30 min'
        WHEN daily_watch_hours LIKE N'%30%60%'              THEN '30-60 min'
        WHEN daily_watch_hours LIKE N'%1%2%ساعة%'           THEN '1-2 hrs'
        WHEN daily_watch_hours LIKE N'%2%3%ساعة%'           THEN '2-3 hrs'
        WHEN daily_watch_hours LIKE N'%أكثر من 3%'          THEN '3+ hrs'
        ELSE daily_watch_hours   -- safety fallback; should not occur
    END,

    /* ── content_type ──────────────────────────────────────
       Raw values already in English (multi-select stored as a
       Python list string); pass through directly.             */
    content_type,

    /* ── peak_usage_time ───────────────────────────────────
       Raw values already in English; pass through directly.    */
    peak_usage_time,

    /* ── daily_opens ───────────────────────────────────────
       Two formatting variants (plain-Arabic and markdown-bold)
       for each of the four options.                           */
    CASE
        WHEN daily_opens LIKE N'%مرة / مرتين%'              THEN '1-2 times/day'
        WHEN daily_opens LIKE N'%مرة / مرتين%'              THEN '1-2 times/day'
        WHEN daily_opens LIKE N'%3%5%'                      THEN '3-5 times/day'
        WHEN daily_opens LIKE N'%6%10%'                     THEN '6-10 times/day'
        WHEN daily_opens LIKE N'%طول اليوم%'                THEN 'All day (lost count)'
        ELSE daily_opens
    END,

    /* ── voice_msg_behavior ────────────────────────────────
       Free-text Arabic field; kept as-is (NULL when blank).
       No mapping needed – Reels.xlsx stores raw Arabic text.  */
    NULLIF(LTRIM(RTRIM(voice_msg_behavior)), ''),

    /* ── usage_duration_since ──────────────────────────────
       Maps six Arabic/emoji variants to English duration bands. */
    CASE
        WHEN usage_duration_since LIKE N'%أقل من 6 شهور%'         THEN '< 6 months'
        WHEN usage_duration_since LIKE N'%6 شهور%سنة%'            THEN '6m - 1 yr'
        WHEN usage_duration_since LIKE N'%سنة%سنتين%'             THEN '1 - 2 yrs'
        WHEN usage_duration_since LIKE N'%سنتين%4%'               THEN '2 - 4 yrs'
        WHEN usage_duration_since LIKE N'%أكثر من 4%'             THEN '4+ yrs'
        ELSE usage_duration_since
    END,

    /* ── content_relevance ─────────────────────────────────
       Four distinct Arabic options (two formatting variants each). */
    CASE
        WHEN content_relevance LIKE N'%مش مناسبة خالص%'           THEN 'Not relevant at all'
        WHEN content_relevance LIKE N'%أحيانًا مناسبة%'           THEN 'Sometimes relevant'
        WHEN content_relevance LIKE N'%مناسبة غالبًا%'            THEN 'Usually relevant'
        WHEN content_relevance LIKE N'%مناسبة جدًا%'              THEN 'Very relevant (feels personalised)'
        ELSE content_relevance
    END,

    /* ── difficulty_closing_app ────────────────────────────
       Four options mapped to English difficulty labels.       */
    CASE
        WHEN difficulty_closing_app LIKE N'%سهل جدًا%'            THEN 'Very easy'
        WHEN difficulty_closing_app LIKE N'%أحيانًا صعب%'         THEN 'Sometimes hard'
        WHEN difficulty_closing_app LIKE N'%صعب غالبًا%'          THEN 'Usually hard'
        WHEN difficulty_closing_app LIKE N'%صعب جدًا%'            THEN 'Very hard'
        ELSE difficulty_closing_app
    END,

    /* ── productivity_impact ───────────────────────────────
       Four options describing how reels affect productivity.  */
    CASE
        WHEN productivity_impact LIKE N'%مش مأثرة%'               THEN 'No impact'
        WHEN productivity_impact LIKE N'%بتشتتني%'                THEN 'Somewhat distracting'
        WHEN productivity_impact LIKE N'%بتديني بريك%'            THEN 'Good break – improves focus'
        WHEN productivity_impact LIKE N'%بضيع وقت%'               THEN 'Wastes a lot of productive time'
        ELSE productivity_impact
    END,

    /* ── sleep_impact ──────────────────────────────────────
       Four options describing effect on sleep quality.       */
    CASE
        WHEN sleep_impact LIKE N'%لأ خالص%'    OR
             sleep_impact LIKE N'%لا خالص%'                       THEN 'No impact – sleep fine'
        WHEN sleep_impact LIKE N'%بسهر شوية%'                     THEN 'Stay up slightly late'
        WHEN sleep_impact LIKE N'%لحد الفجر%'                     THEN 'Stay up until dawn'
        WHEN sleep_impact LIKE N'%نومي بقى وحش%'                  THEN 'Sleep quality is terrible'
        ELSE sleep_impact
    END,

    /* ── feeling_after_closing ─────────────────────────────
       Three options about how the user feels after closing app. */
    CASE
        WHEN feeling_after_closing LIKE N'%مبسوط%'                THEN 'Happy & refreshed'
        WHEN feeling_after_closing LIKE N'%عادي%'                  THEN 'Neutral – nothing special'
        WHEN feeling_after_closing LIKE N'%ندمان%'                 THEN 'Regret lost time'
        ELSE feeling_after_closing
    END,

    /* ── watching_companion ────────────────────────────────
       Raw values already in English; pass through directly.  */
    watching_companion,

    /* ── behavior_while_watching ───────────────────────────
       Raw values already in English; pass through directly.  */
    behavior_while_watching,

    /* ── phone_during_family ───────────────────────────────
       Four Arabic options about phone use during family time. */
    CASE
        WHEN phone_during_family LIKE N'%بحترم القعدة%'    OR
             phone_during_family LIKE N'%بحترم القعدة%'           THEN 'No – respect family time'
        WHEN phone_during_family LIKE N'%بشوف بسرعة%'             THEN 'Quick look then back'
        WHEN phone_during_family LIKE N'%بشارك الأهل%'            THEN 'Share nice videos with family'
        WHEN phone_during_family LIKE N'%مش قادر أسيبه%'          THEN 'Yes – most of the time (can\'t stop)'
        ELSE phone_during_family
    END,

    /* ── family_opinion ────────────────────────────────────
       Raw values already in English; pass through directly.  */
    family_opinion,

    /* ── reason_for_watching ───────────────────────────────
       Raw values already in English; pass through directly.  */
    reason_for_watching,

    /* ── social_media_without_reels ────────────────────────
       Five options about social-media usage if reels disappeared. */
    CASE
        WHEN social_media_without_reels LIKE N'%أقل بكثير%'       THEN 'Much less'
        WHEN social_media_without_reels LIKE N'%أقل قليلاً%'      THEN 'Slightly less'
        WHEN social_media_without_reels LIKE N'%لن يتغير%'        THEN 'No change'
        WHEN social_media_without_reels LIKE N'%ربما يزيد%'       THEN 'Maybe more'
        WHEN social_media_without_reels LIKE N'%سيزيد%'           THEN 'Would increase significantly'
        ELSE social_media_without_reels
    END,

    /* ── purchased_from_video ──────────────────────────────
       Four options about whether user has bought from a video ad. */
    CASE
        WHEN purchased_from_video LIKE N'%لأ خالص%'    OR
             purchased_from_video LIKE N'%لا خالص%'               THEN 'Never'
        WHEN purchased_from_video LIKE N'%مرة أو اتنين%'  OR
             purchased_from_video LIKE N'%مرة أو اتنين%'          THEN 'Once or twice'
        WHEN purchased_from_video LIKE N'%بتعجبني%مبشتريش%'       THEN 'Like things but don\'t buy'
        WHEN purchased_from_video LIKE N'%آه كتير%'               THEN 'Yes – often (influenced easily)'
        ELSE purchased_from_video
    END,

    /* ── purchase_reason ───────────────────────────────────
       Raw values already in English; pass through directly.  */
    purchase_reason,

    /* ── purchase_influence_level ──────────────────────────
       Three Arabic options about how easily the user is influenced. */
    CASE
        WHEN purchase_influence_level LIKE N'%أقل تأثير%'         THEN 'Low Influence'
        WHEN purchase_influence_level LIKE N'%أفكر شوية%'         THEN 'Moderate Influence'
        WHEN purchase_influence_level LIKE N'%بدون تفكير%'        THEN 'Impulse'
        ELSE purchase_influence_level
    END,

    /* ── rewatched_before_purchase ─────────────────────────
       Five-level frequency about rewatching before deciding to buy. */
    CASE
        WHEN rewatched_before_purchase LIKE N'%أبدًا%'            THEN 'Never'
        WHEN rewatched_before_purchase LIKE N'%نادرًا%'           THEN 'Rarely'
        WHEN rewatched_before_purchase LIKE N'%أحيانًا%'          THEN 'Sometimes'
        WHEN rewatched_before_purchase LIKE N'%غالبًا%'           THEN 'Usually'
        WHEN rewatched_before_purchase LIKE N'%دايمًا%'           THEN 'Always'
        ELSE rewatched_before_purchase
    END,

    /* ── watch_intensity_score ─────────────────────────────
       Derived ordinal score (1–5) based on daily_watch_hours only.
       This matches the pattern observed in Reels.xlsx:
         < 30 min    → 1
         30-60 min   → 2
         1-2 hrs     → 3
         2-3 hrs     → 4
         3+ hrs      → 5
       daily_opens does NOT shift the score; the hour band alone
       determines it (all opens × hours combos in the xlsx confirmed
       the score is purely hour-based).                            */
    CASE
        WHEN daily_watch_hours LIKE N'%أقل من 30%'                THEN CAST(1 AS TINYINT)
        WHEN daily_watch_hours LIKE N'%30%60%'                    THEN CAST(2 AS TINYINT)
        WHEN daily_watch_hours LIKE N'%1%2%ساعة%'                 THEN CAST(3 AS TINYINT)
        WHEN daily_watch_hours LIKE N'%2%3%ساعة%'                 THEN CAST(4 AS TINYINT)
        WHEN daily_watch_hours LIKE N'%أكثر من 3%'                THEN CAST(5 AS TINYINT)
        ELSE CAST(3 AS TINYINT)   -- safe default (mid-range) if unmatched
    END,

    /* ── user_segment ──────────────────────────────────────
       Derived from watch_intensity_score bucket:
         1-2  → Light User
         3    → Moderate User
         4-5  → Heavy User                                        */
    CASE
        WHEN daily_watch_hours LIKE N'%أقل من 30%'                THEN N'Light User'
        WHEN daily_watch_hours LIKE N'%30%60%'                    THEN N'Light User'
        WHEN daily_watch_hours LIKE N'%1%2%ساعة%'                 THEN N'Moderate User'
        WHEN daily_watch_hours LIKE N'%2%3%ساعة%'                 THEN N'Heavy User'
        WHEN daily_watch_hours LIKE N'%أكثر من 3%'                THEN N'Heavy User'
        ELSE N'Moderate User'
    END,

    /* ── content_count ─────────────────────────────────────
       Number of content-type categories the respondent selected.
       The raw value is stored as a Python list string, e.g.
       "['Comedy & Entertainment', 'Educational & Cultural']"
       We count the commas and add 1 to get the item count.
       A single-item answer has no commas → LEN diff = 0 → count = 1. */
    CAST(
        (LEN(content_type) - LEN(REPLACE(content_type, ',', ''))) + 1
    AS TINYINT),

    /* ── user_id ───────────────────────────────────────────
       Zero-based surrogate row index matching Reels.xlsx user_id.
       ROW_NUMBER() is 1-based, so we subtract 1.               */
    CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS INT)

FROM
    bronze.reels_survey;
GO


/* ============================================================
   STEP 3 — VERIFICATION QUERIES
   ============================================================
   Run these after the INSERT to confirm the silver table
   matches Reels.xlsx in shape and key distributions.
   ============================================================ */

-- Row count should be 3,289
SELECT COUNT(*) AS total_rows FROM silver.reels_survey;

-- Segment distribution should match: Light~887, Moderate~826, Heavy~1576
SELECT user_segment, COUNT(*) AS cnt
FROM   silver.reels_survey
GROUP  BY user_segment
ORDER  BY cnt DESC;

-- Score distribution: 1=218, 2=669, 3=826, 4=652, 5=924
SELECT watch_intensity_score, COUNT(*) AS cnt
FROM   silver.reels_survey
GROUP  BY watch_intensity_score
ORDER  BY watch_intensity_score;

-- Confirm user_id is 0-based and unique
SELECT MIN(user_id) AS min_id, MAX(user_id) AS max_id,
       COUNT(DISTINCT user_id) AS distinct_ids
FROM   silver.reels_survey;

-- Sample first 5 rows (mirrors Reels.xlsx)
SELECT TOP 5 *
FROM   silver.reels_survey
ORDER  BY user_id;
GO


/* ============================================================
   APPENDIX — df_platform reference view
   ============================================================
   df_platform.xlsx is a flattened version of silver.reels_survey
   where each content type appears on its own row (one row per
   user × platform × content-type combination).

   The query below recreates df_platform on demand.
   Store it as a view or use it in downstream ETL.
   ============================================================ */

CREATE OR ALTER VIEW silver.vw_reels_platform
AS
/*
   Unpivots the multi-value content_type list string into
   individual rows, pairing each user_id with their
   primary_platform and a single content_type value.

   The string format is: ['Type A', 'Type B', 'Type C']
   We strip the outer brackets/quotes and use STRING_SPLIT
   (SQL Server 2016+) to explode the comma-separated values.
*/
WITH cleaned AS
(
    SELECT
        user_id,
        primary_platform,
        -- Remove leading [' and trailing '] to get a clean CSV string
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(content_type, '[''', ''),   -- strip ['
                    ''']', ''),                          -- strip ']
                ''', ''', ','),                          -- ' ', ' → comma separator
                ' ', '')                                 -- trim spaces left by quotes
        AS content_csv
    FROM silver.reels_survey
),
split AS
(
    SELECT
        user_id,
        primary_platform,
        LTRIM(RTRIM(value)) AS content_type_raw
    FROM cleaned
    CROSS APPLY STRING_SPLIT(content_csv, ',')
    WHERE LTRIM(RTRIM(value)) <> ''
)
SELECT
    user_id,
    primary_platform,
    -- Restore spaces that were removed during cleaning
    REPLACE(content_type_raw, '&', ' & ') AS content_type
FROM split;
GO
