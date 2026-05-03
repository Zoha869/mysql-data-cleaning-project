-- ============================================
-- MySQL Data Cleaning Project: Layoffs Dataset
-- ============================================

-- Step 1: View raw data
SELECT * 
FROM world_layoffs.layoffs;

-- Step 2: Create staging table
CREATE TABLE layoffs_staging LIKE world_layoffs.layoffs;

-- Step 3: Insert raw data into staging
INSERT INTO layoffs_staging
SELECT * FROM world_layoffs.layoffs;

-- Step 4: Remove duplicates using ROW_NUMBER()
CREATE TABLE layoffs_cleaned AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY company, location, industry, total_laid_off, 
                            percentage_laid_off, date, stage, country, funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
) t
WHERE row_num = 1;

-- Step 5: Standardize company names
UPDATE layoffs_cleaned
SET company = TRIM(company);

-- Step 6: Standardize industry
UPDATE layoffs_cleaned
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Step 7: Standardize country names
UPDATE layoffs_cleaned
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Step 8: Convert date format
UPDATE layoffs_cleaned
SET date = STR_TO_DATE(date, '%m/%d/%Y');

ALTER TABLE layoffs_cleaned
MODIFY COLUMN date DATE;

-- Step 9: Handle missing industry using self join
UPDATE layoffs_cleaned t1
JOIN layoffs_cleaned t2
     ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- Step 10: Remove empty industry values
UPDATE layoffs_cleaned
SET industry = NULL
WHERE industry = '';

-- Step 11: Remove rows with no layoff info
DELETE FROM layoffs_cleaned
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Step 12: Final cleaned data
SELECT * FROM layoffs_cleaned;