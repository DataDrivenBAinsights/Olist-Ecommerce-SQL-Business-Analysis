-- Executive Business Dashboard & Cross-Functional Analysis

--Task 1 – Executive KPI Dashboard

/*
SELECT 
   GETDATE() AS Report_Date,
   -- Revneue KPIs
   ROUND(SUM(OP.payment_value),2) AS Total_revenue,
   COUNT(DISTINCT(O.customer_id)) AS Total_customers,
   COUNT(DISTINCT(O.order_id)) AS Total_orders,
   ROUND(SUM(OP.payment_value) *1.0 /
         COUNT(DISTINCT(O.order_id)) ,2 ) AS Avg_order_value,

   -- Marketplace KPIs
   COUNT(DISTINCT(OI.seller_id)) AS Total_sellers,
   COUNT(DISTINCT(OI.product_id)) AS Total_products,

   -- Customer experience KPIs
   AVG(ORs.review_score) AS Avg_review,
   ROUND(AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)),2) AS Avg_delivery_days,
   ROUND(SUM(CASE WHEN O.order_delivered_customer_date <= O.order_estimated_delivery_date
                  THEN 1.0
                  ELSE 0
             END ) * 100.0 / COUNT(O.order_id) ,2) AS On_time_delivery_rate,

   -- Customer retntion KPI
   (SELECT
          ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT(customer_id)) FROM Orders),2) 
    FROM (SELECT customer_id
          FROM Orders
          GROUP BY customer_id
          HAVING COUNT(order_id) > 1 ) AS Repeat_customers) 
          AS Repeat_customer_rate

INTO Executive_KPI_Dashboard

FROM Orders AS O
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
LEFT JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
JOIN Order_items AS OI
ON O.order_id = OI.order_id
WHERE O.order_delivered_customer_date IS NOT NULL;
*/

SELECT * FROM Executive_KPI_Dashboard;


-- Task 2 – Monthly Business Performance

WITH MonthlySummary AS
(
    SELECT
        FORMAT(O.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
        SUM(OP.payment_value) AS Revenue_per_month,
        COUNT(DISTINCT O.order_id) AS Orders_per_month,
        COUNT(DISTINCT O.customer_id) AS Customers_per_month,
        ROUND(AVG(OP.payment_value),2) AS Monthly_AOV,
        ROUND(AVG(ORs.review_score),2) AS Monthly_Review_Score
    FROM Orders O
    JOIN Order_payments OP
        ON O.order_id = OP.order_id
    JOIN Order_reviews ORs
        ON O.order_id = ORs.order_id
    GROUP BY FORMAT(O.order_purchase_timestamp,'yyyy-MM')
)

SELECT
    Sales_Month,
    Revenue_per_month,
    Orders_per_month,
    Customers_per_month,
    Monthly_AOV,
    Monthly_Review_Score,

    ROUND(
        (Revenue_per_month -
         LAG(Revenue_per_month) OVER(ORDER BY Sales_Month))
         * 100.0 /
         LAG(Revenue_per_month) OVER(ORDER BY Sales_Month),
    2) AS Revenue_Growth

FROM MonthlySummary
ORDER BY Sales_Month;

/*Business Recommendations

1. Revenue Growth
   Increase marketing during high-growth months.
   Investigate causes of revenue declines.
   Plan seasonal campaigns based on historical trends.

2. Total Orders
   Run promotions during low-order months.
   Prepare inventory and logistics for peak demand.
   Forecast order volumes for better planning.

3. Total Customers
   Strengthen customer acquisition campaigns.
   Expand high-performing marketing channels.
   Balance new customer acquisition with retention efforts.

4. Average Order Value (AOV)
   Increase AOV through upselling and cross-selling.
   Offer bundle deals and free-shipping thresholds.
   Promote premium products to increase spending.

5. Revenue Growth %
   Replicate strategies from high-growth months.
   Investigate periods of declining growth.
   Set monthly revenue growth targets.

6. Order Growth %
   Align inventory with expected demand.
   Compare order growth with revenue trends.
   Optimize operations for growing order volumes.
*/


-- Task 3 – Sales vs Customer Satisfaction

SELECT 
      FORMAT(O.order_purchase_timestamp,'yyyy-MM') AS Sales_month,
      SUM(OP.payment_value) AS Revenue_per_month,
      COUNT(O.order_id) AS Orders_per_month,
      COUNT(O.customer_id) AS Customers_per_month,
      AVG(OP.payment_value) AS Monthly_AOV,
      AVG(ORs.review_score) AS Monthly_review_score,
      ROUND(AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)),2) AS Avg_delivery_days
FROM Orders AS O
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
GROUP BY FORMAT(O.order_purchase_timestamp,'yyyy-MM')
ORDER BY Sales_month ;
/* Business Recommendations
1. Maintain delivery efficiency during high-sales months to ensure increased order volumes
   do not negatively impact customer satisfaction and review scores.
2. Monitor revenue growth alongside customer experience KPIs (average review score and delivery time)
   to detect operational issues early and prevent declining service quality.
3. Allocate additional logistics and customer support resources during periods of rapid sales growth to sustain fast deliveries,
   improve customer satisfaction, and encourage repeat purchases.
*/


-- Task 4 – Product vs Delivery Performance

SELECT PC.column2 AS Product_category,
       SUM(OP.payment_value) AS Total_revenue,
       ROUND(AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)),2) AS Avg_delivery_days,
       COUNT(O.order_id) AS Total_orders,
       ROUND(SUM(CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date
                  THEN 1.0
                  ELSE 0
             END ) * 100.0 / COUNT(O.order_id) ,2) AS Late_delivery_rate,
       AVG(ORs.review_score) AS Avg_review_score
FROM Orders AS O
JOIN Order_items AS OI
ON O.order_id = OI.order_id
JOIN Products AS P
ON OI.product_id = P.product_id
JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
JOIN Product_category AS PC
ON P.product_category_name = PC.column1 
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
GROUP BY PC.column2 
ORDER BY Total_revenue DESC ;

/* Business Insights
1. High-revenue categories like bed_bath_table and computers_accessories have only 3-star ratings, indicating quality or service issues.
2. Categories with longer delivery times generally receive lower customer ratings.
3. High late delivery rates highlight logistics inefficiencies that can reduce customer satisfaction.

Business Recommendations
1. Improve delivery speed in high-volume categories to enhance customer satisfaction.
2. Strengthen quality control for high-revenue, low-rated categories.
3. Monitor seller and logistics performance to reduce late deliveries and improve customer experience.
*/


--Task 5 – Seller Performance Scorecard

SELECT S.seller_id,
       SUM(OP.payment_value) AS Total_revenue,
       COUNT(O.order_id) AS Total_orders,
       AVG(ORs.review_score) AS Avg_review_score,
       ROUND(AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)),2) AS Avg_delivery_days,
       ROUND(SUM(CASE WHEN O.order_delivered_customer_date <= O.order_estimated_delivery_date
                  THEN 1.0
                  ELSE 0
             END ) * 100.0 / COUNT(O.order_id) ,2) AS On_time_delivery_rate
FROM Orders AS O
JOIN Order_items AS OI
ON O.order_id = OI.order_id
JOIN Sellers AS S
ON OI.seller_id = S.seller_id
JOIN Order_payments AS OP
ON OP.order_id = O.order_id
JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
GROUP BY S.seller_id
ORDER BY Total_revenue DESC ;

/* Business Insights
1. Top sellers generate high revenue (over ₹250K–₹500K) while maintaining high on-time delivery rates (around 90–94%),
   showing that operational excellence supports strong sales.
2. Some high-volume sellers have only 3-star average ratings despite good delivery performance,
   indicating that product quality or customer service—not logistics—may be affecting customer satisfaction.
3. Sellers with long delivery times (15–22 days) and low on-time delivery rates (below 85%)
   are at higher risk of poor customer experience and require operational improvement.

Business Recommendations
1. Reward and retain top-performing sellers with high revenue, strong reviews,
   and excellent on-time delivery through incentives and greater marketplace visibility.
2. Support low-rated sellers with product quality audits, customer service training,
   and performance monitoring to improve customer satisfaction.
3. Reduce delivery times and improve on-time performance by monitoring seller SLAs and optimizing logistics for underperforming sellers.
*/


-- Task 6 – Regional Performance Dashboard

SELECT C.customer_state,
       COUNT(O.order_id) AS Total_orders,
       COUNT(C.customer_id) AS Total_customers,
       COUNT(DISTINCT(S.seller_id)) AS Total_sellers,
       SUM(OP.payment_value) AS Total_revenue,
       AVG(ORs.review_score) AS Avg_review_score,
       ROUND(AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)),2) AS Avg_delivery_days
FROM Customers AS C
JOIN Orders AS O
ON C.customer_id = O.customer_id
JOIN Order_items AS OI
ON O.order_id = OI.order_id
JOIN Sellers AS S
ON OI.seller_id = S.seller_id
JOIN Order_payments AS OP
ON OI.order_id = OP.order_id
JOIN Order_reviews AS ORs
ON OI.order_id = ORs.order_id
GROUP BY C.customer_state
ORDER BY Total_orders DESC ;

/* Business Insights
1. Sao Paulo (SP) is the marketplace's largest market, contributing the highest orders, customers, sellers,
   and revenue, making it the primary revenue driver.
2. Northern and Northeastern states (e.g., RR, AP, AM, AL, PA) have the longest delivery times (20–28 days) 
   and generally lower review scores, indicating logistics challenges.
3. States like MG, PR, and DF achieve 4-star average ratings with relatively faster deliveries (11–12 days),
   demonstrating strong operational performance.

Business Recommendations
1. Reduce dependency on SP by increasing marketing and seller acquisition in high-potential states such as RJ, MG, and PR.
2. Improve logistics in slow-delivery regions by expanding fulfillment centers and partnering with regional carriers to reduce delivery times.
3. Replicate best practices from high-performing states (e.g., MG, PR, DF)
   to improve customer satisfaction and operational efficiency across other regions.
*/


-- Task 7 – Marketplace Health Score

WITH MonthlyRevenue AS
(
    SELECT
        FORMAT(O.order_purchase_timestamp, 'yyyy-MM') AS Sales_Month,
        SUM(OP.payment_value) AS Revenue
    FROM Orders O
    JOIN Order_payments OP
        ON O.order_id = OP.order_id
    GROUP BY FORMAT(O.order_purchase_timestamp, 'yyyy-MM')
),
RevenueGrowth AS
(
    SELECT
        Sales_Month,
        Revenue,
        ROUND((Revenue - LAG(Revenue) OVER(ORDER BY Sales_Month))* 100.0 /
            LAG(Revenue) OVER(ORDER BY Sales_Month), 2) AS Revenue_Growth
    FROM MonthlyRevenue
),

SellerPerformance AS
(
    SELECT
        ROUND(AVG(Seller_On_Time_Rate),2) AS Seller_Performance
    FROM
    (
        SELECT
            OI.seller_id,
            SUM(CASE
                    WHEN O.order_delivered_customer_date <= O.order_estimated_delivery_date
                    THEN 1.0
                    ELSE 0
                END) * 100.0 / COUNT(*) AS Seller_On_Time_Rate
        FROM Orders O
        JOIN Order_items OI
            ON O.order_id = OI.order_id
        WHERE O.order_status = 'delivered'
        GROUP BY OI.seller_id
    ) S
),

MarketplaceScore AS
(
    SELECT
        RG.Sales_Month,
        RG.Revenue_Growth,
        ROUND(AVG(ORV.review_score),2) AS Avg_Review_Score,
        ROUND(
            SUM(CASE
                    WHEN O.order_delivered_customer_date <= O.order_estimated_delivery_date
                    THEN 1.0
                    ELSE 0
                END) * 100.0 / COUNT(*),2) AS On_Time_Delivery_Rate,
           SP.Seller_Performance,
       ROUND((
                CASE
                    WHEN RG.Revenue_Growth IS NULL THEN 0
                    WHEN RG.Revenue_Growth < 0 THEN 0
                    WHEN RG.Revenue_Growth > 100 THEN 100
                    ELSE RG.Revenue_Growth
                END
            ) * 0.30
            +
            ((AVG(ORV.review_score) / 5.0) * 100) * 0.30
            +
            (
                SUM(CASE
                        WHEN O.order_delivered_customer_date <= O.order_estimated_delivery_date
                        THEN 1.0
                        ELSE 0
                    END)
                * 100.0 / COUNT(*)) * 0.20
            +
            SP.Seller_Performance * 0.20 ,2) AS Marketplace_Health_Score

    FROM Orders O
    JOIN Order_reviews ORV
        ON O.order_id = ORV.order_id
    JOIN RevenueGrowth RG
        ON FORMAT(O.order_purchase_timestamp, 'yyyy-MM') = RG.Sales_Month
    CROSS JOIN SellerPerformance SP
    WHERE O.order_delivered_customer_date IS NOT NULL
    GROUP BY
        RG.Sales_Month,
        RG.Revenue_Growth,
        SP.Seller_Performance
)

SELECT
    Sales_Month,
    Revenue_Growth,
    Avg_Review_Score,
    On_Time_Delivery_Rate,
    Seller_Performance,
    Marketplace_Health_Score,

    CASE
        WHEN Marketplace_Health_Score >= 90 THEN 'Excellent'
        WHEN Marketplace_Health_Score >= 75 THEN 'Good'
        WHEN Marketplace_Health_Score >= 60 THEN 'Average'
        ELSE 'Needs Improvement'
    END AS Marketplace_Health

FROM MarketplaceScore
ORDER BY Sales_Month;

/* Business Insights
1. Marketplace health was strongest during early 2017, reaching Excellent status due to exceptional revenue growth
   while maintaining high customer satisfaction and delivery performance.
2. From mid-2017 onward, the marketplace health declined to mostly Average, driven by slowing or 
   negative revenue growth despite consistently strong on-time delivery (around 90–99%).
3. In early 2018, the marketplace entered the "Needs Improvement" category, 
   as lower review scores and declining revenue growth outweighed stable seller performance.

Business Recommendations
1. Focus on sustainable revenue growth through targeted marketing campaigns, 
   customer retention programs, and expansion into high-potential markets.
2. Improve customer satisfaction by addressing the causes of lower review scores through better product quality, 
   seller performance monitoring, and customer support.
3. Maintain strong delivery and seller performance while prioritizing sales growth initiatives, 
   as operational performance is already stable and no longer the primary constraint on marketplace health.
*/


-- Task 8 – Business Risks & Opportunities

-- Task 8.1 Revenue Concentration
SELECT
    C.customer_state,
    ROUND(SUM(OP.payment_value),2) AS Total_Revenue,
    ROUND(
        SUM(OP.payment_value) * 100.0 /
        (SELECT SUM(payment_value) FROM Order_payments),
    2) AS Revenue_Share_Percentage
FROM Orders O
JOIN Customers C
    ON O.customer_id = C.customer_id
JOIN Order_payments OP
    ON O.order_id = OP.order_id
GROUP BY C.customer_state
ORDER BY Total_Revenue DESC;

-- Task 8.2 Low Performing Sellers
SELECT
    OI.seller_id,
    COUNT(DISTINCT O.order_id) AS Total_Orders,
    ROUND(AVG(ORV.review_score),2) AS Avg_Review,
    ROUND(
        SUM(CASE
                WHEN O.order_delivered_customer_date >
                     O.order_estimated_delivery_date
                THEN 1.0
                ELSE 0
            END)*100.0/COUNT(*), 2) AS Late_Delivery_Rate

FROM Orders O
JOIN Order_items OI
    ON O.order_id = OI.order_id
JOIN Order_reviews ORV
    ON O.order_id = ORV.order_id
WHERE O.order_status='delivered'
GROUP BY OI.seller_id
HAVING COUNT(*) >= 20
ORDER BY
Late_Delivery_Rate DESC,
Avg_Review ASC;

-- Task 8.3 Slow Moving categories
SELECT
    PC.column2 AS Product_category,
    COUNT(DISTINCT P.product_id) AS Products,
    COUNT(OI.order_id) AS Units_Sold,
    ROUND(
        COUNT(OI.order_id) * 1.0 /
        COUNT(DISTINCT P.product_id),
    2) AS Sales_Per_Product
FROM Products P
JOIN Product_category AS PC
    ON P.product_category_name = PC.column1
LEFT JOIN Order_items OI
    ON P.product_id = OI.product_id
GROUP BY PC.column2
HAVING COUNT(DISTINCT P.product_id) >= 20
ORDER BY Sales_Per_Product;


-- Task 8.4 High Delay regions
SELECT
    C.customer_state,

    ROUND(
        AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)),2) AS Avg_Delivery_Days,
    ROUND(
        SUM(CASE
                WHEN O.order_delivered_customer_date >
                     O.order_estimated_delivery_date
                THEN 1.0
                ELSE 0
            END) *100.0/COUNT(*),2) AS Late_Delivery_Rate
FROM Orders O
JOIN Customers C
    ON O.customer_id = C.customer_id
WHERE O.order_status='delivered'
GROUP BY C.customer_state
ORDER BY Late_Delivery_Rate DESC;


-- Task 8.5 Poor rated products
SELECT
    PC.column2 AS Product_category,
    ROUND(AVG(ORV.review_score),2) AS Avg_Review,
    COUNT(*) AS Total_Reviews
FROM Order_reviews ORV
JOIN Orders O
    ON ORV.order_id = O.order_id
JOIN Order_items OI
    ON O.order_id = OI.order_id
JOIN Products P
    ON OI.product_id = P.product_id
JOIN Product_category AS PC
    ON P.product_category_name = PC.column1
GROUP BY PC.column2
HAVING COUNT(*) >= 20
ORDER BY Avg_Review;

/*  Summary Table

         Task	                           Business Risk	                                     Growth Opportunity
1. Revenue Concentration	       Heavy dependence on a few states                    Expand into underperforming states
2. Low-Performing Sellers	       Late deliveries and poor customer experience	       Train, monitor, or replace weak sellers
3. Slow-Moving Categories	       Excess inventory and low inventory turnover	       Promote, bundle, or rationalize product assortment
4. High-Delay Regions	           Poor logistics and higher cancellation risk	       Improve shipping networks and regional fulfillment
5. Poorly Rated Products	       Reduced customer trust and repeat purchases	       Improve product quality, listings, and supplier standards
*/


/* Task 9
   Summary Tables
Product KPIs
Best Category
Highest Revenue Category
Seller KPIs
Top Seller
Average Seller Revenue
*/

SELECT
    'Best Category' AS KPI,
    PC.column2 AS Category,
    COUNT(OI.order_id) AS Metric
FROM Order_items AS OI
JOIN Products AS P
    ON OI.product_id = P.product_id
JOIN Product_category AS PC
    ON P.product_category_name = PC.column1
GROUP BY PC.column2

HAVING COUNT(OI.order_id) =
(
    SELECT TOP 1 COUNT(OI2.order_id)
    FROM Order_items OI2
    JOIN Products P2
        ON OI2.product_id = P2.product_id
    JOIN Product_category PC2
        ON P2.product_category_name = PC2.column1
    GROUP BY PC2.column2
    ORDER BY COUNT(OI2.order_id) DESC
)

UNION ALL

SELECT
    'Highest Revenue Category',
    PC.column2 AS Product_category,
    ROUND(SUM(OP.payment_value),2)
FROM Orders O
JOIN Order_items OI
    ON O.order_id = OI.order_id
JOIN Order_payments OP
    ON O.order_id = OP.order_id
JOIN Products P
    ON OI.product_id = P.product_id
JOIN Product_category PC
    ON P.product_category_name = PC.column1
GROUP BY PC.column2

HAVING SUM(OP.payment_value) =
(
    SELECT TOP 1 SUM(OP2.payment_value)
    FROM Orders O2
    JOIN Order_items OI2
        ON O2.order_id = OI2.order_id
    JOIN Order_payments OP2
        ON O2.order_id = OP2.order_id
    JOIN Products P2
        ON OI2.product_id = P2.product_id
    JOIN Product_category PC2
        ON P2.product_category_name = PC2.column1
    GROUP BY PC2.column2
    ORDER BY SUM(OP2.payment_value) DESC
)

UNION ALL

SELECT
    'Top Seller',
    OI.seller_id,
    ROUND(SUM(OP.payment_value),2)
FROM Orders O
JOIN Order_items OI
    ON O.order_id = OI.order_id
JOIN Order_payments OP
    ON O.order_id = OP.order_id
GROUP BY OI.seller_id

HAVING SUM(OP.payment_value) =
(
    SELECT TOP 1 SUM(OP2.payment_value)
    FROM Orders O2
    JOIN Order_items OI2
        ON O2.order_id = OI2.order_id
    JOIN Order_payments OP2
        ON O2.order_id = OP2.order_id
    GROUP BY OI2.seller_id
    ORDER BY SUM(OP2.payment_value) DESC
)

UNION ALL

SELECT
    'Average Seller Revenue',
    'All Sellers',
    ROUND(AVG(Seller_Revenue),2)
FROM
(
    SELECT
        OI.seller_id,
        SUM(OP.payment_value) AS Seller_Revenue
    FROM Orders O
    JOIN Order_items OI
        ON O.order_id = OI.order_id
    JOIN Order_payments OP
        ON O.order_id = OP.order_id
    GROUP BY OI.seller_id
) S;


/* Task 10 – Strategic Business Recommendations

1. Revenue Growth
   Expand high-performing categories.
   Increase repeat customer purchases.
   Promote high-value products.

2. Customer Experience
   Reduce delivery delays.
   Improve communication and order tracking.
   Increase customer retention initiatives.

3. Seller Management
   Reward top-performing sellers.
   Support or remove consistently underperforming sellers.

4. Operations
   Optimize logistics networks.
   Reduce freight costs.
   Improve inventory planning.

5. Marketplace Expansion
   Increase seller coverage in underserved regions.
   Diversify revenue sources to reduce concentration risk.
     Monitor executive KPIs through interactive dashboards.*/