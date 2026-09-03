/*
Logistics KPI Summary Table
*/
/*
SELECT

    GETDATE() AS Report_Date,

    ROUND(
        AVG(
            DATEDIFF(DAY,
                     order_purchase_timestamp,
                     order_delivered_customer_date)
        ),
        2
    ) AS Average_Delivery_Days,

    ROUND(
        SUM(
            CASE
                WHEN order_delivered_customer_date <= order_estimated_delivery_date
                THEN 1.0
                ELSE 0
            END
        ) * 100.0 /
        COUNT(*),
        2
    ) AS On_Time_Delivery_Rate,

    ROUND(
        SUM(
            CASE
                WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 1.0
                ELSE 0
            END
        ) * 100.0 /
        COUNT(*),
        2
    ) AS Late_Delivery_Rate,

    ROUND(
        AVG(
            DATEDIFF(DAY,
                     order_purchase_timestamp,
                     order_approved_at)
        ),
        2
    ) AS Average_Approval_Time,

    ROUND(
        AVG(
            DATEDIFF(DAY,
                     order_approved_at,
                     order_delivered_carrier_date)
        ),
        2
    ) AS Average_Shipping_Time,

    (
        SELECT
            ROUND(AVG(freight_value),2)
        FROM Order_items
    ) AS Average_Freight_Cost

INTO Logistics_KPI_Summary

FROM Orders

WHERE order_delivered_customer_date IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL;
*/

SELECT * 
FROM Logistics_KPI_Summary;