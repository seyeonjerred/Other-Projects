-- AUTOMATED DATA CLEANING PROJECT --

SELECT * 
FROM us_household_income1;

SELECT * 
FROM us_household_income1_cleaned;


DELIMITER $$
DROP PROCEDURE IF EXISTS Copy_and_Clean_Data;
CREATE PROCEDURE Copy_and_Clean_Data()
BEGIN
	-- 1. CREATE NEW TABLE (BACKUP TABLE) --
	CREATE TABLE IF NOT EXISTS `us_household_income1_cleaned` (
		`row_id` int DEFAULT NULL,
		`id` int DEFAULT NULL,
		`State_Code` int DEFAULT NULL,
		`State_Name` text,
		`State_ab` text,
		`County` text,
		`City` text,
		`Place` text,
		`Type` text,
		`Primary` text,
		`Zip_Code` int DEFAULT NULL,
		`Area_Code` int DEFAULT NULL,
		`ALand` int DEFAULT NULL,
		`AWater` int DEFAULT NULL,
		`Lat` double DEFAULT NULL,
		`Lon` double DEFAULT NULL,
		`TimeStamp` TIMESTAMP DEFAULT NULL
	) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

	-- 2. COPY RAW DATA TO BACKUP TABLE --
	INSERT INTO us_household_income1_cleaned
	SELECT *, CURRENT_TIMESTAMP
	FROM us_household_income1;

	-- 3. DATA CLEANING STEPS --
    
	-- 3.1 Remove Duplicates
	DELETE FROM us_household_income1_cleaned 
	WHERE row_id IN (
		SELECT row_id
		FROM (
			SELECT row_id, id,
				ROW_NUMBER() OVER (
					PARTITION BY id, `TimeStamp`
					ORDER BY id, `TimeStamp`) AS row_num
			FROM 
				us_household_income1_cleaned
			) AS duplicates
		WHERE 
			row_num > 1
		);

	-- 3.2 Standardization 
	UPDATE us_household_income1_cleaned
	SET State_Name = 'Georgia'
	WHERE State_Name = 'georia';

	UPDATE us_household_income1_cleaned
	SET County = UPPER(County);

	UPDATE us_household_income1_cleaned
	SET City = UPPER(City);

	UPDATE us_household_income1_cleaned
	SET Place = UPPER(Place);

	UPDATE us_household_income1_cleaned
	SET State_Name = UPPER(State_Name);

	UPDATE us_household_income1_cleaned
	SET `Type` = 'CDP'
	WHERE `Type` = 'CPD';

	UPDATE us_household_income1_cleaned
	SET `Type` = 'Borough'
	WHERE `Type` = 'Boroughs';

END $$
DELIMITER ;


CALL Copy_and_Clean_Data();


-- 4. CREATE EVENT --
DROP EVENT run_data_cleaning;
CREATE EVENT run_data_cleaning
	ON SCHEDULE EVERY 30 DAY
DO CALL Copy_and_Clean_Data();

SELECT DISTINCT TimeStamp
FROM us_household_income1_cleaned;




-- 5. DEBUGGING & CHECKING THAT STORED PROCEDURE WORKS --
SELECT row_id, id, row_num
FROM (
	SELECT row_id, id,
		ROW_NUMBER() OVER (
			PARTITION BY id
			ORDER BY id) AS row_num
	FROM us_household_income1 			# to check, run: use_hold_income1_cleaned
		AS ) duplicates
	WHERE 
		row_num > 1;


SELECT COUNT(row_id)
FROM us_household_income1; 				# to check, run: use_hold_income1_cleaned

SELECT State_Name, COUNT(State_Name)
FROM us_household_income1 				# to check, run: use_hold_income1_cleaned
GROUP BY State_Name;
