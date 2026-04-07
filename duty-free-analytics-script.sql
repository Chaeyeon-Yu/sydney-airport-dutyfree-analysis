-- Sydney Airport Duty-free Shop Analysis

-- 1. Exploratory Data Analysis

-- =========================================================================================================================
-- 1) Data Volume & Time Range
-- =========================================================================================================================

/* The transactions table has 22,194 rows from 2024-01-01 06:18:00 to 2024-12-31 15:38:00.
*/

SELECT
	count(*) AS total_rows,
	min(tx_time) AS start_date,
	max(tx_time) AS end_date
FROM
	transactions;

-- =========================================================================================================================
-- 2) Understanding Dimensions
-- =========================================================================================================================

/* There are 9 categories of product, 
 * such as Confectionery (21 variant), Liquor (17), Cosmetics (16), 
 * Jewellery (12), Souvenir (11), 	Indigenous (11), Apparel (9),
 * Honey (8), Tea (3). (Each variant of item has unique SKU.)
 */

SELECT
	category,
	count(DISTINCT product_sku) AS sku_count
FROM 
	product_master
GROUP BY 
	category
ORDER BY
	sku_count desc;

-- =========================================================================================================================
-- 3) Data Integrity (Quality Check)
-- =========================================================================================================================

/*  A. [Data Quality Check]
 *  Identified 'No Boarding Pass' (13.06%) segment: 
 *  Transactions made without scanning a boarding pass resulted in 
 *  NULL values for nationality and age_group.
 */


SELECT
	count(customer_id) AS total_customers,
	sum(CASE WHEN nationality IS NULL THEN 1 ELSE 0 END) AS null_nationality_count,
	sum(CASE WHEN age_group IS NULL THEN 1 ELSE 0 END) AS null_age_group_count,
	round(sum(CASE WHEN nationality IS NULL THEN 1 ELSE 0 END) * 100.0 / count (*), 2) || '%' AS null_ratio 
FROM
	customer_details;


/*  B. [VIEW: customer_types]
 *   - Purpose: Segment customers into 'Passenger' and 'No Boarding Pass' groups.
 *   - Usage: Simplifies demographic analysis and conversion rate tracking 
 *     by separating travel-based segments.
 *   - The 'No Boarding Pass' group represents a segment of unidentified customers, 
 *     such as airport staff or transit passengers, whose demographic data was not captured 
 *     due to technical scanning failures, transit complexities, or manual overrides 
 *     during peak operational hours at Sydney T1.
 */

CREATE VIEW customer_types AS
	SELECT
		customer_id,
		(CASE 
		WHEN nationality IS NOT NULL AND age_group IS NOT NULL THEN 'Passenger'
		ELSE 'No Boarding Pass'
		END) AS customer_type
	FROM customer_details;

SELECT * FROM customer_types;

-- =========================================================================================================================
-- 4) Sales Distribution
-- =========================================================================================================================

-- A. Detailed Product Level Performance (SKU/Variant Analysis)

SELECT 
	t.product_sku,
	pm.category,
	pm.item,
	pm.variant,
	count(t.tx_id) AS tx_count,
	sum(t.qty) AS total_qty,
	sum(t.net_amount) AS total_sales,
	round(sum(t.net_amount) / SUM(t.qty), 2) AS avg_unit_price 
FROM 
	transactions t 
	INNER JOIN product_master pm ON t.product_sku = pm.product_sku
GROUP BY
	1, 2, 3, 4
ORDER BY
	total_qty DESC;


-- B. Relative Sales Share

SELECT
	item,
	total_sales,
	ROUND(total_sales * 100.0 / sum(total_sales) over(), 2) || '%' AS sales_share
FROM (
	SELECT
		pm.item,
		sum(t.net_amount) AS total_sales
	FROM 
		transactions t
		INNER JOIN product_master pm ON t.product_sku = pm.product_sku
	GROUP BY 1
)
ORDER BY total_sales DESC;

-- C. Daily Sales View

DROP VIEW IF EXISTS daily_sales;

CREATE VIEW daily_sales AS
	SELECT 
		date(t.tx_time) AS tx_date,
		COALESCE(h.event_name, 'Normal') AS period_type,
		sum(t.net_amount) AS daily_sales
	FROM 
		transactions t
		LEFT JOIN holiday_events h ON t.event_id = h.event_id
	GROUP BY 
		tx_date
	ORDER BY 
		tx_date;

SELECT * FROM daily_sales;

WITH sales_with_avg AS (
SELECT 
    tx_date,
    period_type,
    daily_sales,
    round(AVG(daily_sales) OVER (ORDER BY tx_date 
    					   ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    					   ), 2) AS moving_avg_7d,
    lag(daily_sales, 7) OVER (ORDER BY tx_date) AS last_week_sales
FROM 
    daily_sales
)
SELECT 
	tx_date,
	period_type,
	daily_sales,
	last_week_sales,
	round(((daily_sales - last_week_sales) * 100.0 / NULLIF(last_week_sales, 0)), 2) AS wow_growth_rate,
	moving_avg_7d,
	round(((daily_sales - moving_avg_7d) / moving_avg_7d) * 100.0, 2) AS gap_percentage
FROM 
	sales_with_avg
ORDER BY
	tx_date;


-- 2. Strategic Business Insights & Analytics 

-- =========================================================================================================================
-- 1) Impact of Seasonal Holidays on Purchase Patterns

/* Q1. How do holidays shift the demographic composition?
 *  
 * Q2. Which nationalities drive the revenue surge?
 */
-- =========================================================================================================================

DROP VIEW IF EXISTS holiday_stats;

CREATE VIEW holiday_stats AS 
	SELECT 
		COALESCE(h.event_name, 'Normal') AS period_type,
		c.nationality,
		p.category,
		p.item,
		sum(t.net_amount) AS category_total_sales,
		sum(t.qty) AS total_qty,
		count(*) AS tx_count
	FROM transactions t 
		 INNER JOIN customer_details c ON t.customer_id = c.customer_id
		 LEFT JOIN holiday_events h ON t.event_id = h.event_id
		 INNER JOIN product_master p ON t.product_sku = p.product_sku
	GROUP BY 
		period_type,
		category,
		item;

SELECT * FROM holiday_stats;

	


-- =========================================================================================================================
-- 2) Category Profitability & Margin Analysis

/* Beyond top-line revenue, which product categories contribute most to the net gross profit, 
 * and where are the opportunities to optimize the 'High-Volume, Low-Margin' vs. 'Low-Volume, High-Margin' trade-off?
 */
-- =========================================================================================================================






-- =========================================================================================================================
-- 3) Sales Velocity & Inventory Strategy
-- =========================================================================================================================

-- Q1. Which product categories or items show the highest sales frequency (turnover), and how quickly do they sell compared to others? 

-- A. Data Preparation (VIEW Creation)

DROP VIEW IF EXISTS qty_sold_base; 

CREATE VIEW qty_sold_base AS 
	SELECT
		p.product_sku,
		p.item,
		p.variant,
		t.tx_id,
		t.qty,
		t.unit_price,
		p.cost_price,
		t.net_amount,
		DATE(t.tx_time) AS tx_date
	FROM
		transactions t 
		JOIN product_master p ON p.product_sku = t.product_sku;

-- B. Aggregate Sale Performance

SELECT 
    item,
    COUNT(tx_id) AS tx_freq,
    SUM(qty) AS total_item_qty,
    ROUND(SUM(qty) * 1.0 / NULLIF(COUNT(DISTINCT tx_date), 0), 2) AS item_unit_sold_per_day  -- daily_velocity
FROM 
    qty_sold_base
GROUP BY 
    item
ORDER BY
    total_item_qty DESC;
	

-- Q2. How do high-velocity, low-margin items compare to low-velocity, high-revenue luxury items 
-- 	   in terms of their contribution to total profit?

-- A. Luxury Segment Performance

WITH velo_marg AS (
	SELECT
		item,
		count(tx_id) AS tx_count,
		round(sum(qty * unit_price) / sum(qty), 2) AS avg_unit_price,
		round(sum(net_amount), 2) AS total_revenue,
		round(sum(net_amount) * 100.0 / sum(sum(net_amount)) OVER (), 2) AS revenue_ratio,
		round(sum(qty) * 1.0 / NULLIF(count(DISTINCT tx_date), 0) ,2) AS daily_velocity
	FROM
		qty_sold_base
	GROUP BY
		item
) 
SELECT 
	*
FROM velo_marg
WHERE avg_unit_price >= 100;

-- B. High-Velocity Items (Top 10)
	
WITH velo_marg AS (
	SELECT
		item,
		count(tx_id) AS tx_count,
		round(sum(qty * unit_price) / sum(qty), 2) AS avg_unit_price,
		round(sum(net_amount), 2) AS total_revenue,
		round(sum(net_amount) * 100.0 / sum(sum(net_amount)) OVER (), 2) AS revenue_ratio,
		round(sum(qty) * 1.0 / NULLIF(count(DISTINCT tx_date), 0) ,2) AS daily_velocity
	FROM
		qty_sold_base
	GROUP BY
		item
) 
SELECT 
	*
FROM velo_marg
ORDER BY daily_velocity DESC
LIMIT 5;
		

-- C. Relative Quartile Segmentation
-- 	  Segmenting items based on actual Gross Profit and Sales Velocity.

--	|-------------------------|---------------------|---------------------------------------------------------|
--	|         Segment         |	Interpretation		|					   Business Strategy				  |
--	|-------------------------|---------------------|---------------------------------------------------------|
-- 	| Luxury + High-Velocity  |	Star			    | Focus on inventory security; High profit & high demand. |
--	|-------------------------|---------------------|---------------------------------------------------------|
-- 	| Luxury + Low-Velocity	  |	Niche Luxury		| High margin per unit; Targeted marketing for VIPs.   	  |
--	|-------------------------|---------------------|---------------------------------------------------------|
-- 	| Budget + High-Velocity  |	Volume Driver		| Traffic generators; Ensure competitive pricing		  |
--	|-------------------------|---------------------|---------------------------------------------------------|
-- 	| Budget + Low-Velocity	  |	Underperformers		| Potential for discontinuation or clearance sales.		  |
--	|-------------------------|---------------------|---------------------------------------------------------|



WITH item_stats AS (
	SELECT
		product_sku,
		item,
		-- Average Unit Price
		round(sum(qty * unit_price) / NULLIF(sum(qty), 0), 2) AS avg_unit_price,
		-- Total Revenue
		sum(net_amount) AS total_revenue,
		-- Total Profit
		round(sum(net_amount) - sum(qty * cost_price), 2) AS total_gross_profit,
		-- Profit Margin (%)
		round(sum(net_amount) - sum(qty * cost_price) * 100.0 / NULLIF(sum(net_amount), 0), 2) AS margin_percentage,
		-- Sales Velocity
		round(sum(qty) * 1.0 / count(DISTINCT tx_date), 2) AS daily_velocity
	FROM 
		qty_sold_base
	GROUP BY
		item
), item_rank AS (
SELECT
	*,
	ntile(4) OVER (ORDER BY avg_unit_price DESC) AS price_quartile,
	ntile(4) OVER (ORDER BY daily_velocity DESC) AS velocity_quartile,
	round(total_gross_profit * 100.0 / sum(total_gross_profit) OVER (), 2) AS profit_contribution_ratio
FROM 
	item_stats
)
SELECT
	item,
	avg_unit_price,
	daily_velocity,
	margin_percentage,
    profit_contribution_ratio,
	CASE WHEN price_quartile = 1 THEN 'Luxury'
		 WHEN price_quartile = 4 THEN 'Budget'
		 ELSE 'Mid-Tier'
	END AS price_level,
	CASE WHEN velocity_quartile = 1 THEN 'High-Velocity'
		 WHEN velocity_quartile = 4 THEN 'Low-Velocity'
		 ELSE 'Steady-Seller'
	END AS velocity_level
FROM
	item_rank
WHERE
	price_quartile = 1
	OR velocity_quartile = 1
ORDER BY 
	profit_contribution_ratio DESC;


-- =========================================================================================================================
-- 4) Impact of Operational Variability (The Delay Effect)

/* Does a 'Delayed' flight status lead to a statistically significant increase 
 * in Average Transaction Value (ATV) due to extended passenger dwell time?
 */
-- =========================================================================================================================





-- =========================================================================================================================
-- 5) Macro-Segmented Consumer Behavior

/* What are the distinct category preferences across different nationalities, 
 * and how can we tailor 'Seasonal Hero Products' for specific groups 
 * like Japanese students or Korean skincare enthusiasts?
 */
-- =========================================================================================================================




-- =========================================================================================================================
-- 6) Promotional Efficiency & Margin Dilution

/* To what extent did the 'Buy X Get Y' promotions (e.g., Paw Paw Ointment) increase sales volume, 
 * and did the volume uplift offset the reduction in the Realized Average Unit Price?
 */
-- =========================================================================================================================




-- =========================================================================================================================
-- 7) Analyzing the 'Ghost' Segment (Data Integrity)

/* How does the purchasing behavior of the 'No Boarding Pass' segment differ from 'Passenger' segments, 
 * and what does this reveal about airport staff or visitor spending habits?
 */
-- =========================================================================================================================





















