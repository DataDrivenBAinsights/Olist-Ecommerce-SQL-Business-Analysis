-- Advanced Business Insights & Segmentation

-- Task 1 – RFM Customer Segmentation

WITH RFM AS
(
SELECT
    C.customer_unique_id,

    DATEDIFF(DAY,MAX(O.order_purchase_timestamp),
             (SELECT MAX(order_purchase_timestamp) FROM Orders)) AS Recency,
    COUNT(DISTINCT O.order_id) AS Frequency,
    SUM(OP.payment_value) AS Monetary
FROM Customers AS C
JOIN Orders AS O
ON C.customer_id = O.customer_id
JOIN Order_payments AS OP
ON O.order_id = OP.order_id
WHERE O.order_status='delivered'
GROUP BY C.customer_unique_id
),

Scores AS
(
SELECT *,
       NTILE(5) OVER(ORDER BY Recency DESC) AS R_Score,
       NTILE(5) OVER(ORDER BY Frequency ASC) AS F_Score,
       NTILE(5) OVER(ORDER BY Monetary ASC) AS M_Score
FROM RFM
)

SELECT *,
CASE
    WHEN R_Score=5 AND F_Score>=4 AND M_Score>=4 THEN 'Champions'
    WHEN R_Score>=4 AND F_Score>=4 THEN 'Loyal Customers'
    WHEN R_Score>=4 AND F_Score>=2 THEN 'Potential Loyalists'
    WHEN R_Score<=2 AND F_Score>=3 THEN 'At Risk'
    WHEN R_Score=1 AND F_Score<=2 THEN 'Lost Customers'
    ELSE 'Others'
END AS Customer_Segment
FROM Scores;

WITH RFM AS
(
    SELECT
        C.customer_unique_id,

        DATEDIFF(
            DAY,
            MAX(O.order_purchase_timestamp),
            (SELECT MAX(order_purchase_timestamp) FROM Orders)
        ) AS Recency,

        COUNT(DISTINCT O.order_id) AS Frequency,

        SUM(OP.payment_value) AS Monetary

    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id

    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id

    WHERE O.order_status = 'delivered'

    GROUP BY C.customer_unique_id
),

Scores AS
(
    SELECT *,
           NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,
           NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
           NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score
    FROM RFM
),

Segmented_Customers AS
(
    SELECT *,
        CASE
            WHEN R_Score = 5 AND F_Score >= 4 AND M_Score >= 4
                THEN 'Champions'
            WHEN R_Score >= 4 AND F_Score >= 4
                THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND F_Score >= 2
                THEN 'Potential Loyalists'
            WHEN R_Score <= 2 AND F_Score >= 3
                THEN 'At Risk'
            WHEN R_Score = 1 AND F_Score <= 2
                THEN 'Lost Customers'
            ELSE 'Others'
        END AS Customer_Segment

    FROM Scores
)

SELECT
    Customer_Segment,
    COUNT(*) AS Customer_Count
FROM Segmented_Customers
GROUP BY Customer_Segment
ORDER BY Customer_Count DESC;

/* Summary Table
Segment	                    Characteristics	                                  Recommended Action
Champions	         Recent, frequent, high spend	                          Reward with VIP benefits and exclusive offers

Loyal                Customers	Purchase regularly	                          Maintain loyalty through rewards and personalized recommendations

Potential            Loyalists	Recent customers with moderate purchases	  Encourage repeat purchases using targeted promotions

At Risk	             Previously active but haven't purchased recently	      Launch win-back campaigns and special discounts

Lost Customers	     Long inactive, low purchase frequency	                  Re-engage selectively or deprioritize if acquisition cost is high
*/


--Task 2 – Customer Cohort Analysis

WITH CustomerCohort AS
(
    SELECT customer_id,
        FORMAT(MIN(order_purchase_timestamp), 'yyyy-MM') AS Cohort_Month
    FROM Orders
    GROUP BY customer_id
),

CustomerOrders AS
(
    SELECT customer_id,
        COUNT(order_id) AS Total_Orders
    FROM Orders
    GROUP BY customer_id
)

SELECT CC.Cohort_Month,
    COUNT(CC.customer_id) AS Total_Customers,
    SUM(CASE WHEN CO.Total_Orders > 1
            THEN 1
            ELSE 0
        END) AS Repeat_Customers,
    ROUND(
        SUM(CASE WHEN CO.Total_Orders > 1
                THEN 1.0
                ELSE 0
            END) * 100.0
        / COUNT(CC.customer_id),
    2) AS Repeat_Purchase_Rate,
    ROUND(
        SUM(CASE WHEN CO.Total_Orders > 1
                THEN 1.0
                ELSE 0
            END) * 100.0
        / COUNT(CC.customer_id),
    2) AS Customer_Retention_Rate
FROM CustomerCohort AS CC
JOIN CustomerOrders AS CO
ON CC.customer_id = CO.customer_id
GROUP BY CC.Cohort_Month
ORDER BY CC.Cohort_Month;

/* Key Insights
1. 0% repeat purchase and retention across every cohort indicates customers are making only one purchase.

2. Customer acquisition grew significantly from 2017 through mid-2018, peaking at 7,544 new customers in November 2017.

3. Despite strong customer acquisition, none of the cohorts generated repeat buyers, highlighting a major retention challenge.

4. Very small cohorts in September 2016, December 2016, September 2018,
   and October 2018 are likely due to limited data availability rather than business performance.

Business Recommendations
1. Prioritize retention strategies such as loyalty programs, personalized offers,
   and post-purchase email campaigns to encourage second purchases.

2. Analyze why customers do not return by reviewing product quality,
   delivery performance, pricing, and customer reviews.

3. Target customers within 30–60 days of their first purchase with cross-sell recommendations and exclusive discounts.

4. Track repeat purchase and retention KPIs monthly to measure the effectiveness of retention
   initiatives and reduce reliance on acquiring new customers.
 */
 

-- Task 3 – Seller Performance Matrix

WITH Seller_Performance AS
(
    SELECT
        OI.seller_id,
        SUM(P.payment_value) AS Total_Revenue,
        ROUND(AVG(CAST(R.review_score AS FLOAT)),2) AS Avg_Review_Score
    FROM Orders AS O
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Order_payments AS P
        ON O.order_id = P.order_id
    JOIN Order_reviews AS R
        ON O.order_id = R.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY OI.seller_id
),

Benchmark AS
(
    SELECT AVG(Total_Revenue) AS Avg_Revenue,
        AVG(Avg_Review_Score) AS Avg_Rating
    FROM Seller_Performance
)

SELECT SP.seller_id,
    ROUND(SP.Total_Revenue,2) AS Total_Revenue,
    SP.Avg_Review_Score,
    CASE
        WHEN SP.Total_Revenue >= B.Avg_Revenue
         AND SP.Avg_Review_Score >= B.Avg_Rating
            THEN 'High Revenue / High Rating'

        WHEN SP.Total_Revenue >= B.Avg_Revenue
         AND SP.Avg_Review_Score < B.Avg_Rating
            THEN 'High Revenue / Low Rating'

        WHEN SP.Total_Revenue < B.Avg_Revenue
         AND SP.Avg_Review_Score >= B.Avg_Rating
            THEN 'Low Revenue / High Rating'

        ELSE 'Low Revenue / Low Rating'
    END AS Seller_Segment
FROM Seller_Performance AS SP
CROSS JOIN Benchmark AS B
ORDER BY Total_Revenue DESC;

/* Business Recommendations

1. High Revenue / High Rating
   Reward top-performing sellers with incentives, premium visibility, and exclusive campaigns.
   Use their best practices as benchmarks for other sellers.

2. High Revenue / Low Rating
   Prioritize improvements in delivery speed, product quality, and customer service.
   Monitor customer feedback closely to prevent revenue loss.

3. Low Revenue / High Rating
   Increase their exposure through promotions, search ranking, and marketing campaigns.
   Encourage product assortment expansion to drive sales growth.

4. Low Revenue / Low Rating
   Provide operational training and performance improvement plans.
   Review seller performance regularly and consider delisting consistently underperforming sellers.
*/


-- Task 4 – Product Portfolio Matrix

WITH Product_Performance AS
(
    SELECT
        PC.column2 AS Product_category,
        SUM(PAY.payment_value) AS Total_Revenue,
        COUNT(OI.order_id) AS Total_Orders
    FROM Products AS P
    JOIN Order_items AS OI
        ON P.product_id = OI.product_id
    JOIN Order_payments AS PAY
        ON OI.order_id = PAY.order_id
    JOIN Product_category AS PC
    ON P.product_category_name = PC.column1
    GROUP BY PC.column2
),

Category_Avg AS
(
    SELECT
        AVG(Total_Revenue) AS Avg_Revenue,
        AVG(Total_Orders) AS Avg_Orders
    FROM Product_Performance
)

SELECT
    PP.product_category,
    ROUND(PP.Total_Revenue,2) AS Total_Revenue,
    PP.Total_Orders,
    CASE
        WHEN PP.Total_Revenue >= CA.Avg_Revenue
         AND PP.Total_Orders >= CA.Avg_Orders
            THEN 'High Revenue / High Volume'

        WHEN PP.Total_Revenue >= CA.Avg_Revenue
         AND PP.Total_Orders < CA.Avg_Orders
            THEN 'High Revenue / Low Volume'

        WHEN PP.Total_Revenue < CA.Avg_Revenue
         AND PP.Total_Orders >= CA.Avg_Orders
            THEN 'Low Revenue / High Volume'

        ELSE 'Low Revenue / Low Volume'
    END AS Portfolio_Segment
FROM Product_Performance PP
CROSS JOIN Category_Avg CA
ORDER BY Total_Revenue DESC;

/* Business Recommendations
       Segment	                                              Recommendation
1. High Revenue / High Volume	      Continue investing in inventory, marketing, and seller partnerships to maximize growth.

2. High Revenue / Low Volume	      Promote these premium categories through targeted campaigns to increase sales volume.

3. Low Revenue / High Volume	      Improve pricing, margins, and cross-selling opportunities to increase profitability.

4. Low Revenue / Low Volume	          Review product performance and consider reducing inventory, replacing products, or discontinuing underperforming categories.
*/


-- Task 5 – Regional Opportunity Analysis

WITH Regional_Performance AS
(
    SELECT
        C.customer_state,
        ROUND(SUM(PAY.payment_value),2) AS Total_Revenue,
        COUNT(DISTINCT C.customer_unique_id) AS Total_Customers,
        COUNT(DISTINCT S.seller_id) AS Total_Sellers
    FROM Orders O
    JOIN Customers C
        ON O.customer_id = C.customer_id
    JOIN Order_items OI
        ON O.order_id = OI.order_id
    JOIN Sellers S
        ON OI.seller_id = S.seller_id
    JOIN Order_payments PAY
        ON O.order_id = PAY.order_id
    GROUP BY C.customer_state
)

SELECT
    customer_state,
    Total_Revenue,
    Total_Customers,
    Total_Sellers,
    ROUND(Total_Revenue * 1.0 / Total_Customers,2) AS Revenue_per_Customer,
    ROUND(Total_Customers * 1.0 / Total_Sellers,2) AS Customers_per_Seller,
    CASE
        WHEN Total_Customers >
             (SELECT AVG(Total_Customers) FROM Regional_Performance)
         AND Total_Sellers <
             (SELECT AVG(Total_Sellers) FROM Regional_Performance)
            THEN 'High Expansion Opportunity'

        WHEN Total_Customers >
             (SELECT AVG(Total_Customers) FROM Regional_Performance)
            THEN 'High Demand'

        WHEN Total_Sellers <
             (SELECT AVG(Total_Sellers) FROM Regional_Performance)
            THEN 'Seller Gap'

        ELSE 'Balanced'
    END AS Opportunity_Level
FROM Regional_Performance
ORDER BY Customers_per_Seller DESC;

/* Business Recommendations
    Opportunity Level	                                       Recommendation
High Expansion Opportunity	            Prioritize seller acquisition, regional marketing, and logistics investment to capture unmet demand.

High Demand                         	Recruit additional sellers to reduce competition pressure and improve product availability.

Seller Gap	                            Launch seller onboarding programs and offer incentives to attract new merchants.

Balanced	                            Maintain current operations while monitoring demand and seller growth trends.
*/


-- Task 6 – Operational Risk Analysis

-- High cancellation rates
SELECT
    C.customer_state,
    COUNT(O.order_id) AS Total_Orders,
    SUM(CASE
            WHEN O.order_status = 'canceled' THEN 1
            ELSE 0
        END) AS Cancelled_Orders,
    ROUND(
        SUM(CASE
                WHEN O.order_status = 'canceled' THEN 1.0
                ELSE 0
            END) * 100 / COUNT(O.order_id),2
    ) AS Cancellation_Rate
FROM Orders O
JOIN Customers C
    ON O.customer_id = C.customer_id
GROUP BY C.customer_state
ORDER BY Cancellation_Rate DESC;

-- Low review scores
SELECT
    C.customer_state,
    ROUND(AVG(R.review_score),2) AS Avg_Review_Score,
    COUNT(R.review_id) AS Total_Reviews
FROM Orders O
JOIN Customers C
    ON O.customer_id = C.customer_id
JOIN Order_reviews R
    ON O.order_id = R.order_id
GROUP BY C.customer_state
ORDER BY Avg_Review_Score DESC;

-- Late deliveries
SELECT
    C.customer_state,
    COUNT(O.order_id) AS Delivered_Orders,
    ROUND(
        SUM(CASE
                WHEN O.order_delivered_customer_date >
                     O.order_estimated_delivery_date
                THEN 1.0
                ELSE 0
            END) * 100 / COUNT(O.order_id),2
    ) AS Late_Delivery_Rate
FROM Orders O
JOIN Customers C
    ON O.customer_id = C.customer_id
WHERE O.order_status = 'delivered'
GROUP BY C.customer_state
ORDER BY Late_Delivery_Rate DESC;

-- Seller concentration
SELECT TOP 10
    S.seller_state,
    COUNT(DISTINCT S.seller_id) AS Total_Sellers,
    ROUND(
        COUNT(DISTINCT S.seller_id) * 100.0 /
        (SELECT COUNT(DISTINCT seller_id) FROM Sellers),2
    ) AS Seller_Share_Percent
FROM Sellers S
GROUP BY S.seller_state
ORDER BY Seller_Share_Percent DESC;

-- Revenue concentration
SELECT
    C.customer_state,
    ROUND(SUM(P.payment_value),2) AS Revenue,
    ROUND(
        SUM(P.payment_value) * 100.0 /
        (SELECT SUM(payment_value) FROM Order_payments),2
    ) AS Revenue_Share_Percent
FROM Orders O
JOIN Customers C
    ON O.customer_id = C.customer_id
JOIN Order_payments P
    ON O.order_id = P.order_id
GROUP BY C.customer_state
ORDER BY Revenue_Share_Percent DESC;

/* Business Recommendations
       Risk Area	                                                    Recommendation
1. High Cancellation Rates	                 Investigate stock availability, payment failures, and logistics issues; work with affected sellers to reduce cancellations.

2. Low Review Scores	                     Improve product quality, seller service, and post-purchase support in underperforming regions.

3. Late Deliveries	Optimize                 logistics partners, expand regional fulfillment capacity, and monitor carrier performance.

4. High Seller Concentration	             Recruit sellers from underrepresented states to diversify supply and reduce operational dependency.

5. High Revenue Concentration	             Expand marketing and seller acquisition in lower-performing regions 
                                             to reduce reliance on a few key markets and improve long-term resilience.
*/


-- Task 7 – Marketplace Opportunity Score

WITH State_Metrics AS
(
    SELECT
        C.customer_state,
        SUM(P.payment_value) AS Revenue,
        COUNT(DISTINCT C.customer_unique_id) AS Customers,
        COUNT(DISTINCT OI.seller_id) AS Sellers,
        AVG(R.review_score) AS Avg_Review
    FROM Orders O
    JOIN Customers C
        ON O.customer_id = C.customer_id
    JOIN Order_payments P
        ON O.order_id = P.order_id
    JOIN Order_items OI
        ON O.order_id = OI.order_id
    LEFT JOIN Order_reviews R
        ON O.order_id = R.order_id
    GROUP BY C.customer_state
),

Scores AS
(
    SELECT
        *,
        Revenue * 100.0 / MAX(Revenue) OVER() AS Revenue_Score,
        Customers * 100.0 / MAX(Customers) OVER() AS Demand_Score,
        (1 - Sellers * 1.0 / MAX(Sellers) OVER()) * 100 AS Seller_Opportunity_Score,
        Avg_Review * 20 AS Satisfaction_Score
    FROM State_Metrics
)

SELECT
    customer_state,
    ROUND(Revenue,2) AS Revenue,
    Customers,
    Sellers,
    ROUND(Avg_Review,2) AS Avg_Review,
    ROUND(Revenue_Score,2) AS Revenue_Score,
    ROUND(Demand_Score,2) AS Demand_Score,
    ROUND(Seller_Opportunity_Score,2) AS Seller_Opportunity_Score,
    ROUND(Satisfaction_Score,2) AS Satisfaction_Score,
    ROUND(
        Revenue_Score * 0.30 +
        Demand_Score * 0.30 +
        Seller_Opportunity_Score * 0.20 +
        Satisfaction_Score * 0.20,
        2
    ) AS Marketplace_Opportunity_Score
FROM Scores
ORDER BY Marketplace_Opportunity_Score DESC;

/* Business Recommendations
       Opportunity Level	                                         Recommendation
1. Very High Opportunity	            Prioritize investment in seller acquisition, regional fulfillment, and marketing to maximize growth.

2. High Opportunity	                    Expand product assortment and improve logistics to support increasing customer demand.

3. Medium Opportunity	                Launch targeted promotional campaigns and monitor demand before scaling further.

4. Low Opportunity	                    Maintain current operations, investigate performance constraints, and evaluate long-term market viability.
*/


-- Task 8 – Executive Insights Dashboard


WITH Customer_Segment AS
(
    SELECT
        C.customer_unique_id,
        SUM(OP.payment_value) AS Total_Spend,
        CASE
            WHEN SUM(OP.payment_value) >= 1000 THEN 'High Value'
            WHEN SUM(OP.payment_value) >= 300 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS Customer_Segment
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    GROUP BY C.customer_unique_id
),

Best_Customer_Segment AS
(
    SELECT TOP 1
        Customer_Segment,
        SUM(Total_Spend) AS Revenue
    FROM Customer_Segment
    GROUP BY Customer_Segment
    ORDER BY Revenue DESC
),

Category_Revenue AS
(
    SELECT
        PC.column2 AS product_category_name,
        SUM(OP.payment_value) AS Revenue
    FROM Products AS P
    JOIN Order_items AS OI
        ON P.product_id = OI.product_id
    JOIN Order_payments AS OP
        ON OI.order_id = OP.order_id
    JOIN Product_category AS PC
        ON p.product_category_name = PC.column1
    GROUP BY PC.column2
),

Best_Product_Category AS
(
    SELECT TOP 1
        product_category_name,
        Revenue
    FROM Category_Revenue
    ORDER BY Revenue DESC
),

Seller_Revenue AS
(
    SELECT
        OI.seller_id,
        SUM(OP.payment_value) AS Revenue
    FROM Order_items AS OI
    JOIN Order_payments AS OP
        ON OI.order_id = OP.order_id
    GROUP BY OI.seller_id
),

Best_Seller AS
(
    SELECT TOP 1
        seller_id,
        Revenue
    FROM Seller_Revenue
    ORDER BY Revenue DESC
),

State_Revenue AS
(
    SELECT
        C.customer_state,
        SUM(OP.payment_value) AS Revenue
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    GROUP BY C.customer_state
),

Best_State AS
(
    SELECT TOP 1
        customer_state,
        Revenue
    FROM State_Revenue
    ORDER BY Revenue DESC
),

Category_Rating AS
(
    SELECT
        PC.column2 AS product_category_name,
        AVG(R.review_score) AS Avg_Rating
    FROM Products AS P
    JOIN Order_items AS OI
        ON P.product_id = OI.product_id
    JOIN Order_reviews AS R
        ON OI.order_id = R.order_id
    JOIN Product_category AS PC
        ON P.product_category_name = PC.column1
    GROUP BY PC.column2
),

Highest_Rated_Category AS
(
    SELECT TOP 1
        product_category_name,
        Avg_Rating
    FROM Category_Rating
    ORDER BY Avg_Rating DESC
),

State_Opportunity AS
(
    SELECT
        C.customer_state,
        SUM(OP.payment_value) AS Revenue,
        COUNT(DISTINCT C.customer_unique_id) AS Customers,
        COUNT(DISTINCT OI.seller_id) AS Sellers,
        AVG(R.review_score) AS Avg_Rating,

        (
            (SUM(OP.payment_value) * 100.0 /
                MAX(SUM(OP.payment_value)) OVER()) * 0.30 +

            (COUNT(DISTINCT C.customer_unique_id) * 100.0 /
                MAX(COUNT(DISTINCT C.customer_unique_id)) OVER()) * 0.30 +

            ((1 - COUNT(DISTINCT OI.seller_id) * 1.0 /
                MAX(COUNT(DISTINCT OI.seller_id)) OVER()) * 100) * 0.20 +

            (AVG(R.review_score) * 20) * 0.20
        ) AS Opportunity_Score

    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    LEFT JOIN Order_reviews AS R
        ON O.order_id = R.order_id
    GROUP BY C.customer_state
),

Largest_Opportunity AS
(
    SELECT TOP 1
        customer_state,
        Opportunity_Score
    FROM State_Opportunity
    ORDER BY Opportunity_Score DESC
)

SELECT
    BCS.Customer_Segment AS Best_Customer_Segment,
    BPC.product_category_name AS Best_Product_Category,
    BS.seller_id AS Best_Seller,
    BST.customer_state AS Best_State,
    HRC.product_category_name AS Highest_Rated_Category,
    LO.customer_state AS Largest_Opportunity_Region
FROM Best_Customer_Segment AS BCS
CROSS JOIN Best_Product_Category AS BPC
CROSS JOIN Best_Seller AS BS
CROSS JOIN Best_State AS BST
CROSS JOIN Highest_Rated_Category AS HRC
CROSS JOIN Largest_Opportunity AS LO;

/* Business Recommendations
         KPI	                                           Recommendation
1. Best Customer Segment	        Focus loyalty programs and personalized offers on the highest-value customers to maximize retention.

2. Best Product Category	        Increase inventory, marketing, and seller participation in top-performing categories.

3. Best Seller	                    Strengthen partnerships with top sellers and replicate their best practices across the marketplace.

4. Best State	                    Continue investing in logistics and customer experience while reducing dependence through geographic expansion.

5. Highest Rated Category	        Promote highly rated categories and use them as benchmarks for product quality and customer satisfaction.

6. Largest Opportunity Region	    Prioritize seller onboarding, marketing campaigns, and logistics investment to capture untapped market potential.
*/


/* SWOT Analysis 


                         Strengths                                                                                         	Weaknesses
1. High overall customer satisfaction with most                                     Delivery delays significantly reduce customer satisfaction and increase negative reviews.
   orders receiving 4–5 star reviews.	                                            

2. Strong revenue generated from top-performing product categories                  Revenue is concentrated in a few states, creating dependence on key markets.
   such as Health & Beauty, Watches & Gifts, and Bed Bath & Table.	                

3. High on-time delivery rate indicates an efficient                                Several sellers consistently receive low ratings or experience frequent late deliveries.
   logistics network for most orders.	                                            

4. Large base of loyal and repeat customers contributes                             Many product categories generate low revenue and low sales volume, tying up inventory and resources. 
   to stable marketplace revenue.	                                                

5. Diverse seller network supports a broad product assortment.	                    Some regions have high customer demand but relatively few sellers, limiting market penetration.


                 Opportunities	                                                                                   Threats
1. Expand into states with high customer demand but                                 Increasing logistics costs or delivery delays could reduce customer satisfaction and retention.
   low seller density identified in the Regional Opportunity Analysis.
   
2. Recruit more sellers in underserved regions to                                   Heavy dependence on a few high-revenue states exposes the marketplace to regional economic risks.
   improve product availability and reduce delivery times.
   
3. Promote high-revenue, low-volume product categories                              Poor-performing sellers can damage the marketplace's overall reputation.
   through targeted marketing to increase sales.	 
   
4. Increase customer retention through personalized offers and                      Strong competition from other e-commerce platforms may reduce market share and seller retention.
   loyalty programs targeting high-value customers.	      
   
5. Optimize low-performing categories by improving pricing,                         Continued high cancellation rates in certain regions may increase operational costs and customer churn.
   assortment, or discontinuing weak products.	  
  

   Summary

1. Strengths:     Strong customer satisfaction, healthy logistics performance, and high-performing product categories provide a solid foundation for growth.

2. Weaknesses:    Delivery delays, revenue concentration, and underperforming sellers are the primary operational challenges.

3. Opportunities: Expanding seller coverage in underserved regions, strengthening customer retention, and investing in high-potential categories can drive future growth.

4. Threats:       Regional revenue dependence, logistics disruptions, competitive pressure, and poor seller performance pose the greatest risks to long-term marketplace success.


Business Recommendations
 Priority       	                    Recommendation	                                                                      Expected Impact
1. High	            Expand seller acquisition in high-demand, low-seller states.	                                 Increase market coverage and revenue growth.

2. High	            Reduce late deliveries through logistics optimization and seller monitoring.	                 Improve customer satisfaction and retention.

3. Medium	        Invest more in high-revenue product categories while reviewing low-performing categories.	     Improve profitability and inventory efficiency.

4. Medium	        Strengthen loyalty programs for high-value and repeat customers.	                             Increase repeat purchases and customer lifetime value.

5. Low	            Diversify revenue across more states and categories.	                                         Reduce business risk and improve long-term resilience.
*/ 


/*Task 10 – Strategic Business Recommendations

       Business Area	             Key Finding	                              Strategic Recommendation	                                                                   Expected Business Impact
1. Customer Retention	    High-value and repeat customers contribute         Launch loyalty programs, personalized promotions,                           Increase repeat purchase rate, customer lifetime value, and retention
                            a significant share of revenue.                    and targeted retention campaigns for high-value customers.
                                                	
2. Product Strategy	        A few product categories generate most of          Increase investment in top-performing categories and review                 Improve revenue, inventory efficiency, and profitability.
                            the revenue, while others underperform.	           or discontinue consistently low-performing categories.                      
                            	           	
3. Seller Development	    Seller performance varies significantly            Provide seller training, performance scorecards, and                        Improve seller quality, customer satisfaction, and marketplace consistency.
                            in ratings and delivery performance.               incentive programs for high-performing sellers while 
                                                                               supporting underperforming sellers.	
                          	            	
4. Logistics Optimization	Late deliveries are associated with                Optimize shipping routes, strengthen logistics partnerships,                Reduce delivery delays, improve customer satisfaction,
                            lower customer review scores.                      and monitor seller shipping performance.                                    and lower operational costs.
                            	                    	
5. Regional Expansion	    Some states have high customer demand              Recruit new sellers, establish regional fulfillment support,                Increase market penetration, improve product availability, 
                            but relatively few sellers.	                       and invest in marketing within underserved states.                          and drive regional revenue growth.
                                                   
6. Revenue Growth	        Revenue is concentrated in a limited number        Diversify revenue by expanding into emerging regions,                       Reduce business risk and create sustainable long-term growth.
                            of states and product categories.                  promoting premium products, and increasing cross-selling 
                                                                               and upselling opportunities.
                           	               	
7. Customer Experience	    Customer satisfaction declines with                Improve order tracking, enhance customer support, simplify returns,         Increase review scores, strengthen customer trust, and improve retention.
                            cancellations and delayed deliveries.              and proactively communicate delivery updates.

*/