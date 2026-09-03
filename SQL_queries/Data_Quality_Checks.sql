-- Data Quality Report


IF OBJECT_ID('Data_Quality_Report', 'U') IS NOT NULL
    DROP TABLE Data_Quality_Report;

CREATE TABLE Data_Quality_Report
(
    Check_Name VARCHAR(100),
    Table_Name VARCHAR(50),
    Total_Issues INT,
    Status VARCHAR(10),
    Recommendation VARCHAR(200)
);

-- 1 inserting dupicatae primary keys( if any)

-- From Customers
INSERT INTO Data_Quality_Report
SELECT
'Duplicate Customer IDs',
'Customers',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Customer ID should be unique'
FROM
(
    SELECT customer_id
    FROM Customers
    GROUP BY customer_id
    HAVING COUNT(*)>1
)d;

-- From Orders
INSERT INTO Data_Quality_Report
SELECT
'Duplicate Order IDs',
'Orders',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Order ID should be unique'
FROM
(
    SELECT order_id
    FROM Orders
    GROUP BY order_id
    HAVING COUNT(*)>1
)d;

-- From Products
INSERT INTO Data_Quality_Report
SELECT
'Duplicate Product IDs',
'Products',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Product ID should be unique'
FROM
(
    SELECT product_id
    FROM Products
    GROUP BY product_id
    HAVING COUNT(*)>1
)d;

-- Fron Sellers
INSERT INTO Data_Quality_Report
SELECT
'Duplicate Seller IDs',
'Sellers',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Seller ID should be unique'
FROM
(
    SELECT seller_id
    FROM Sellers
    GROUP BY seller_id
    HAVING COUNT(*)>1
)d;

-- Missing custimer id in orders
INSERT INTO Data_Quality_Report
SELECT
'Missing Customer IDs',
'Orders',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Every order must belong to a customer'
FROM Orders
WHERE customer_id IS NULL;

-- Missing delivery dates
INSERT INTO Data_Quality_Report
SELECT
'Missing Delivery Dates',
'Orders',
COUNT(*),
'INFO',
'Expected for cancelled or undelivered orders'
FROM Orders
WHERE order_delivered_customer_date IS NULL;


-- Negative values
-- 1 Payments
INSERT INTO Data_Quality_Report
SELECT
'Negative Payments',
'Order_Payments',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Payment value cannot be negative'
FROM Order_payments
WHERE payment_value<0;

-- 2 Product price
INSERT INTO Data_Quality_Report
SELECT
'Negative Product Price',
'Order_Items',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Price cannot be negative'
FROM Order_items
WHERE price<0;

-- 3 Freight value
INSERT INTO Data_Quality_Report
SELECT
'Negative Freight',
'Order_Items',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Freight value cannot be negative'
FROM Order_items
WHERE freight_value<0;


-- Invalid dates
-- Delivered before purchased
INSERT INTO Data_Quality_Report
SELECT
'Delivered Before Purchase',
'Orders',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Delivery date must be after purchase date'
FROM Orders
WHERE order_delivered_customer_date < order_purchase_timestamp;

-- Carrier Pickup Before Approval
INSERT INTO Data_Quality_Report
SELECT
'Carrier Pickup Before Approval',
'Orders',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Carrier pickup should occur after approval'
FROM Orders
WHERE order_delivered_carrier_date < order_approved_at;

-- Estimated Delivery Before Purchase
INSERT INTO Data_Quality_Report
SELECT
'Estimated Delivery Before Purchase',
'Orders',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Estimated delivery should be after purchase'
FROM Orders
WHERE order_estimated_delivery_date < order_purchase_timestamp;

-- Orphan records
-- Orders Without Customers
INSERT INTO Data_Quality_Report
SELECT
'Orphan Orders',
'Orders',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Every order should have a matching customer'
FROM Orders o
LEFT JOIN Customers c
ON o.customer_id=c.customer_id
WHERE c.customer_id IS NULL;
-- Order Items Without Orders

INSERT INTO Data_Quality_Report
SELECT
'Orphan Order Items',
'Order_Items',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Every order item should have a matching order'
FROM Order_items oi
LEFT JOIN Orders o
ON oi.order_id=o.order_id
WHERE o.order_id IS NULL;
-- Order Items Without Products

INSERT INTO Data_Quality_Report
SELECT
'Orphan Products',
'Order_Items',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Every order item should reference an existing product'
FROM Order_items oi
LEFT JOIN Products p
ON oi.product_id=p.product_id
WHERE p.product_id IS NULL;

-- Order Items Without Sellers
INSERT INTO Data_Quality_Report
SELECT
'Orphan Sellers',
'Order_Items',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Every order item should reference an existing seller'
FROM Order_items oi
LEFT JOIN Sellers s
ON oi.seller_id=s.seller_id
WHERE s.seller_id IS NULL;

-- Invalid order status
INSERT INTO Data_Quality_Report
SELECT
'Invalid Order Status',
'Orders',
COUNT(*),
CASE WHEN COUNT(*)=0 THEN 'PASS' ELSE 'FAIL' END,
'Order status should be one of the valid values'
FROM Orders
WHERE order_status NOT IN
(
'created',
'approved',
'invoiced',
'processing',
'shipped',
'delivered',
'unavailable',
'canceled'
);

--
SELECT *
FROM Data_Quality_Report
ORDER BY
CASE Status
    WHEN 'FAIL' THEN 1
    WHEN 'INFO' THEN 2
    ELSE 3
END,
Check_Name;

