/* ============================================================
   Convert Arabic values → English in silver.reels_survey
   Reference: Reels.xlsx
   Covers all 18 requested columns.
   Safe to run multiple times (already-English rows fall to ELSE
   which keeps the current value unchanged).
   ============================================================ */

-- ── 1. region ────────────────────────────────────────────────
UPDATE silver.reels_survey
SET region =
    CASE
        WHEN region LIKE N'%القاهرة الكبرى%'       THEN N'Greater Cairo'
        WHEN region LIKE N'%الدلتا%'                THEN N'Nile Delta'
        WHEN region LIKE N'%الصعيد%'                THEN N'Upper Egypt'
        WHEN region LIKE N'%الساحل%'                THEN N'North Coast / Red Sea'
        WHEN region LIKE N'%البحر الأحمر%'          THEN N'North Coast / Red Sea'
        WHEN region LIKE N'%القناة%'                THEN N'Canal Zone / Sinai'
        WHEN region LIKE N'%سيناء%'                 THEN N'Canal Zone / Sinai'
        WHEN region LIKE N'%خارج مصر%'             THEN N'Abroad'
        ELSE region
    END;

-- ── 2. occupation ────────────────────────────────────────────
UPDATE silver.reels_survey
SET occupation =
    CASE
        WHEN occupation LIKE N'%موظف%'              THEN N'Employee (Gov/Private)'
        WHEN occupation LIKE N'%عمل حر%'            THEN N'Freelancer'
        WHEN occupation LIKE N'%Freelancer%'        THEN N'Freelancer'
        WHEN occupation LIKE N'%بدرس%'              THEN N'Student'
        WHEN occupation LIKE N'%قاعد في البيت%'     THEN N'Homemaker / Unemployed'
        WHEN occupation LIKE N'%ربة منزل%'          THEN N'Homemaker / Unemployed'
        WHEN occupation LIKE N'%متقاعد%'            THEN N'Retired'
        ELSE occupation
    END;

-- ── 3. education_level ───────────────────────────────────────
UPDATE silver.reels_survey
SET education_level =
    CASE
        WHEN education_level LIKE N'%دراسات عليا%'          THEN N'Postgraduate'
        WHEN education_level LIKE N'%خريج%'                 THEN N'University Graduate'
        WHEN education_level LIKE N'%مؤهل عالي%'           THEN N'University Graduate'
        WHEN education_level LIKE N'%طالب جامعي%'          THEN N'University Student'
        WHEN education_level LIKE N'%طالب ثانوي%'          THEN N'Secondary School Student'
        WHEN education_level LIKE N'%طالب قبل الثانوي%'    THEN N'Pre-Secondary Student'
        WHEN education_level LIKE N'%تعليم متوسط%'         THEN N'Intermediate/Technical Education'
        WHEN education_level LIKE N'%فني%'                  THEN N'Intermediate/Technical Education'
        WHEN education_level LIKE N'%بفك الخط%'            THEN N'Basic Literacy'
        ELSE education_level
    END;

-- ── 4. daily_opens ───────────────────────────────────────────
UPDATE silver.reels_survey
SET daily_opens =
    CASE
        WHEN daily_opens LIKE N'%مرة / مرتين%'              THEN N'1-2 times/day'
        WHEN daily_opens LIKE N'%3 – 5%'                    THEN N'3-5 times/day'
        WHEN daily_opens LIKE N'%6 – 10%'                   THEN N'6-10 times/day'
        WHEN daily_opens LIKE N'%طول اليوم%'                THEN N'All day (lost count)'
        ELSE daily_opens
    END;

-- ── 5. voice_msg_behavior ────────────────────────────────────
UPDATE silver.reels_survey
SET voice_msg_behavior =
    CASE
        WHEN voice_msg_behavior LIKE N'%بسرعته العادية%'    THEN N'Normal speed – no problem'
        WHEN voice_msg_behavior LIKE N'%معنديش مشكلة%'      THEN N'Normal speed – no problem'
        WHEN voice_msg_behavior LIKE N'%معنديش خلق%'        THEN N'No patience – 2x speed'
        WHEN voice_msg_behavior LIKE N'%2×%'                 THEN N'No patience – 2x speed'
        WHEN voice_msg_behavior LIKE N'%مرتين%'             THEN N'No patience – 2x speed'
        WHEN voice_msg_behavior LIKE N'%x2%'                 THEN N'No patience – 2x speed'
        WHEN voice_msg_behavior LIKE N'%جزء منه%'           THEN N'Partial listen if long'
        WHEN voice_msg_behavior LIKE N'%بأجل%'              THEN N'Sometimes postpone'
        WHEN voice_msg_behavior LIKE N'%أجل%'               THEN N'Sometimes postpone'
        ELSE voice_msg_behavior
    END;

-- ── 6. usage_duration_since ──────────────────────────────────
UPDATE silver.reels_survey
SET usage_duration_since =
    CASE
        WHEN usage_duration_since LIKE N'%أقل من 6 شهور%'   THEN N'< 6 months'
        WHEN usage_duration_since LIKE N'%6 شهور إلى سنة%'  THEN N'6-12 months'
        WHEN usage_duration_since LIKE N'%سنة إلى سنتين%'   THEN N'1-2 years'
        WHEN usage_duration_since LIKE N'%سنتين إلى 4%'     THEN N'2-4 years'
        WHEN usage_duration_since LIKE N'%أكثر من 4%'       THEN N'4+ years'
        ELSE usage_duration_since
    END;

-- ── 7. content_relevance ─────────────────────────────────────
UPDATE silver.reels_survey
SET content_relevance =
    CASE
        WHEN content_relevance LIKE N'%مش مناسبة خالص%'     THEN N'Not relevant at all'
        WHEN content_relevance LIKE N'%أحيانًا مناسبة%'     THEN N'Sometimes relevant'
        WHEN content_relevance LIKE N'%مناسبة غالبًا%'      THEN N'Mostly relevant'
        WHEN content_relevance LIKE N'%مناسبة جدًا%'        THEN N'Very relevant'
        ELSE content_relevance
    END;

-- ── 8. feeling_after_closing ─────────────────────────────────
UPDATE silver.reels_survey
SET feeling_after_closing =
    CASE
        WHEN feeling_after_closing LIKE N'%مبسوط%'          THEN N'Happy and refreshed'
        WHEN feeling_after_closing LIKE N'%منتعش%'          THEN N'Happy and refreshed'
        WHEN feeling_after_closing LIKE N'%عادي%'           THEN N'Neutral (nothing special)'
        WHEN feeling_after_closing LIKE N'%ندمان%'          THEN N'Regret wasted time'
        ELSE feeling_after_closing
    END;

-- ── 9. watching_companion ────────────────────────────────────
UPDATE silver.reels_survey
SET watching_companion =
    CASE
        WHEN watching_companion LIKE N'%لوحدي%'             THEN N'Alone (guilty pleasure)'
        WHEN watching_companion LIKE N'%الصحاب%'            THEN N'With friends'
        WHEN watching_companion LIKE N'%شريك الحياة%'       THEN N'With life partner'
        WHEN watching_companion LIKE N'%الأهل%'             THEN N'With family'
        WHEN watching_companion LIKE N'%الزمايل%'           THEN N'With classmates/coworkers'
        WHEN watching_companion LIKE N'%الشغل%'             THEN N'With classmates/coworkers'
        WHEN watching_companion LIKE N'%الجامعة%'           THEN N'With classmates/coworkers'
        ELSE watching_companion
    END;

-- ── 10. behavior_while_watching ──────────────────────────────
UPDATE silver.reels_survey
SET behavior_while_watching =
    CASE
        WHEN behavior_while_watching LIKE N'%أشاهد فقط%'           THEN N'Watch only'
        WHEN behavior_while_watching LIKE N'%أشارك الفيديوهات%'    THEN N'Share videos'
        WHEN behavior_while_watching LIKE N'%أبحث عن نفس%'         THEN N'Search for more on topic'
        WHEN behavior_while_watching LIKE N'%أحفظ الفيديوهات%'     THEN N'Save videos'
        ELSE behavior_while_watching
    END;

-- ── 11. phone_during_family ──────────────────────────────────
UPDATE silver.reels_survey
SET phone_during_family =
    CASE
        WHEN phone_during_family LIKE N'%بحترم القعدة%'             THEN N'No – respect family time'
        WHEN phone_during_family LIKE N'%لا بحترم%'                 THEN N'No – respect family time'
        WHEN phone_during_family LIKE N'%بشوف بسرعة%'              THEN N'Quick check then back'
        WHEN phone_during_family LIKE N'%بشارك الأهل%'             THEN N'Share with family'
        WHEN phone_during_family LIKE N'%مش قادر أسيبه%'           THEN N'Yes, mostly (can''t put it down)'
        WHEN phone_during_family LIKE N'%آه معظم الوقت%'           THEN N'Yes, mostly (can''t put it down)'
        ELSE phone_during_family
    END;

-- ── 12. family_opinion ───────────────────────────────────────
UPDATE silver.reels_survey
SET family_opinion =
    CASE
        WHEN family_opinion LIKE N'%بيشجعوني%'              THEN N'Supportive (edutainment)'
        WHEN family_opinion LIKE N'%بيشتكوا%'               THEN N'Complain – causes conflicts'
        WHEN family_opinion LIKE N'%مشاكل%'                 THEN N'Complain – causes conflicts'
        WHEN family_opinion LIKE N'%بينصحوني%'              THEN N'Advise me to reduce usage'
        WHEN family_opinion LIKE N'%عادي مش مهتمين%'        THEN N'Indifferent'
        ELSE family_opinion
    END;

-- ── 13. reason_for_watching ──────────────────────────────────
UPDATE silver.reels_survey
SET reason_for_watching =
    CASE
        WHEN reason_for_watching LIKE N'%تحسين المزاج%'     THEN N'Mood improvement'
        WHEN reason_for_watching LIKE N'%قتل الوقت%'        THEN N'Killing time'
        WHEN reason_for_watching LIKE N'%الترفيه%'          THEN N'Entertainment'
        WHEN reason_for_watching LIKE N'%التعلم%'           THEN N'Learning'
        WHEN reason_for_watching LIKE N'%الترند%'           THEN N'Following trends'
        ELSE reason_for_watching
    END;

-- ── 14. social_media_without_reels ──────────────────────────
UPDATE silver.reels_survey
SET social_media_without_reels =
    CASE
        WHEN social_media_without_reels LIKE N'%أقل بكثير%'         THEN N'Would decrease a lot'
        WHEN social_media_without_reels LIKE N'%أقل قليلاً%'        THEN N'Would decrease slightly'
        WHEN social_media_without_reels LIKE N'%لن يتغير%'          THEN N'Would not change'
        WHEN social_media_without_reels LIKE N'%ربما يزيد%'         THEN N'Might increase slightly'
        WHEN social_media_without_reels LIKE N'%سيزيد بمعدل كبير%'  THEN N'Would increase a lot'
        ELSE social_media_without_reels
    END;

-- ── 15. purchased_from_video ─────────────────────────────────
UPDATE silver.reels_survey
SET purchased_from_video =
    CASE
        WHEN purchased_from_video LIKE N'%لأ خالص%'                 THEN N'Never'
        WHEN purchased_from_video LIKE N'%لا خالص%'                 THEN N'Never'
        WHEN purchased_from_video LIKE N'%مرة أو اتنين%'            THEN N'Once or twice'
        WHEN purchased_from_video LIKE N'%بتعجبني حاجات%'           THEN N'Like items but never buy'
        WHEN purchased_from_video LIKE N'%مبشتريش%'                 THEN N'Like items but never buy'
        WHEN purchased_from_video LIKE N'%آه كتير%'                 THEN N'Yes, often (easily influenced)'
        ELSE purchased_from_video
    END;

-- ── 16. purchase_reason ──────────────────────────────────────
UPDATE silver.reels_survey
SET purchase_reason =
    CASE
        WHEN purchase_reason LIKE N'%لفتت انتباهي%'                 THEN N'Visual attraction'
        WHEN purchase_reason LIKE N'%Visual Attraction%'            THEN N'Visual attraction'
        WHEN purchase_reason LIKE N'%محتوى الفيديو كان مقنع%'      THEN N'Persuasive content'
        WHEN purchase_reason LIKE N'%Content Persuasiveness%'       THEN N'Persuasive content'
        WHEN purchase_reason LIKE N'%محتاجها بالفعل%'              THEN N'Genuine need'
        WHEN purchase_reason LIKE N'%Need%'                         THEN N'Genuine need'
        WHEN purchase_reason LIKE N'%مشترتش%'                      THEN N'N/A – Never purchased'
        WHEN purchase_reason LIKE N'%ترند%'                         THEN N'Trend / Social proof'
        WHEN purchase_reason LIKE N'%Trend%'                        THEN N'Trend / Social proof'
        WHEN purchase_reason LIKE N'%Social Proof%'                 THEN N'Trend / Social proof'
        ELSE purchase_reason
    END;

-- ── 17. purchase_influence_level ─────────────────────────────
UPDATE silver.reels_survey
SET purchase_influence_level =
    CASE
        WHEN purchase_influence_level LIKE N'%أقل تأثير%'           THEN N'Low influence'
        WHEN purchase_influence_level LIKE N'%Low Influence%'       THEN N'Low influence'
        WHEN purchase_influence_level LIKE N'%أفكر شوية%'           THEN N'Moderate influence'
        WHEN purchase_influence_level LIKE N'%Moderate Influence%'  THEN N'Moderate influence'
        WHEN purchase_influence_level LIKE N'%بدون تفكير%'          THEN N'High influence (impulse)'
        WHEN purchase_influence_level LIKE N'%Impulse%'             THEN N'High influence (impulse)'
        ELSE purchase_influence_level
    END;

-- ── 18. rewatched_before_purchase ────────────────────────────
UPDATE silver.reels_survey
SET rewatched_before_purchase =
    CASE
        WHEN rewatched_before_purchase LIKE N'%أبدًا%'              THEN N'Never'
        WHEN rewatched_before_purchase LIKE N'%نادرًا%'             THEN N'Rarely'
        WHEN rewatched_before_purchase LIKE N'%أحيانًا%'            THEN N'Sometimes'
        WHEN rewatched_before_purchase LIKE N'%غالبًا%'             THEN N'Usually'
        WHEN rewatched_before_purchase LIKE N'%دايمًا%'             THEN N'Always'
        ELSE rewatched_before_purchase
    END;

-- ── Verify: sample 10 rows after update ──────────────────────
SELECT TOP 10
    region, occupation, education_level, daily_opens,
    voice_msg_behavior, usage_duration_since, content_relevance,
    feeling_after_closing, watching_companion, behavior_while_watching,
    phone_during_family, family_opinion, reason_for_watching,
    social_media_without_reels, purchased_from_video, purchase_reason,
    purchase_influence_level, rewatched_before_purchase
FROM silver.reels_survey
ORDER BY user_id;
