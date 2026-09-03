-- Customer Satisfaction KPI Dashboard

/*
SELECT

    GETDATE() AS Report_Date,

    -- Overall Average Review Score
    ROUND(
        AVG(review_score),
        2
    ) AS Average_Review_Score,


    -- 5 Star Review Rate
    ROUND(SUM(CASE WHEN review_score = 5
                THEN 1.0
                ELSE 0
              END) * 100.0 / COUNT(*), 2) AS Five_Star_Review_Rate,

    -- 1 Star Review Rate
    ROUND( SUM( CASE
                WHEN review_score = 1
                THEN 1.0
                ELSE 0
                END) * 100.0 / COUNT(*), 2 ) AS One_Star_Review_Rate,

    -- Average Delivery Days
 ROUND( AVG( DATEDIFF( DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)),2 ) AS Average_Delivery_Days,

    -- Late Delivery Rate
    ROUND(
        SUM( CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
                THEN 1.0
                ELSE 0
             END) * 100.0 /COUNT(*),2 ) AS Late_Delivery_Rate,

    -- Total Reviews
    COUNT(*) AS Total_Reviews

INTO Customer_Satisfaction_KPI_Summary
FROM Order_reviews r
JOIN Orders o
ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL;
*/

SELECT * 
FROM Customer_Satisfaction_KPI_Summary ;