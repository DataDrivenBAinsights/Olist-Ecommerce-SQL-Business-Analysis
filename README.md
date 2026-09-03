# Olist E-Commerce Marketplace — SQL Business Analysis

## Project Overview

This project explores the Olist Brazilian E-Commerce dataset to understand how an online marketplace is performing across sales, customers, products, sellers, logistics, and customer satisfaction.

The main goal was to take raw transactional data and turn it into useful business insights that could help management make better decisions around revenue growth, customer retention, seller performance, delivery operations, and marketplace expansion.

The analysis was carried out using SQL Server, with the results designed to support further visualization and dashboard development in Power BI.

## Business Problem

An e-commerce marketplace generates large amounts of data across different parts of the customer journey. Looking at individual transactions alone doesn't provide much insight into how the business is performing.

This analysis focuses on questions such as:

- How much revenue is the marketplace generating?
- Which products and categories perform best?
- Where does most of the revenue come from?
- How many customers return to make additional purchases?
- Which sellers are performing well?
- Are orders being delivered on time?
- Does delivery performance affect customer satisfaction?
- Which areas represent opportunities or risks for the marketplace?

## Dataset

The analysis uses the Olist Brazilian E-Commerce Public Dataset, which contains approximately 100,000 orders from a Brazilian online marketplace.

**Source:** [Brazilian E-Commerce Public Dataset by Olist — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

### Main Tables

| Table | Description |
|---|---|
| Orders | Order status and order lifecycle timestamps |
| Order_items | Products, sellers, prices, and freight |
| Order_payments | Payment methods and payment values |
| Order_reviews | Customer review scores |
| Customers | Customer information and location |
| Sellers | Seller information and location |
| Products | Product information and categories |
| Geolocation | Geographic information |
| Product_category_name_translation | Product category translations |

## Tools Used

- SQL Server
- SQL
- Excel/CSV for data handling
- GitHub for project documentation

## Data Preparation & Quality Checks

Checks included:

- Missing values
- Duplicate records
- Invalid dates
- Negative or unusual monetary values
- Missing relationships between tables
- Incorrect order timelines
- Delivery dates occurring before purchase dates
- Carrier pickup occurring before order approval
- Inconsistent order statuses

![Data Quality Checks](https://github.com/DataDrivenBAinsights/Olist-Ecommerce-SQL-Business-Analysis/blob/main/images/Data%20Quality%20Checks.png?raw=true)

**Business Question:** Is the underlying order, customer, product, and seller data reliable enough to base business decisions on?

**Insight:** Out of 17 checks, 15 passed with zero issues, confirming clean primary keys, valid monetary values, and intact table relationships. The one real failure — 1,359 orders where carrier pickup occurred *before* order approval — points to a data-entry or timestamp-logging issue in the order-approval workflow rather than a logistics failure, and should be flagged to the operations/engineering team. The "Missing Delivery Dates" flag (2,965 orders) is informational only, since this is expected for cancelled or undelivered orders.

## Business Analysis

### Sales Analysis

Key metrics:

- Total Revenue
- Total Orders
- Average Order Value
- Revenue by State
- Revenue by Product Category
- Revenue by Payment Method
- Monthly Revenue
- Revenue Growth

![Monthly Revenue Trend](https://github.com/DataDrivenBAinsights/Olist-Ecommerce-SQL-Business-Analysis/blob/main/images/Monthly%20Revenue%20Trend.png?raw=true)

**Business Question:** How has the marketplace's revenue and order volume grown month over month, and is that growth stable?

**Insight:** Revenue climbed from a handful of orders in late 2016 to a peak of roughly R$1.19M across 7,544 orders by November 2017, before growth flattened and became more volatile through 2018 (e.g., a sharp dip to just 16 orders/R$4,439 in September 2018, likely a data cutoff or reporting gap rather than a real sales crash). The business scaled quickly in its first year, but growth is no longer consistently accelerating — a signal to investigate what drove the 2017 surge and whether it can be replicated.

![State-wise Revenue Analysis](https://github.com/DataDrivenBAinsights/Olist-Ecommerce-SQL-Business-Analysis/blob/main/images/State%20wise%20Revenue%20Analysis.png?raw=true)

**Business Question:** Which states drive the most revenue, and how concentrated is that revenue geographically?

**Insight:** São Paulo (SP) alone contributes 37.47% of total revenue (R$5.99M), and together with Rio de Janeiro (13.39%) and Minas Gerais (11.7%), the top three states account for over 62% of all revenue. This is a meaningful geographic concentration risk — any disruption in SP's logistics or demand would materially hurt the whole marketplace, which supports the recommendation to expand seller/customer coverage in mid-tier states like RS, PR, and SC.

### Customer Analysis

Key metrics:

- Total Customers
- New Customers
- Repeat Customers
- Customer Revenue
- Average Customer Spend
- Customer Segments

![Customer Segmentation](https://github.com/DataDrivenBAinsights/Olist-Ecommerce-SQL-Business-Analysis/blob/main/images/Customer%20Segmentation.png?raw=true)

**Business Question:** How is the customer base segmented by value and loyalty, and where is the biggest retention opportunity?

**Insight:** "Lost Customers" (18,236) and "Others" (36,786) dominate the base, while only 1,599 customers are "Potential Loyalists" and 7,676 are "Champions." This mirrors the Executive KPI showing a 0% repeat-customer rate — the marketplace is almost entirely driven by one-time buyers, meaning nearly all revenue depends on continuously acquiring new customers rather than retaining existing ones. This is the single largest opportunity area in the whole analysis.

### Product Analysis

Key metrics:

- Product Revenue
- Order Volume
- Category Revenue
- Average Order Value
- Product Ratings
- Category Performance

![Product Analysis - Top 25 Categories](images/Product_Analysis_Top_25_.png)

**Business Question:** Which product categories generate the most revenue, and how do price, shipping cost, and order volume vary across them?

**Insight:** bed_bath_table (R$1.24M), health_beauty (R$1.44M) and sports_leisure (R$1.16M) are the clear revenue leaders, but they get there differently — health_beauty earns more per order (avg. price ~R$130) on fewer units, while bed_bath_table relies on higher volume (11,823 orders) at a lower average price (~R$92). Shipping costs stay fairly consistent (R$15–24) across most categories, so category profitability is driven more by price point and volume than by logistics cost.

### Seller Analysis

The analysis evaluates sellers based on:

- Revenue
- Order volume
- Customer ratings
- Delivery performance
- Revenue contribution

![Seller Analysis - Top 15 Sellers](images/Seller_Analysis_Top_15_.png)

**Business Question:** Which sellers contribute the most revenue, and how much does the marketplace depend on a small group of top performers?

**Insight:** The top seller alone generated R$229,472 in revenue from 1,156 orders, and the top 15 sellers collectively account for a large share of total marketplace revenue despite the platform having 2,970 total sellers. This heavy reliance on a small number of high-performing sellers is a seller-concentration risk — losing even one or two top sellers could create a noticeable revenue gap, reinforcing the recommendation to actively support and retain top-performing sellers while growing mid-tier seller performance.

### Logistics Analysis

Logistics KPIs:

- Average Delivery Days
- On-Time Delivery Rate
- Late Delivery Rate
- Average Approval Time
- Average Shipping Time
- Average Freight Cost

![Logistics KPI Summary](images/Logistics_KPI_Summary.png)

**Business Question:** How efficient is the delivery process, and what share of orders arrive late?

**Insight:** Average delivery takes 12 days with a 91.89% on-time delivery rate, leaving an 8.11% late-delivery rate. Order approval itself is fast (0 days average) and shipping preparation takes about 2 days, so the bulk of the 12-day cycle is transit/carrier time — meaning delivery-speed improvements should target carrier and last-mile logistics rather than internal order processing. Average freight cost sits at R$19.99 per order.

### Customer Satisfaction Analysis

Metrics analyzed:

- Average Review Score
- 5-Star Review Rate
- 1-Star Review Rate
- Reviews by Product Category
- Reviews by Seller
- Review Score vs Delivery Performance

![Customer Satisfaction KPIs](images/Customer_Satisfaction_KPIs.png)

**Business Question:** How satisfied are customers overall, and does that satisfaction line up with delivery performance?

**Insight:** The average review score is 4/5, with 59.22% of reviews being 5-star versus only 9.76% being 1-star — on the surface a healthy satisfaction picture. But this sits alongside a 7.99% late-delivery rate and 12-day average delivery time, and the Business Opportunities dashboard flags customer satisfaction (avg. review score 2.50 in its risk calculation) as the highest operational risk area — meaning satisfaction, while decent on average, is fragile and closely tied to delivery reliability.

## Executive KPI Dashboard

Executive KPIs:

- Total Revenue
- Total Orders
- Total Customers
- Average Order Value
- Total Sellers
- Total Products
- Average Review Score
- Average Delivery Days
- On-Time Delivery Rate
- Repeat Customer Rate

![Executive KPIs](images/Executive_KPIs.png)

**Business Question:** At a glance, how healthy is the overall business — revenue, scale, delivery, and retention?

**Insight:** The marketplace has generated R$19.88M in total revenue across 96,475 orders (avg. order value R$206.08), served by 2,970 sellers and 32,214 products, with a strong 92.17% on-time delivery rate and 4/5 average review. The one alarming figure is a 0.00% repeat-customer rate — confirming the Customer Segmentation finding that this business currently runs entirely on one-time purchases, making customer retention the top strategic priority.

### Monthly Business Performance

Tracks:

- Total Revenue
- Total Orders
- Total Customers
- Average Order Value
- Revenue Growth %
- Order Growth %

**Business Question:** How consistent is month-over-month growth in revenue and order count?

**Insight:** Growth is highly volatile month to month — e.g., +705,751% in Jan 2017 (from a near-zero base) down to swings like -26.49% in Dec 2017 and -10.99% in Feb 2018 — indicating the business has not yet reached a stable, predictable growth pattern and would benefit from smoothing demand through marketing calendars or promotions timed to historically weak months.

### Marketplace Health Score

The score combines:

| Component | Weight |
|---|---|
| Revenue Growth | 30% |
| Customer Satisfaction | 30% |
| On-Time Delivery | 20% |
| Repeat Customer Rate | 20% |

![Marketplace Health Score](images/Marketplace_Health.png)

**Business Question:** Combining growth, satisfaction, delivery, and retention into one score, how is overall marketplace health trending over time?

**Insight:** Health scores swing sharply — from "Needs Improvement" (24.32) in Sep 2016 up to "Excellent" (91.73–91.76) in early 2017, then settling into a steady "Average" band (roughly 53–77) through 2018. The early volatility reflects the tiny order base in the platform's first months, while the more recent "Average" plateau — driven mainly by inconsistent revenue growth and a flat 0% repeat-customer contribution — shows the business has stabilized operationally (on-time delivery holds near 91.6%) but hasn't yet found a lever to push overall health back into "Good"/"Excellent" territory.

## Business Opportunities & Decision Support

![Business Opportunities Dashboard](images/Business_Opportunities_Dashboard.png)

**Business Question:** Across every dimension of the business, what are the single best/worst performers and where is the biggest opportunity?

**Insight:** This dashboard consolidates the "best of" findings: SP leads in both expansion (highest revenue region) and overall state revenue; one seller (ID ending `b3b52b2`) stands out at R$249,640.70 in revenue; health_beauty is the top revenue category (R$1.44M) while cds_dvds_musicals earns the highest average rating (4.64); and kitchen_dining_laundry_garden_furniture shows an alarming -93.28% month-over-month revenue decline, flagging it for review. Most notably, "Customer Retention" is explicitly ranked the #1 business priority, driven by 93,099 one-time customers — the largest single opportunity in the dataset — while the lowest average review score (2.50) marks customer satisfaction as the highest operational risk.

![Business Decision Logic](images/Business_Descision_Logic.png)

**Business Question:** Based on the underlying analysis, which segment, category, seller, state, and region should management prioritize decisions around?

**Insight:** This summary distills the decision logic into a single row for quick reference: focus retention efforts on the Low Value customer segment, prioritize investment in bed_bath_table (best category by this cut) and the top seller (`...0b010ab`), concentrate expansion and operational focus on SP (best state and largest opportunity region), and use agro_industry_and_commerce as the benchmark for highest-rated category performance. It acts as a one-glance decision card for stakeholders who don't need the full underlying detail.

## Advanced Analysis

**Customer:**
- RFM segmentation
- Customer retention
- Customer churn risk
- Customer Lifetime Value

**Products:**
- Product portfolio analysis
- Category growth
- Demand trends
- Inventory planning

**Sellers:**
- Seller performance matrix
- Seller growth
- Revenue concentration
- Seller risk

**Geography:**
- State-level revenue
- Customer concentration
- Seller concentration
- Regional expansion opportunities

**Risk:**
- Revenue concentration
- Delivery delays
- Low customer satisfaction
- Seller dependency
- Declining business performance

## Key Business Insights

- A significant share of marketplace revenue comes from a relatively small number of states, creating a potential geographic dependency risk.
- Repeat purchasing represents an important opportunity. Improving retention can increase customer lifetime value and reduce reliance on continuously acquiring new customers.
- Delivery performance is closely connected to the customer experience. Late deliveries are more likely to result in lower review scores.
- Seller performance varies considerably across the marketplace.
- A relatively small number of categories contribute a substantial portion of marketplace revenue.

## Business Recommendations

- Focus retention campaigns on high-value and at-risk customers.
- Improve delivery reliability in regions with higher late-delivery rates.
- Monitor and support sellers with consistently poor ratings or delivery performance.
- Invest in high-performing product categories while reviewing weak categories.
- Expand seller coverage in regions with strong customer demand.
- Monitor revenue concentration to reduce dependence on a small number of states or sellers.
- Use customer reviews as an early indicator of product and operational problems.
- Track the Marketplace Health Score regularly.

## SQL Techniques Used

- SELECT / WHERE / GROUP BY
- JOINs
- CASE statements
- Aggregate functions
- Subqueries
- CTEs
- Window functions
- LAG / LEAD
- RANK / DENSE_RANK
- Date and time functions
- Conditional aggregation
- Data quality checks
- Customer segmentation
- KPI calculations

## Repository Structure

```
Olist-SQL-Business-Analysis/
├── README.md
├── images/
│   ├── Data_Quality_Checks.png
│   ├── Monthly_Revenue_Trend.png
│   ├── State_wise_Revenue_Analysis.png
│   ├── Customer_Segmentation.png
│   ├── Product_Analysis_Top_25_.png
│   ├── Seller_Analysis_Top_15_.png
│   ├── Logistics_KPI_Summary.png
│   ├── Customer_Satisfaction_KPIs.png
│   ├── Executive_KPIs.png
│   ├── Marketplace_Health.png
│   ├── Business_Opportunities_Dashboard.png
│   └── Business_Descision_Logic.png
├── data/
│   └── Olist Dataset
├── sql/
│   ├── EDA.sql
│   ├── Data_Quality.sql
│   ├── Sales_Analysis.sql
│   ├── Customer_Analysis.sql
│   ├── Product_Analysis.sql
│   ├── Seller_Analysis.sql
│   ├── Logistics_Analysis.sql
│   ├── Customer_Satisfaction.sql
│   ├── Executive_KPIs.sql
│   ├── Advanced_Analytics.sql
│   ├── Predictive_Analytics.sql
│   └── Business_Strategy.sql
└── outputs/
    └── Summary Tables
```

## What I Learned

- Breaking business problems into analytical questions
- Working with multiple related tables
- Performing data quality checks before analysis
- Building meaningful business KPIs
- Using SQL for customer and seller segmentation
- Applying window functions to business problems
- Connecting operational metrics with customer satisfaction
- Turning analysis into practical recommendations
- Presenting technical findings from a business perspective

## Future Improvements

- Build a fully interactive Power BI dashboard
- Add advanced DAX measures
- Develop a machine-learning churn model
- Improve revenue forecasting
- Build a more advanced Customer Lifetime Value model
- Automate KPI reporting
- Add statistical testing to investigate relationships between delivery performance and customer satisfaction

## Conclusion

This project demonstrates how an e-commerce dataset can be transformed into a structured business analysis using SQL.

The overall workflow was:

**Raw Data → Data Quality → SQL Analysis → KPIs → Insights → Recommendations**

## Author

**Lokesh**

Aspiring Business Analyst / Data Analyst

**Skills:** SQL • Data Analysis • Business Intelligence • KPI Development • Business Strategy
