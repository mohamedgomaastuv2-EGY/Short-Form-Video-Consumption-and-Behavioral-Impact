-- LOADING...Data In Bronze Layer


	TRUNCATE TABLE bronze.reels_survey; -- to emty the table before adding the data ( to refresh & add new data is the file is updated

	BULK INSERT bronze.reels_survey 

	FROM 'D:\YF\DATA ANALYST CORE\DEPI TECH TRACK\Final Project\Final Project\Dataset\DWH\Bronze Layer\survey_row_data.csv'

	WITH ( 

	FIRSTROW = 2, 

	FIELDTERMINATOR = ',', 

	TABLOCK 

);
