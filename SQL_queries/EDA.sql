-- Total rows in each table

select count(*) as total_customers from Customers;
select count(*) as total_orders from Orders;
select count(*) as total_sellers from Sellers;
select count(*) as total_order_items from Order_items;
select count(*) as total_payments from Order_payments;
select count(*) as total_reviews from Order_reviews;
select count(*) as total_products from Products;
select count(*) as total_product_category from Product_category;

-- Getting a sample batch
select top 10 * 
from customers;

select top 10 * 
from Geoloacation;

select top 10 * 
from Orders;

select top 10 * 
from Order_items;

select top 10 * 
from Order_reviews;

select top 10 * 
from Order_payments;

select top 10 * 
from Products;

select top 10 * 
from Sellers;

select top 10 * 
from Product_category;

-- Structure of the tables
exec sp_help Customers;

exec sp_help Orders;

exec sp_help Order_payments;

exec sp_help Order_items;

exec sp_help Order_reviews;

exec sp_help Products;

exec sp_help Sellers;

exec sp_help Product_category;

-- Finding wether there are Null values or not 
-- How many null values are there

--1 Geolocation table
select 
count(*) as total_rows,
sum(case when geolocation_lat is null then 1 else 0 end) as null_lat,
round( 100.0 * sum(case when geolocation_lat is null then 1 else 0 end)/count(*),2) as Percent_null_lat,
sum(case when geolocation_zip_code_prefix is null then 1 else 0 end) as null_zip_code,
sum(case when geolocation_lng is null then 1 else 0 end) as null_lng,
sum(case when geolocation_city is null then 1 else 0 end) as null_city,
sum(case when geolocation_state is null then 1 else 0 end) as null_state
from Geoloacation;

-- 2 Order_review table
select 
count(*) as total_rows,
sum(case when order_id is null then 1 else 0 end) as null_reviews,
sum(case when review_comment_title is null then 1 else 0 end) as null_comment_title,
round( 100.0 * sum(case when review_comment_title is null then 1 else 0 end)/count(*),2) as Percent_null_title,
sum(case when review_comment_message is null then 1 else 0 end) as null_comment_message,
round( 100.0 * sum(case when review_comment_message is null then 1 else 0 end)/count(*),2) as Percent_null_message
from Order_reviews
-- Observation 
-- All customer do not leave a written review , they prefer to give rating only

-- 3 Orders table
select 
count(*) as total_rows,
sum(case when  order_id is null then 1 else 0 end) as null_order_id,
sum(case when  order_delivered_carrier_date is null then 1 else 0 end) as null_carrier_date,
round( 100.0 * sum(case when order_delivered_carrier_date is null then 1 else 0 end)/count(*),2) as Percent_null_carrier_date,
sum(case when  order_delivered_customer_date is null then 1 else 0 end) as null_delivered_customer_date,
round( 100.0 * sum(case when order_delivered_customer_date is null then 1 else 0 end)/count(*),2) as Percent_null_customer_date
from Orders;
--Observation
-- Some orders were cancelled by the customers
-- And some orders were not delivered due to various reasons such as Logistics, Avalability, etc.


-- 4 Products table
select 
count(*) as total_rows,
sum(case when product_id is null then 1 else 0 end) as null_product_id,
sum(case when product_category_name is null then 1 else 0 end) as null_Product_category,
round( 100.0 * sum(case when product_category_name is null then 1 else 0 end)/count(*),2) as Percent_null_product_category_name,
sum(case when product_name_lenght is null then 1 else 0 end) as null_product_name,
round( 100.0 * sum(case when product_name_lenght is null then 1 else 0 end)/count(*),2) as Percent_null_name_length,
sum(case when product_description_lenght is null then 1 else 0 end) as null_product_description,
round( 100.0 * sum(case when product_description_lenght is null then 1 else 0 end)/count(*),2) as Percent_null_description_length,
sum(case when product_photos_qty is null then 1 else 0 end) as null_product_photos,
round( 100.0 * sum(case when product_photos_qty is null then 1 else 0 end)/count(*),2) as Percent_null_photos_qty,
sum(case when product_weight_g is null then 1 else 0 end) as null_productt_weight,
sum(case when product_length_cm is null then 1 else 0 end) as null_product_length,
sum(case when product_height_cm is null then 1 else 0 end) as null_product_height,
sum(case when product_width_cm is null then 1 else 0 end) as null_product_width
from Products;

-- 5 Sellers table
select 
count(*) as total_rows,
sum(case when seller_id is null then 1 else 0 end) as null_Seller_id,
sum(case when seller_zip_code_prefix is null then 1 else 0 end) as null_zip_code,
sum(case when seller_city is null then 1 else 0 end) as null_seller_city,
sum(case when seller_state is null then 1 else 0 end) as null_seller_state
from Sellers;


-- finding Number of duplicates

select 
customer_id,
count(*) as duplicates
from Customers
group by customer_id
having count(*) > 1;

select 
order_item_id,
count(*) as duplicates
from Order_items
group by order_item_id
having count(*) > 1;

select 
product_id,
count(*) as duplicates
from Products
group by product_id
having count(*) > 1;

select 
seller_id,
count(*) as duplicates
from Sellers
group by seller_id
having count(*) > 1;

-- Exploring Date Columns

select 
min(order_purchase_timestamp) as first_order,
max(order_purchase_timestamp) as last_order,
datediff( day ,min(order_purchase_timestamp) , max(order_purchase_timestamp)) as time_diff,
min(format(order_purchase_timestamp , 'yyyy-MM')) as first_month,
max(format(order_purchase_timestamp , 'yyyy-MM')) as last_month
from Orders;
-- Observations
-- First order was on date - 04|09|2016
-- Last order was on date - 17|10|2018
-- Time gap between first and last order is - 773 days ( 2 years approx.)

-- 
select 
year(order_purchase_timestamp) as year,
month(order_purchase_timestamp) as month,
count(*) as total_orders
from Orders
group by year(order_purchase_timestamp),
month(order_purchase_timestamp)
order by total_orders desc;
-- Observations
-- November 2017 has the most order placed in a single month

-- Exploring catagorical columns
-- 1 Order Status
select * from Orders;

select Order_status,
count(order_status) as total_orders
from Orders
group by order_status
order by total_orders desc;

-- 2 Payment Type
select * from Order_payments;

select payment_type,
count(payment_type) as total_payments
from Order_payments
group by payment_type
order by total_payments desc;
-- Observation 
-- Most of the cusotmers choose to pay with 'Credit Cards'

-- 3 Review Score
select * from Order_reviews;

select review_score,
count(review_score) as total_reviews
from Order_reviews
group by review_score
order by total_reviews desc;
-- Observations 
-- More than 60% of the customers give 5 star rating to the porducts they recieved

-- Customer State
select * from Customers;

select customer_state,
count(customer_state) as total_customers
from Customers
group by customer_state
order by total_customers desc;
-- Observations 
-- About 40% of the customers are from Sao Paulo state 


-- Exploring KPIs

select 
min(payment_value) as min_payment,
max(payment_value) as max_payment,
avg(payment_value) as avg_payment
from Order_payments;
-- Observations 
-- Maximum payment done is $13664
-- Minimum payment is $0
-- Average payment is $154


select 
min(payment_installments) as min_installments,
max(payment_installments) as max_installments,
avg(payment_installments) as avg_installments
from Order_payments;
-- Observations 
-- Maximum installments paid is - 24
-- Minimum installments paid is - 0
-- Average installments paid is - 2


select 
min(price) as min_price,
max(price) as max_price,
avg(price) as avg_price
from Order_items;
-- Observations 
-- Minimum price for any product is $.85
-- Maximum price for any product is $6735
-- Average price for any product is $120.65


select 
min(freight_value) as min_freight,
max(freight_value) as max_freight,
avg(freight_value) as avg_freight
from Order_items;
-- Observations 
-- Minimum freight value is - $0
-- Maximum freight value is - $409
-- Average freight value is - $20

select 
min(review_score) as min_score,
max(review_score) as max_score,
avg(review_score) as avg_score
from order_reviews;
-- Observations
-- Minimum review score is - 1
-- Maximum review score is - 5
-- Average review score is - 4


-- Detecting outliers

-- 1 Delivery time
select top 20
datediff(day,order_purchase_timestamp , order_delivered_customer_date)  as delivery_days
from  Orders
where order_delivered_customer_date is not null
order by delivery_days desc;
-- Observation 
-- The longest time taken to make a delivery is '210' days

select count(*) as late_deliveries
from Orders
where order_delivered_customer_date is not null
and datediff(day,order_purchase_timestamp , order_delivered_customer_date)  > 60
-- Observation 
-- 298 Orders were delivered late i.e. after 60 days of ordering


-- 2 Orders with most items
select
order_id,
count(*) as total_items
from Order_items
group by order_id
order by total_items desc;
-- Observations
-- Most number of items an order have is - 21

select top 20
seller_id,
sum(price) as revenue
from Order_items
group by seller_id
order by revenue DESC;
-- Observations
-- Revenue of the top seller is - $229472


-- Verifying refrential integirity
select count(*)
from Orders as O
full join Customers as C
on O.customer_id = C.customer_id
where C.customer_id is null;

select count(*)
from Orders as O
full join Order_payments as OP
on O.order_id = OP.order_id
where O.order_id is null;

select count(*)
from Orders as O
full join Order_reviews as ORe
on O.order_id = ORe.order_id
where O.order_id is null;

select count(*) 
from Products as P
full join Order_items as OI
on P.product_id = OI.product_id
where OI.product_id is null;

select count(*)
from Order_items as OI
full join Sellers as S
on OI.seller_id = S.seller_id
where S.seller_id is null


/*  Key Summary Tables

-- 1 Monthly sales summary
select
    format(O.order_purchase_timestamp, 'yyyy-MM') as sales_month,
    count(distinct O.order_id) as total_orders,
    count(distinct O.customer_id) as unique_customers,
    sum(OI.price) as revenue,
    sum(OI.freight_value) as freight_cost,
    avg(OI.price) as avg_order_value
into Fact_MonthlySales
from Orders as O
join Order_items as OI
    on O.order_id = OI.order_id
group by format(O.order_purchase_timestamp, 'yyyy-MM');*/

select * from Fact_MonthlySales;


-- 2 Customer summary
/*select
    C.customer_state,
    C.customer_city,
    count(distinct C.customer_id) as total_customers,
    count(distinct O.order_id) as total_orders
into Dim_CustomerSummary
from Customers as C
left join Orders as O
    on C.customer_id = O.customer_id
group by
    C.customer_state,
    C.customer_city;*/

select * from Dim_CustomerSummary;


-- 3 Seller summary
/*select
    S.seller_state,
    S.seller_city,
    count(distinct S.seller_id) as total_sellers,
    count(OI.order_id) as items_sold,
    sum(OI.price) as revenue,
    avg(OI.price) as avg_item_price
into Dim_SellerSummary
from Sellers as S
left join Order_items as OI
    on OI.seller_id = OI.seller_id
group by
    S.seller_state,
    S.seller_city;*/

select * from Dim_SellerSummary;


-- 4 Product category summary
/*select
    P.product_category_name,
    count(distinct P.product_id) as total_products,
    count(OI.order_id) as items_sold,
    sum(OI.price) as revenue,
    avg(OI.price) as avg_price
into Dim_CategorySummary
from Products as P
left join Order_items as OI
    on P.product_id = OI.product_id
group by
    P.product_category_name;*/

select * from Dim_CategorySummary;


-- 5 Delivery performance summary
/*select
    C.customer_state,
    count(*) as total_orders,
    avg(datediff(day,
        order_purchase_timestamp,
        order_delivered_customer_date)) as avg_delivery_days,
    max(datediff(day,
        order_purchase_timestamp,
        order_delivered_customer_date)) as longest_delivery
into Fact_DeliveryPerformance
from Orders as O
join Customers as C
    on O.customer_id = C.customer_id
where order_delivered_customer_date is not null
group by C.customer_state;*/

select * from Fact_DeliveryPerformance;


-- 6 Review summary
/*select
    review_score,
    count(*) as total_reviews
into Fact_ReviewSummary
from Order_reviews
group by review_score;*/

select * from Fact_ReviewSummary;

-- KPI summary
/*select
    (select count(distinct customer_id) from Customers) as Total_Customers,
    (select count(distinct seller_id) from Sellers) as Total_Sellers,
    (select count(*) from Orders) as Total_Orders,
    (select count(distinct product_id) from Products) as Total_Products,
    (select count(distinct product_category_name) from Products) as Total_Categories,
    (select avg(review_score) from Order_reviews) as Avg_review,
    (select sum(price) from  Order_items) as Total_Revenue,
    (select avg(price) from Order_items) as Avg_Item_Price
    into fact_KPIs;*/

select * from Fact_KPIs;
