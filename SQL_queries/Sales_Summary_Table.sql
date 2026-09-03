

-- Sales Summary Report
/*
-- Drop table if it already exists
IF OBJECT_ID('Sales_Summary','U') IS NOT NULL
DROP TABLE Sales_Summary;

WITH PaymentSummary AS
(
    SELECT
        order_id,
        SUM(payment_value) AS Revenue,
        COUNT(*) AS Total_Payments
    FROM Order_payments
    GROUP BY order_id
),

ItemSummary AS
(
    SELECT
        order_id,
        COUNT(*) AS Total_Items_Sold
    FROM Order_items
    GROUP BY order_id
),

DeliverySummary AS
(
    SELECT
        order_id,
        DATEDIFF(DAY,
                 order_purchase_timestamp,
                 order_delivered_customer_date) AS Delivery_Days
    FROM Orders
    WHERE order_delivered_customer_date IS NOT NULL
)

SELECT

    FORMAT(o.order_purchase_timestamp,'yyyy-MM') AS Sales_Month,

    COUNT(DISTINCT o.order_id) AS Total_Orders,

    COUNT(DISTINCT c.customer_id) AS Unique_Customers,

    SUM(ps.Revenue) AS Revenue,

    ROUND(
        SUM(ps.Revenue)*1.0 /
        COUNT(DISTINCT o.order_id),2
    ) AS Avg_Order_Value,

    SUM(ISNULL(i.Total_Items_Sold,0)) AS Total_Items_Sold,

    SUM(ISNULL(ps.Total_Payments,0)) AS Total_Payments,

    COUNT(DISTINCT CASE
        WHEN o.order_status='delivered'
        THEN o.order_id END) AS Delivered_Orders,

    COUNT(DISTINCT CASE
        WHEN o.order_status='canceled'
        THEN o.order_id END) AS Cancelled_Orders,

    COUNT(DISTINCT CASE
        WHEN o.order_status='unavailable'
        THEN o.order_id END) AS Unavailable_Orders,

    ROUND(
        AVG(CAST(d.Delivery_Days AS FLOAT)),2
    ) AS Avg_Delivery_Days,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN o.order_status='delivered'
            THEN o.order_id END)
        *100.0 /
        COUNT(DISTINCT o.order_id),2
    ) AS Delivery_Success_Rate,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN o.order_status='canceled'
            THEN o.order_id END)
        *100.0 /
        COUNT(DISTINCT o.order_id),2
    ) AS Cancellation_Rate

INTO Sales_Summary

FROM Orders o

LEFT JOIN Customers c
ON o.customer_id=c.customer_id

LEFT JOIN PaymentSummary ps
ON o.order_id=ps.order_id

LEFT JOIN ItemSummary i
ON o.order_id=i.order_id

LEFT JOIN DeliverySummary d
ON o.order_id=d.order_id

GROUP BY FORMAT(o.order_purchase_timestamp,'yyyy-MM')

ORDER BY Sales_Month;

ALTER TABLE Sales_Summary
ADD Revenue_Growth_Percentage DECIMAL(10,2);

WITH RevenueCTE AS
(
    SELECT
        Sales_Month,
        Revenue,

        LAG(Revenue) OVER
        (
            ORDER BY Sales_Month
        ) AS Previous_Revenue

    FROM Sales_Summary
)

UPDATE SS

SET Revenue_Growth_Percentage =
CASE
    WHEN rc.Previous_Revenue IS NULL THEN NULL

    ELSE ROUND(
        ((RC.Revenue-RC.Previous_Revenue)
        *100.0)
        /RC.Previous_Revenue,2)
END

FROM Sales_Summary  AS SS

JOIN RevenueCTE AS RC
ON SS.Sales_Month=RC.Sales_Month;
*/

SELECT * 
FROM Sales_summary;