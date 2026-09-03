-- Seller Performance Analysis

-- Task 1 – Seller Overview

-- Task 1.1 How many active sellers are there?
SELECT COUNT(DISTINCT(seller_id)) AS Total_sellers
FROM Sellers;

-- Number of total sellers is - 3095

-- Task 1.2 How many sellers have completed at least one sale?
WITH SellerCount AS
(
SELECT S.seller_id,
       COUNT(OI.order_id) AS Total_orders
FROM Sellers AS S
JOIN Order_items AS OI 
ON S.seller_id = OI.seller_id
GROUP BY S.seller_id)

SELECT COUNT(seller_id) AS Seller_with_orders
FROM SellerCount
WHERE Total_orders >= 1;

-- All sellers have completed at least 1 order

-- Task 1.3 How many sellers have never sold a product?
WITH SellerCount AS
(
SELECT S.seller_id,
       COUNT(OI.order_id) AS Total_orders
FROM Sellers AS S
JOIN Order_items AS OI 
ON S.seller_id = OI.seller_id
GROUP BY S.seller_id)

SELECT COUNT(seller_id) AS Seller_with_no_orders
FROM SellerCount
WHERE Total_orders = 0;

-- There is no seller who have never sold a product
/* Business Recommendations
1. Re-engage inactive sellers through onboarding campaigns or promotional incentives.
2. Monitor seller activity regularly and remove sellers that remain inactive for extended periods.
3. Recruit additional sellers in product categories with limited competition.
4. Ensure a balanced seller base across different regions to improve product availability.
*/

-- Task 2 – Top Performing Sellers

-- Task 2.1 Which sellers generate the highest revenue?
SELECT S.seller_id,
       COUNT(OI.order_id) AS Total_orders,
       COUNT(DISTINCT(P.product_id)) AS Total_products,
       SUM(OI.price) AS Total_revenue,
       AVG(OI.price) AS Avg_price_per_order
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
JOIN Products AS P
ON P.product_id = OI.product_id
GROUP BY S.seller_id
ORDER BY Total_revenue DESC; 


/* Business Recommendations
1. Increase Average Revenue per Order (ARPO) for high-volume sellers through bundles, upselling, and cross-selling.
2. Promote high-value sellers with premium products to attract more traffic and increase overall marketplace revenue.
3. Analyze the practices of top-performing balanced sellers and replicate successful strategies across other sellers to improve marketplace performance.
*/


-- Task 3 – Seller Performance Ranking

-- Task 3.1 Seller ranked on the basis of revenue
SELECT S.seller_id,
       SUM(OI.price) AS Total_revenue,
       RANK() OVER (ORDER BY SUM(OI.price)  DESC) AS Revenue_rank,
       DENSE_RANK() OVER(ORDER BY SUM(OI.price) DESC) AS Revenue_dense_rank
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
GROUP BY S.seller_id;

-- Task 3.2 Sellers ranked on the basis of orders
SELECT S.seller_id,
       COUNT(OI.order_id) AS Total_orders,
       RANK() OVER (ORDER BY COUNT(OI.order_id)  DESC) AS Order_rank,
       DENSE_RANK() OVER(ORDER BY COUNT(OI.order_id) DESC) AS Order_dense_rank
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
GROUP BY S.seller_id;

-- Task 3.3 Sellers ranked on the basis of products sold
SELECT S.seller_id,
       COUNT(DISTINCT(OI.product_id)) AS Total_products,
       RANK() OVER (ORDER BY COUNT(DISTINCT(OI.product_id)) DESC) AS Products_rank,
       DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT(OI.product_id)) DESC) AS Products_dense_rank
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
GROUP BY S.seller_id;

/* Business Recommendations
1. Develop a seller scorecard combining revenue, customer satisfaction, and delivery performance.
2. Recognize top-ranked sellers through badges or certification programs.
3. Use rankings to identify sellers eligible for incentive programs.
4. Encourage healthy competition by publishing performance benchmarks.
*/

-- Task 4 – Seller Geographic Analysis

-- Task 4.1 Sellers by state
SELECT seller_state,
       COUNT(seller_id) AS Total_sellers
FROM Sellers
GROUP BY seller_state
ORDER BY total_sellers DESC;

/* Insights 
1.Sellers Are Highly Concentrated in the Southeast Region
The seller network is heavily concentrated in a few states, particularly Sao Paulo (SP).
SP alone has 1,849 sellers, accounting for 60% of all sellers (1,849 out of 3,095).
The next largest states are PR (349), MG (244), SC (190), and RJ (171), but each has far fewer sellers than SP.

2. Several states have fewer than 10 sellers, including:
PE (9), PB (6), MS (5), RN (5), MT (4), RO (2), SE (2)

-- Business Recommendation
1. Reduce dependency on São Paulo by encouraging seller acquisition in underrepresented states.
2. Launch regional seller onboarding programs and incentives in low-representation states to build a more balanced and resilient seller network.
*/

-- Task 4.2 Revenue by seller state
SELECT S.seller_state,
       SUM(OI.price) AS Total_revenue
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
GROUP BY S.seller_state
ORDER BY Total_revenue DESC;

/* Insights
1. Sao Paulo (SP) dominates seller revenue with USD 8.75M, while PR, MG, RJ, and SC are the next major contributors.
The marketplace depends heavily on these top-performing states.

2. Low-Revenue States Offer Growth Potential.States such as AC, AM, PA, SE, and PI contribute minimal revenue,
indicating opportunities to expand seller participation, improve logistics, and increase regional demand.

Business Recommendation
1. Continue investing in high-performing states such as SP, PR, and MG to protect the core revenue base.
2. Develop targeted expansion strategies for low-revenue states through seller incentives, localized marketing campaigns,
   and improved delivery infrastructure to create a more geographically balanced marketplac
*/

-- Task 4.3 Average revenue per seller
SELECT 
      SUM(price) * 1.0 / COUNT(DISTINCT(seller_id)) AS Avg_revenue_per_order
FROM Order_items;

-- Average revenue per seller - USD 4391 


-- Task 5 – Seller Delivery Performance

-- Task 5.1 Which sellers deliver the fastest?
SELECT S.seller_id,
       AVG(DATEDIFF(DAY, O.order_purchase_timestamp , O.order_delivered_customer_date)) AS Avg_delivery_time
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
JOIN Orders AS O
ON OI.order_id = O.order_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY S.seller_id
ORDER BY Avg_delivery_time ASC;

-- Task 5.2 Which sellers experience the most delays?
SELECT S.seller_id,
       COUNT(O.order_id) AS Delayed_orders
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
JOIN Orders AS O
ON OI.order_id = O.order_id
WHERE O.order_delivered_customer_date > O.order_estimated_delivery_date AND
      O.order_delivered_customer_date IS NOT NULL
GROUP BY S.seller_id
ORDER BY Delayed_orders DESC;

-- Late delivery percentage by sellers
SELECT S.seller_id,
       COUNT(DISTINCT(O.order_id)) AS Total_orders,
       COUNT(DISTINCT CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date
                 THEN O.order_id
            END) AS Late_deliveries,
       ROUND(
             COUNT(DISTINCT CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date
                            THEN O.order_id
            END) * 100.0 / COUNT(DISTINCT(O.order_id)), 2 ) AS Late_delivery_percentage
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
JOIN Orders AS O
ON OI.order_id = O.order_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY S.seller_id
ORDER BY Late_delivery_percentage DESC;

-- On time delivery % by sellers
SELECT S.seller_id,
       COUNT(DISTINCT(O.order_id)) AS Total_orders,
       COUNT(DISTINCT CASE WHEN O.order_delivered_customer_date < O.order_estimated_delivery_date
                 THEN O.order_id
            END) AS On_time_deliveries,
       ROUND(
             COUNT(DISTINCT CASE WHEN O.order_delivered_customer_date < O.order_estimated_delivery_date
                            THEN O.order_id
            END) * 100.0 / COUNT(DISTINCT(O.order_id)), 2 ) AS On_time_delivery_percentage
FROM Sellers AS S
JOIN Order_items AS OI
ON S.seller_id = OI.seller_id
JOIN Orders AS O
ON OI.order_id = O.order_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY S.seller_id
ORDER BY On_time_delivery_percentage DESC;

/* Business Recommendations
1. Highlight fast-delivery sellers to customers with special labels.
2. Work with slow-performing sellers to improve inventory and shipping processes.
3. Set delivery performance targets and monitor compliance.
4. Collaborate with logistics partners to reduce delivery delays.
*/


-- Task 6 – Seller Customer Satisfaction

-- Task 6.1 Which sellers receive the highest review scores?
SELECT OI.seller_id,
       COUNT(ORs.review_id) AS Total_reviews,
       AVG(ORs.review_score) AS Avg_review
FROM Order_items AS OI
JOIN Order_reviews AS ORs
ON OI.order_id = ORs.order_id
GROUP BY OI.seller_id
ORDER BY Avg_review DESC;

-- Insights
-- Most sellers that have 5 star reviews have less orders

-- Task 6.2 Which sellers have the lowest ratings?
SELECT OI.seller_id,
       AVG(ORs.review_score) AS Avg_review
FROM Order_items AS OI
JOIN Order_reviews AS ORs
ON OI.order_id = ORs.order_id
GROUP BY OI.seller_id
ORDER BY Avg_review ASC;

/* Business Recommendations
1. Reward sellers with consistently high customer ratings.
2. Investigate recurring complaints for low-rated sellers.
3. Provide customer service and quality training to underperforming sellers.
4. Monitor review trends to identify emerging quality issues.
*/


--Task 7 – High Revenue vs High Ratings

-- Task 7.1 Do top-selling sellers also receive the best ratings?
SELECT OI.seller_id,
       SUM(OI.price) AS Total_revenue,
       AVG(ORs.review_score) AS Avg_review
FROM Order_items AS OI
JOIN Order_reviews AS ORs
ON OI.order_id = ORs.order_id
GROUP BY OI.seller_id
ORDER BY Total_revenue DESC ;

-- Insights
-- Most of the top selling sellers recieves ratings of 4 star,
-- with some recieving 3 star rating

-- Task 7.2 Are there sellers with high revenue but poor customer satisfaction?
WITH SellerReviews AS (
SELECT OI.seller_id,
       SUM(OI.price) AS Total_revenue,
       AVG(ORs.review_score) AS Avg_review
FROM Order_items AS OI
JOIN Order_reviews AS ORs
ON OI.order_id = ORs.order_id
GROUP BY OI.seller_id)

SELECT * 
FROM SellerReviews
WHERE Avg_review < 3
ORDER BY Total_revenue DESC ;

-- There are not many selllers that have high revenue but poor customer satisfaction

/* Business Recommendations
1. Prioritize improvements for sellers with high revenue but low ratings to reduce the risk of customer churn.
2. Showcase sellers who perform well in both sales and customer satisfaction.
3. Introduce seller quality metrics into performance evaluations.
4. Balance revenue growth initiatives with customer experience improvements.
*/


--Task 8 – Seller Contribution Analysis

WITH SellerRevenue AS (
SELECT seller_id,
       SUM(price) AS Revenue_seller
FROM Order_items
GROUP BY seller_id )

SELECT 
      seller_id,
      Revenue_seller,
      ROUND(Revenue_seller * 100 / SUM(Revenue_seller) OVER() ,2 ) AS Revenue_seller_percentage,
      ROUND(SUM(Revenue_seller) OVER(ORDER BY Revenue_seller DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)* 100 
            / SUM(Revenue_seller) OVER() ,2 )  AS Cumulative_revenue_seller_perc
FROM SellerRevenue
ORDER BY Revenue_seller DESC;

-- Insights
-- No seller generate a huge percentage of revenue indiveidually
-- The top seller only generate 1.7% of the total revenue
-- The contribution of top 10 sellers - 13.15%

/* Business Recommendations
1. Continue supporting top-performing sellers while reducing dependence on a small group.
2. Help mid-tier sellers improve performance through targeted development programs.
3. Diversify the seller base to reduce operational and revenue concentration risk.
4. Monitor seller contribution trends regularly to identify changes in marketplace dynamics.
*/


-- Task 9 – Low Performing Sellers

WITH LowSellers AS(
SELECT OI.seller_id,
       COUNT(OI.order_id) AS Total_orders,
       SUM(OI.price) AS Total_revenue,
       AVG(ORs.review_score) AS Avg_review,
       AVG(DATEDIFF(DAY,O.order_purchase_timestamp, O.order_delivered_customer_date)) AS Delivery_time
FROM Order_items AS OI
JOIN Orders AS O
ON OI.order_id = O.order_id
JOIN Order_reviews AS ORs
ON OI.order_id = ORs.order_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY OI.seller_id)

SELECT *
FROM LowSellers
WHERE Total_orders < 300 
      AND Total_revenue < 10000 
      AND Avg_review < 3 
      AND Delivery_time > 20
ORDER BY Total_revenue DESC;

/* Business Recommendations
1. Provide performance improvement plans for struggling sellers.
2. Offer operational training on inventory management and fulfillment.
3. Review product quality and pricing strategies for underperforming sellers.
4. Remove persistently poor-performing sellers if they fail to meet platform standards.
*/
