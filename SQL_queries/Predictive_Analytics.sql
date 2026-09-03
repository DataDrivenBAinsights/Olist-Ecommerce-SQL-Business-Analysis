-- Predictive & Advanced Analytics

-- Task 1 – Revenue Trend & Forecast

WITH MonthlyRevenue AS
(
    SELECT
        FORMAT(O.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
        SUM(OP.payment_value) AS Monthly_Revenue
    FROM Orders AS O
    JOIN Order_payments AS OP
        ON o.order_id = op.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY FORMAT(O.order_purchase_timestamp,'yyyy-MM')
),

RevenueTrend AS
(
    SELECT
        Sales_Month,
        Monthly_Revenue,

        -- Previous Month Revenue
        LAG(Monthly_Revenue) OVER(ORDER BY Sales_Month) AS Previous_Month_Revenue,

        -- 3-Month Moving Average
        AVG(Monthly_Revenue * 1.0) OVER(ORDER BY Sales_Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Moving_Average_3M
    FROM MonthlyRevenue
)

SELECT
    Sales_Month,
    ROUND(Monthly_Revenue,2) AS Monthly_Revenue,
    ROUND(Moving_Average_3M,2) AS Moving_Average_3M,
    ROUND(
        ((Monthly_Revenue - Previous_Month_Revenue)/ NULLIF(Previous_Month_Revenue,0)) * 100,2) AS Revenue_Growth_Percentage,
    ROUND(Moving_Average_3M,2) AS Forecasted_Next_Month_Revenue
FROM RevenueTrend
ORDER BY Sales_Month;

/* Revenue Trend Insights
1. Strong long-term revenue growth
   Revenue increased from USD 46.6K (Oct 2016) to USD 985.4K (Aug 2018), indicating significant marketplace expansion despite monthly fluctuations.

2. Early data is not representative
   Dec 2016 recorded only USD 19.62 in revenue, resulting in an artificial -99.96% decline followed by a 649,979.84% increase in Jan 2017.
   These months are likely incomplete and should be excluded from trend analysis.

3. Consistent growth during 2017
   From Jan–Nov 2017, revenue generally increased, with only minor declines in Apr (-5.65%) and Jun (-13.55%), showing strong business momentum.

4. Seasonal peak in November
   November 2017 achieved the highest monthly revenue of USD 1.15M, growing 53.57% over October. 
   This suggests strong seasonal demand, likely driven by major shopping events and holiday promotions.

5. Post-peak correction
   Revenue declined 26.9% in Dec 2017, indicating that the November spike was seasonal rather than sustained.

6. Stable performance in 2018
   Revenue remained consistently around USD 1.0M–USD 1.13M between Jan and Aug 2018, reflecting a mature and stable growth phase.

7. Revenue volatility reduced
   Compared to 2017, monthly revenue growth in 2018 mostly stayed within ±10%, indicating improved business stability and more predictable sales.

8. 3-Month Moving Average confirms upward trend
   The moving average increased steadily from USD 46.6K to approximately USD 1.01M, smoothing short-term fluctuations and confirming sustained long-term revenue growth.

9. Forecast indicates stable future revenue
   The forecasted next-month revenue for Aug 2018 is approximately USD 1.01M, suggesting the marketplace is expected to maintain revenue around the USD 1M level if current trends continue.

Business Recommendations
Finding	                                                             Recommendation

Strong long-term revenue growth	                  Continue investing in customer acquisition, seller onboarding, and marketplace expansion.

November generates exceptional revenue	          Increase inventory, marketing budgets, and logistics capacity before peak shopping seasons to maximize sales.

Revenue drops after peak periods	              Launch post-holiday promotions and loyalty campaigns to reduce seasonal declines.

Stable revenue around ₹1M in 2018	              Focus on improving profitability through higher average order value, cross-selling, and operational efficiency rather than relying solely on revenue growth.

Months with negative growth	                      Analyze underperforming product categories, regions, and marketing campaigns to identify the causes of revenue declines.

Moving average continues to rise	              Use the forecast for inventory planning, workforce scheduling, and budgeting to avoid stockouts or overstocking.

Revenue growth has stabilized	                  Shift business strategy from rapid expansion to customer retention, repeat purchases, and seller performance improvement.

Early months contain incomplete data	          Exclude Oct–Dec 2016 from trend and forecasting analyses to ensure accurate business reporting.
*/


-- Task 2 – Customer Churn Prediction

WITH CustomerMetrics AS
(
    SELECT
        c.customer_unique_id,
        MAX(CAST(o.order_purchase_timestamp AS DATE)) AS Last_Purchase_Date,
        DATEDIFF(DAY,MAX(CAST(o.order_purchase_timestamp AS DATE)),
            (SELECT MAX(CAST(order_purchase_timestamp AS DATE))
             FROM Orders)
        ) AS Days_Since_Last_Purchase,
        COUNT(DISTINCT O.order_id) AS Purchase_Frequency,
        ROUND(SUM(OP.payment_value),2) AS Total_Spend
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)

SELECT
    customer_unique_id,
    Last_Purchase_Date,
    Days_Since_Last_Purchase,
    Purchase_Frequency,
    Total_Spend,
    CASE
        WHEN Days_Since_Last_Purchase > 180
             AND Purchase_Frequency = 1
             THEN 'High'
        WHEN Days_Since_Last_Purchase > 120
             THEN 'Medium'
        ELSE 'Low'
    END AS Churn_Risk
FROM CustomerMetrics
ORDER BY
    CASE
        WHEN Days_Since_Last_Purchase > 180
             AND Purchase_Frequency = 1 THEN 1
        WHEN Days_Since_Last_Purchase > 120 THEN 2
        ELSE 3
    END,
    Days_Since_Last_Purchase DESC;

/* Business Insights
1. Customers with High Churn Risk have not purchased for over 180 days and placed only one order,
   making them the least likely to return without intervention.

2. Medium Churn Risk customers have been inactive for over 120 days but may still be recoverable through targeted engagement.

3. Low Churn Risk customers purchased recently and are actively engaged with the marketplace.

4. Customers with high purchase frequency and high spending represent valuable customers and
   should be prioritized for retention even if they become inactive.

5. Comparing churn risk across customer segments can help identify where retention efforts will have the greatest business impact.

Business Recommendations
    Finding	                                                  Recommendation
High churn customers	                    Launch win-back campaigns with personalized discounts, coupons, or free shipping offers.

Medium churn customers	                    Send reminder emails, product recommendations, and limited-time promotions before they become high-risk.

Loyal customers	                            Reward with loyalty points, exclusive offers, and early access to sales to maintain engagement.

High-value customers showing inactivity	    Assign premium retention campaigns and personalized support to reduce revenue loss.

One-time buyers dominate high-risk segment	Improve post-purchase engagement through follow-up emails, cross-selling, and reorder reminders.

Monitor churn monthly	                    Track churn trends over time and measure the effectiveness of retention campaigns using a dashboard.
*/


-- Task 3 – Demand Forecast by Product Category

WITH CategoryMonthlySales AS
(
    SELECT
        FORMAT(O.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
        PC.column2 AS Product_category,
        COUNT(DISTINCT O.order_id) AS Monthly_Orders,
        SUM(OP.payment_value) AS Monthly_Revenue
    FROM Orders AS O
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Products AS P
        ON OI.product_id = P.product_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    JOIN Product_category AS PC
        ON P.product_category_name = PC.column1
    WHERE O.order_status = 'delivered'
    GROUP BY
        FORMAT(O.order_purchase_timestamp,'yyyy-MM'),
        PC.column2
),

CategoryTrend AS
(
    SELECT
        Sales_Month,
        Product_category,
        Monthly_Orders,
        Monthly_Revenue,
        LAG(Monthly_Revenue) OVER
        (PARTITION BY Product_category ORDER BY Sales_Month) AS Previous_Month_Revenue,
        AVG(Monthly_Revenue * 1.0) OVER
        (PARTITION BY Product_category ORDER BY Sales_Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ) AS Moving_Average_3M
    FROM CategoryMonthlySales
)

SELECT
    Sales_Month,
    Product_category,
    Monthly_Orders,
    ROUND(Monthly_Revenue,2) AS Monthly_Revenue,
    ROUND(Moving_Average_3M,2) AS Moving_Average_3M,
    ROUND(
        ((Monthly_Revenue - Previous_Month_Revenue)
        / NULLIF(Previous_Month_Revenue,0))*100,
    2) AS Revenue_Growth_Percentage,
    CASE
        WHEN Previous_Month_Revenue IS NULL THEN 'New Category'
        WHEN Monthly_Revenue > Previous_Month_Revenue THEN 'Growing'
        WHEN Monthly_Revenue < Previous_Month_Revenue THEN 'Declining'
        ELSE 'Stable'
    END AS Growth_Trend

FROM CategoryTrend
ORDER BY Product_category,
         Sales_Month;

/* Business Insights
1. Growing categories show increasing monthly orders and revenue, indicating rising customer demand.

2. Declining categories experience consecutive revenue or order decreases, suggesting weakening demand or increased competition.

3. A rising 3-month moving average confirms sustained long-term growth rather than temporary sales spikes.

4. Categories with high revenue but low order growth may benefit from premium pricing or higher average order values.

5. Categories with high order growth but lower revenue growth may require pricing optimization or cross-selling opportunities.

Newly introduced categories should be monitored over several months before evaluating their performance due to limited historical data.

Business Recommendations

      Finding                                                               	Recommendation
Categories with sustained growth	                Increase inventory levels, marketing investment, and seller onboarding to capitalize on rising demand.

Categories with declining demand	                Review pricing, promotions, and product assortment to identify causes of reduced sales.

High-demand seasonal categories	                    Forecast inventory in advance to prevent stockouts during peak periods.

Categories with consistently low revenue	        Consider discontinuing low-performing products or replacing them with higher-demand alternatives.

Stable categories	                                Maintain inventory levels and focus on improving margins through operational efficiency.

Growing order volume but slower revenue growth	    Introduce product bundles, upselling, and premium variants to increase average order value.

Monthly demand fluctuations                     	Use the 3-month moving average for inventory planning and purchasing decisions instead of relying solely on monthly sales.
*/


-- Task 4 – Inventory Planning Insights

WITH CategorySales AS
(
    SELECT
        PC.column2 AS Product_category,
        COUNT(DISTINCT O.order_id) AS Order_Volume,
        COUNT(DISTINCT FORMAT(O.order_purchase_timestamp,'yyyy-MM'))
            AS Sales_Frequency,
        SUM(OP.payment_value) AS Revenue
    FROM Orders AS O
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Products AS P
        ON OI.product_id = P.product_id
    JOIN Product_category AS PC
        ON P.product_category_name = PC.column1
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY PC.column2
),

CategoryContribution AS
(
    SELECT
        *,
        ROUND(Revenue * 100.0 / SUM(Revenue) OVER(), 2) AS Revenue_Contribution
    FROM CategorySales
)

SELECT
    Product_category,
    Order_Volume,
    Sales_Frequency,
    ROUND(Revenue,2) AS Revenue,
    Revenue_Contribution,
    CASE
        WHEN Revenue_Contribution >= 5
             AND Order_Volume >= 1000
            THEN 'High Demand'
        WHEN Revenue_Contribution >= 2
            THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS Demand_Classification
FROM CategoryContribution
ORDER BY
    Revenue DESC;

/* Business Insights
1. Categories with high order volume and high revenue contribution are the primary demand drivers and require sufficient inventory to avoid stockouts.

2. Categories with consistent sales frequency generate demand throughout the year and support stable inventory planning.

3. Categories with low order volume, low sales frequency, and minimal revenue contribution are slow-moving and occupy warehouse space with limited returns.

4. A small number of product categories typically contribute the majority of marketplace revenue, indicating inventory should be prioritized for these categories.

5. Medium-demand categories offer opportunities for growth through targeted promotions and assortment optimization.

Business Recommendations

   Finding	                                                   Recommendation
High-demand categories	                        Increase safety stock, improve supplier coordination, and prioritize warehouse space to prevent stockouts.

Medium-demand categories	                    Monitor demand trends closely and support growth through targeted marketing and promotional campaigns.

Low-demand (slow-moving) categories         	Reduce inventory levels, limit replenishment, and consider clearance promotions to free warehouse capacity.

Categories with high revenue contribution	    Prioritize forecasting accuracy and maintain higher service levels to protect revenue.

Categories with low sales frequency     	    Adopt a just-in-time replenishment strategy to reduce inventory holding costs.

Inventory concentration in a few categories 	Diversify the product portfolio while ensuring top-performing categories remain well stocked.

Regular inventory review	                    Update inventory classifications monthly using order volume, revenue contribution,
                                                and sales frequency to respond to changing demand.
*/


-- Task 5 – Seller Growth Trend

WITH SellerMonthlySales AS
(
    SELECT
        FORMAT(O.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
        OI.seller_id,
        COUNT(DISTINCT O.order_id) AS Monthly_Orders,
        SUM(OP.payment_value) AS Monthly_Revenue
    FROM Orders AS O
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        FORMAT(O.order_purchase_timestamp,'yyyy-MM'),
        OI.seller_id
),

SellerTrend AS
(
    SELECT
        Sales_Month,
        seller_id,
        Monthly_Orders,
        Monthly_Revenue,
        LAG(Monthly_Revenue) OVER(PARTITION BY seller_id ORDER BY Sales_Month) AS Previous_Month_Revenue
    FROM SellerMonthlySales
)

SELECT
    Sales_Month,
    seller_id,
    Monthly_Orders,
    ROUND(Monthly_Revenue,2) AS Monthly_Revenue,
    ROUND(
        ((Monthly_Revenue - Previous_Month_Revenue)
        / NULLIF(Previous_Month_Revenue,0))*100,
    2) AS Revenue_Growth_Percentage,
    CASE
        WHEN Previous_Month_Revenue IS NULL THEN 'New Seller'
        WHEN Monthly_Revenue > Previous_Month_Revenue THEN 'Growing'
        WHEN Monthly_Revenue < Previous_Month_Revenue THEN 'Declining'
        ELSE 'Stable'
    END AS Growth_Trend
FROM SellerTrend
ORDER BY
    seller_id,
    Sales_Month;

/* Business Insights
1. Sellers with consistent month-over-month revenue growth are expanding their market presence and contributing more to marketplace revenue.

2. Sellers with declining revenue and order volume may be losing competitiveness due to pricing,
   inventory shortages, or customer satisfaction issues.

3. Sellers showing stable performance provide a reliable revenue base and should be monitored for future growth opportunities.

4. Newly onboarded sellers require additional months of data before meaningful growth trends can be assessed.

5. Comparing revenue growth with order growth helps distinguish between increased sales volume and higher average selling prices.

Business Recommendations

     Finding	                                                             Recommendation
Consistently growing sellers	        Reward with premium marketplace visibility, marketing support, and participation in promotional campaigns.

Sellers with declining revenue	        Review pricing, product assortment, delivery performance, and customer ratings to identify improvement opportunities.

High-order, low-growth sellers	        Encourage upselling, cross-selling, and premium product offerings to increase average order value.

New sellers	                            Provide onboarding support, training, and promotional incentives to accelerate early growth.

Top-performing sellers	                Build long-term partnerships and ensure sufficient inventory during peak demand periods.

Persistently underperforming sellers	Offer operational coaching or consider performance-based policies to maintain marketplace quality.

Monthly performance monitoring	        Track seller growth trends regularly to identify emerging top performers and sellers at risk of losing market share.
*/



-- Task 6 – Customer Lifetime Value (CLV)

WITH CustomerCLV AS
(
    SELECT
        C.customer_unique_id,
        COUNT(DISTINCT O.order_id) AS Orders,
        SUM(OP.payment_value) AS Total_Spend,
        AVG(OP.payment_value) AS Average_Order_Value
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id = O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY C.customer_unique_id
)

SELECT
    customer_unique_id,
    Orders,
    ROUND(Total_Spend,2) AS Total_Spend,
    ROUND(Average_Order_Value,2) AS Average_Order_Value,
    ROUND(Average_Order_Value * Orders,2) AS Estimated_CLV,
    CASE
        WHEN (Average_Order_Value * Orders) >= 1000 THEN 'High Value'
        WHEN (Average_Order_Value * Orders) >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Customer_Segment
FROM CustomerCLV
ORDER BY Estimated_CLV DESC;

/* Business Insights
1. High-CLV customers generate the greatest long-term revenue and are the marketplace's most valuable customer segment.

2. Customers with high order frequency and high spending contribute disproportionately to total revenue and should be prioritized for retention.

3. Medium-CLV customers represent strong growth potential and can be moved into the high-value segment through personalized offers and loyalty initiatives.

4. Low-CLV customers are typically first-time or infrequent buyers and require engagement strategies to encourage repeat purchases.

5. Comparing CLV across customer segments helps optimize marketing budgets by focusing on customers with the highest expected return.

Business Recommendations

    Finding                                                          	Recommendation
High-CLV customers	                        Invest in VIP programs, exclusive discounts, personalized recommendations, and early access to new products to maximize retention.

Medium-CLV customers	                    Increase purchase frequency through targeted promotions, cross-selling, and product bundles.

Low-CLV customers	                        Launch onboarding campaigns, first-repeat purchase discounts, and personalized follow-up communications to encourage additional purchases.

High AOV but few orders	                    Use loyalty rewards and reorder reminders to increase purchase frequency.

Frequent buyers with low AOV	            Promote premium products and bundled offers to increase average order value.

Marketing budget allocation	                Prioritize customer acquisition channels and retention campaigns that attract or retain high-CLV customers to maximize return on investment.

Ongoing CLV monitoring	                    Refresh CLV calculations regularly to identify emerging high-value customers and adjust marketing strategies accordingly.
*/


--Task 7 – Seasonal Trend Analysis

WITH MonthlySales AS
(
    SELECT
        YEAR(O.order_purchase_timestamp) AS Sales_Year,
        MONTH(O.order_purchase_timestamp) AS Month_No,
        DATENAME(MONTH, O.order_purchase_timestamp) AS Month_Name,
        COUNT(DISTINCT O.order_id) AS Monthly_Orders,
        SUM(OP.payment_value) AS Monthly_Revenue
    FROM Orders AS O
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE O.order_status = 'delivered'
    GROUP BY
        YEAR(O.order_purchase_timestamp),
        MONTH(O.order_purchase_timestamp),
        DATENAME(MONTH, O.order_purchase_timestamp)
),

MonthlyAverage AS
(
    SELECT
        Month_No,
        Month_Name,
        AVG(Monthly_Revenue) AS Average_Monthly_Sales,
        AVG(Monthly_Orders) AS Average_Monthly_Orders
    FROM MonthlySales
    GROUP BY
        Month_No,
        Month_Name
),

OverallAverage AS
(
    SELECT
        AVG(Monthly_Revenue) AS Overall_Average_Revenue
    FROM MonthlySales
)

SELECT
    M.Month_No,
    M.Month_Name,
    ROUND(M.Average_Monthly_Sales,2) AS Average_Monthly_Sales,
    ROUND(M.Average_Monthly_Orders,0) AS Average_Monthly_Orders,
    ROUND(
        (M.Average_Monthly_Sales / o.Overall_Average_Revenue) * 100,
    2) AS Seasonal_Index,
    CASE
        WHEN (M.Average_Monthly_Sales / o.Overall_Average_Revenue) * 100 >= 110
            THEN 'Peak Season'
        WHEN (M.Average_Monthly_Sales / o.Overall_Average_Revenue) * 100 >= 90
            THEN 'Normal Season'
        ELSE 'Low Season'
    END AS Season_Type
FROM MonthlyAverage AS M
CROSS JOIN OverallAverage AS O
ORDER BY Month_No;

/* Business Insights
1. November consistently records the highest revenue and order volume, making it the strongest sales month and indicating significant seasonal demand.

2. December also performs above average, suggesting holiday shopping continues after the November peak.

3. Months with a Seasonal Index above 100 experience demand higher than the yearly average and should be considered high-priority sales periods.

4. Months with a Seasonal Index below 100 represent lower-demand periods where promotional activities may be required to stimulate sales.

5. Comparing seasonal indices across years helps distinguish recurring seasonal patterns from one-time sales spikes.

Business Recommendations

    Finding	                                  Recommendation
Peak-season months	                         Increase inventory, warehouse capacity, and logistics resources before high-demand periods to prevent stockouts and delivery delays.

High seasonal demand	                     Allocate larger marketing budgets and launch promotional campaigns before peak shopping events.

Low-season months	                         Use discounts, bundled offers, and loyalty campaigns to increase customer demand during slower periods.

Consistent seasonal patterns	             Incorporate seasonal indices into demand forecasting and procurement planning to improve forecast accuracy.

High order volumes during peak months	     Strengthen supplier coordination and workforce planning to maintain service quality.

Seasonal product demand	                     Stock seasonal product categories earlier and optimize inventory allocation across fulfillment centers.

Annual planning	                             Use historical seasonal trends to schedule marketing campaigns, inventory purchases, and staffing throughout the year.
*/


-- Task 8 – Business Risk Prediction

WITH MonthlyRisk AS
(
    SELECT
        FORMAT(O.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
        SUM(OP.payment_value) AS Revenue,
        AVG(CAST(ORs.review_score AS FLOAT)) AS Avg_Review_Score,
        AVG(DATEDIFF(DAY,O.order_purchase_timestamp, O.order_delivered_customer_date)) AS Avg_Delivery_Days,
        COUNT(DISTINCT OI.seller_id) AS Active_Sellers,
        COUNT(DISTINCT C.customer_state) AS Active_States
    FROM Orders AS O
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    JOIN Order_reviews AS ORs
        ON O.order_id = ORs.order_id
    JOIN Order_items AS OI
        ON O.order_id = OI.order_id
    JOIN Customers AS C
        ON O.customer_id = C.customer_id
    WHERE O.order_status = 'delivered'
    GROUP BY FORMAT(O.order_purchase_timestamp,'yyyy-MM')
),

RiskTrend AS
(
    SELECT
        *,
        LAG(Revenue) OVER(ORDER BY Sales_Month) AS Prev_Revenue,
        LAG(Avg_Review_Score) OVER(ORDER BY Sales_Month) AS Prev_Review,
        LAG(Avg_Delivery_Days) OVER(ORDER BY Sales_Month) AS Prev_Delivery
    FROM MonthlyRisk
)

SELECT
    Sales_Month,
    ROUND(Revenue,2) AS Revenue,
    ROUND(((Revenue - Prev_Revenue) / NULLIF(Prev_Revenue,0))*100,2) AS Revenue_Growth_Percentage,
    ROUND(Avg_Review_Score,2) AS Avg_Review_Score,
    ROUND(Avg_Delivery_Days,2) AS Avg_Delivery_Days,
    Active_Sellers,
    Active_States,
    CASE
        WHEN Revenue < Prev_Revenue THEN 'Revenue Risk'
        WHEN Avg_Review_Score < Prev_Review THEN 'Review Risk'
        WHEN Avg_Delivery_Days > Prev_Delivery THEN 'Delivery Risk'
        ELSE 'Stable'
    END AS Primary_Risk
FROM RiskTrend
ORDER BY Sales_Month;

/* Business Insights
1. Declining revenue indicates weakening sales momentum and should be investigated to identify issues with demand, pricing, or promotions.

2. Falling review scores suggest deteriorating customer satisfaction, which can negatively impact repeat purchases and brand reputation.

3. Increasing delivery times highlight operational inefficiencies that may reduce customer satisfaction and increase cancellation risk.

4. High seller dependency exposes the marketplace to revenue risk if a few sellers contribute a large share of total sales.

5. High regional dependency indicates overreliance on specific states, making revenue vulnerable to regional economic or competitive changes.

6. Monitoring these KPIs together provides an early-warning system, allowing management to identify and address business risks before they significantly impact performance.

Business Recommendations

      Risk Area	                                                  Recommendation
Declining Revenue	                 Monitor monthly revenue growth, identify underperforming categories, and launch targeted marketing campaigns to stimulate demand.

Declining Reviews	                 Improve product quality, seller performance, and customer support to maintain high customer satisfaction.

Increasing Delivery Delays	         Optimize logistics, strengthen carrier partnerships, and monitor on-time delivery rates to reduce shipping delays.

Seller Dependency	                 Diversify the seller base by recruiting and supporting additional high-performing sellers to reduce reliance on a few top contributors.

Regional Dependency	                 Expand marketing and seller acquisition efforts in lower-performing regions to balance revenue distribution across states.

KPI Monitoring	                     Create an executive risk dashboard tracking revenue growth, review score, delivery performance,
                                     seller concentration, and regional concentration monthly.

Proactive Risk Management	         Set KPI thresholds (e.g., negative revenue growth, review score below 4.0, increasing delivery days) 
                                     to trigger early corrective actions before risks escalate.
*/


--Task 9 – Predictive KPI Dashboard

WITH

-- 1. Forecasted Revenue

MonthlyRevenue AS
(
    SELECT
        FORMAT(O.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,
        SUM(OP.payment_value) AS Revenue
    FROM Orders AS O
    JOIN Order_payments AS OP
        ON O.order_id = OP.order_id
    WHERE O.order_status='delivered'
    GROUP BY FORMAT(O.order_purchase_timestamp,'yyyy-MM')
),

RevenueForecast AS
(
    SELECT TOP 1
        AVG(Revenue*1.0) OVER(
            ORDER BY Sales_Month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS Forecasted_Revenue
    FROM MonthlyRevenue
    ORDER BY Sales_Month DESC
),

-- 2. High Churn Customers

CustomerChurn AS
(
    SELECT
        C.customer_unique_id,
        DATEDIFF(DAY,MAX(o.order_purchase_timestamp),
            (SELECT MAX(order_purchase_timestamp)
             FROM Orders)
        ) AS Days_Since_Last_Purchase,
        COUNT(DISTINCT O.order_id) AS Orders
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id=O.customer_id
    WHERE O.order_status='delivered'
    GROUP BY C.customer_unique_id
),
HighChurn AS
(
    SELECT COUNT(*) AS High_Churn_Customers
    FROM CustomerChurn
    WHERE Days_Since_Last_Purchase>180
          AND Orders=1
),

-- 3. Fastest Growing Category

CategoryGrowth AS
(
    SELECT
        PC.column2 AS Product_category,
        SUM(OP.payment_value) AS Revenue
    FROM Orders AS O
    JOIN Order_items AS OI
        ON O.order_id=OI.order_id
    JOIN Products AS P
        ON OI.product_id=P.product_id
    JOIN Order_payments AS OP
        ON O.order_id=OP.order_id
    JOIN Product_category AS PC
        ON P.product_category_name = PC.column1
    WHERE O.order_status='delivered'
    GROUP BY PC.column2
),
TopCategory AS
(
    SELECT TOP 1
        Product_category
    FROM CategoryGrowth
    ORDER BY Revenue DESC
),

-- 4. Highest CLV Segment

CustomerCLV AS
(
    SELECT
        C.customer_unique_id,
        SUM(OP.payment_value) AS Spend
    FROM Customers AS C
    JOIN Orders AS O
        ON C.customer_id=O.customer_id
    JOIN Order_payments AS OP
        ON O.order_id=OP.order_id
    WHERE O.order_status='delivered'
    GROUP BY C.customer_unique_id
),

CLVSegment AS
(
    SELECT TOP 1
        CASE
            WHEN Spend>=1000 THEN 'High Value'
            WHEN Spend>=500 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS Highest_CLV_Segment,
        COUNT(*) AS Customers
    FROM CustomerCLV
    GROUP BY
        CASE
            WHEN Spend>=1000 THEN 'High Value'
            WHEN Spend>=500 THEN 'Medium Value'
            ELSE 'Low Value'
        END
    ORDER BY Customers DESC
),

-- 5. Peak Sales Month

PeakMonth AS
(
    SELECT TOP 1
        DATENAME(MONTH,O.order_purchase_timestamp) AS Peak_Sales_Month,
        SUM(OP.payment_value) AS Revenue
    FROM Orders AS O
    JOIN Order_payments AS OP
        ON O.order_id=OP.order_id
    WHERE o.order_status='delivered'
    GROUP BY DATENAME(MONTH,order_purchase_timestamp)
    ORDER BY Revenue DESC
),

-- 6. Marketplace Risk

Risk AS
(
    SELECT
        CASE
            WHEN (SELECT COUNT(*) FROM HighChurn) > 10000
                THEN 'High'
            WHEN (SELECT COUNT(*) FROM HighChurn) > 5000
                THEN 'Medium'
            ELSE 'Low'
        END AS Marketplace_Risk_Level
)
SELECT
    ROUND(rf.Forecasted_Revenue,2) AS Forecasted_Revenue,
    HC.High_Churn_Customers,
    TC.Product_category AS Fastest_Growing_Category,
    CS.Highest_CLV_Segment,
    PM.Peak_Sales_Month,
    RK.Marketplace_Risk_Level
FROM RevenueForecast AS RF
CROSS JOIN HighChurn AS HC
CROSS JOIN TopCategory AS TC
CROSS JOIN CLVSegment AS CS
CROSS JOIN PeakMonth AS PM
CROSS JOIN Risk AS RK;

/* Business Recommendations
     KPI	                                              Recommendation
Forecasted Revenue	                 Use the forecast for budgeting, inventory planning, procurement, and workforce scheduling.

High Churn Customers	             Launch personalized win-back campaigns, loyalty rewards, and targeted email promotions for high-risk customers.

Fastest Growing Category	         Increase stock levels, onboard additional sellers, and allocate more marketing spend to capitalize on demand.

Highest CLV Segment	                 Prioritize retention of high-value customers through VIP benefits, exclusive offers, and personalized recommendations.

Peak Sales Month	                 Prepare inventory, logistics capacity, and marketing campaigns several weeks before the peak season to maximize sales.

Marketplace Risk Level	             Monitor revenue growth, customer satisfaction, delivery performance, seller concentration, and 
                                     regional dependency monthly to identify risks early and take proactive corrective actions.
*/