-- ==========================================================
-- 04: GOLD LAYER — REPORTING VIEWS
-- Project: Sydney Duty Free Analytics
-- Purpose: Business-ready aggregated views for dashboards
-- ==========================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SYDNEY_DF_WH;
USE DATABASE SYDNEY_DF_DB;
USE SCHEMA GOLD;

------------------------------------------------------------
-- 1. REPORT_DAILY_SALES_OVERVIEW
-- Business Purpose: Provides a day-by-day revenue summary for executive dashboards.
-- Includes total revenue, transaction count, average transaction value,
-- and month-over-month (MoM) growth % to track sales momentum.
------------------------------------------------------------
CREATE OR REPLACE VIEW SYDNEY_DF_DB.GOLD.REPORT_DAILY_SALES_OVERVIEW AS
WITH daily_metrics AS (
    SELECT
        SALE_DATE,
        DATE_TRUNC('MONTH', SALE_DATE)  AS SALE_MONTH,
        DAYNAME(SALE_DATE)              AS DAY_OF_WEEK,
        COUNT(DISTINCT TX_ID)           AS TOTAL_TRANSACTIONS,
        SUM(NET_AMOUNT)                 AS TOTAL_REVENUE,
        SUM(QTY)                        AS TOTAL_UNITS_SOLD,
        ROUND(SUM(NET_AMOUNT) / NULLIF(COUNT(DISTINCT TX_ID), 0), 2) AS AVG_TRANSACTION_VALUE
    FROM SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS
    GROUP BY SALE_DATE
),
monthly_agg AS (
    SELECT
        SALE_MONTH,
        SUM(TOTAL_REVENUE)                                      AS MONTHLY_REVENUE,
        LAG(SUM(TOTAL_REVENUE)) OVER (ORDER BY SALE_MONTH)      AS PREV_MONTH_REVENUE
    FROM daily_metrics
    GROUP BY SALE_MONTH
)
SELECT
    d.SALE_DATE,
    d.SALE_MONTH,
    d.DAY_OF_WEEK,
    d.TOTAL_TRANSACTIONS,
    d.TOTAL_REVENUE,
    d.TOTAL_UNITS_SOLD,
    d.AVG_TRANSACTION_VALUE,
    m.MONTHLY_REVENUE,
    m.PREV_MONTH_REVENUE,
    ROUND(
        (m.MONTHLY_REVENUE - m.PREV_MONTH_REVENUE) 
        / NULLIF(m.PREV_MONTH_REVENUE, 0) * 100, 2
    ) AS MOM_GROWTH_PCT
FROM daily_metrics d
LEFT JOIN monthly_agg m
    ON d.SALE_MONTH = m.SALE_MONTH;


------------------------------------------------------------
-- 2. REPORT_CUSTOMER_SEGMENTATION_ANALYSIS
-- Business Purpose: Identifies high-value traveller segments by nationality and age group.
-- Ranks nationalities by total spending to prioritise marketing and product assortment.
-- Filters on IS_BOARDING_PASS_SCANNED to separate identified vs. unscanned customers.
------------------------------------------------------------
CREATE OR REPLACE VIEW SYDNEY_DF_DB.GOLD.REPORT_CUSTOMER_SEGMENTATION_ANALYSIS AS
SELECT
    c.NATIONALITY,
    c.AGE_GROUP,
    c.IS_BOARDING_PASS_SCANNED,
    COUNT(DISTINCT f.TX_ID)                                     AS TOTAL_TRANSACTIONS,
    COUNT(DISTINCT f.CUSTOMER_ID)                               AS UNIQUE_CUSTOMERS,
    SUM(f.NET_AMOUNT)                                           AS TOTAL_REVENUE,
    SUM(f.QTY)                                                  AS TOTAL_UNITS_SOLD,
    ROUND(SUM(f.NET_AMOUNT) / NULLIF(COUNT(DISTINCT f.CUSTOMER_ID), 0), 2) AS REVENUE_PER_CUSTOMER,
    ROUND(SUM(f.NET_AMOUNT) / NULLIF(COUNT(DISTINCT f.TX_ID), 0), 2)       AS AVG_BASKET_VALUE,
    DENSE_RANK() OVER (ORDER BY SUM(f.NET_AMOUNT) DESC)        AS NATIONALITY_REVENUE_RANK
FROM SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS f
LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_CUSTOMERS c
    ON f.CUSTOMER_ID = c.CUSTOMER_ID
GROUP BY c.NATIONALITY, c.AGE_GROUP, c.IS_BOARDING_PASS_SCANNED;


------------------------------------------------------------
-- 3. REPORT_FLIGHT_OPERATIONS_INSIGHTS
-- Business Purpose: Links sales to flight operations to identify which airlines,
-- destinations, and time-of-day windows drive the most revenue.
-- OPERATIONAL_SEGMENT classifies SALE_HOUR into retail shift windows.
-- Joins DIM_FLIGHTS on FLIGHT_ID for accurate matching.
------------------------------------------------------------
CREATE OR REPLACE VIEW SYDNEY_DF_DB.GOLD.REPORT_FLIGHT_OPERATIONS_INSIGHTS AS
SELECT
    fl.AIRLINE,
    fl.AIRLINE_CODE,
    fl.DESTINATION,
    fl.FLIGHT_STATUS,
    CASE
        WHEN f.SALE_HOUR BETWEEN 5  AND 8  THEN 'EARLY_MORNING'
        WHEN f.SALE_HOUR BETWEEN 9  AND 11 THEN 'MORNING_PEAK'
        WHEN f.SALE_HOUR BETWEEN 12 AND 14 THEN 'MIDDAY'
        WHEN f.SALE_HOUR BETWEEN 15 AND 17 THEN 'AFTERNOON_PEAK'
        WHEN f.SALE_HOUR BETWEEN 18 AND 21 THEN 'EVENING'
        ELSE 'OVERNIGHT'
    END AS OPERATIONAL_SEGMENT,
    COUNT(DISTINCT f.TX_ID)                                     AS TOTAL_TRANSACTIONS,
    SUM(f.NET_AMOUNT)                                           AS TOTAL_REVENUE,
    SUM(f.QTY)                                                  AS TOTAL_UNITS_SOLD,
    ROUND(SUM(f.NET_AMOUNT) / NULLIF(COUNT(DISTINCT f.TX_ID), 0), 2) AS AVG_TRANSACTION_VALUE,
    COUNT(DISTINCT f.CUSTOMER_ID)                               AS UNIQUE_CUSTOMERS
FROM SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS f
LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_FLIGHTS fl
    ON f.FLIGHT_ID = fl.FLIGHT_ID
GROUP BY fl.AIRLINE, fl.AIRLINE_CODE, fl.DESTINATION, fl.FLIGHT_STATUS, OPERATIONAL_SEGMENT;


------------------------------------------------------------
-- 4. REPORT_PROMOTION_ROI
-- Business Purpose: Measures promotional effectiveness by comparing event/holiday
-- sales against normal (non-event) periods. Calculates discount spend vs. net revenue
-- to evaluate promotion ROI and identify the most impactful events.
------------------------------------------------------------
CREATE OR REPLACE VIEW SYDNEY_DF_DB.GOLD.REPORT_PROMOTION_ROI AS
SELECT
    f.EVENT_ID,
    COALESCE(e.EVENT_NAME, 'Normal Sales')                      AS EVENT_NAME,
    IFF(f.EVENT_ID = 'NORMAL', 'NORMAL_SALES', 'EVENT_SALES')  AS SALES_PERIOD_TYPE,
    f.PROMO_ID,
    COUNT(DISTINCT f.TX_ID)                                     AS TOTAL_TRANSACTIONS,
    SUM(f.NET_AMOUNT)                                           AS TOTAL_NET_REVENUE,
    SUM(f.DISC_AMOUNT)                                          AS TOTAL_DISCOUNT_GIVEN,
    SUM(f.NET_AMOUNT) + SUM(f.DISC_AMOUNT)                     AS TOTAL_GROSS_REVENUE,
    ROUND(
        SUM(f.DISC_AMOUNT) / NULLIF(SUM(f.NET_AMOUNT) + SUM(f.DISC_AMOUNT), 0) * 100, 2
    ) AS DISCOUNT_TO_GROSS_PCT,
    SUM(f.QTY)                                                  AS TOTAL_UNITS_SOLD,
    ROUND(SUM(f.NET_AMOUNT) / NULLIF(COUNT(DISTINCT f.TX_ID), 0), 2) AS AVG_TRANSACTION_VALUE,
    COUNT(DISTINCT f.CUSTOMER_ID)                               AS UNIQUE_CUSTOMERS
FROM SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS f
LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_EVENTS e
    ON f.EVENT_ID = e.EVENT_ID
GROUP BY f.EVENT_ID, e.EVENT_NAME, f.PROMO_ID;


------------------------------------------------------------
-- 5. REPORT_BASKET_DYNAMICS
-- Business Purpose: Calculates average items per transaction (IPT)
-- and identifies product categories frequently purchased together
-- in the same TX_ID. Supports Slice & Dice by Nationality and Airline.
------------------------------------------------------------
CREATE OR REPLACE VIEW SYDNEY_DF_DB.GOLD.REPORT_BASKET_DYNAMICS AS
WITH basket_summary AS (
    SELECT
        f.TX_ID,
        c.NATIONALITY,
        fl.AIRLINE,
        COUNT(f.LINE_NO)            AS ITEMS_IN_BASKET,
        COUNT(DISTINCT p.CATEGORY)  AS DISTINCT_CATEGORIES,
        SUM(f.NET_AMOUNT)           AS BASKET_REVENUE,
        LISTAGG(DISTINCT p.CATEGORY, ' | ') WITHIN GROUP (ORDER BY p.CATEGORY) AS CATEGORIES_IN_BASKET
    FROM SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS f
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_CUSTOMERS c
        ON f.CUSTOMER_ID = c.CUSTOMER_ID
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_FLIGHTS fl
        ON f.FLIGHT_ID = fl.FLIGHT_ID
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_PRODUCTS p
        ON f.PRODUCT_SKU = p.PRODUCT_SKU
    GROUP BY f.TX_ID, c.NATIONALITY, fl.AIRLINE
),
category_pairs AS (
    SELECT
        c.NATIONALITY,
        fl.AIRLINE,
        p1.CATEGORY AS CATEGORY_A,
        p2.CATEGORY AS CATEGORY_B,
        COUNT(DISTINCT a.TX_ID) AS CO_PURCHASE_COUNT
    FROM SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS a
    INNER JOIN SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS b
        ON a.TX_ID = b.TX_ID
        AND a.PRODUCT_SKU < b.PRODUCT_SKU
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_PRODUCTS p1
        ON a.PRODUCT_SKU = p1.PRODUCT_SKU
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_PRODUCTS p2
        ON b.PRODUCT_SKU = p2.PRODUCT_SKU
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_CUSTOMERS c
        ON a.CUSTOMER_ID = c.CUSTOMER_ID
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_FLIGHTS fl
        ON a.FLIGHT_ID = fl.FLIGHT_ID
    WHERE p1.CATEGORY <> p2.CATEGORY
    GROUP BY c.NATIONALITY, fl.AIRLINE, p1.CATEGORY, p2.CATEGORY
)
SELECT
    'BASKET_METRICS'                                    AS REPORT_SECTION,
    bs.NATIONALITY,
    bs.AIRLINE,
    COUNT(DISTINCT bs.TX_ID)                            AS TOTAL_TRANSACTIONS,
    ROUND(AVG(bs.ITEMS_IN_BASKET), 2)                  AS AVG_ITEMS_PER_TRANSACTION,
    ROUND(AVG(bs.DISTINCT_CATEGORIES), 2)              AS AVG_CATEGORIES_PER_BASKET,
    ROUND(AVG(bs.BASKET_REVENUE), 2)                   AS AVG_BASKET_REVENUE,
    NULL                                                AS CATEGORY_A,
    NULL                                                AS CATEGORY_B,
    NULL                                                AS CO_PURCHASE_COUNT
FROM basket_summary bs
GROUP BY bs.NATIONALITY, bs.AIRLINE

UNION ALL

SELECT
    'CATEGORY_CO_PURCHASE'                              AS REPORT_SECTION,
    cp.NATIONALITY,
    cp.AIRLINE,
    NULL                                                AS TOTAL_TRANSACTIONS,
    NULL                                                AS AVG_ITEMS_PER_TRANSACTION,
    NULL                                                AS AVG_CATEGORIES_PER_BASKET,
    NULL                                                AS AVG_BASKET_REVENUE,
    cp.CATEGORY_A,
    cp.CATEGORY_B,
    cp.CO_PURCHASE_COUNT
FROM category_pairs cp;


------------------------------------------------------------
-- 6. REPORT_HOURLY_SALES_HEATMAP
-- Business Purpose: Aggregates total revenue and transaction counts
-- by hour of the day (0-23) for staffing optimization heatmaps.
-- Supports Slice & Dice by Nationality and Airline.
------------------------------------------------------------
CREATE OR REPLACE VIEW SYDNEY_DF_DB.GOLD.REPORT_HOURLY_SALES_HEATMAP AS
SELECT
    f.SALE_HOUR,
    CASE
        WHEN f.SALE_HOUR BETWEEN 0  AND 4  THEN 'OVERNIGHT'
        WHEN f.SALE_HOUR BETWEEN 5  AND 8  THEN 'EARLY_MORNING'
        WHEN f.SALE_HOUR BETWEEN 9  AND 11 THEN 'MORNING_PEAK'
        WHEN f.SALE_HOUR BETWEEN 12 AND 14 THEN 'MIDDAY'
        WHEN f.SALE_HOUR BETWEEN 15 AND 17 THEN 'AFTERNOON_PEAK'
        WHEN f.SALE_HOUR BETWEEN 18 AND 21 THEN 'EVENING'
        ELSE 'LATE_NIGHT'
    END                                                 AS TIME_BAND,
    c.NATIONALITY,
    fl.AIRLINE,
    COUNT(DISTINCT f.TX_ID)                             AS TOTAL_TRANSACTIONS,
    SUM(f.NET_AMOUNT)                                   AS TOTAL_REVENUE,
    SUM(f.QTY)                                          AS TOTAL_UNITS_SOLD,
    ROUND(SUM(f.NET_AMOUNT) / NULLIF(COUNT(DISTINCT f.TX_ID), 0), 2) AS AVG_TRANSACTION_VALUE,
    COUNT(DISTINCT f.CUSTOMER_ID)                       AS UNIQUE_CUSTOMERS,
    ROUND(SUM(f.NET_AMOUNT) / NULLIF(SUM(SUM(f.NET_AMOUNT)) OVER (), 0) * 100, 2) AS PCT_OF_TOTAL_REVENUE
FROM SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS f
LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_CUSTOMERS c
    ON f.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_FLIGHTS fl
    ON f.FLIGHT_ID = fl.FLIGHT_ID
GROUP BY f.SALE_HOUR, c.NATIONALITY, fl.AIRLINE;


------------------------------------------------------------
-- 7. REPORT_PRODUCT_PROFITABILITY_MATRIX
-- Business Purpose: Compares each product's sales volume against
-- its profit margin. Categorises products into quadrants:
-- 'Star', 'Cash Cow', 'Question Mark', 'Dog' for strategic decisions.
-- Supports Slice & Dice by Nationality and Airline.
------------------------------------------------------------
CREATE OR REPLACE VIEW SYDNEY_DF_DB.GOLD.REPORT_PRODUCT_PROFITABILITY_MATRIX AS
WITH product_metrics AS (
    SELECT
        p.PRODUCT_SKU,
        p.CATEGORY,
        p.ITEM,
        p.PRODUCT_VARIANT,
        p.SELLING_PRICE,
        p.COST_PRICE,
        p.PROFIT_MARGIN,
        c.NATIONALITY,
        fl.AIRLINE,
        SUM(f.QTY)                                      AS TOTAL_UNITS_SOLD,
        SUM(f.NET_AMOUNT)                               AS TOTAL_REVENUE,
        SUM(f.QTY * p.COST_PRICE)                       AS TOTAL_COST,
        SUM(f.NET_AMOUNT) - SUM(f.QTY * p.COST_PRICE)  AS TOTAL_PROFIT,
        COUNT(DISTINCT f.TX_ID)                         AS TOTAL_TRANSACTIONS
    FROM SYDNEY_DF_DB.SILVER.FACT_TRANSACTIONS f
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_PRODUCTS p
        ON f.PRODUCT_SKU = p.PRODUCT_SKU
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_CUSTOMERS c
        ON f.CUSTOMER_ID = c.CUSTOMER_ID
    LEFT JOIN SYDNEY_DF_DB.SILVER.DIM_FLIGHTS fl
        ON f.FLIGHT_ID = fl.FLIGHT_ID
    GROUP BY p.PRODUCT_SKU, p.CATEGORY, p.ITEM, p.PRODUCT_VARIANT,
             p.SELLING_PRICE, p.COST_PRICE, p.PROFIT_MARGIN,
             c.NATIONALITY, fl.AIRLINE
),
thresholds AS (
    SELECT
        MEDIAN(TOTAL_UNITS_SOLD)    AS MEDIAN_VOLUME,
        MEDIAN(PROFIT_MARGIN)       AS MEDIAN_MARGIN
    FROM product_metrics
)
SELECT
    pm.PRODUCT_SKU,
    pm.CATEGORY,
    pm.ITEM,
    pm.PRODUCT_VARIANT,
    pm.NATIONALITY,
    pm.AIRLINE,
    pm.SELLING_PRICE,
    pm.COST_PRICE,
    pm.PROFIT_MARGIN,
    pm.TOTAL_UNITS_SOLD,
    pm.TOTAL_REVENUE,
    pm.TOTAL_COST,
    pm.TOTAL_PROFIT,
    pm.TOTAL_TRANSACTIONS,
    ROUND(pm.TOTAL_PROFIT / NULLIF(pm.TOTAL_REVENUE, 0) * 100, 2) AS EFFECTIVE_MARGIN_PCT,
    CASE
        WHEN pm.TOTAL_UNITS_SOLD >= t.MEDIAN_VOLUME AND pm.PROFIT_MARGIN >= t.MEDIAN_MARGIN
            THEN 'Star (High Volume / High Profit)'
        WHEN pm.TOTAL_UNITS_SOLD >= t.MEDIAN_VOLUME AND pm.PROFIT_MARGIN < t.MEDIAN_MARGIN
            THEN 'Cash Cow (High Volume / Low Profit)'
        WHEN pm.TOTAL_UNITS_SOLD < t.MEDIAN_VOLUME AND pm.PROFIT_MARGIN >= t.MEDIAN_MARGIN
            THEN 'Question Mark (Low Volume / High Profit)'
        ELSE 'Dog (Low Volume / Low Profit)'
    END                                                 AS PROFITABILITY_QUADRANT,
    t.MEDIAN_VOLUME                                     AS BENCHMARK_MEDIAN_VOLUME,
    t.MEDIAN_MARGIN                                     AS BENCHMARK_MEDIAN_MARGIN
FROM product_metrics pm
CROSS JOIN thresholds t;
