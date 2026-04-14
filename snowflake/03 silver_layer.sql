-- ==========================================================
-- 03: SILVER LAYER TRANSFORMATION
-- Project: Sydney Duty Free Analytics
-- Purpose: Data cleansing, Type casting, and Relational Modeling
-- ==========================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SYDNEY_DF_WH;
USE DATABASE SYDNEY_DF_DB;
USE SCHEMA SILVER;

------------------------------------------------------------
-- 1. DIMENSION TABLES
-- Description: Master data providing context (Who, What, Where, When) for transactions.
------------------------------------------------------------

-- [DIM_CUSTOMERS]
-- Standardising nationality codes using a robust CASE WHEN mapping.
-- Handles full names, common abbreviations, typos, and whitespace/case issues.
-- Deduplication: QUALIFY ROW_NUMBER() on CUSTOMER_ID (keeps first occurrence).
-- Null handling: 1,045 rows have NULL nationality + age_group — these are customers
-- whose boarding pass was not scanned due to technical issues or manual staff entry
-- (e.g., customer declined to present boarding pass). Flagged via IS_BOARDING_PASS_SCANNED.

CREATE OR REPLACE TABLE SYDNEY_DF_DB.SILVER.DIM_CUSTOMERS AS
SELECT 
    CUSTOMER_ID,
    CASE UPPER(TRIM(NATIONALITY))
        WHEN 'AU'        THEN 'AU'
        WHEN 'AUS'       THEN 'AU'
        WHEN 'AUSTRALIA'  THEN 'AU'
        WHEN 'AUST'      THEN 'AU'

        WHEN 'CN'        THEN 'CN'
        WHEN 'CHN'       THEN 'CN'
        WHEN 'CHINA'     THEN 'CN'
        WHEN 'PRC'       THEN 'CN'

        WHEN 'NZ'        THEN 'NZ'
        WHEN 'NZL'       THEN 'NZ'
        WHEN 'NEW ZEALAND' THEN 'NZ'

        WHEN 'US'        THEN 'US'
        WHEN 'USA'       THEN 'US'
        WHEN 'UNITED STATES' THEN 'US'
        WHEN 'UNITED STATES OF AMERICA' THEN 'US'

        WHEN 'GB'        THEN 'GB'
        WHEN 'GBR'       THEN 'GB'
        WHEN 'UK'        THEN 'GB'
        WHEN 'UNITED KINGDOM' THEN 'GB'
        WHEN 'ENGLAND'   THEN 'GB'
        WHEN 'BRITAIN'   THEN 'GB'

        WHEN 'KR'        THEN 'KR'
        WHEN 'KOR'       THEN 'KR'
        WHEN 'KOREA'     THEN 'KR'
        WHEN 'SOUTH KOREA' THEN 'KR'

        WHEN 'IN'        THEN 'IN'
        WHEN 'IND'       THEN 'IN'
        WHEN 'INDIA'     THEN 'IN'

        WHEN 'JP'        THEN 'JP'
        WHEN 'JPN'       THEN 'JP'
        WHEN 'JAPAN'     THEN 'JP'

        WHEN 'PH'        THEN 'PH'
        WHEN 'PHL'       THEN 'PH'
        WHEN 'PHILIPPINES' THEN 'PH'
        WHEN 'PHILIPINES' THEN 'PH'

        WHEN 'CA'        THEN 'CA'
        WHEN 'CAN'       THEN 'CA'
        WHEN 'CANADA'    THEN 'CA'

        WHEN 'SG'        THEN 'SG'
        WHEN 'SGP'       THEN 'SG'
        WHEN 'SINGAPORE' THEN 'SG'

        WHEN 'TH'        THEN 'TH'
        WHEN 'THA'       THEN 'TH'
        WHEN 'THAILAND'  THEN 'TH'

        ELSE COALESCE(INITCAP(TRIM(NATIONALITY)), 'NO_BOARDING_PASS')
    END AS NATIONALITY,
    COALESCE(TRIM(AGE_GROUP), 'NO_BOARDING_PASS') AS AGE_GROUP,
    IFF(NATIONALITY IS NOT NULL AND AGE_GROUP IS NOT NULL, TRUE, FALSE) AS IS_BOARDING_PASS_SCANNED
FROM SYDNEY_DF_DB.BRONZE.RAW_CUSTOMERS
WHERE CUSTOMER_ID IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY CUSTOMER_ID) = 1;

-- [DIM_PRODUCTS]
-- Renaming 'VARIANT' to 'PRODUCT_VARIANT' to avoid conflicts with Snowflake's reserved keyword.
-- Category standardisation: maps synonyms/typos to canonical duty-free retail categories.
-- Adds PROFIT_MARGIN for Gold-layer profitability analysis.
-- Deduplication: QUALIFY ROW_NUMBER() on PRODUCT_SKU.

CREATE OR REPLACE TABLE SYDNEY_DF_DB.SILVER.DIM_PRODUCTS AS
SELECT 
    PRODUCT_SKU,
    CASE UPPER(TRIM(CATEGORY))
        WHEN 'LIQUOR'         THEN 'LIQUOR'
        WHEN 'SPIRITS'        THEN 'LIQUOR'
        WHEN 'ALCOHOL'        THEN 'LIQUOR'
        WHEN 'WINE'           THEN 'LIQUOR'
        WHEN 'BEER'           THEN 'LIQUOR'

        WHEN 'CONFECTIONERY'  THEN 'CONFECTIONERY'
        WHEN 'CHOCOLATE'      THEN 'CONFECTIONERY'
        WHEN 'SWEETS'         THEN 'CONFECTIONERY'
        WHEN 'CANDY'          THEN 'CONFECTIONERY'

        WHEN 'COSMETICS'      THEN 'COSMETICS'
        WHEN 'SKINCARE'       THEN 'COSMETICS'
        WHEN 'SKIN CARE'      THEN 'COSMETICS'
        WHEN 'BEAUTY'         THEN 'COSMETICS'
        WHEN 'FRAGRANCE'      THEN 'COSMETICS'
        WHEN 'PERFUME'        THEN 'COSMETICS'

        WHEN 'SOUVENIR'       THEN 'SOUVENIR'
        WHEN 'SOUVENIRS'      THEN 'SOUVENIR'
        WHEN 'GIFT'           THEN 'SOUVENIR'
        WHEN 'GIFTS'          THEN 'SOUVENIR'

        WHEN 'APPAREL'        THEN 'APPAREL'
        WHEN 'CLOTHING'       THEN 'APPAREL'
        WHEN 'CLOTHES'        THEN 'APPAREL'
        WHEN 'FASHION'        THEN 'APPAREL'

        WHEN 'JEWELLERY'      THEN 'JEWELLERY'
        WHEN 'JEWELRY'        THEN 'JEWELLERY'
        WHEN 'ACCESSORIES'    THEN 'JEWELLERY'

        WHEN 'HONEY'          THEN 'HONEY'
        WHEN 'MANUKA'         THEN 'HONEY'

        WHEN 'TEA'            THEN 'TEA'
        WHEN 'TEAS'           THEN 'TEA'
        WHEN 'HERBAL TEA'     THEN 'TEA'

        WHEN 'INDIGENOUS'     THEN 'INDIGENOUS'
        WHEN 'ABORIGINAL'     THEN 'INDIGENOUS'

        ELSE INITCAP(TRIM(CATEGORY))
    END AS CATEGORY,
    INITCAP(TRIM(ITEM)) AS ITEM,
    INITCAP(TRIM(VARIANT)) AS PRODUCT_VARIANT,
    SELLING_PRICE,
    COST_PRICE,
    ROUND(SELLING_PRICE - COST_PRICE, 2) AS PROFIT_MARGIN
FROM SYDNEY_DF_DB.BRONZE.RAW_PRODUCTS
WHERE PRODUCT_SKU IS NOT NULL
  AND SELLING_PRICE > 0
QUALIFY ROW_NUMBER() OVER (PARTITION BY PRODUCT_SKU ORDER BY PRODUCT_SKU) = 1;

-- [DIM_FLIGHTS]
-- Flight number: UPPER/TRIM for consistency.
-- Extracts AIRLINE_CODE (IATA 2-char prefix) and numeric FLIGHT_NUM for flexible grouping.
-- Standardises airline names, destinations, and flight status.
-- Deduplication: RAW_FLIGHTS has 5,907 rows but only 21 unique flights (daily schedule).
-- This is a daily flight schedule table, so we keep all rows (one per departure).
-- QUALIFY dedup on FLIGHT_ID to remove exact duplicates only.
-- Null handling: COALESCE on airline, destination, flight_status.

CREATE OR REPLACE TABLE SYDNEY_DF_DB.SILVER.DIM_FLIGHTS AS
SELECT 
    FLIGHT_ID,
    UPPER(TRIM(FLIGHT_NO)) AS FLIGHT_NO,
    REGEXP_SUBSTR(UPPER(TRIM(FLIGHT_NO)), '^[A-Z0-9]{2}') AS AIRLINE_CODE,
    TRY_CAST(REGEXP_SUBSTR(UPPER(TRIM(FLIGHT_NO)), '[0-9]+$') AS INT) AS FLIGHT_NUM,
    COALESCE(INITCAP(TRIM(AIRLINE)), 'UNKNOWN') AS AIRLINE,
    COALESCE(INITCAP(TRIM(DESTINATION)), 'UNKNOWN') AS DESTINATION,
    TO_TIMESTAMP(DEPARTURE_TIME) AS DEPARTURE_TIMESTAMP,
    COALESCE(UPPER(TRIM(FLIGHT_STATUS)), 'UNKNOWN') AS FLIGHT_STATUS
FROM SYDNEY_DF_DB.BRONZE.RAW_FLIGHTS
WHERE FLIGHT_ID IS NOT NULL
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY FLIGHT_ID, TO_TIMESTAMP(DEPARTURE_TIME)
    ORDER BY DEPARTURE_TIME
) = 1;

-- [DIM_EVENTS]
-- Converting holiday event periods to DATE format for efficient date-range filtering.
-- Adds EVENT_DURATION_DAYS for promotional analysis.
-- Validates END_DATE >= START_DATE.
-- Deduplication: QUALIFY ROW_NUMBER() on EVENT_ID.
-- Null handling: COALESCE on EVENT_NAME.

CREATE OR REPLACE TABLE SYDNEY_DF_DB.SILVER.DIM_EVENTS AS
SELECT 
    EVENT_ID,
    COALESCE(INITCAP(TRIM(EVENT_NAME)), 'NORMAL') AS EVENT_NAME,
    TO_DATE(START_DATE) AS START_DATE,
    TO_DATE(END_DATE) AS END_DATE,
    DATEDIFF('day', TO_DATE(START_DATE), TO_DATE(END_DATE)) + 1 AS EVENT_DURATION_DAYS
FROM SYDNEY_DF_DB.BRONZE.RAW_EVENTS
WHERE EVENT_ID IS NOT NULL
  AND TO_DATE(END_DATE) >= TO_DATE(START_DATE)
QUALIFY ROW_NUMBER() OVER (PARTITION BY EVENT_ID ORDER BY EVENT_ID) = 1;


------------------------------------------------------------
-- 2. FACT TABLE
-- Description: Quantitative data representing business events (Sales Transactions).
------------------------------------------------------------

-- [FACT_TRANSACTIONS]
-- Key transformations:
-- 1. Converting transaction time to TIMESTAMP; extracting SALE_DATE, SALE_HOUR for time-series.
-- 2. Flight number standardisation to match DIM_FLIGHTS.
-- 3. Payment method normalisation into canonical groups (CARD, CASH, DIGITAL_WALLET).
-- 4. Null handling: EVENT_ID→'NORMAL', PROMO_ID→'NO_PROMO', PAYMENT_METHOD→'UNKNOWN'.
-- 5. Data quality gates: non-null TX_ID, non-negative NET_AMOUNT.
-- 6. Deduplication: QUALIFY ROW_NUMBER() on TX_ID + LINE_NO (keeps latest TX_TIME).

CREATE OR REPLACE TABLE SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS AS
SELECT 
    TX_ID,
    LINE_NO,
    TO_TIMESTAMP(TX_TIME) AS TX_TIMESTAMP,
    CAST(TO_TIMESTAMP(TX_TIME) AS DATE) AS SALE_DATE,
    EXTRACT(HOUR FROM TO_TIMESTAMP(TX_TIME)) AS SALE_HOUR,
    CUSTOMER_ID,
    FLIGHT_ID,
    IFNULL(EVENT_ID, 'NORMAL') AS EVENT_ID,
    PRODUCT_SKU,
    ABS(QTY) AS QTY,
    UNIT_PRICE,
    NET_AMOUNT,
    DISC_AMOUNT,
    ROUND(DIV0(DISC_AMOUNT, NET_AMOUNT + DISC_AMOUNT) * 100, 2) AS DISC_PCT,
    IFNULL(PROMO_ID, 'NO_PROMO') AS PROMO_ID,
    CASE UPPER(TRIM(IFNULL(PAYMENT_METHOD, 'UNKNOWN')))
        WHEN 'CREDIT/DEBIT CARD' THEN 'CARD'
        WHEN 'CREDIT CARD'        THEN 'CARD'
        WHEN 'DEBIT CARD'         THEN 'CARD'
        WHEN 'VISA'               THEN 'CARD'
        WHEN 'MASTERCARD'         THEN 'CARD'
        WHEN 'AMEX'               THEN 'CARD'
        WHEN 'CC'                 THEN 'CARD'

        WHEN 'CASH'               THEN 'CASH'

        WHEN 'ALIPAY'             THEN 'DIGITAL_WALLET'
        WHEN 'WECHAT PAY'         THEN 'DIGITAL_WALLET'
        WHEN 'DIGITAL WALLET'     THEN 'DIGITAL_WALLET'
        WHEN 'APPLE PAY'          THEN 'DIGITAL_WALLET'
        WHEN 'GOOGLE PAY'         THEN 'DIGITAL_WALLET'
        WHEN 'SAMSUNG PAY'        THEN 'DIGITAL_WALLET'

        WHEN 'UNKNOWN'            THEN 'UNKNOWN'
        ELSE INITCAP(TRIM(PAYMENT_METHOD))
    END AS PAYMENT_METHOD,
    CASE UPPER(TRIM(IFNULL(PAYMENT_METHOD, 'UNKNOWN')))
        WHEN 'ALIPAY'             THEN 'ALIPAY'
        WHEN 'WECHAT PAY'         THEN 'WECHAT_PAY'
        WHEN 'DIGITAL WALLET'     THEN 'OTHER'
        WHEN 'APPLE PAY'          THEN 'APPLE_PAY'
        WHEN 'GOOGLE PAY'         THEN 'GOOGLE_PAY'
        WHEN 'SAMSUNG PAY'        THEN 'SAMSUNG_PAY'
        ELSE NULL
    END AS DIGITAL_WALLET_PROVIDER
FROM SYDNEY_DF_DB.BRONZE.RAW_TRANSACTIONS
WHERE TX_ID IS NOT NULL 
  AND NET_AMOUNT >= 0
QUALIFY ROW_NUMBER() OVER (PARTITION BY TX_ID, LINE_NO ORDER BY TX_TIME DESC) = 1;


------------------------------------------------------------
-- 3. REFERENTIAL INTEGRITY CONSTRAINTS
-- Note: Snowflake does NOT enforce PK/FK constraints, but they serve as
-- metadata documentation for BI tools, query optimisers, and data lineage.
-- PKs were declared inline above via CTAS. FKs are added below via ALTER.
------------------------------------------------------------

ALTER TABLE SYDNEY_DF_DB.SILVER.DIM_CUSTOMERS
    ADD CONSTRAINT pk_dim_customers PRIMARY KEY (CUSTOMER_ID)
RELY;

ALTER TABLE SYDNEY_DF_DB.SILVER.DIM_PRODUCTS
    ADD CONSTRAINT pk_dim_products PRIMARY KEY (PRODUCT_SKU)
RELY;

ALTER TABLE SYDNEY_DF_DB.SILVER.DIM_FLIGHTS
    ADD CONSTRAINT pk_dim_flights PRIMARY KEY (FLIGHT_ID)
RELY;

ALTER TABLE SYDNEY_DF_DB.SILVER.DIM_EVENTS
    ADD CONSTRAINT pk_dim_events PRIMARY KEY (EVENT_ID)
RELY;

ALTER TABLE SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS
    ADD CONSTRAINT pk_fact_transactions PRIMARY KEY (TX_ID, LINE_NO)
RELY;

ALTER TABLE SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS
    ADD CONSTRAINT fk_fact_customer
    FOREIGN KEY (CUSTOMER_ID) REFERENCES SYDNEY_DF_DB.SILVER.DIM_CUSTOMERS(CUSTOMER_ID)
RELY;

ALTER TABLE SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS
    ADD CONSTRAINT fk_fact_flight
    FOREIGN KEY (FLIGHT_ID) REFERENCES SYDNEY_DF_DB.SILVER.DIM_FLIGHTS(FLIGHT_ID)
RELY;

ALTER TABLE SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS
    ADD CONSTRAINT fk_fact_event
    FOREIGN KEY (EVENT_ID) REFERENCES SYDNEY_DF_DB.SILVER.DIM_EVENTS(EVENT_ID)
RELY;

ALTER TABLE SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS
    ADD CONSTRAINT fk_fact_product
    FOREIGN KEY (PRODUCT_SKU) REFERENCES SYDNEY_DF_DB.SILVER.DIM_PRODUCTS(PRODUCT_SKU)
RELY;
