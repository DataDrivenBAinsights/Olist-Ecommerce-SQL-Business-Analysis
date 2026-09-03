
--Sales and Revenue analysis

--Task 1.1 Monthly Revenue Trend

SELECT
    FORMAT(o.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    SUM(op.payment_value) AS Total_Revenue,
    ROUND(
        SUM(op.payment_value) * 1.0 /
        COUNT(DISTINCT o.order_id),2
    ) AS Average_Order_Value
FROM Orders o
JOIN Order_payments op
ON o.order_id = op.order_id
GROUP BY FORMAT(o.order_purchase_timestamp,'yyyy-MM')
ORDER BY Sales_Month;

--Task 1.2 Monthly Order Trend

SELECT
FORMAT(order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
COUNT(*) AS Total_Orders
FrOM Orders
GROUP BY FORMAT(order_purchase_timestamp,'yyyy-MM')
ORDER BY Sales_Month;

--Task 1.3 Running Revenue

WITH MonthlyRevenue AS
(
SELECT
FORMAT(o.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
SUM(op.payment_value) AS Revenue
FROM Orders o
JOIN Order_payments op
ON o.order_id=op.order_id
GROUP BY FORMAT(o.order_purchase_timestamp,'yyyy-MM')
)
SELECT
Sales_Month,
Revenue,
SUM(Revenue)
OVER(
ORDER BY Sales_Month ROWS UNBOUNDED PRECEDING
) AS Running_Revenue
FROM MonthlyRevenue;

/* insights

1.Revenue grew consistently from 2017, peaking at approximately 1.19 million in November 2017,
highlighting strong seasonal demand during the year-end shopping period.

2.Average Order Value (AOV) remained relatively stable between ?147–?174 across most months,
indicating that revenue growth was driven primarily by higher order volumes rather than customers spending significantly more per order.

3.The sharp decline in orders and revenue during September–October 2018 reflects incomplete data for those months rather than an actual business downturn, 
so they should be excluded from trend analysis.
*/


--Task 2.1 Month over Month Revenue Growth

WITH MonthlyRevenue AS
(
SELECT
FORMAT(o.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
SUM(op.payment_value) AS Revenue
FROM Orders o
JOIN Order_payments op
ON o.order_id=op.order_id
GROUP BY FORMAT(o.order_purchase_timestamp,'yyyy-MM')
)
SELECT
Sales_Month,
Revenue,
LAG(Revenue)
OVER(
ORDER BY Sales_Month
) AS Previous_Month_Revenue,
ROUND(
(
Revenue-
LAG(Revenue)
OVER(
ORDER BY Sales_Month)
)*100.0
/LAG(Revenue) OVER(ORDER BY Sales_Month)
,2
) AS Revenue_Growth_Percentage
FROM MonthlyRevenue;

/* Insights

1.Revenue showed a strong upward trend throughout 2017, with the largest monthly increase of 53.25% in November 2017,
indicating a significant boost from holiday and promotional sales.

2.Despite overall growth, revenue experienced periodic declines (April, June, December 2017 and February, June, August 2018),
suggesting seasonal fluctuations and the need for targeted sales campaigns during weaker months.

3.The dramatic revenue drops in September (-99.57%) and October (-86.72%) 2018 are most likely due to incomplete dataset
coverage rather than actual business performance and should be excluded from business trend analysis.
*/


--Task 3.1 Revenue by State

SELECT
c.customer_state,
COUNT(DISTINCT o.order_id) AS Orders,
COUNT(DISTINCT c.customer_id) AS Customers,
SUM(op.payment_value) AS Revenue,
ROUND(
SUM(op.payment_value)/
COUNT(DISTINCT c.customer_id),2) AS Revenue_Per_Customer
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
JOIN Order_payments op
ON o.order_id=op.order_id
GROUP BY c.customer_state
ORDER BY Revenue DESC;

/* Insights
1.Sao Paulo (SP) is the dominant market, generating nearly USD6.0 million in revenue from 41,745 orders,
making the business highly dependent on a single state.

2.Rio de Janeiro (RJ) and Minas Gerais (MG) are the next largest contributors,
but together they still generate significantly less revenue than SP, highlighting a strong geographic concentration of sales.

3.Several low-volume states such as Para (PA), Paraiba (PB), Alagoas (AL), Rondonia (RO), and Acre (AC) have high revenue per order,
indicating opportunities to increase order volume in these high-value markets.
*/

--Task 3.2 Top 10 States by Revenue

SELECT TOP 10
c.customer_state,
SUM(op.payment_value) AS Revenue
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
JOIN Order_payments op
ON o.order_id=op.order_id
GROUP BY c.customer_state
ORDER BY Revenue DESC;

--Task 3.3 State Revenue Contribution

WITH StateRevenue AS
(
SELECT
c.customer_state,
SUM(op.payment_value) AS Revenue
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
JOIN Order_payments op
ON o.order_id=op.order_id
GROUP BY c.customer_state
)
SELECT
customer_state,
Revenue,
ROUND(Revenue*100.0/
SUM(Revenue) OVER(),2) AS Revenue_Contribution_Percentage
FROM StateRevenue
ORDER BY Revenue DESC;

-- Insights
-- Sao Paulo(SP) and Rio De Jeniro(RJ) contribute almost 50% of the total interview

--Task 3.4 High Revenue but Few Customers

SELECT
c.customer_state,
COUNT(DISTINCT c.customer_id) AS Customers,
SUM(op.payment_value) AS Revenue,
ROUND(
SUM(op.payment_value)/
COUNT(DISTINCT c.customer_id)
,2) AS Revenue_Per_Customer
FROM Customers c
JOIN Orders o
ON c.customer_id=o.customer_id
JOIN Order_payments op
ON o.order_id=op.order_id
GROUP BY c.customer_state
HAVING COUNT(DISTINCT c.customer_id)<5000
ORDER BY Revenue DESC;

-- Insights
-- Some States like Santa Catrina(SC) ,Bahia(BA) has few cusotmers but high Aerage order value,
-- indicating that they alsi contribute to overall revenue


--Task 4.1 Revenue by City

SELECT
    c.customer_city,
    COUNT(DISTINCT o.order_id) AS Total_Orders,
    COUNT(DISTINCT c.customer_id) AS Total_Customers,
    SUM(op.payment_value) AS Revenue,
    ROUND(
        SUM(op.payment_value) * 1.0 /
        COUNT(DISTINCT o.order_id),2
    ) AS Average_Order_Value
FROM Customers c
JOIN Orders o
    ON c.customer_id = o.customer_id
JOIN Order_payments op
    ON o.order_id = op.order_id
GROUP BY c.customer_city
ORDER BY Revenue DESC;

/* Insights

1.Sao Paulo is the largest revenue-generating city, contributing over USD2.2 million from 15,540 orders,
making it the company's most important urban market by a wide margin.

2.Cities such as Rio de Janeiro, Brasilia, Salvador, Florianopolis, and Fortaleza achieve higher Average Order Values (?165–?187) than São Paulo,
indicating stronger customer spending despite lower order volumes.

3.Smaller cities like Joao Pessoa (?247.48), Belem (?216.74), Teresina (?215.75), Maceio (?215.27), and Campo Grande (?209.38) have the highest Average Order Values,
presenting attractive opportunities for targeted marketing and customer acquisition to drive revenue growth.
*/


--Task 4.2 Top 10 Cities by Revenue

SELECT TOP 10
    c.customer_city,
    SUM(op.payment_value) AS Revenue
FROM Customers c
JOIN Orders o
    ON c.customer_id = o.customer_id
JOIN Order_payments op
    ON o.order_id = op.order_id
GROUP BY c.customer_city
ORDER BY Revenue DESC;

-- Insights
-- Sao Paulo is the largest revenue-generating city, contributing over USD2.2 million from 15,540 orders,
-- followed by Rio De Jeniro ,Belo Horizonte and Brasilia,
-- making it the company's most important urban market by a wide margin.


--Task 4.3 Highest Average Order Value by City

SELECT TOP 10
    c.customer_city,
    COUNT(DISTINCT o.order_id) AS Orders,
    SUM(op.payment_value) AS Revenue,
    ROUND(
        SUM(op.payment_value) * 1.0 /
        COUNT(DISTINCT o.order_id),2
    ) AS Average_Order_Value
FROM Customers c
JOIN Orders o
    ON c.customer_id = o.customer_id
JOIN Order_payments op
    ON o.order_id = op.order_id
GROUP BY c.customer_city
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY Average_Order_Value DESC;

-- Insights
--  Smaller cities like Divinopolis(284), Porto Velho(258) have the highest order average.


--Task 5.1 Revenue by Order Status

SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS Orders,
    SUM(op.payment_value) AS Revenue
FROM Orders o
JOIN Order_payments op
    ON o.order_id = op.order_id
GROUP BY o.order_status
ORDER BY Revenue DESC;

/* Insights

1.Delivered orders account for the vast majority of business activity, generating over USD15.42 million in revenue from 96,477 orders,
demonstrating strong order fulfillment performance.

2.Canceled and unavailable orders represent a relatively small share of total orders but account for nearly USD270,000 in lost revenue,
indicating opportunities to reduce order failures and recover sales.

3.Very few orders remain in the created, approved, invoiced, processing, and shipped stages,
suggesting that most orders move efficiently through the fulfillment pipeline to final delivery.
*/

--Task 5.2 Revenue Lost Due to Cancelled Orders

SELECT
    COUNT(DISTINCT o.order_id) AS Cancelled_Orders,
    SUM(op.payment_value) AS Cancelled_Revenue
FROM Orders o
JOIN Order_payments op
    ON o.order_id = op.order_id
WHERE o.order_status = 'canceled';

-- Insights
-- Revenue lost due to Cancelled orders = USD 143k

--Task 5.3 Revenue Contribution by Order Status

WITH StatusRevenue AS
(
    SELECT
        o.order_status,
        SUM(op.payment_value) AS Revenue
    FROM Orders o
    JOIN Order_payments op
        ON o.order_id = op.order_id
    GROUP BY o.order_status
)
SELECT
    order_status,
    Revenue,
    ROUND(
        Revenue * 100.0 /
        SUM(Revenue) OVER(),
        2
    ) AS Revenue_Contribution_Percentage
FROM StatusRevenue
ORDER BY Revenue DESC;

-- Insights
-- Delivered orders make up '96' percent of the revenue


--Task 6.1 Overall Average Order Value

SELECT
    ROUND(
        SUM(payment_value) * 1.0 /
        COUNT(DISTINCT order_id),
        2
    ) AS Average_Order_Value
FROM Order_payments;
-- Insight
-- Overall order value = USD160.99

--Task 6.2 Monthly Average Order Value

SELECT
    FORMAT(o.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
    ROUND(
        SUM(op.payment_value) * 1.0 /
        COUNT(DISTINCT o.order_id),
        2
    ) AS Average_Order_Value
FROM Orders o
JOIN Order_payments op
    ON o.order_id = op.order_id
GROUP BY FORMAT(o.order_purchase_timestamp,'yyyy-MM')
ORDER BY Sales_Month;

/* Insights

1.Average Order Value remained relatively stable between USD 147 and USD174 for most months, indicating consistent customer spending patterns over time.

2.The highest reliable AOV was recorded in October 2016 (USD 182.38), while most of 2017–2018 maintained a healthy and stable AOV despite fluctuations in order volume.

3.The unusually high AOV in September 2018 (USD 277.47) is likely caused by incomplete monthly data with very few orders and should be excluded from trend analysis.
*/

--Task 6.3 Average Order Value by State

SELECT
    c.customer_state,
    ROUND(
        SUM(op.payment_value) * 1.0 /
        COUNT(DISTINCT o.order_id),
        2
    ) AS Average_Order_Value
FROM Customers c
JOIN Orders o
    ON c.customer_id = o.customer_id
JOIN Order_payments op
    ON o.order_id = op.order_id
GROUP BY c.customer_state
ORDER BY Average_Order_Value DESC;

/* Insights

1.Paraiba (PB) has the highest Average Order Value (USD 264.08), followed by Acre (AC), Rondonia (RO), and Amapa (AP),
indicating that customers in these states spend significantly more per order than the national average.

2.Sao Paulo (SP), despite being the largest revenue-generating state, has the lowest Average Order Value (USD 143.69),
suggesting its strong revenue is driven by high order volume rather than high-value purchases.

Several smaller states consistently record AOVs above USD 200,
presenting opportunities to increase overall revenue by expanding customer acquisition and marketing efforts in these high-spending regions.
*/

--Revenue by Payment Type

SELECT
    payment_type,
    COUNT(*) AS Total_Payments,
    SUM(payment_value) AS Revenue,
    ROUND(
        AVG(payment_value),
        2
    ) AS Average_Payment
FROM Order_payments
GROUP BY payment_type
ORDER BY Revenue DESC;

/* Insights

1.Credit cards are the dominant payment method, accounting for 76,795 transactions and over USD 12.54 million in revenue,
making them the primary driver of sales.

2.Boleto is the second most popular payment option, contributing nearly USD 2.87 million in revenue,
but its average payment (USD 145.03) is lower than credit cards (?163.32).

3.Voucher payments have the lowest average payment value (USD 65.70),
suggesting they are primarily used for smaller purchases or discounted transactions, while debit card usage remains relatively limited.
*/

--Task 7.1 Revenue by Product Category

WITH PaymentSummary AS
(
    SELECT
        order_id,
        SUM(payment_value) AS Revenue
    FROM Order_payments
    GROUP BY order_id
),
ItemCount AS
(
    SELECT
        order_id,
        COUNT(*) AS Total_Items
    FROM Order_items
    GROUP BY order_id)
SELECT
    pct.column2 AS Product_Category,
    COUNT(DISTINCT oi.order_id) AS Total_Orders,
    ROUND(
        SUM(ps.Revenue * 1.0 / ic.Total_Items), 2) AS Revenue
FROM Order_items oi
JOIN Products p
    ON oi.product_id = p.product_id
LEFT JOIN Product_category pct
    ON p.product_category_name = pct.column1
JOIN PaymentSummary ps
    ON oi.order_id = ps.order_id
JOIN ItemCount ic
    ON oi.order_id = ic.order_id
GROUP BY pct.column2
ORDER BY Revenue DESC;

/* Insights

1.Health & Beauty, Watches & Gifts, and Bed Bath & Table are the top three revenue-generating categories,
each contributing over ?1.2 million, making them the core drivers of overall sales.

2.Some categories, such as Bed Bath & Table and Sports & Leisure, generate high revenue primarily through large order volumes,
indicating strong and consistent customer demand.

3.Many niche categories (e.g., Security & Services, Fashion Children's Clothes, CDs/DVDs/Musicals, and Flowers) contribute very little revenue,
suggesting opportunities to optimize inventory, reduce assortment, or focus marketing on higher-performing categories.
*/

--Task 7.2 Top 10 Product Categories by Revenue

WITH PaymentSummary AS
(
    SELECT order_id,
           SUM(payment_value) AS Revenue
    FROM Order_payments
    GROUP BY order_id
),
ItemCount AS
(
    SELECT order_id,
           COUNT(*) AS Total_Items
    FROM Order_items
    GROUP BY order_id
)
SELECT TOP 10
pct.column2 AS Product_category,
ROUND(
SUM(ps.Revenue*1.0/ic.Total_Items),2
) AS Revenue
FROM Order_items oi
JOIN Products p
ON oi.product_id=p.product_id
LEFT JOIN Product_category pct
ON p.product_category_name=pct.column1
JOIN PaymentSummary ps
ON oi.order_id=ps.order_id
JOIN ItemCount ic
ON oi.order_id=ic.order_id
GROUP BY pct.column2
ORDER BY Revenue DESC;

-- Insights
-- Health & Beauty, Watches & Gifts, and Bed Bath & Table are the top three revenue-generating categories,
-- each contributing over ?1.2 million, making them the core drivers of overall sales.

--Task 7.3 Lowest Revenue Categories

SELECT TOP 10
pct.column2 AS Product_category,
SUM(oi.price) AS Revenue
FROM Order_items oi
JOIN Products p
ON oi.product_id=p.product_id
LEFT JOIN Product_category pct
ON p.product_category_name=pct.column1
GROUP BY pct.column2
ORDER BY Revenue;

-- Insights
--.Many niche categories (e.g., Security & Services, Fashion Children's Clothes, CDs/DVDs/Musicals, and Flowers) contribute very little revenue,
-- suggesting opportunities to optimize inventory, reduce assortment, or focus marketing on higher-performing categories.

--Task 7.4 Category Revenue Contribution

WITH CategoryRevenue AS
(
SELECT
pct.column2,
SUM(oi.price) AS Revenue
FROM Order_items oi
JOIN Products p
ON oi.product_id=p.product_id
LEFT JOIN Product_category pct
ON p.product_category_name=pct.column1
GROUP BY pct.column2
)
SELECT
column2 AS Product_category,
Revenue,
ROUND(
Revenue*100.0/SUM(Revenue)OVER()
,2) AS Revenue_Contribution_Percentage
FROM CategoryRevenue
ORDER BY Revenue DESC;

/* Insights

1.The top five product categories—Health & Beauty (9.26%), Watches & Gifts (8.87%), Bed Bath & Table (7.63%), Sports & Leisure (7.27%), and Computers & Accessories (6.71%)
—collectively contribute nearly 40% of total revenue, making them the business's primary revenue drivers.

2.Most remaining product categories each contribute less than 2% of total revenue,
indicating a long-tail product portfolio where a few high-performing categories generate the majority of sales while many niche categories have minimal revenue impact.
*/

--Task 7.5 Ranking Categories

SELECT
pct.column2 AS Product_category,
SUM(oi.price) AS Revenue,
RANK()
OVER(
ORDER BY SUM(oi.price) DESC
) AS Revenue_Rank
FROM Order_items oi
JOIN Products p
ON oi.product_id=p.product_id
LEFT JOIN Product_category pct
ON p.product_category_name=pct.column1
GROUP BY pct.column2
ORDER BY Revenue DESC;



--Task 8.1 Revenue Contribution by State

WITH StateRevenue AS
(
    SELECT
        c.customer_state,
        SUM(op.payment_value) AS Revenue
    FROM Customers c
    JOIN Orders o
        ON c.customer_id = o.customer_id
    JOIN Order_payments op
        ON o.order_id = op.order_id
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    Revenue,
    ROUND(
        Revenue * 100.0 /
        SUM(Revenue) OVER(), 2) AS Revenue_Contribution_Percentage
FROM StateRevenue
ORDER BY Revenue DESC;

/* Insights

1.Sao Paulo (SP) contributes 37.47% of total revenue, making it the single largest market and indicating a strong geographic dependence on one state.

2.The top five states—Sao Paulo (SP), Rio de Janeiro (RJ), Minas Gerais (MG), Rio Grande do Sul (RS), and Parana (PR)
—together contribute approximately 73% of total revenue, showing that sales are heavily concentrated in a few key markets.

3.Most remaining states individually contribute less than 2% of total revenue,
highlighting opportunities to expand market penetration and diversify revenue across underperforming regions.
*/

--Task 8.2 Top 5 Revenue Contributing States

WITH StateRevenue AS
(
    SELECT
        c.customer_state,
        SUM(op.payment_value) AS Revenue
    FROM Customers c
    JOIN Orders o
        ON c.customer_id = o.customer_id
    JOIN Order_payments op
        ON o.order_id = op.order_id
    GROUP BY c.customer_state
)
SELECT TOP 5
    customer_state,
    Revenue,
    ROUND(
        Revenue * 100.0 /SUM(Revenue) OVER(),2) AS Revenue_Contribution_Percentage
FROM StateRevenue
ORDER BY Revenue DESC;

-- Insights

-- The top five states—Sao Paulo (SP), Rio de Janeiro (RJ), Minas Gerais (MG), Rio Grande do Sul (RS), and Parana (PR)
-- —together contribute approximately 73% of total revenue, showing that sales are heavily concentrated in a few key markets.

--Task 8.3 Cumulative Revenue Contribution by State

WITH StateRevenue AS
(
    SELECT
        c.customer_state,
        SUM(op.payment_value) AS Revenue
    FROM Customers c
    JOIN Orders o
        ON c.customer_id = o.customer_id
    JOIN Order_payments op
        ON o.order_id = op.order_id
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    Revenue,
    ROUND(
        Revenue * 100.0 /
        SUM(Revenue) OVER(), 2) AS Revenue_Contribution,
    ROUND(
        SUM(Revenue) OVER( ORDER BY Revenue DESC ROWS UNBOUNDED PRECEDING ) * 100.0/SUM(Revenue) OVER(),
         2) AS Cumulative_Contribution
FROM StateRevenue
ORDER BY Revenue DESC;

-- Insights
-- 1. Top 5 states make upto 73 % of the total revenue
-- 2. Bottom 10 statas make only upto 5.5 % of the total revenue