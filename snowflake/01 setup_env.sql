-- ==========================================================
-- 01: ANALYTICAL ENVIRONMENT SETUP
-- Project: Sydney Duty Free Sales Insights
-- Architecture: Medallion (Bronze, Silver, Gold) for reliable data analysis
-- ==========================================================

USE ROLE ACCOUNTADMIN;

------------------------------------------------------------
-- 1. Create a dedicated Warehouse for the project
------------------------------------------------------------

-- I use a 'SMALL' size for typical data analytics tasks.
-- AUTO_SUSPEND = 60: The warehouse turns off after 60 seconds of inactivity to save credits.
CREATE OR REPLACE WAREHOUSE SYDNEY_DF_WH
    WITH 
        WAREHOUSE_SIZE = 'SMALL'
        AUTO_SUSPEND = 60
        AUTO_RESUME = TRUE  
        INITIALLY_SUSPENDED = TRUE          -- Starts in a suspended state to avoid immediate costs
    COMMENT = 'Dedicated warehouse for Sydney Duty Free analytics';

-- Use the newly created warehouse
USE WAREHOUSE SYDNEY_DF_WH;

------------------------------------------------------------
-- 2. Create the dedicated database
------------------------------------------------------------

CREATE OR REPLACE DATABASE SYDNEY_DF_DB
COMMENT = 'Database for Sydney Duty Free sales analysis and reporting';

------------------------------------------------------------
-- 3. Create schemas based on the Medallion Architecture
------------------------------------------------------------

CREATE OR REPLACE SCHEMA SYDNEY_DF_DB.BRONZE;   -- BRONZE: Raw landing zone for original CSV files (unchanged).
CREATE OR REPLACE SCHEMA SYDNEY_DF_DB.SILVER;   -- SILVER: Cleaned and standardised data ready for modeling.
CREATE OR REPLACE SCHEMA SYDNEY_DF_DB.GOLD;     -- GOLD: Aggregated business metrics and final reporting views.

------------------------------------------------------------
-- 4. Create an Internal Stage for data ingestion
------------------------------------------------------------

-- This stage acts as a gateway to upload local CSV files into Snowflake.
-- Located in the BRONZE schema to maintain clear data lineage.
CREATE OR REPLACE STAGE SYDNEY_DF_DB.BRONZE.CSV_STAGE
DIRECTORY = (ENABLE = TRUE)
COMMENT = 'Stage area for raw CSV files from Sydney Duty Free stores';

------------------------------------------------------------
-- 5. Define the CSV File Format
------------------------------------------------------------

-- Ensuring consistent data parsing and handling of null values during ingestion.
CREATE OR REPLACE FILE FORMAT SYDNEY_DF_DB.BRONZE.CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','                   -- Standard comma separation
    SKIP_HEADER = 1                         -- Ignore header row during COPY INTO
    NULL_IF = ('NULL', 'null', '', 'NA')    -- Handle various null string formats
    EMPTY_FIELD_AS_NULL = TRUE              -- Convert empty fields to SQL NULL
    FIELD_OPTIONALLY_ENCLOSED_BY = '"';     -- Support for fields containing commas

------------------------------------------------------------
-- 6. Verification: List all created schemas to confirm setup
------------------------------------------------------------

-- This ensures the infrastructure is ready for the data ingestion step.
SHOW SCHEMAS IN DATABASE SYDNEY_DF_DB;

------------------------------------------------------------
-- 7. (Optional) Set Data Retention for disaster recovery
------------------------------------------------------------

-- Allows for point-in-time recovery if accidental data loss occurs.
ALTER DATABASE SYDNEY_DF_DB SET DATA_RETENTION_TIME_IN_DAYS = 1;