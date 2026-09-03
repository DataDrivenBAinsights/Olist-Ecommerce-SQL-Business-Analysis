-- Business Strategy & Decision Analytics

--Task 1 – Customer Retention Strategy

WITH Customer_RFM AS
(
    SELECT
        c.customer_unique_id,

        -- Recency (Days since last purchase)
        DATEDIFF(DAY,MAX(o.order_purchase_timestamp),
                 (SELECT MAX(order_purchase_timestamp)
                  FROM Orders)) AS Recency,

        -- Frequency
        COUNT(DISTINCT O.order_id) AS Frequency,

        -- Monetary
        ROUND(SUM(OP.payment_value),2) AS Monetary

    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY C.customer_unique_id
),

Customer_Segments AS
(
    SELECT *,
        CASE
            WHEN Recency <= 30 AND Frequency >= 5 AND Monetary >= 1000
                THEN 'Champions'
            WHEN Recency <= 60 AND Frequency >= 3
                THEN 'Loyal Customers'
            WHEN Recency <= 90 AND Frequency >= 2
                THEN 'Potential Loyalists'
            WHEN Recency > 90 AND Frequency >= 2
                THEN 'At Risk'
            ELSE 'Lost Customers'
        END AS Customer_Segment
    FROM Customer_RFM
)

SELECT
    Customer_Segment,
    COUNT(*) AS Customer_Count,
    ROUND(SUM(Monetary),2) AS Revenue_Contribution,
    ROUND(
        SUM(CASE WHEN Frequency > 1 THEN 1.0 ELSE 0 END) *100.0/COUNT(*),2) AS Repeat_Purchase_Rate,
    CASE
        WHEN Customer_Segment = 'Champions'
            THEN 'VIP Rewards & Exclusive Offers'
        WHEN Customer_Segment = 'Loyal Customers'
            THEN 'Loyalty Program & Cross-Selling'
        WHEN Customer_Segment = 'Potential Loyalists'
            THEN 'Personalized Discounts'
        WHEN Customer_Segment = 'At Risk'
            THEN 'Win-Back Campaign'
        WHEN Customer_Segment = 'Lost Customers'
            THEN 'Reactivation Email Campaign'
    END AS Recommended_Strategy

FROM Customer_Segments
GROUP BY Customer_Segment
ORDER BY Revenue_Contribution DESC;

/* Business Recommendations
1. Loyal Customers: Retain with VIP memberships, early access to new products, and exclusive rewards since they contribute the highest lifetime value.

2. Repeat Customers: Increase purchase frequency through personalized recommendations, loyalty points, and limited-time offers.

3. One-Time Customers: Re-engage with welcome-back discounts, abandoned-cart reminders, and targeted email campaigns to encourage a second purchase.

4. Prioritize campaigns for Repeat Customers because converting them into loyal customers generally delivers the 
   highest long-term business impact while requiring lower acquisition costs than attracting new customers.
*/


--Task 2 – Marketing Campaign Targeting

WITH customer_metrics AS (
    SELECT
        C.customer_unique_id,
        COUNT(DISTINCT O.order_id) AS purchase_frequency,
        SUM(OP.payment_value) AS total_spent,
        AVG(OP.payment_value) AS average_order_value
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY C.customer_unique_id
),

customer_segments AS (
    SELECT
        customer_unique_id,
        average_order_value,
        purchase_frequency,
        CASE
            WHEN purchase_frequency >= 5 AND average_order_value >= 200
                THEN 'High-Value Loyal'
            WHEN purchase_frequency BETWEEN 2 AND 4 AND average_order_value >= 150
                THEN 'Growth Customers'
            WHEN purchase_frequency >= 2
                THEN 'Frequent Buyers'
            ELSE 'One-Time Customers'
        END AS customer_segment
    FROM customer_metrics
)

SELECT
    customer_segment AS Customer_Segment,
    ROUND(AVG(average_order_value),2) AS Average_Order_Value,
    ROUND(AVG(CAST(purchase_frequency AS FLOAT)),2) AS Purchase_Frequency,
    CASE
        WHEN customer_segment = 'High-Value Loyal'
            THEN 'High'
        WHEN customer_segment = 'Growth Customers'
            THEN 'Medium'
        WHEN customer_segment = 'Frequent Buyers'
            THEN 'Medium'
        ELSE 'Low'
    END AS Campaign_Priority
FROM customer_segments
GROUP BY customer_segment
ORDER BY
CASE customer_segment
    WHEN 'High-Value Loyal' THEN 1
    WHEN 'Growth Customers' THEN 2
    WHEN 'Frequent Buyers' THEN 3
    ELSE 4
END;

/* Key Insights
1. High-Value Loyal customers should receive the highest campaign priority because they have the 
   greatest lifetime value and are most likely to respond to premium offers.

2. Growth Customers have the highest conversion potential since they already purchase repeatedly 
   and need targeted incentives to become loyal customers.

3. Frequent Buyers can generate additional revenue through cross-selling and upselling strategies.

4. One-Time Customers should receive low-cost re-engagement campaigns to improve repeat purchase rates while controlling marketing spend.

   Business Recommendations

    Customer Segment	                Recommended Campaign
1. High-Value Loyal	        Reward with VIP memberships, exclusive discounts, early product launches, and premium loyalty benefits to maximize retention.

2. Growth Customers	        Target with personalized product recommendations, bundle offers, and loyalty points to convert them into loyal customers.

3. Frequent Buyers	            Encourage higher basket value through cross-selling, upselling, and limited-time promotions.

4. One-Time Customers	        Use welcome-back emails, first-repeat discounts, and remarketing campaigns to encourage a second purchase.
*/


--Task 3 – Product Investment Matrix

WITH monthly_category_sales AS (
    SELECT
        PC.column2 AS Product_category,
        FORMAT(o.order_purchase_timestamp,'yyyy-MM') AS sales_month,
        SUM(op.payment_value) AS revenue,
        AVG(CAST(r.review_score AS FLOAT)) AS review_score
    FROM Orders O
    JOIN Order_items OI
        ON O.order_id = OI.order_id
    JOIN Products P
        ON OI.product_id = P.product_id
    JOIN Product_category AS PC
        ON P.product_category_name = PC.column1
    JOIN Order_payments OP
        ON O.order_id = OP.order_id
    LEFT JOIN order_reviews R
        ON O.order_id = R.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY
        PC.column2,
        FORMAT(O.order_purchase_timestamp,'yyyy-MM')
),

category_growth AS (
    SELECT
        Product_category,
        sales_month,
        revenue,
        review_score,
        LAG(revenue) OVER(PARTITION BY Product_category ORDER BY sales_month) AS previous_revenue
    FROM monthly_category_sales
),

category_summary AS (
    SELECT
        Product_category,
        SUM(revenue) AS total_revenue,
        AVG(
            CASE
                WHEN previous_revenue IS NULL OR previous_revenue = 0 THEN NULL
                ELSE ((revenue - previous_revenue) * 100.0 / previous_revenue)
            END) AS growth_rate,
        AVG(review_score) AS avg_review_score
    FROM category_growth
    GROUP BY Product_category
)

SELECT
    Product_Category,
    ROUND(total_revenue,2) AS Revenue,
    ROUND(growth_rate,2) AS Growth_Rate_Percent,
    ROUND(avg_review_score,2) AS Review_Score,
    CASE
        WHEN total_revenue >= 500000
             AND growth_rate >= 10
             AND avg_review_score >= 4.2
            THEN 'Invest'

        WHEN total_revenue >= 250000
             AND avg_review_score >= 4.0
            THEN 'Maintain'

        WHEN avg_review_score < 4.0
            THEN 'Improve'

        ELSE 'Review'
    END AS Investment_Priority
FROM category_summary
ORDER BY Revenue DESC;

/* Key Insights
1. Prioritize Invest categories as they combine high revenue, strong growth, and excellent customer satisfaction, 
   making them the best candidates for future expansion.

2. Maintain categories provide stable revenue and should remain part of the core portfolio.

3. Improve categories have business potential but require operational improvements before additional investment.

4. Review categories should be analyzed for declining demand, poor profitability, or consistently low customer satisfaction,
   as they may no longer justify continued investment.

   Business Recommendations
1. Increase investment in Sports & Leisure and Toys through higher marketing budgets, expanded inventory, 
   and onboarding more sellers, as these categories combine strong revenue, growth, and customer satisfaction.

2. Improve customer experience for Bed Bath Table, Furniture Decor, and Office Furniture by addressing product quality,
   packaging, and delivery issues before allocating additional investment.

3. Maintain stable investment in high-performing categories such as Health Beauty, Computers Accessories, 
   Watches Gifts, Housewares, Garden Tools, and Baby, while continuously monitoring market demand and competition.

4. Test growth opportunities in fast-growing but low-revenue categories (e.g., Fashion Bags Accessories, Construction Tools Safety, Drinks, and Art) 
   through targeted marketing campaigns and limited inventory expansion before making large investments.

5. Review underperforming categories such as Electronics, Home Appliances, and Books to identify whether pricing, assortment,
   or marketing is limiting sales despite positive customer feedback.

6. Restructure or phase out consistently weak categories like Security & Services, where declining revenue and poor customer ratings indicate low business potential.

*/

-- Task 4 – Seller Development Strategy

WITH seller_performance AS (
    SELECT
        S.seller_id,
        SUM(OP.payment_value) AS revenue,
        AVG(CAST(R.review_score AS FLOAT)) AS review_score,
        AVG(
            DATEDIFF(DAY,O.order_estimated_delivery_date, O.order_delivered_customer_date)) AS delivery_variance
    FROM Sellers S
    JOIN Order_items OI
        ON S.seller_id = OI.seller_id
    JOIN orders O
        ON OI.order_id = O.order_id
    JOIN Order_payments OP
        ON O.order_id = OP.order_id
    LEFT JOIN Order_reviews R
        ON O.order_id = R.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY S.seller_id
)

SELECT
    seller_id,
    ROUND(revenue,2) AS Revenue,
    ROUND(review_score,2) AS Review_Score,
    CASE
        WHEN delivery_variance <= 0 THEN 'On Time'
        WHEN delivery_variance <= 3 THEN 'Slight Delay'
        ELSE 'Delayed'
    END AS Delivery_Performance,

    CASE
        WHEN revenue >= 100000
             AND review_score >= 4.2
             AND delivery_variance <= 0
            THEN 'Reward'
        WHEN review_score < 4
             OR delivery_variance > 3
            THEN 'Support'
        ELSE 'Monitor'
    END AS Seller_Priority
FROM seller_performance
ORDER BY Revenue DESC;

/* Business Insights
1. Sellers with high revenue, excellent customer ratings, and on-time deliveries are the 
   marketplace's top performers and should be retained as strategic partners.

2. High-revenue sellers with poor review scores or frequent delivery delays present a 
   business risk because they generate sales but may reduce customer satisfaction.

3. Sellers with strong ratings but lower revenue have growth potential and can benefit from increased marketplace visibility.

4. Consistent delivery delays are a leading indicator of declining customer experience and should trigger operational reviews.

5. Monitoring seller performance across revenue, customer satisfaction, and logistics provides a balanced approach to seller management.

Business Recommendations
1. Reward top-performing sellers with reduced commissions, premium marketplace placement, exclusive campaigns, and early access to new platform features.

2. Provide operational support to sellers with low ratings or delivery issues through logistics assistance, inventory planning, and seller training.

3. Create a Seller Performance Scorecard combining revenue, review score, and delivery performance to monitor sellers monthly.

4. Introduce performance-based incentives that encourage sellers to maintain high ratings and on-time delivery.

5. Flag high-risk sellers with repeated delivery delays or poor reviews for proactive intervention before customer satisfaction declines.

6. Help emerging sellers with good ratings but low sales through promotional campaigns and better search visibility to diversify marketplace revenue.

7. Review underperforming sellers regularly and consider corrective action or removal if performance does not improve over multiple evaluation periods.
*/


-- Task 5 – Regional Expansion Strategy

WITH state_summary AS (
    SELECT
        C.customer_state,
        SUM(OP.payment_value) AS revenue,
        COUNT(DISTINCT C.customer_unique_id) AS customers,
        COUNT(DISTINCT OI.seller_id) AS sellers
    FROM Orders AS O
    JOIN Customers AS C
        ON O.customer_id = C.customer_id
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY C.customer_state
)

SELECT
    customer_state AS State,
    ROUND(revenue,2) AS Revenue,
    customers AS Customers,
    sellers AS Sellers,
    ROUND(CAST(customers AS FLOAT) / NULLIF(sellers,0),2) AS Customers_Per_Seller,
    CASE
        WHEN CAST(customers AS FLOAT) / NULLIF(sellers,0) >= 20
             AND revenue >= 500000
            THEN 'High'
        WHEN CAST(customers AS FLOAT) / NULLIF(sellers,0) >= 10
            THEN 'Medium'
        ELSE 'Low'
    END AS Expansion_Priority

FROM state_summary
ORDER BY Revenue DESC;

/* Business Insights

1. States with high revenue and a high Customers-per-Seller ratio indicate strong demand but 
   limited seller coverage, making them the best candidates for expansion.

2. High-revenue states with a balanced customer-to-seller ratio represent mature markets 
   where the focus should be on improving seller quality rather than increasing seller count.

3. States with many customers but relatively few sellers may experience longer delivery times 
   and stock limitations, highlighting opportunities for recruiting new sellers.

4. Low-revenue states with a small customer base should receive targeted marketing campaigns before significant seller expansion.

5. Comparing revenue, customers, and seller density helps identify underserved regions with the greatest growth potential.

Business Recommendations

1. Prioritize expansion into states with High Expansion Priority by recruiting additional sellers and strengthening local fulfillment capacity.

2. Recruit new sellers in regions with a high Customers-per-Seller ratio to reduce operational bottlenecks and improve product availability.

3. Invest in regional logistics hubs in high-demand states to shorten delivery times and improve customer satisfaction.

4. Support medium-priority states with localized marketing campaigns and seller onboarding programs to stimulate marketplace growth.

5. Monitor low-priority states and expand only after customer demand increases to ensure efficient resource allocation.

6. Diversify the seller network across multiple states to reduce dependence on a few regions and improve marketplace resilience.

7. Review regional performance quarterly using revenue growth, customer acquisition, and seller density to adjust expansion priorities dynamically.
*/


-- Task 6 – Pricing & Revenue Opportunities

WITH category_performance AS (
    SELECT
        PC.column2 AS Product_category,
        SUM(OP.payment_value) AS revenue,
        AVG(OP.payment_value) AS average_order_value,
        COUNT(DISTINCT O.order_id) AS order_volume
    FROM Orders O
    JOIN Order_items OI
        ON O.order_id = OI.order_id
    JOIN Products P
        ON OI.product_id = P.product_id
    JOIN Product_category AS PC
        ON P.product_category_name = PC.column1
    JOIN Order_payments OP
        ON O.order_id = OP.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY PC.column2
),

overall_metrics AS (
    SELECT
        AVG(average_order_value) AS avg_aov,
        AVG(order_volume) AS avg_order_volume
    FROM category_performance
)

SELECT
    cp.Product_category AS Product_Category,
    ROUND(cp.revenue,2) AS Revenue,
    ROUND(cp.average_order_value,2) AS Average_Order_Value,
    cp.order_volume AS Order_Volume,
    CASE
        WHEN cp.order_volume > om.avg_order_volume
             AND cp.average_order_value < om.avg_aov
            THEN 'High Opportunity'
        WHEN cp.order_volume > om.avg_order_volume
            THEN 'Medium Opportunity'
        ELSE 'Low Opportunity'
    END AS Opportunity_Level
FROM category_performance AS CP
CROSS JOIN overall_metrics AS OM
ORDER BY Revenue DESC;

/*  Business Insights
1. Categories with high order volume but low average order value (AOV) offer the greatest opportunity 
   for revenue growth through pricing optimization and basket-size expansion.

2. High-revenue categories with low AOV indicate strong customer demand, suggesting that
   even a small increase in average order value could significantly boost total revenue.

3. Categories with both high AOV and high order volume are already performing well and should focus on maintaining pricing competitiveness.

4. Low-demand categories with low AOV represent limited short-term revenue opportunities and should be evaluated carefully before further investment.

5. Comparing Revenue, AOV, and Order Volume helps identify where pricing strategies can deliver the highest return.

Business Recommendations
1. Increase Average Order Value by introducing product bundles, volume discounts, and cross-selling in high-demand categories.

2. Recommend complementary products during checkout to encourage customers to spend more per order.

3. Implement free shipping thresholds above the current average order value to increase basket size.

4. Use dynamic pricing for categories with strong demand to improve margins while remaining competitive.

5. Promote premium product variants in high-volume categories to encourage customers to trade up.

6. Target high-opportunity categories with personalized promotions and loyalty offers to maximize incremental revenue.

7. Monitor pricing performance regularly using AOV, conversion rate, and revenue growth to ensure pricing changes have a positive business impact.
*/


--Task 7 – Operational Efficiency Scorecard

WITH operational_kpis AS (
    SELECT
        -- Delivery Performance (% On-Time)
        ROUND(100.0 * SUM(CASE
                            WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date
                            THEN 1 ELSE 0
                            END) / COUNT(*), 2) AS delivery_performance,

        -- Average Review Score
        ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS review_score,

        -- Cancellation Rate (%)
        ROUND(100.0 * SUM(CASE
                             WHEN o.order_status = 'canceled'
                             THEN 1 ELSE 0
                             END) / COUNT(*), 2) AS cancellation_rate,

        -- Average Seller Performance (Review Score)
        ROUND(AVG(CAST(r.review_score AS FLOAT)), 2) AS seller_performance
    FROM Orders O
    LEFT JOIN Order_reviews R
        ON O.order_id = R.order_id
),

scorecard AS (
    SELECT
        delivery_performance,
        review_score,
        cancellation_rate,
        seller_performance,

        -- Overall Operational Score (100-point scale)
        ROUND(
              (delivery_performance * 0.40)
            + (review_score / 5.0 * 100 * 0.30)
            + ((100 - cancellation_rate) * 0.15)
            + (seller_performance / 5.0 * 100 * 0.15),
        2) AS overall_operational_score

    FROM operational_kpis
)

SELECT
    delivery_performance AS Delivery_Performance,
    review_score AS Review_Score,
    cancellation_rate AS Cancellation_Rate,
    seller_performance AS Seller_Performance,
    overall_operational_score AS Overall_Operational_Score,
    CASE
        WHEN delivery_performance < 90
            THEN 'Improve Delivery Operations'
        WHEN review_score < 4.0
            THEN 'Improve Customer Satisfaction'
        WHEN cancellation_rate > 2
            THEN 'Reduce Order Cancellations'
        WHEN seller_performance < 4.0
            THEN 'Support Seller Performance'
        ELSE 'Operations Performing Well'
    END AS Immediate_Action
FROM scorecard;

/* Business Insights
1. Delivery performance is the strongest operational KPI, indicating that most orders are delivered on or before the estimated date.

2. Customer review scores remain healthy, suggesting overall customer satisfaction, 
   but even small declines should be monitored because they directly affect repeat purchases.

3. Cancellation rates are low, reflecting efficient order processing and inventory management.

4. Seller performance closely aligns with customer review scores, highlighting the 
   importance of seller service quality in the overall customer experience.

5. The Overall Operational Score provides a single KPI for executives to monitor marketplace health and quickly identify operational risks.

Business Recommendations
1. Maintain high on-time delivery rates by optimizing logistics partnerships and warehouse operations.

2. Continuously monitor customer reviews and address recurring complaints related to product quality, packaging, or delivery.

3. Reduce order cancellations through better inventory forecasting, stock synchronization, and seller inventory management.

4. Support underperforming sellers with training, performance dashboards, and logistics assistance to improve customer satisfaction.

5. Track the Operational Score monthly and establish target thresholds (e.g., >90 = Excellent, 80–90 = Good, <80 = Needs Improvement) to enable proactive decision-making.

6. Implement automated KPI alerts for significant declines in delivery performance, review scores,
   or spikes in cancellation rates so operational issues can be addressed before they impact customers.
*/


-- Task 8 – Business Priority Matrix

WITH business_metrics AS (

    -- Customer Retention (Repeat Purchase Rate)
    SELECT
        'Customer Retention' AS Business_Area,
        ROUND(
            COUNT(DISTINCT CASE WHEN customer_orders > 1 THEN customer_unique_id END)
            * 100.0 / COUNT(DISTINCT customer_unique_id), 2
        ) AS KPI_Value
    FROM (
        SELECT
            C.customer_unique_id,
            COUNT(DISTINCT o.order_id) AS customer_orders
        FROM Customers AS C
        JOIN Orders AS O
            ON C.customer_id = O.customer_id
        WHERE O.order_status = 'delivered'
        GROUP BY C.customer_unique_id
    ) t

    UNION ALL

    -- Logistics (On-Time Delivery Rate)
    SELECT
        'Logistics',
        ROUND(
            SUM(CASE
                    WHEN order_delivered_customer_date <= order_estimated_delivery_date
                    THEN 1 ELSE 0
                END) * 100.0 / COUNT(*), 2)
    FROM Orders
    WHERE order_status = 'delivered'

    UNION ALL

    -- Product Quality (Average Review Score)
    SELECT
        'Product Quality',
        ROUND(AVG(CAST(review_score AS FLOAT)), 2)
    FROM Order_reviews

    UNION ALL

    -- Seller Development (Average Seller Revenue)
    SELECT
        'Seller Development',
        ROUND(AVG(Seller_Revenue), 2)
    FROM
    (
        SELECT
            OI.seller_id,
            SUM(OP.payment_value) AS Seller_Revenue
        FROM Order_items OI
        JOIN Orders O
            ON OI.order_id = O.order_id
        JOIN Order_payments OP
            ON O.order_id = OP.order_id
        WHERE O.order_status = 'delivered'
        GROUP BY OI.seller_id
    ) s

    UNION ALL

    -- Marketing (Average Order Value)
    SELECT
        'Marketing',
        ROUND(AVG(payment_value), 2)
    FROM order_payments

    UNION ALL

    -- Regional Expansion (Customers per Seller)
    SELECT
        'Regional Expansion',
        ROUND(AVG(Customers_Per_Seller), 2)
    FROM
    (
        SELECT
            C.customer_state,
            COUNT(DISTINCT C.customer_unique_id) * 1.0 /
            COUNT(DISTINCT OI.seller_id) AS Customers_Per_Seller
        FROM Customers C
        JOIN Orders O
            ON C.customer_id = O.customer_id
        JOIN Order_items OI
            ON O.order_id = OI.order_id
        WHERE O.order_status = 'delivered'
        GROUP BY C.customer_state
    ) x
),

priority_matrix AS
(
    SELECT
        Business_Area,
        KPI_Value,

        CASE
            WHEN Business_Area = 'Customer Retention' AND KPI_Value < 15 THEN 'High'
            WHEN Business_Area = 'Logistics' AND KPI_Value < 95 THEN 'High'
            WHEN Business_Area = 'Product Quality' AND KPI_Value < 4 THEN 'Medium'
            WHEN Business_Area = 'Seller Development' AND KPI_Value < 10000 THEN 'Medium'
            WHEN Business_Area = 'Marketing' AND KPI_Value < 150 THEN 'High'
            WHEN Business_Area = 'Regional Expansion' AND KPI_Value > 25 THEN 'High'
            ELSE 'Medium'
        END AS Impact,
        CASE
            WHEN Business_Area IN ('Marketing', 'Seller Development')
                THEN 'Low'
            WHEN Business_Area IN ('Customer Retention', 'Product Quality')
                THEN 'Medium'
            ELSE 'High'
        END AS Effort,
        CASE
            WHEN
                (Business_Area = 'Customer Retention' AND KPI_Value < 15)
                OR (Business_Area = 'Logistics' AND KPI_Value < 95)
                OR (Business_Area = 'Marketing' AND KPI_Value < 150)
                OR (Business_Area = 'Regional Expansion' AND KPI_Value > 25)
            THEN 'High'
            ELSE 'Medium'
        END AS Priority
    FROM business_metrics
)

SELECT
    Business_Area,
    KPI_Value,
    Impact,
    Effort,
    Priority
FROM priority_matrix
ORDER BY
    CASE Priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    CASE Business_Area
        WHEN 'Customer Retention' THEN 1
        WHEN 'Logistics' THEN 2
        WHEN 'Marketing' THEN 3
        WHEN 'Product Quality' THEN 4
        WHEN 'Seller Development' THEN 5
        WHEN 'Regional Expansion' THEN 6
        ELSE 7
    END;

/* Business Insights

1. Customer Retention should be the top priority because retaining existing customers is
   more cost-effective than acquiring new ones and directly improves Customer Lifetime Value (CLV).

2. Logistics has the greatest operational impact. Faster and more reliable deliveries 
   improve customer satisfaction, increase repeat purchases, and reduce negative reviews.

3. Marketing offers one of the highest returns with relatively low implementation 
   effort by targeting high-value and repeat customers using personalized campaigns.

4. Product Quality improvements should focus on high-revenue categories with below-average review scores
   to maximize customer satisfaction and reduce returns.

5. Seller Development is a long-term initiative that improves marketplace quality by
   helping sellers enhance service, delivery performance, and customer experience.

6. Regional Expansion should target states with high customer demand but relatively few sellers to unlock new revenue opportunities.

7. Pricing and Inventory Optimization provide incremental revenue gains by 
   increasing basket size and ensuring products remain available when demand is highest.

Business Recommendations
High Priority 
1. Launch customer retention and loyalty programs for high-value and repeat customers.
2. Improve logistics by reducing delivery delays and expanding fulfillment capacity in high-demand regions.
3. Execute personalized marketing campaigns targeting customers with high conversion potential.
4. Recruit new sellers in underserved states to balance supply with customer demand.

Medium Priority 
1. Improve product quality in categories with high revenue but low review scores.
2. Provide seller training, performance dashboards, and incentive programs.
3. Implement pricing strategies such as bundles, cross-selling, and premium product recommendations.
4. Enhance demand forecasting to optimize inventory levels and reduce stock shortages.
*/


-- Task 9 – Executive Strategy Dashboard

/*
WITH

-- 1. Customer Segmentation
customer_segment AS
(
    SELECT
        Customer_Segment,
        COUNT(*) AS Customer_Count
    FROM
    (
        SELECT
            C.customer_unique_id,
            CASE
                WHEN COUNT(DISTINCT O.order_id) >= 5 THEN 'Loyal Customers'
                WHEN COUNT(DISTINCT O.order_id) BETWEEN 2 AND 4 THEN 'Repeat Customers'
                ELSE 'One-Time Customers'
            END AS Customer_Segment
        FROM Customers AS C
        JOIN Orders AS O
            ON C.customer_id = O.customer_id
        WHERE O.order_status='delivered'
        GROUP BY C.customer_unique_id
    )x
    GROUP BY Customer_Segment
),

-- 2. Product Category Growth
category_growth AS
(
    SELECT TOP 1
        PC.column2 AS Product_category,
        SUM(op.payment_value) AS Revenue
    FROM Products AS P
    JOIN Order_items AS OI
        ON P.product_id=OI.product_id
    JOIN Orders AS O
        ON OI.order_id=O.order_id
    JOIN Order_payments AS OP
        ON O.order_id=OP.order_id
    JOIN Product_category AS PC
        ON P.product_category_name = PC.column1
    WHERE O.order_status='delivered'
    GROUP BY PC.column2
    ORDER BY Revenue DESC
),

-- 3. Best Seller
best_seller AS
(
    SELECT TOP 1
        OI.seller_id,
        SUM(OP.payment_value) AS Revenue
    FROM Order_items AS OI
    JOIN Orders AS O
        ON OI.order_id=O.order_id
    JOIN Order_payments AS OP
        ON O.order_id=OP.order_id
    WHERE O.order_status='delivered'
    GROUP BY OI.seller_id
    ORDER BY Revenue DESC
),

-- 4. Best Expansion Region
best_region AS
(
    SELECT TOP 1
        C.customer_state,
        COUNT(DISTINCT C.customer_unique_id)*1.0/
        COUNT(DISTINCT OI.seller_id) AS Customers_Per_Seller
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id=O.customer_id
    JOIN Order_items AS OI
        ON O.order_id=OI.order_id
    WHERE O.order_status='delivered'
    GROUP BY C.customer_state
    ORDER BY Customers_Per_Seller DESC
),

-- 5. Operational Risk
risk AS
(
    SELECT
        ROUND(SUM(CASE
                   WHEN order_delivered_customer_date >
                     order_estimated_delivery_date
                   THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Late_Delivery_Rate
    FROM Orders
    WHERE Order_status='delivered'
)

SELECT
    (SELECT TOP 1 Customer_Segment
     FROM customer_segment
     ORDER BY Customer_Count DESC)
        AS Highest_Priority_Customer_Segment,

    (SELECT product_category
     FROM category_growth)
        AS Highest_Growth_Product_Category,

    (SELECT seller_id
     FROM best_seller)
        AS Best_Performing_Seller,

    (SELECT customer_state
     FROM best_region)
        AS Highest_Revenue_Regiion,

    CASE
        WHEN (SELECT Late_Delivery_Rate FROM risk) > 10
            THEN 'Logistics'
        ELSE 'Customer Satisfaction'
    END
        AS Highest_Operational_Risk,

    CASE
        WHEN (SELECT Customer_Count
              FROM customer_segment
              WHERE Customer_Segment='One-Time Customers')
             >
             (SELECT Customer_Count
              FROM customer_segment
              WHERE Customer_Segment='Repeat Customers')
        THEN 'Customer Retention'
        ELSE 'Regional Expansion'
    END
        AS Top_Business_Priority
        
    INTO Business_decision_summary_table;
*/

SELECT *
FROM Business_decision_summary_table;

/*
/* ============================================================
   OLIST - BUSINESS INSIGHTS LOGIC TABLE
   Purpose:
   Store the logic, metric and business interpretation behind
   the executive insights used in the dashboard.
   ============================================================ */

DROP TABLE IF EXISTS Business_Insights_Logic;

CREATE TABLE Business_Insights_Logic
(
    Insight_Name           VARCHAR(100),
    Selected_Value         VARCHAR(200),
    Metric                 VARCHAR(100),
    Metric_Value           DECIMAL(18,2),
    Selection_Criteria     VARCHAR(500),
    Business_Interpretation VARCHAR(1000)
);


/* ============================================================
   1. BEST CUSTOMER SEGMENT
   Logic:
   Segment customers according to number of purchases.
   Here, Low Value = customers with only one order.
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        C.customer_unique_id,
        COUNT(DISTINCT O.order_id) AS Order_Count,
        SUM(OP.payment_value) AS Customer_Revenue
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    GROUP BY C.customer_unique_id
),
CustomerSegments AS
(
    SELECT
        customer_unique_id,
        CASE
            WHEN Customer_Revenue < 200 THEN 'Low Value'
            WHEN Customer_Revenue < 1000 THEN 'Medium Value'
            ELSE 'High Value'
        END AS Customer_Segment
    FROM CustomerOrders
),
SegmentSummary AS
(
    SELECT
        Customer_Segment,
        COUNT(*) AS Customer_Count
    FROM CustomerSegments
    GROUP BY Customer_Segment
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Best Customer Segment',
    Customer_Segment,
    'Customer Count',
    Customer_Count,
    'Segment with the highest number of customers',
    'A large low-value customer base creates an opportunity to increase customer spending and repeat purchases.'
FROM SegmentSummary
ORDER BY Customer_Count DESC;


/* ============================================================
   2. BEST PRODUCT CATEGORY
   Logic:
   Category with the highest revenue.
   ============================================================ */

WITH CategoryRevenue AS
(
    SELECT
        PC.column2 AS Product_Category,
        SUM(OI.price + OI.freight_value) AS Revenue
    FROM Order_items AS OI
    JOIN Products AS P
        ON OI.product_id = P.product_id
    JOIN Product_category AS PC
        ON PC.column1 = P.product_category_name
    GROUP BY PC.column2
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Best Product Category',
    Product_Category,
    'Revenue',
    Revenue,
    'Category with the highest revenue',
    'The highest-revenue category is a key commercial driver and should be monitored for continued growth.'
FROM CategoryRevenue
WHERE Product_Category IS NOT NULL
ORDER BY Revenue DESC;


/* ============================================================
   3. BEST PERFORMING SELLER
   Logic:
   Seller with the highest revenue.
   ============================================================ */

WITH SellerRevenue AS
(
    SELECT
        OI.seller_id,
        SUM(OI.price + OI.freight_value) AS Revenue
    FROM Order_items AS OI
    GROUP BY OI.seller_id
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Best Performing Seller',
    seller_id,
    'Revenue',
    Revenue,
    'Seller with the highest revenue',
    'This seller can be used as a benchmark to identify successful seller practices.'
FROM SellerRevenue
ORDER BY Revenue DESC;


/* ============================================================
   4. BEST STATE
   Logic:
   State with the highest revenue.
   ============================================================ */

WITH StateRevenue AS
(
    SELECT
        C.customer_state AS State,
        SUM(OP.payment_value) AS Revenue
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    GROUP BY C.customer_state
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Best State',
    State,
    'Revenue',
    Revenue,
    'State with the highest revenue',
    'The highest-revenue state represents the strongest existing geographic market.'
FROM StateRevenue
ORDER BY Revenue DESC;


/* ============================================================
   5. HIGHEST-RATED PRODUCT CATEGORY
   Logic:
   Category with the highest average review score.
   ============================================================ */

WITH CategoryRatings AS
(
    SELECT
        PC.column2 AS Product_Category,
        AVG(CAST(R.review_score AS DECIMAL(10,2))) AS Avg_Review_Score
    FROM Order_reviews AS R
    JOIN Orders AS O
        ON R.order_id = O.order_id
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Products AS P
        ON OI.product_id = P.product_id
    JOIN Product_category AS PC
        ON PC.column1 = P.product_category_name
    WHERE PC.column2 IS NOT NULL
    GROUP BY PC.column2
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Highest-Rated Category',
    Product_Category,
    'Average Review Score',
    Avg_Review_Score,
    'Category with the highest average customer review score',
    'Strong customer satisfaction in this category indicates an opportunity to maintain quality and support further demand.'
FROM CategoryRatings
ORDER BY Avg_Review_Score DESC;


/* ============================================================
   6. HIGHEST PRIORITY CUSTOMER SEGMENT
   Logic:
   One-time customers represent the largest retention opportunity.
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        C.customer_unique_id,
        COUNT(DISTINCT O.order_id) AS Order_Count
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    GROUP BY C.customer_unique_id
),
CustomerSegments AS
(
    SELECT
        customer_unique_id,
        CASE
            WHEN Order_Count = 1 THEN 'One-Time Customers'
            ELSE 'Repeat Customers'
        END AS Customer_Segment
    FROM CustomerOrders
),
SegmentSummary AS
(
    SELECT
        Customer_Segment,
        COUNT(*) AS Customer_Count
    FROM CustomerSegments
    GROUP BY Customer_Segment
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Highest Priority Customer Segment',
    Customer_Segment,
    'Customer Count',
    Customer_Count,
    'Segment representing the largest customer retention opportunity',
    'Converting one-time buyers into repeat customers can increase customer lifetime value and long-term revenue.'
FROM SegmentSummary
WHERE Customer_Segment = 'One-Time Customers'
ORDER BY Customer_Count DESC;


/* ============================================================
   7. HIGHEST GROWTH PRODUCT CATEGORY
   Logic:
   Compare revenue in the latest month with the previous month.
   ============================================================ */

WITH MonthlyCategorySales AS
(
    SELECT
        PC.column2 AS Product_Category,
        DATEFROMPARTS(
            YEAR(O.order_purchase_timestamp),
            MONTH(O.order_purchase_timestamp),
            1
        ) AS Sales_Month,
        SUM(OI.price) AS Revenue
    FROM Orders AS O
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Products AS P
        ON OI.product_id = P.product_id
     JOIN Product_category AS PC
        ON PC.column1 = P.product_category_name
    WHERE PC.column2 IS NOT NULL
    GROUP BY
        PC.column2,
        DATEFROMPARTS(
            YEAR(O.order_purchase_timestamp),
            MONTH(O.order_purchase_timestamp),
            1
        )
),
LatestMonths AS
(
    SELECT
        MAX(Sales_Month) AS Latest_Month
    FROM MonthlyCategorySales
),
CategoryGrowth AS
(
    SELECT
        CurrentMonth.Product_Category,
        CurrentMonth.Revenue AS Current_Revenue,
        PreviousMonth.Revenue AS Previous_Revenue,
        CASE
            WHEN PreviousMonth.Revenue > 0
            THEN
                ((CurrentMonth.Revenue - PreviousMonth.Revenue)
                / PreviousMonth.Revenue) * 100
            ELSE NULL
        END AS Growth_Percentage
    FROM MonthlyCategorySales AS CurrentMonth
    JOIN MonthlyCategorySales AS PreviousMonth
        ON CurrentMonth.Product_Category =
           PreviousMonth.Product_Category
       AND PreviousMonth.Sales_Month =
           DATEADD(MONTH, -1, CurrentMonth.Sales_Month)
    CROSS JOIN LatestMonths
    WHERE CurrentMonth.Sales_Month = Latest_Month
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Highest Growth Product Category',
    Product_Category,
    'Month-over-Month Revenue Growth %',
    Growth_Percentage,
    'Category with the highest positive revenue growth in the latest month',
    'The fastest-growing category is a potential candidate for additional marketing, inventory and seller support.'
FROM CategoryGrowth
WHERE Growth_Percentage IS NOT NULL
ORDER BY Growth_Percentage DESC;


/* ============================================================
   8. BEST EXPANSION REGION
   Logic:
   Region with the highest revenue.
   This is deliberately called "Expansion Region" only because
   the existing business insight uses that label.
   ============================================================ */

WITH RegionalPerformance AS
(
    SELECT
        C.customer_state AS State,
        SUM(OP.payment_value) AS Revenue,
        COUNT(DISTINCT O.order_id) AS Total_Orders,
        COUNT(DISTINCT C.customer_unique_id) AS Customers
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    GROUP BY C.customer_state
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Best Expansion Region',
    State,
    'Revenue',
    Revenue,
    'Region with the highest revenue',
    'The strongest existing region can be considered for further expansion, subject to growth and profitability analysis.'
FROM RegionalPerformance
ORDER BY Revenue DESC;


/* ============================================================
   9. HIGHEST OPERATIONAL RISK
   Logic:
   Identify the category with the lowest average review score.
   Lower satisfaction is treated as higher customer-experience risk.
   ============================================================ */

WITH CategoryRisk AS
(
    SELECT
        PC.column2 AS Product_Category,
        AVG(CAST(R.review_score AS DECIMAL(10,2))) AS Avg_Review_Score
    FROM Order_reviews AS R
    JOIN Orders AS O
        ON R.order_id = O.order_id
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Products AS P
        ON OI.product_id = P.product_id
     JOIN Product_category AS PC
        ON PC.column1 = P.product_category_name
    WHERE PC.column2 IS NOT NULL
    GROUP BY PC.column2
)
INSERT INTO Business_Insights_Logic
SELECT TOP 1
    'Highest Operational Risk',
    'Customer Satisfaction',
    'Average Review Score',
    Avg_Review_Score,
    'Lowest average review score indicates the greatest customer-experience risk',
    'Customer satisfaction should be monitored closely because poor experiences can negatively affect retention and repeat purchases.'
FROM CategoryRisk
ORDER BY Avg_Review_Score ASC;


/* ============================================================
   10. TOP BUSINESS PRIORITY
   Logic:
   Customer retention is selected because one-time customers
   represent a major opportunity for repeat purchases.
   ============================================================ */

WITH CustomerOrders AS
(
    SELECT
        C.customer_unique_id,
        COUNT(DISTINCT O.order_id) AS Order_Count
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    GROUP BY C.customer_unique_id
)
INSERT INTO Business_Insights_Logic
SELECT
    'Top Business Priority',
    'Customer Retention',
    'One-Time Customer Count',
    SUM(
        CASE
            WHEN Order_Count = 1 THEN 1
            ELSE 0
        END
    ),
    'Priority based on the size of the one-time customer base',
    'Improving retention and converting one-time customers into repeat buyers can increase long-term customer value.'
FROM CustomerOrders;
*/


SELECT *
FROM Business_Insights_Logic
ORDER BY Insight_Name;