-- CUSTOMER ANALYSIS

-- Task 1 – Customer Overview

-- Task 1.1 Total Customers
SELECT COUNT(customer_id) AS Total_customers
FROM Customers;

-- Total Customers = 99441

-- Task 1.2 Total Orders
SELECT COUNT(order_id) AS Total_orders
FROM Orders;

-- Total Orders = 99441

-- Task 1.3 Order per Customer
SELECT C.customer_id,
	   COUNT(O.order_id) AS Order_per_customer
FROM Customers AS C
JOIN Orders AS O
ON C.customer_id = O.customer_id
GROUP BY C.customer_id
ORDER BY Order_per_customer DESC;

-- All customers have exactly one order each


-- Task 2 – New vs Repeat Customers 

-- Task 2.1 New Customers
SELECT customer_id,
       MIN(order_purchase_timestamp) AS First_purchase_date
FROM Orders
GROUP  BY customer_id
ORDER BY First_purchase_date;

-- Total new customers = 99441
-- There are 'No' repeat customers

-- Task 2.2 Repeat Customers
SELECT customer_id,
       COUNT(order_id) AS Order_per_customer
FROM Orders
GROUP BY customer_id
HAVING COUNT(order_id) >1
ORDER BY Order_per_customer DESC ;

-- Number of repeat customers = 0


-- Task 3 – Customer Lifetime Value (CLV)

-- Task 3.1 Total revenue per customer
SELECT O.customer_id,
       SUM(OP.payment_value) AS Total_payment
FROM Orders AS O
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
GROUP BY O.customer_id
ORDER BY Total_payment DESC;

-- Insights
-- Total highest order value by a single customer is = USD 13664
-- Minimum order value by a single customer is = 0

-- Task 3.2 Top 20 customers
SELECT TOP 20 O.customer_id,
       SUM(OP.payment_value) AS Total_payment
FROM Orders AS O
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
GROUP BY O.customer_id
ORDER BY Total_payment DESC;


-- Task 4 – Customer Segmentation

-- Task 4.1 How many customers belong to each segment?
WITH CustomerSpending AS
(
    SELECT
        O.customer_id,
        SUM(OP.payment_value) AS total_spending
    FROM Orders O
    JOIN Order_payments OP
        ON O.order_id = OP.order_id
    GROUP BY O.customer_id
)

SELECT
    CASE
        WHEN total_spending > 1000 THEN 'High Value'
        WHEN total_spending BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment,
    COUNT(*) AS number_of_customers
FROM CustomerSpending
GROUP BY
    CASE
        WHEN total_spending > 1000 THEN 'High Value'
        WHEN total_spending BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END
ORDER BY number_of_customers DESC;
 /* Insights
 1 Number of Low Value customers - 95144
 2 Number of Medium Value customers -	3122
 3 Number of High Value customers - 1174
 */

 -- Task 4.2 Which segment generates the most revenue?
 WITH CustomerSpending AS
(
    SELECT
        O.customer_id,
        SUM(OP.payment_value) AS total_spending
    FROM Orders O
    JOIN Order_payments OP
        ON O.order_id = OP.order_id
    GROUP BY O.customer_id
)

SELECT
    CASE
        WHEN total_spending > 1000 THEN 'High Value'
        WHEN total_spending BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_segment,
    COUNT(*) AS customers,
    SUM(total_spending) AS total_revenue,
    ROUND(AVG(total_spending),2) AS avg_customer_spending
FROM CustomerSpending
GROUP BY
    CASE
        WHEN total_spending > 1000 THEN 'High Value'
        WHEN total_spending BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END
ORDER BY total_revenue DESC;

/* Insights
 
1.95.7% of customers are Low Value, generating USD 12.01M in revenue with an average spend of USD 126.27.
 Increase their average spend through cross-selling and promotions.
2.Only 1.2% of customers are High Value, but they spend USD 1,592 on average.
 Focus on retaining these customers with loyalty and VIP programs.
3. 3.1% of customers are Medium Value, spending USD 681 on average.
 Target this segment with upselling campaigns to convert them into High Value customers.
 */


-- Task 5 – Geographic Customer Analysis

-- Task 5.1 Customers by state
SELECT COUNT(C.customer_id) AS Customers_BY_state,
       C.customer_state,
       SUM(OP.payment_value) AS Revenue_by_state
FROM Customers AS C
JOIN Orders AS O
ON C.customer_id = O.customer_id
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
GROUP BY C.customer_state
ORDER BY Revenue_by_state DESC;

/* Insights
1. Sao Paulo has almost 44% of the customer base

2. The states with high customers contrubute most to the revnue(top 5 states = 75% of the revenue)
*/

-- Task 5.2 Customers by City
SELECT COUNT(C.customer_id) AS Customers_by_city,
       C.customer_city,
       SUM(OP.payment_value) AS Revenue_by_state
FROM Customers AS C
JOIN Orders AS O
ON C.customer_id = O.customer_id
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
GROUP BY C.customer_city
ORDER BY Revenue_by_state DESC;

-- Insights
-- Metro cities like Sao Paulo, Rio De Jenrio and Belo Horizonte make up almost 26 % of the total customers 


--Task 6 – Customer Purchase Frequency

-- Task 6.1 Average order per customers
SELECT
    ROUND(AVG(total_orders), 2) AS avg_orders_per_customer
FROM(
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders
    FROM Orders
    GROUP BY customer_id
) AS CustomerOrders;

-- Average order per customer is 1 , indicating that the business relies heavily on acquiring new customers rather than retaining existing ones.

-- Task 6.2 Order purchase frequency
SELECT
    total_orders,
    COUNT(*) AS number_of_customers
FROM(
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders
    FROM Orders
    GROUP BY customer_id
) AS CustomerOrders
GROUP BY total_orders
ORDER BY total_orders;

-- Order purchase frequency of all the customers = 1


--Task 7 – Customer Recency

-- Task 7.1 When did customers make their last purchase?
SELECT customer_id,
       MAX(order_purchase_timestamp) AS Last_purchase_date
FROM Orders
GROUP BY customer_id
ORDER BY Last_purchase_date DESC;

-- The most recent purchase in the dateset is '17-10-2018'

-- Task 7.2 Days since last purchase?
SELECT customer_id,
       MAX(order_purchase_timestamp) AS Last_purchase_date,
       DATEDIFF(DAY, MAX(order_purchase_timestamp), '2018-11-01' ) AS Days_since_last_purchase 
FROM Orders
GROUP BY customer_id
ORDER BY Last_purchase_date DESC;

/* Insights
1. 0–30 days: Active customers
2. 31–90 days: At-risk customers
3. 90+ days: Dormant customers who may need re-engagement campaigns
*/


--Task 8 – Customer Revenue Distribution

-- Task 8.1 Top 10% customers by revenue
WITH CustomerRevenue AS
(
SELECT O.customer_id,
       SUM(OP.payment_value) AS Customer_revenue
FROM Orders AS O
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
GROUP BY O.customer_id),

RankedCustomers AS
( SELECT *,
         NTILE(10) OVER(ORDER BY Customer_revenue DESC) AS Customer_decile
FROM CustomerRevenue)

SELECT *
FROM RankedCustomers;

-- Task 8.2 What percentage of revenue comes from the top 10% of customers?
WITH CustomerRevenue AS
(
SELECT O.customer_id,
       SUM(OP.payment_value) AS Customer_revenue
FROM Orders AS O
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
GROUP BY O.customer_id),

RankedCustomers AS
( SELECT *,
         NTILE(10) OVER(ORDER BY Customer_revenue DESC) AS Customer_decile
FROM CustomerRevenue)

SELECT ROUND(SUM(CASE WHEN Customer_decile = 1 THEN Customer_revenue END) * 100 
       /SUM(Customer_revenue),2) as Top_10_percent_revenue_share
FROM RankedCustomers;

-- Contribution of top 10% customers in revenue is '38.3%'


-- Task 9 – Customer Satisfaction

-- Task 9.1 Spending and Review relationship
SELECT O.customer_id,
       OP.payment_value,
       ORs.review_score
FROM Orders AS O
JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
ORDER BY OP.payment_value DESC;

/*Insight:

1.Some of the highest-spending customers gave the lowest possible rating.

2.These customers represent a high risk of churn because they contribute significant revenue but had a poor experience.

3.Most of the customers shown have review scores of 5.

4.Higher spending does not necessarily result in higher satisfaction.
*/


/* Business Recommendations

1. Customer Retention
Launch loyalty programs for repeat customers.
Offer personalized discounts to inactive customers.

2. High-Value Customers
Provide exclusive offers and early access to premium customers.

3. Low-Value Customers
Encourage higher spending through bundles and free shipping thresholds.

4. Geographic Expansion
Target states with many customers but relatively low revenue per customer.

5. Prioritize High-Revenue States (Sao Paulo (SP), Rio de Janeiro (RJ), and Minas Gerais (MG))
Increase investment in these states through targeted marketing, premium services,
and customer retention programs to maximize revenue from the strongest markets.

6. Expand Presence in Low-Performing States (RR, AP, AC, and AM)
 Launch region-specific marketing campaigns, promotional offers, 
and improve logistics to increase customer acquisition and unlock growth in these underpenetrated markets.
*/