SELECT * FROM Store_Project.customers;

-- CLEANING DATA

UPDATE customers
SET customer_city = UPPER(customer_city);

ALTER TABLE orders
MODIFY COLUMN order_purchase_date DATETIME;

ALTER TABLE orders
MODIFY COLUMN order_delivered_data DATETIME;
ALTER TABLE orders
MODIFY COLUMN order_delivered_time TIME;

SELECT * FROM orders
WHERE order_delivered_time = '00:00:00'; 

UPDATE orders
SET order_delivered_data = NULL
WHERE order_delivered_data = 'N/A';

UPDATE orders
SET order_delivered_time = NULL
WHERE order_delivered_time = '00:00:00';

UPDATE orders
SET order_approved_date = NULL
WHERE order_approved_date = 'N/A';

UPDATE orders
SET order_approved_time = NULL
WHERE order_approved_time = '00:00:00';

ALTER TABLE orders
ADD COLUMN order_delivered_timestamp DATETIME AFTER order_approved_time;
UPDATE orders
SET order_delivered_timestamp = CONCAT(order_delivered_data, ' ', order_delivered_time)
;

ALTER TABLE orders
ADD COLUMN order_purchase_timestamp DATETIME AFTER order_status;
UPDATE orders
SET order_purchase_timestamp = CONCAT(order_purchase_date, ' ', order_purchase_time);

ALTER TABLE orders
DROP COLUMN  order_purchase_date,
DROP COLUMN order_purchase_time, 
DROP COLUMN order_delivered_data, 
DROP COLUMN order_delivered_time,
DROP COLUMN order_approved_date,
DROP COLUMN order_approved_time;

-- DELETE DUPLICATED customer_id
-- Check duplicated rows
SELECT customer_id, COUNT(*) AS duplicate_row
FROM customers
GROUP BY customer_id
HAVING count(*)>1
;

-- Change Data type to date
ALTER table orders
modify order_purchase_date DATE,
modify order_approved_date DATE,
modify order_delivered_data DATE,
modify order_estimated_delivery_date DATE;

UPDATE orders
SET order_delivered_data = NULL
WHERE order_delivered_data=' ';

-- CUSTOMER ANALYSIS:

-- How many customers do we have in total?
SELECT count(distinct(customer_id)) as total_customer
FROM customers;

-- What are the top 5 cities where having the most customers?
SELECT customer_city, COUNT(*) AS city_count
FROM customers
GROUP BY customer_city
ORDER BY city_count DESC
LIMIT 15;

-- •	How many orders were placed by each customer?
SELECT distinct(customer_id), count(order_id) AS number_of_order
FROM orders
Group by customer_id;

-- ORDER ANALYSIS:

-- The timeframe of the dataset
SELECT 
	MAX(order_purchase_timestamp) AS started_date, 
    MIN(order_purchase_timestamp) AS ended_date
FROM orders;

-- types of order status: delivered, invoiced, shipped, processing, unavailable, canceled, created, approved
SELECT distinct(order_status)
FROM orders;

-- indicate the number of invalid orders for each distinct order status 
SELECT order_status, COUNT(*) AS invalid_orders
FROM orders
WHERE order_delivered_timestamp is NULL
GROUP BY order_status
ORDER BY invalid_orders;

-- orders in 2018, 2017, 2016
SELECT 
	SUM(CASE WHEN YEAR(order_purchase_date)=2018 THEN 1 ELSE 0 END) AS orders_2018, -- 54011
    SUM(CASE WHEN YEAR(order_purchase_date)=2017 THEN 1 ELSE 0 END) AS orders_2017, -- 45101
    SUM(CASE WHEN YEAR(order_purchase_date)=2016 THEN 1 ELSE 0 END) AS orders_2016 -- 329
FROM orders;

-- total orders delivered
SELECT 
	SUM(CASE WHEN YEAR(order_purchase_date)=2018 THEN 1 ELSE 0 END) AS order_delivered_2018, -- 52783
    SUM(CASE WHEN YEAR(order_purchase_date)=2017 THEN 1 ELSE 0 END) AS order_delivered_2017, -- 43428
    SUM(CASE WHEN YEAR(order_purchase_date)=2016 THEN 1 ELSE 0 END) AS order_delivered_2016 -- 267
FROM orders
WHERE order_status='delivered'
;

-- total orders canceled: 334
SELECT 
	SUM(CASE WHEN YEAR(order_purchase_date)=2018 THEN 1 ELSE 0 END) AS order_canceled_2018, -- 334
    SUM(CASE WHEN YEAR(order_purchase_date)=2017 THEN 1 ELSE 0 END) AS order_canceled_2017, -- 265
    SUM(CASE WHEN YEAR(order_purchase_date)=2016 THEN 1 ELSE 0 END) AS order_canceled_2016 -- 26
FROM orders
WHERE order_status='canceled';

select distinct(order_item_id) from order_items; -- 1,2,3...21

SELECT order_item_id, count(order_item_id)
from order_items
Group by order_item_id; 

-- Total Revenue: $15 421 083
SELECT round(sum(pa.payment_value),0) AS total_revenue
FROM payments pa
JOIN orders od ON pa.order_id = od.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
;

-- REVENUE EACH YEAR
SELECT 
	YEAR(od.order_purchase_timestamp) AS the_year,
    ROUND(SUM(pa.payment_value),0) AS revenue
FROM orders od
JOIN payments pa ON pa.order_id = od.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY the_year
ORDER BY the_year;
		
-- QUARTERLY REVENUE
SELECT 
	YEAR(od.order_purchase_timestamp) AS the_year,
    QUARTER(od.order_purchase_timestamp) AS the_quarter,
    ROUND(SUM(pa.payment_value),0) AS revenue
FROM orders od
JOIN payments pa ON pa.order_id = od.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY the_year, the_quarter
ORDER BY the_year, the_quarter;

-- MONTHLY SALES
SELECT 
	YEAR(od.order_purchase_timestamp) AS the_year,
    QUARTER(od.order_purchase_timestamp) AS the_quarter,
    MONTH(od.order_purchase_timestamp) AS the_month,
    ROUND(SUM(pa.payment_value),0) AS revenue
FROM orders od
JOIN payments pa ON pa.order_id = od.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY the_year, the_quarter, the_month
ORDER BY revenue DESC;

-- Retrieve the total revenue amount for a specific product:
SELECT product_category_name, revenue_amount 
FROM product_revenue
WHERE product_id = '2f763ba79d9cd987b2034aac7ceffe06';

-- Average price of product sold: 120.29
SELECT round(AVG(price),2) AS average_price
FROM order_items;

-- TOP 20 best-selling products
SELECT oi.order_id, oi.product_id, pr.product_category_name, count(oi.product_id) AS number_product_sold
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN orders od ON od.order_id = oi.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
Group By oi.order_id, oi.product_id, pr.product_category_name
Order By count(product_id) DESC
LIMIT 20;

-- TOP 20 pruducts sold with highest revenue
SELECT oi.order_id, oi.product_id, pv.product_category_name, pv.revenue_amount
FROM order_items oi
JOIN product_revenue pv ON oi.product_id = pv.product_id
JOIN orders od ON od.order_id = oi.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
Group By oi.order_id, oi.product_id, pv.product_category_name, pv.revenue_amount
Order By pv.revenue_amount DESC
LIMIT 20;

-- total orders over 2 years?: = 99 470 orders
SELECT count(DISTINCT(order_id)) AS total_orders
FROM orders
WHERE order_status <> 'canceled' AND order_delivered_timestamp IS NOT NULL
;

-- Number of Orders Quarterly

SELECT
	Year(order_purchase_timestamp) AS the_year,
    QUARTER(order_purchase_timestamp) AS the_quarter,
    COUNT(*) AS num_order
FROM orders
WHERE order_status <> 'canceled' AND order_delivered_timestamp IS NOT NULL
GROUP BY the_year, the_quarter
ORDER BY the_year, the_quarter;

-- Number of Orders MONTHLY
SELECT
	Year(order_purchase_timestamp) AS the_year,
   MONTH(order_purchase_timestamp) AS the_month,
    COUNT(*) AS num_order
FROM orders
WHERE order_status <> 'canceled' AND order_delivered_timestamp IS NOT NULL
GROUP BY the_year, the_month
ORDER BY num_order DESC;
    
-- PRODUCT ANALYSIS:

-- Change product weight from G to KG
UPDATE products
SET product_weight_g = product_weight_g / 1000;

ALTER TABLE products
CHANGE product_weight_g product_weight_kg DECIMAL(4,2);

-- Upadate the empty spaces in ‘product_category_name’ to 'N/A'
SELECT *
FROM products
WHERE product_category_name = '';
UPDATE products
SET product_category_name = 'N/A'
WHERE product_category_name = '';

-- •	How many products do we have in total?: 71
SELECT count(distinct(product_category_name)) AS total_product_name
FROM products;

-- Total Product ID sold: 108 591

SELECT COUNT(oi.product_id) AS total_product_id
FROM order_items oi
JOIN orders od ON od.order_id = oi.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
;

-- TOTAL ORDERS SOLD
SELECT COUNT(od.order_id) AS total_num_orders
FROM orders od
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
;

-- - MOST POPULAR PRODUCTS ORDERED AND IT'S PERCENTAGE OF TOTAL
SELECT 
	pr.product_category_name AS product_name,
    COUNT(od.order_id) AS num_order,
    round((count(od.order_id)/total_orders.total_num_order)*100,2) AS percentage
FROM orders od
JOIN order_items oi ON oi.order_id = od.order_id
JOIN (
	SELECT product_id, product_category_name 
    FROM products pr
    ) AS pr ON oi.product_id = pr.product_id
 CROSS JOIN (
	SELECT COUNT(od.order_id) AS total_num_order
    FROM orders od
    JOIN order_items oi ON oi.order_id = od.order_id
    JOIN products pr ON pr.product_id = oi.product_id
	WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL  
    ) AS total_orders
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY product_name, total_num_order
order by percentage DESC
;


-- Generate Products Information and Revenue Amount from each product
CREATE OR REPLACE VIEW product_revenue AS
SELECT 
	oi.product_id, 
    pr.product_category_name, 
    (pr.product_length_cm * pr.product_height_cm * pr.product_width_cm) AS product_volume,
    count(oi.product_id) AS product_quantity,
    oi.price,
    oi.shipping_charges,
    round(sum(pa.payment_value),0) AS revenue_amount
FROM order_items oi
JOIN products pr ON oi.product_id = pr.product_id
JOIN orders od ON oi.order_id = od.order_id
JOIN payments pa ON pa.order_id = od.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
Group by oi.product_id, pr.product_category_name, product_volume, oi.price, oi.shipping_charges
Order by pr.product_category_name; 

-- Ranking the products’ performance during the 3-year time period
SELECT
	YEAR(od.order_purchase_timestamp) AS the_year,
    pr.product_category_name AS product_name,
    COUNT(od.order_id) AS num_order,
    RANK() OVER(ORDER BY COUNT(od.order_id) DESC) AS ranking
FROM orders od
JOIN order_items oi ON oi.order_id = od.order_id
JOIN products pr ON pr.product_id = oi.product_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY product_name, the_year
order by ranking;

-- THE AVARAGE ORDER VALUE: 153
SELECT
	ROUND(SUM(pa.payment_value)/COUNT(od.order_id), 0) AS average_order_value
FROM payments pa
JOIN orders od ON od.order_id = pa.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
;

-- VARAGE ORDER VALUE BY PAYMENT METHOD
SELECT
	pa.payment_type,
    ROUND(SUM(pa.payment_value)/COUNT(distinct(od.order_id)), 0) AS average_order_value
FROM payments pa
JOIN orders od ON od.order_id = pa.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY payment_type
ORDER BY average_order_value DESC;

-- NUMBER OF SELLER: 3087
SELECT COUNT(distinct(seller_id)) 
FROM order_items;

-- PAYMENT VALUE FOR EACH ORDER ID
SELECT 
	od.order_id AS order_id,
    ROUND(SUM(pa.payment_value),2) AS payment_value
FROM orders od
JOIN payments pa ON pa.order_id = od.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY order_id;

-- TOTAL CUSTOMERS: 99 441
SELECT count(customer_id) AS total_customers
FROM customers;
-- Distinct Customers: 96 096
SELECT count(distinct(customer_id)) AS customers
FROM customers;
-- Total Customer State: 27
SELECT count(distinct(customer_state)) AS total_customer_state
FROM customers;

-- number of customers have made repeat purchases: 2979
SELECT COUNT(*) AS num_customer_repeat
FROM(
	SELECT 
		cu.customer_id AS customer_repeat_purchase,
		COUNT(distinct(od.order_id)) AS num_repeat_purchase
	FROM customers cu
	JOIN orders od ON od.customer_id = cu.customer_id
	WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
	GROUP BY customer_repeat_purchase
	HAVING COUNT(od.order_id) > 1
	ORDER BY num_repeat_purchase DESC
	) AS repeat_customers
;

-- REVENUE OF RETURN CUSTOMERS:
SELECT ROUND(SUM(revenue), 0) AS revenue_re_customers
FROM 
	(
	SELECT 
		cu.customer_id AS customer_repeat_purchase,
		COUNT(distinct(od.order_id)) AS num_repeat_purchase,
		SUM(pa.payment_value) AS revenue
	FROM orders od
	JOIN customers cu ON cu.customer_id = od.customer_id
	JOIN payments pa ON pa.order_id = od.order_id
	WHERE cu.customer_id IN
		(
		SELECT cu.customer_id
		FROM orders od
		JOIN customers cu ON cu.customer_id = od.customer_id
		WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
		GROUP BY cu.customer_id
		HAVING COUNT(cu.customer_id) > 1
		)
	GROUP BY customer_repeat_purchase
	HAVING COUNT(cu.customer_id) > 1
	ORDER BY num_repeat_purchase
    ) AS sub_query
;

-- Percentage of total_reveneu from return customers
SELECT ROUND((revenue_re_customers/total_revenue)*100,2) AS percentage_return_customers
FROM 
	(
	SELECT ROUND(SUM(revenue), 0) AS revenue_re_customers
	FROM 
		(
		SELECT 
			cu.customer_id AS customer_repeat_purchase,
			COUNT(distinct(od.order_id)) AS num_repeat_purchase,
			SUM(pa.payment_value) AS revenue
		FROM orders od
		JOIN customers cu ON cu.customer_id = od.customer_id
		JOIN payments pa ON pa.order_id = od.order_id
		WHERE cu.customer_id IN
			(
			SELECT cu.customer_id
			FROM orders od
			JOIN customers cu ON cu.customer_id = od.customer_id
			WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
			GROUP BY cu.customer_id
			HAVING COUNT(cu.customer_id) > 1
			)
		GROUP BY customer_repeat_purchase
		HAVING COUNT(cu.customer_id) > 1
		ORDER BY num_repeat_purchase
		) AS sub_query
	) AS return_customers_revenue,

	(SELECT
		ROUND(SUM(pa.payment_value), 0) AS total_revenue
		FROM payment pa
		JOIN orders od ON od.order_id = pa.order_id
		WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
	) AS total_revenue
;

-- the average order cancellation rate, and how does this impact seller performance?
-- Canceled status: 625, 0.63%
SELECT 
	order_status,
    COUNT(order_id) AS num_order,
	ROUND( 100 * COUNT(order_id)/SUM(COUNT(order_id)) OVER (),2) AS percentage
FROM orders
GROUP BY order_status
;

-- payment methods are most commonly used: credit card, wallet, then voucher, debit card
SELECT
	payment_type,
    COUNT(*) AS num_payment_type
FROM payments pa
JOIN orders od ON od.order_id = pa.order_id
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY payment_type;

-- Payment Types by region
select
	cu.customer_city,
    pa.payment_type,
    COUNT(DISTINCT(pa.order_id)) AS order_quantity,
    RANK() OVER (ORDER BY COUNT(DISTINCT(pa.order_id)) DESC) AS ranking
FROM customers cu
JOIN orders od ON od.customer_id = cu.customer_id
JOIN payments pa ON od.order_id = pa.order_id 
WHERE od.order_status <> 'canceled' AND od.order_delivered_timestamp IS NOT NULL
GROUP BY customer_city, payment_type
ORDER BY order_quantity DESC
;





