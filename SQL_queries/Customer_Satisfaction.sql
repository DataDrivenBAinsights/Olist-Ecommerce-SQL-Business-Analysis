-- Customer Review & Satisfaction Analysis


-- Task 1 – Review Overview

-- Task 1.1 How many reviews were received?
SELECT COUNT(*) AS Total_reviews
FROM Order_reviews;

-- Total number of reviews - 99224

-- Task 1.2 What is the average review score?
SELECT AVG(review_score) AS Avg_review_score
FROM Order_reviews;

-- Average review score - 4

-- Task 1.3 What is the distribution of review scores (1–5)?
SELECT review_score,
       COUNT(order_id) AS Total_orders
FROM Order_reviews
GROUP BY review_score
ORDER BY Total_orders DESC;

-- Approximately 60% of orders recieved 5 review score.
/* Business Recommendations
1. Establish the average review score as a core customer experience KPI.
2. Monitor review trends regularly to identify improvements or declining satisfaction.
3. Set customer satisfaction targets and track performance against them.
4. Use review data alongside sales and operational metrics to understand business health.
*/


-- Task 2 – Review Score Distribution

SELECT review_score,
       COUNT(order_id) AS Total_orders,
       ROUND(COUNT(*) * 100/ SUM(COUNT(*)) OVER() ,2 ) AS Percentage_by_review_score
FROM Order_reviews
GROUP BY review_score
ORDER BY Total_orders DESC;

-- 57% of the reviews were 5 star.
-- 11424 Customers leave 1 review_score.
/* Business Recommendations
1. Analyze the reasons behind low-rating reviews (1–2 stars) and identify recurring issues.
2. Encourage satisfied customers to leave reviews to increase positive feedback volume.
3. Create automated alerts for products or sellers receiving a high number of negative reviews.
4. Use positive reviews in marketing campaigns to build customer trust.
*/


--Task 3 – Delivery Performance vs Review Score

SELECT ORs.review_score,
       AVG(DATEDIFF(DAY,O.order_purchase_timestamp,O.order_delivered_customer_date)) AS Avg_delivery_days,
       COUNT(O.order_id) AS Total_orders,
       COUNT(CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date
                  THEN 1
           END) AS Late_deliveries,
       ROUND(COUNT(CASE WHEN O.order_delivered_customer_date > O.order_estimated_delivery_date
                  THEN 1
           END) * 100 / COUNT(*) ,2) AS Late_deliveries_rate
FROM Orders AS O
JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
WHERE O.order_delivered_customer_date IS NOT NULL
GROUP BY ORs.review_score
ORDER BY ORs.review_score DESC;

-- Yes, Delivery speed affects customer ratings.
-- Longer the delivery period, lower the review score and vice versa.
-- Orders with 1 review score have the highest late delivery rate - 37%
/* Business Recommendations
1. Prioritize improving delivery reliability because delays can directly reduce customer ratings.
2. Provide customers with accurate delivery estimates and real-time tracking.
3. Proactively notify customers about potential delays to reduce frustration.
4. Evaluate logistics partners based on both delivery performance and customer feedback.
*/


-- Task 4 – Product Categories & Customer Ratings

SELECT PC.column2 AS Product_categories,
       AVG(ORs.review_score) AS Avg_review,
       COUNT(ORs.review_id) AS Total_reviews
FROM Order_items AS OI
JOIN Order_reviews AS ORs
ON OI.order_id = ORs.order_id
JOIN Products AS P
ON OI.product_id = P.product_id
JOIN Product_category AS PC
ON P.product_category_name = PC.column1
GROUP BY PC.column2
ORDER BY Avg_review DESC ,
         Total_reviews DESC;

/* Insights
1. Categories like Health & Beauty (9,645 reviews), Sports & Leisure (8,640), Housewares (6,943), and Watches & Gifts (5,950) 
   all maintain an average review score of 4 despite handling thousands of customer reviews.

2. Some of the largest categories have only an average review score of 3, including:
   Bed Bath Table (11,137 reviews)
   Furniture Decor (8,331 reviews)
   Computers Accessories (7,849 reviews)
   Telephony (4,517 reviews).

-- Business Recommendations
1. Promote high-rated categories as reliable product choices.
2. Investigate low-rated categories for product quality, description accuracy, or supplier issues.
3. Improve product descriptions, images, and specifications to reduce customer expectation gaps.
4. Review suppliers contributing to consistently poor-rated products.
*/



-- Task 5 – Seller Ratings

SELECT OI.seller_id,
       AVG(ORs.review_score) AS Avg_review_score,
       COUNT(ORs.review_id) AS Total_reviews,
       RANK() OVER(ORDER BY AVG(ORs.review_score) DESC,
                            COUNT(ORs.review_id) DESC ) AS Seller_rank,
       DENSE_RANK() OVER(ORDER BY AVG(ORs.review_score) DESC,
                            COUNT(ORs.review_id) DESC ) AS Seller_dense_rank
FROM Order_items AS OI
JOIN Order_reviews AS ORs
ON OI.order_id = ORs.order_id
GROUP BY OI.seller_id
ORDER BY Avg_review_score DESC,
         Total_reviews DESC;

/* Insights 
1. Sellers who have recieved review score of 5 have sold very few orders highest sold ordere being 34.
2. Most sellers who have sold large number of orders have recieved review scores between 4 and 3.

-- Business Recommendations
1. Create a seller rating scorecard combining:
   Review score
   Delivery performance
   Cancellation rate
   Order volume
2. Reward highly rated sellers with better visibility on the platform.
3. Provide training and support to sellers with consistently low ratings.
4. Remove or restrict sellers who repeatedly provide poor customer experiences.
*/


-- Task 6 – State-wise Customer Satisfaction

SELECT C.customer_state,
       AVG(ORs.review_score) AS Avg_review_score,
       COUNT(ORs.review_id) AS Total_reviews
FROM Customers AS C
JOIN Orders AS O
ON C.customer_id = O.customer_id
JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
GROUP BY C.customer_state
ORDER BY Avg_review_score DESC,
         Total_reviews DESC;

/* Insights
1. States such as SP, MG, RS, PR, and SC maintain an average review score of 4 despite high review volumes,
   indicating strong and consistent customer satisfaction.

2. States including RJ, BA, CE, PA, and MA have an average review score of 3,
   suggesting lower customer satisfaction and a need to investigate delivery, product quality, or seller performance.

-- Regional Difference
   Yes. Southern and Central states generally have higher average review scores (4), 
   while several Northeastern states and RJ have lower average scores (3), indicating regional differences in customer experience.

-- Business Recommendations
1. Investigate regions with lower ratings to identify local delivery or seller issues.
2. Improve logistics support in areas with poor customer satisfaction.
3. Allocate customer support resources based on regional complaint patterns.
4. Develop region-specific strategies based on customer expectations.
*/


--Task 7 – Payment Method vs Satisfaction

SELECT OP.payment_type,
       AVG(ORs.review_score) AS Avg_review_score,
       COUNT(ORs.review_id) AS Total_reviews
FROM Orders AS O
JOIN Order_reviews AS ORs
ON O.order_id = ORs.order_id
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
GROUP BY OP.payment_type
ORDER BY Avg_review_score DESC;

-- Credit cards(76600 Reviews) and Baleto(19762 Reviews) are the most common payment type and both has Average review score of 4.
-- All payment types has the Average review score of 4 Other than which are not defined,

/* Business Recommendations
1. Ensure all payment methods provide a smooth and reliable checkout experience.
2. Investigate payment methods associated with lower ratings for possible transaction issues.
3. Promote convenient payment options preferred by customers.
4. Reduce payment failures and improve payment confirmation speed.
*/


-- Task 8 – Review Timing Analysis

SELECT ORs.review_score,
       AVG(DATEDIFF(HOUR,O.order_delivered_customer_date,ORs.review_creation_date)) AS Avg_review_time
FROM Orders AS O
JOIN Order_reviews AS ORs
ON O.order_id = ORS.order_id
GROUP BY ORs.review_score
ORDER BY ORs.review_score DESC;

-- Order that recieves high reviews get a review in 3 to 6 hours.
-- Almost all the customers leave a review at the same day.

/* Business Recommendations
1. Encourage customers to provide feedback shortly after receiving products.
2. Send automated review requests after successful delivery.
3. Analyze delayed reviews separately because they may reflect different customer experiences.
4. Use review timing patterns to improve customer engagement strategies.
*/


/*Task 9 – Customer Satisfaction KPI Dashboard
Create a one-row summary table including:
KPI	Description
Average Review Score	Overall customer satisfaction
5-Star Review Rate	Percentage of 5-star reviews
1-Star Review Rate	Percentage of 1-star reviews
Average Delivery Days	Delivery speed
Late Delivery Rate	Percentage of late deliveries
Total Reviews	Number of customer reviews*/


/*Task 10 – Business Recommendations
Prepare recommendations based on all review analyses.
Examples:
Customer Experience
Improve delivery reliability to increase review scores.
Provide proactive communication when delays occur.
Product Quality
Review categories with consistently low ratings.
Improve product descriptions and quality control.
Seller Performance
Recognize highly rated sellers.
Provide coaching for sellers with poor customer feedback.
Operations
Use review data as an operational KPI.
Track review trends monthly to detect emerging issues.*/