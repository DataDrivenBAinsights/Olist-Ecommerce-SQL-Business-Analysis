-- Data Cleaning

-- 1 Checking duplicate records
SELECT customer_id , COUNT(*)
FROM Customers
GROUP BY customer_id
HAVING COUNT(*) >1;

SELECT order_id , COUNT(*)
FROM Orders
GROUP BY order_id
HAVING COUNT(*) >1;

SELECT product_id , COUNT(*)
FROM Products
GROUP BY product_id
HAVING COUNT(*) >1;

SELECT seller_id , COUNT(*)
FROM Sellers
GROUP BY seller_id
HAVING COUNT(*) >1;

SELECT review_id , COUNT(*)
FROM Order_reviews
GROUP BY review_id
HAVING COUNT(*) >1;

-- Observation 
-- There is no Null primary key


-- Counting Null values (if there is any)

SELECT
COUNT(*) AS total_rows,
COUNT(customer_unique_id) AS customer_unique_id,
COUNT(customer_zip_code_prefix) AS zip_code,
COUNT(customer_city) AS city,
COUNT(customer_state) AS state
FROM Customers;
-- No null values found

SELECT
COUNT(*) AS total_orders,
COUNT(order_status) AS order_status,
COUNT(order_purchase_timestamp) AS purchase_date,
COUNT(order_delivered_customer_date) AS delivered_date,
COUNT(order_estimated_delivery_date) AS estimated_date
FROM Orders;
-- There are some Null values in delivered date as some orders must have been cancelled

SELECT
COUNT(*) AS total_rows,
SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS null_lat,
ROUND( 100.0 * SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_lat,
SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_code,
SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS null_lng,
SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS null_city,
SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM Geoloacation;

-- 2 Order_review table
SELECT 
COUNT(*) AS total_rows,
SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_reviews,
SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS null_comment_title,
ROUND( 100.0 * SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_title,
SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_comment_message,
ROUND( 100.0 * SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_message
FROM Order_reviews;
-- Observation 
-- All customer do not leave a written review , they prefer to give rating only

-- 3 Orders table
SELECT
COUNT(*) AS total_rows,
SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_carrier_date,
ROUND( 100.0 * SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_carrier_date,
SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered_customer_date,
ROUND( 100.0 * SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_customer_date
FROM Orders;
--Observation
-- Some orders were cancelled by the customers
-- And some orders were not delivered due to various reasons such as Logistics, Avalability, etc.


-- 4 Products table
SELECT 
COUNT(*) AS total_rows,
SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_Product_category,
ROUND( 100.0 * SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_product_category_name,
SUM(CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END) AS null_product_name,
ROUND( 100.0 * SUM(CASE WHEN product_name_lenght IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_name_length,
SUM(CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END) AS null_product_description,
ROUND( 100.0 * SUM(CASE WHEN product_description_lenght IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_description_length,
SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END) AS null_product_photos,
ROUND( 100.0 * SUM(CASE WHEN product_photos_qty IS NULL THEN 1 ELSE 0 END)/COUNT(*),2) AS Percent_null_photos_qty,
SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS null_productt_weight,
SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS null_product_length,
SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS null_product_height,
SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS null_product_width
FROM Products;

-- 5 Sellers table
SELECT 
COUNT(*) AS total_rows,
SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_Seller_id,
SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_code,
SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) AS null_seller_city,
SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS null_seller_state
FROM Sellers;

-- Checking data consistency

-- Delivered before purchase
SELECT *
FROM Orders
WHERE order_delivered_customer_date < order_purchase_timestamp;
-- No rows found

-- Estimated delivery before purchase
SELECT *
FROM Orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;
-- No rows found

-- Approval before purchase
SELECT *
FROM Orders
WHERE order_approved_at < order_purchase_timestamp;
-- No rows found

-- Carrier pickup before approval
SELECT COUNT(*)
FROM Orders
WHERE order_delivered_carrier_date < order_approved_at;
-- There are 1359 orders where carrier is picked up before approval

-- Carrier pickup before purchase
SELECT COUNT(*)
FROM Orders
WHERE order_delivered_carrier_date < order_purchase_timestamp;
-- There arae 166 orders where carrier is picked up before purchase

-- Order delivered before carrier picked
SELECT COUNT(*)
FROM Orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;
-- There are 23 orders where order is delivered before carrier is picked up

-- Orders approved but never purchased
SELECT *
FROM Orders
WHERE order_purchase_timestamp IS NULL
AND order_approved_at IS NOT NULL;
-- No rows found

-- Delivered orders without delivery date
SELECT *
FROM Orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NULL;
-- There are 8 orders which are delivered without delivery date

-- Delivered orders without carrier date
SELECT *
FROM Orders
WHERE order_status = 'delivered'
AND order_delivered_carrier_date IS NULL;
-- There is 1 order where order delivery date is null as well as carrier date is also null
-- There is 1 order where both are null 

-- Orders without payments
SELECT o.order_id
FROM Orders o
LEFT JOIN Order_payments op
ON o.order_id = op.order_id
WHERE op.order_id IS NULL;
-- There is 1 order without payment

-- Review created before order delivered
SELECT *
FROM Order_reviews r
JOIN Orders o
    ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_delivered_customer_date;


--Checking numeric columns

-- Negative payment value
SELECT *
FROM Order_payments
WHERE payment_value < 0;
-- No rows found

-- Negatie price values
SELECT *
FROM Order_items
WHERE price <0;
-- No rows found

-- Negative freight value
SELECT * 
FROM Order_items 
WHERE freight_value <0;
-- No rows found

-- Negative product dimensions
SELECT * 
FROM Products
WHERE product_weight_g <0 or product_length_cm <0 or product_height_cm <0;
-- No rows found

-- Checking order status
SELECT
order_status,
COUNT(*) AS total_orders
FROM Orders
GROUP BY order_status
ORDER BY total_orders DESC;
-- Most of the orders are delivered


-- Validatng relationships 

SELECT COUNT(*)
FROM Orders AS O
LEFT JOIN Customers AS C
ON O.customer_id = C.customer_id
WHERE C.customer_id IS NULL;
-- Every order has a customer

SELECT COUNT(*)
FROM Orders AS O
LEFT JOIN Order_payments AS OP
ON O.order_id = OP.order_id
WHERE OP.order_id IS NULL;
-- 1 Orders do not have matching payment records


SELECT COUNT(*)
FROM Orders AS O
LEFT JOIN Order_reviews AS ORe
ON O.order_id = ORe.order_id
WHERE O.order_id IS NULL;
-- All orders has a review

-- Are there products that have never been ordered ?
SELECT COUNT(*) 
FROM Products AS P
LEFT JOIN Order_items AS OI
ON P.product_id = OI.product_id
WHERE OI.product_id IS NULL; 
-- All products have been ordered at least once

SELECT COUNT(*)
FROM Order_items AS OI
LEFT JOIN Sellers AS S
ON OI.seller_id = S.seller_id
WHERE S.seller_id IS NULL;
-- There are no order items that do not have a seller

-- Categorizing delivery performance
SELECT
order_id,
DATEDIFF(
    DAY,
    order_purchase_timestamp,
    order_delivered_customer_date
) AS delivery_days,
CASE
    WHEN DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) <= 7 THEN 'Fast'
    WHEN DATEDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) <= 15 THEN 'Normal'
    ELSE 'Slow'
END AS delivery_category
FROM Orders
WHERE order_delivered_customer_date IS NOT NULL;

