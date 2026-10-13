# Customer & Product Analysis (SQL)

## Project Overview
A beginner SQL analytics project that examines customer purchasing behavior, repeat purchases, product performance, and monthly revenue.

**Data transparency:** This project uses synthetic, generated retail-style sample data. It does not represent transactions from a real company.

## Objectives
- Segment customers by completed-order spending.
- Group customers into cohorts by their first completed purchase month.
- Calculate the repeat-customer rate.
- Identify top products by revenue and quantity sold.
- Compare monthly revenue and calculate month-over-month change.
- Summarize revenue by product category and order status.

## Database Schema
Database: `customer_product_analysis`

| Table | Purpose |
|---|---|
| `customers` | Customer profile, city, and signup date |
| `products` | Product name, category, and listed price |
| `orders` | Order date, customer, and order status |
| `order_items` | Products, quantities, and transaction unit prices |

## SQL Concepts Demonstrated
- `INNER JOIN` and `LEFT JOIN`
- `GROUP BY`, `HAVING`, and aggregate functions
- Common Table Expressions (CTEs)
- `CASE` expressions
- Subqueries and `NOT EXISTS`
- Date functions and `TIMESTAMPDIFF`
- Window functions: `LAG()` and `DENSE_RANK()`

## Requirements
- MySQL 8.0 or later
- MySQL Workbench (or another MySQL client)
```

## Limitations
- The dataset is synthetic and intended for SQL practice.
- This is a SQL analysis project, not a production sales system.
- Results should not be presented as actual company performance.
