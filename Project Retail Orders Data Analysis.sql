select * from retail_orders;

describe retail_orders;

-- str_to_date(order_date, "%d-%m-%Y")

-- Step 1: Add a new temporary column
ALTER TABLE retail_orders ADD order_date_temp DATE;

-- Step 2: Update the temporary column with converted dates
UPDATE retail_orders SET order_date_temp = str_to_date(order_date, "%d-%m-%Y");

-- Step 3: Drop the original text column
ALTER TABLE retail_orders DROP COLUMN order_date;

-- Step 4: Rename the temporary column to the original column name
ALTER TABLE retail_orders CHANGE order_date_temp order_date DATE;




-- 1. Find top 10 highest reveue generating products 

select 
	count(distinct product_id) as distinctProducts
from retail_orders;

SELECT 
	product_id, ROUND(SUM(quantity*sale_price),2) as sales
FROM retail_orders
GROUP BY product_id
ORDER BY sales DESC
LIMIT 10;



-- 2. Find top 5 highest selling products in each region.

WITH CTE AS (
SELECT 
	region, product_id, 
    ROUND(SUM(quantity*sale_price),2) as sales
FROM retail_orders
GROUP BY region, product_id )

SELECT 
	region, product_id, sales
FROM (
SELECT 
	region, product_id, sales,
    ROW_NUMBER() OVER(PARTITION BY region ORDER BY sales DESC) as rn
FROM CTE ) temp
WHERE rn <= 5
ORDER BY 1,3 DESC;




-- 3. Find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023.
WITH CTE AS (
SELECT
	MONTH(order_date) as mn,
	date_format(order_date, "%b") as mnth,
    ROUND(SUM(CASE WHEN YEAR(order_date) = 2022 THEN quantity*sale_price ELSE 0 END)) as sales2022,
    ROUND(SUM(CASE WHEN YEAR(order_date) = 2023 THEN quantity*sale_price ELSE 0 END)) as sales2023
FROM retail_orders
GROUP BY MONTH(order_date),date_format(order_date, "%b") )

SELECT 
	mnth, 
    ROUND((sales2023 - sales2022)*100/sales2022, 2) AS grwothPercent
FROM CTE
ORDER BY mn;




-- 4. For each category which month had highest sales

select distinct category from retail_orders;

SELECT 
	category, yearMonth, sales
FROM (
SELECT 
	category, date_format(order_date, "%b-%Y") as yearMonth,
	ROUND(SUM(quantity*sale_price)) AS sales,
    ROW_NUMBER() OVER(PARTITION BY category ORDER BY ROUND(SUM(quantity*sale_price)) DESC) AS rn
FROM retail_orders
GROUP BY category, date_format(order_date, "%b-%Y") ) temp
WHERE rn = 1;



-- 5. Which sub category had highest growth by profit in 2023 compare to 2022 ?

WITH CTE AS (
SELECT  
	category, sub_category,
    ROUND(SUM(CASE WHEN YEAR(order_date) = 2022 THEN quantity*sale_price ELSE 0 END)) as sales2022,
    ROUND(SUM(CASE WHEN YEAR(order_date) = 2023 THEN quantity*sale_price ELSE 0 END)) as sales2023
FROM retail_orders
GROUP BY category, sub_category )

SELECT 
	*, (sales2023-sales2022) as growthInSales
FROM CTE
ORDER BY ROUND((sales2023-sales2022),4) DESC
LIMIT 1;