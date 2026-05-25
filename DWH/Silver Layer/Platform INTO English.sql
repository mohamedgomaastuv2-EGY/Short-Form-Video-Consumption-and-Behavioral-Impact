-- Transforming Data into English

UPDATE silver.platform_survey

SET content_type =

CASE

    WHEN content_type LIKE N'%كوميدي%'
        THEN 'Comedy & Entertainment'

    WHEN content_type LIKE N'%تعليمي%'
      OR content_type LIKE N'%ثقافي%'
        THEN 'Educational & Cultural'

    WHEN content_type LIKE N'%أخبار%'
        THEN 'News & Current Affairs'

    WHEN content_type LIKE N'%ديني%'
        THEN 'Religious'

    WHEN content_type LIKE N'%تطوير%'
        THEN 'Self-development'

    WHEN content_type LIKE N'%رياضة%'
        THEN 'Sports'

    WHEN content_type LIKE N'%موسيقى%'
      OR content_type LIKE N'%رقص%'
        THEN 'Music & Dance'

    WHEN content_type LIKE N'%موضة%'
      OR content_type LIKE N'%جمال%'
        THEN 'Fashion & Beauty'

    WHEN content_type LIKE N'%ألعاب%'
      OR content_type LIKE N'%جيمينج%'
        THEN 'Gaming'

    WHEN content_type LIKE N'%طبخ%'
      OR content_type LIKE N'%وصفات%'
        THEN 'Cooking'

    ELSE content_type

END;