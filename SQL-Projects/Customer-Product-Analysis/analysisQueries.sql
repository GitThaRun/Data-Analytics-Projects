USE customer_product_analysis;

-- 1. Customer segmentation by completed-order spending
WITH customer_spending AS (
    SELECT c.customer_id, c.customer_name,
           COUNT(DISTINCT o.order_id) AS completed_orders,
           COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS total_spending
    FROM customers c
    LEFT JOIN orders o
      ON o.customer_id = c.customer_id AND o.status = 'Completed'
    LEFT JOIN order_items oi ON oi.order_id = o.order_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT customer_id, customer_name, completed_orders, total_spending,
       CASE WHEN total_spending >= 2500 THEN 'High Value'
            WHEN total_spending >= 500 THEN 'Medium Value'
            ELSE 'Low Value' END AS customer_segment
FROM customer_spending
ORDER BY total_spending DESC;

-- 2. Customer cohorts: activity month relative to first completed purchase
WITH first_purchase AS (
    SELECT customer_id, MIN(order_date) AS first_purchase_date,
           DATE_FORMAT(MIN(order_date), '%Y-%m-01') AS cohort_month
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT DISTINCT fp.customer_id, fp.cohort_month,
           TIMESTAMPDIFF(
               MONTH,
               CAST(fp.cohort_month AS DATE),
               CAST(DATE_FORMAT(o.order_date, '%Y-%m-01') AS DATE)
           ) AS months_since_first_purchase
    FROM first_purchase fp
    JOIN orders o ON o.customer_id = fp.customer_id
    WHERE o.status = 'Completed'
      AND o.order_date >= fp.first_purchase_date
)
SELECT cohort_month, months_since_first_purchase,
       COUNT(DISTINCT customer_id) AS active_customers
FROM cohort_activity
GROUP BY cohort_month, months_since_first_purchase
ORDER BY cohort_month, months_since_first_purchase;

-- 3. Repeat customer rate among customers with >= 1 completed order
WITH customer_order_counts AS (
    SELECT customer_id, COUNT(*) AS completed_orders
    FROM orders
    WHERE status = 'Completed'
    GROUP BY customer_id
)
SELECT COUNT(*) AS customers_with_completed_orders,
       SUM(completed_orders >= 2) AS repeat_customers,
       ROUND(100.0 * SUM(completed_orders >= 2) / COUNT(*), 2)
           AS repeat_customer_rate_percentage
FROM customer_order_counts;

-- 4. Top 10 products by completed-order revenue
SELECT p.product_id, p.product_name,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- 5. Top 10 products by completed-order quantity
SELECT p.product_id, p.product_name,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC, total_revenue DESC
LIMIT 10;

-- 6. Monthly revenue from completed orders
SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS monthly_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY sales_month;

-- 7. Month-over-month comparison for months with completed sales
WITH monthly_sales AS (
    SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'Completed'
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
),
comparison AS (
    SELECT sales_month, revenue,
           LAG(revenue) OVER (ORDER BY sales_month) AS previous_month_revenue
    FROM monthly_sales
)
SELECT sales_month, ROUND(revenue, 2) AS revenue,
       ROUND(previous_month_revenue, 2) AS previous_month_revenue,
       ROUND(revenue - previous_month_revenue, 2) AS revenue_change,
       ROUND(100 * (revenue - previous_month_revenue)
             / NULLIF(previous_month_revenue, 0), 2) AS growth_percentage
FROM comparison
ORDER BY sales_month;

-- 8. Rank products by revenue
WITH product_revenue AS (
    SELECT p.product_id, p.product_name,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM products p
    JOIN order_items oi ON oi.product_id = p.product_id
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY p.product_id, p.product_name
)
SELECT product_id, product_name, ROUND(revenue, 2) AS revenue,
       DENSE_RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
FROM product_revenue
ORDER BY revenue_rank, product_name;

-- 9. Customer first completed purchase
SELECT c.customer_id, c.customer_name,
       MIN(o.order_date) AS first_completed_purchase
FROM customers c
LEFT JOIN orders o
  ON o.customer_id = c.customer_id AND o.status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY first_completed_purchase;

-- 10. Revenue by category
SELECT p.category,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 11. Customers with no completed orders
SELECT c.customer_id, c.customer_name
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
      AND o.status = 'Completed'
);

-- 12. Order status summary
SELECT status, COUNT(*) AS total_orders
FROM orders
GROUP BY status
ORDER BY total_orders DESC;

