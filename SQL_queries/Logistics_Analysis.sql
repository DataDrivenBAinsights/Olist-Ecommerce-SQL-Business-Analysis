-- Day 8 – Delivery & Logistics Analysis

-- Task 1 – Delivery Performance Overview

SELECT 
      AVG(DATEDIFF(DAY,order_purchase_timestamp,order_delivered_customer_date)) AS Avg_delivery_date,
      MIN(DATEDIFF(DAY,order_purchase_timestamp,order_delivered_customer_date)) AS Min_delivery_date,
      MAX(DATEDIFF(DAY,order_purchase_timestamp,order_delivered_customer_date)) AS Max_delivery_date
FROM Orders
WHERE order_delivered_customer_date IS NOT NULL;

/* Insights
1. Average delivery days taken to deliver an order is 12 days.
2. Minimum delivery days taken to deliver an order is 0 days( delivered on the same day)
3. Maximum delivery days taken to deliver an order is 210 days.

-- Business Recommendations
1. Set internal delivery benchmarks based on average delivery performance.
2. Investigate orders with exceptionally long delivery times to identify operational bottlenecks.
3. Monitor delivery performance regularly to ensure service level agreements (SLAs) are consistently met.
4. Use historical delivery data to improve future delivery time estimates.
*/


-- Task 2 – On-Time vs Late Deliveries

-- Task 2.1 How many orders were delivered on time?
SELECT COUNT(*) AS On_time_deliveries,
       (COUNT(*) *100/
       (SELECT COUNT(*) 
       FROM Orders
       WHERE order_delivered_customer_date IS NOT NULL)) AS On_time_delivery_percentage
FROM Orders
WHERE order_delivered_customer_date < order_estimated_delivery_date AND
      order_delivered_customer_date IS NOT NULL;

-- Insights 
-- Total on time deliveries -88649(91%)

-- Task 2.2 How many were delivered late?
SELECT COUNT(*) AS Late_deliveries,
       (COUNT(*) *100/
       (SELECT COUNT(*) 
       FROM Orders
       WHERE order_delivered_customer_date IS NOT NULL)) AS Late_delivery_percentage
FROM Orders
WHERE order_delivered_customer_date > order_estimated_delivery_date AND
      order_delivered_customer_date IS NOT NULL;

-- Insights
-- Total late deliveries - 7827(8%)

/* Business Recommendations
1. Improve coordination with logistics partners to reduce late deliveries.
2. Review estimated delivery dates to ensure they are realistic and achievable.
3. Prioritize orders at risk of delay through automated monitoring systems.
4. Introduce KPIs and incentives focused on maintaining high on-time delivery rates.
*/


-- Task 3 – Delivery Time by State

SELECT C.customer_state,
       AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)) AS Avg_delivery_date
FROM Customers AS C
JOIN Orders AS O
ON C.customer_id = O.customer_id
GROUP BY C.customer_state
ORDER BY Avg_delivery_date ; 
/* Insights
1. Sao Paulo (SP) has the shortest average delivery time at 8 days, followed by Parana (PR) and Minas Gerais (MG) at 11 days.
2. Roraima (RR) has the longest average delivery time at 29 days, followed by Amapá (AP) at 27 days and Amazonas (AM) at 26 days.

Business Recomendations
1. Replicate the logistics strategies used in these high-performing states and 
   consider placing additional fulfillment centers near regions with longer delivery times.
2. Improve last-mile delivery by partnering with regional logistics providers, establishing local warehouses, 
   or adjusting estimated delivery dates to better match actual delivery performance and improve customer satisfaction.
*/


-- Task 4 – Seller Delivery Performance

-- Task 4.1 Which sellers consistently deliver quickly?
SELECT S.seller_id,
       AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)) AS Avg_delivery_days
FROM Orders AS O
JOIN Order_items AS OI
ON O.order_id = OI.order_id
JOIN Sellers AS S
ON OI.seller_id = S.seller_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY S.seller_id
ORDER BY Avg_delivery_days;

-- Task 4.2 Which sellers frequently miss delivery estimates?
SELECT S.seller_id,
       COUNT(O.order_id) AS Total_orders,
       SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
             THEN 1
             ELSE 0
           END) AS Late_orders,
       ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
             THEN 1.0
             ELSE 0
           END) * 100.0 / COUNT(O.order_id) ,2 ) AS Late_order_rate,
       AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)) AS Avg_delivery_days
FROM Orders AS O
JOIN Order_items AS OI
ON O.order_id = OI.order_id
JOIN Sellers AS S
ON OI.seller_id = S.seller_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY S.seller_id
HAVING COUNT(O.order_id) >= 20
ORDER BY Late_order_rate DESC;

/* Business Recommendations
1. Recognize and promote sellers with consistently fast deliveries.
2. Provide operational training to sellers with poor delivery performance.
3. Monitor seller-specific delivery KPIs and establish minimum performance standards.
4. Encourage sellers to maintain adequate inventory levels to reduce dispatch delays.
*/


-- Task 5 – Order Processing Time

SELECT AVG(DATEDIFF(DAY ,order_purchase_timestamp,order_approved_at)) AS Avg_approval_time,
       AVG(DATEDIFF(DAY,order_approved_at, order_delivered_carrier_date)) AS Avg_carrier_delivery_time
FROM ORDERS;

-- Average approval time for an order is 0 days.
-- Average carrier delivery time for an order is 2 days.

/* Business Recommendations
1. Automate payment verification where possible to reduce approval time.
2. Reduce warehouse processing time through better inventory management.
3. Monitor carrier pickup schedules to minimize delays after order approval.
4. Identify operational bottlenecks causing slow order processing and address them proactively.
*/


-- Task 6 – Logistics Cost Analysis

SELECT PC.column2 AS Product_category,
       AVG(OI.freight_value) AS Avg_freight_cost,
       ROUND(AVG(OI.freight_value * 100 / OI.price) ,2) AS Avg_freight_perc_of_price,
       AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)) AS Avg_delivery_time
FROM Order_items AS OI
JOIN Orders AS O
ON OI.order_id = O.order_id
JOIN Products AS P
ON OI.product_id = P.product_id
JOIN Product_category AS PC
ON P.product_category_name = PC.column1
GROUP BY PC.column2 
ORDER BY Avg_freight_cost DESC ;

/* Insights
1. Categories such as Computers ($48.45), Home Appliances 2 ($44.54), Furniture Mattress & Upholstery ($42.91),
and Kitchen/Dining/Laundry Furniture ($42.70) have the highest average freight costs.

2. Several categories have freight costs that account for a large share of the product price:
   Home Comfort 2: 93.39%
   DVDs & Blu-ray: 83.30%
   Electronics: 68.35%
   Christmas Supplies: 67.57%
   Flowers: 56.50%

3. Some categories with high freight costs still achieve relatively fast deliveries:
   Small Appliances (Home Oven & Coffee): Freight $36.16, Delivery 9 days
   Construction Tools Lights: Freight $24.95, Delivery 9 days
   Kitchen/Dining/Laundry Furniture: Freight $42.70, Delivery 11 days

-- Business Recommendations

1. Negotiate shipping contracts for bulky items, optimize packaging, and establish regional warehouses to reduce transportation costs.
2. Bundle these products, introduce minimum order values for free shipping, or review pricing strategies to better absorb freight costs.
3. Focus on improving warehouse placement and seller fulfillment processes for slow-moving categories rather than simply increasing shipping spend.
*/


--Task 7 – Delivery vs Customer Satisfaction

SELECT ORs.review_score,
       COUNT(O.order_id) AS Total_orders,
       AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)) AS Avg_delivery_time,
       ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date 
             THEN 1.0
             ELSE 0
           END) * 100.0 / COUNT(O.order_id) ,2 ) AS Late_order_rate
FROM Orders AS O
JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
GROUP BY ORs.review_score
ORDER BY Avg_delivery_time;

/* Insights

1.Higher review scores are strongly associated with better delivery performance. 
  Orders with 5-star reviews have the shortest average delivery time (10 days) and the lowest late delivery rate (2.98%),
  while 1-star reviews average 21 days with a 31.11% late delivery rate.

2. Delivery delays have a major impact on customer satisfaction. As the average delivery time increases from 10 to 21 days, 
   the average review score steadily declines from 5 stars to 1 star, indicating delivery speed is a key driver of ratings.

-- Business Recommendations
1. Improve delivery speed and reliability.
   Since longer delivery times are closely linked to lower review scores, optimize logistics, strengthen carrier partnerships, and improve inventory placement to reduce delivery delays.

2. Focus on reducing late deliveries.
   Prioritize regions, sellers, or shipping partners with high late-delivery rates.
   Even a modest reduction in delays can significantly improve customer satisfaction and ratings.

3. Replicate best-performing operations. 
   Analyze the fulfillment practices of orders receiving 5-star reviews (10-day delivery, 2.98% late rate) and
   apply those best practices across lower-performing sellers and regions to improve the overall customer experience.
*/


-- Task 8 – Cancellation & Delivery Analysis

-- Task 8.1 What percentage of delivered orders were delayed?
SELECT CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date  
            THEN 'Delayed'
            ELSE 'On Time'
            END AS Delivery_status,
        COUNT(*) AS Total_orders,
        ROUND( COUNT(*) * 100/
               SUM(COUNT(*)) OVER() ,2 ) AS Prcentage
FROM Orders
WHERE order_status = 'delivered'
GROUP BY CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date  
            THEN 'Delayed'
            ELSE 'On Time'
            END ;

-- Task 8.2 Which order statuses are most common among delayed shipments?
SELECT COUNT(*) AS Total_orders ,
       order_status
FROM Orders
WHERE order_delivered_customer_date > order_estimated_delivery_date  
GROUP BY order_status;

-- There are 7286 Delivered orders and 1 Cancelled order in delayed orders.

/* Business Recommendations
1. Identify orders at high risk of cancellation and intervene before shipment.
2. Improve stock availability to prevent fulfillment delays.
3. Communicate expected delays proactively to reduce cancellation rates.
4. Review cancellation trends by region and seller to identify recurring operational issues.
*/



