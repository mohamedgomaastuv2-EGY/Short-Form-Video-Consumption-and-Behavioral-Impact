DROP TABLE IF EXISTS silver.platform_survey;
GO

CREATE TABLE silver.platform_survey (
    user_id INT,
    primary_platform NVARCHAR(100),
    content_type NVARCHAR(100)
);
GO