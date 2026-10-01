-- 1.1 Row count and NULL check on key columns
SELECT COUNT(*) AS total_rows FROM superstore_raw;

SELECT
    SUM(CASE WHEN order_id    IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_date  IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer,
    SUM(CASE WHEN sales       IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN profit      IS NULL THEN 1 ELSE 0 END) AS null_profit,
    SUM(CASE WHEN postal_code IS NULL THEN 1 ELSE 0 END) AS null_postal_code
FROM superstore_raw;

-- 1.2 Duplicate check (row_id should be unique)
SELECT row_id, COUNT(*) AS cnt
FROM superstore_raw
GROUP BY row_id
HAVING COUNT(*) > 1;

-- 1.3 Create the clean table.
-- Dates arrive as text in DD-MM-YYYY (e.g. 31-07-2012). We rebuild them as YYYY-MM-DD so SQL date functions work.
DROP TABLE IF EXISTS superstore;

CREATE TABLE superstore AS
SELECT
    row_id,
    order_id,
    date(substr(order_date, 7, 4) || '-' || substr(order_date, 4, 2) || '-' || substr(order_date, 1, 2)) AS order_date,
    date(substr(ship_date,  7, 4) || '-' || substr(ship_date,  4, 2) || '-' || substr(ship_date,  1, 2)) AS ship_date,
    ship_mode,
    customer_id,
    TRIM(customer_name) AS customer_name,
    segment,
    market,
    region,
    country,
    state,
    city,
    product_id,
    category,
    sub_category,
    product_name,
    ROUND(sales, 2)  AS sales,
    quantity,
    discount,
    ROUND(profit, 2) AS profit,
    ROUND(shipping_cost, 2) AS shipping_cost,
    order_priority
FROM superstore_raw
WHERE order_id IS NOT NULL
  AND sales IS NOT NULL;

-- 1.4 Sanity checks on the clean table
SELECT MIN(order_date) AS first_order, MAX(order_date) AS last_order FROM superstore;

SELECT COUNT(*) AS ship_before_order FROM superstore WHERE ship_date < order_date;   -- expect 0
SELECT COUNT(*) AS bad_dates         FROM superstore WHERE order_date IS NULL;        -- expect 0
SELECT COUNT(*) AS negative_sales    FROM superstore WHERE sales < 0;                 -- expect 0



-- PART 2: BUSINESS ANALYSIS

-- Q1. Overall KPIs
SELECT
    ROUND(SUM(sales), 2)                            AS total_revenue,
    ROUND(SUM(profit), 2)                           AS total_profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 2)      AS profit_margin_pct,
    COUNT(DISTINCT order_id)                        AS total_orders,
    COUNT(DISTINCT customer_id)                     AS total_customers,
    ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM superstore;

-- Q2. Revenue and profit by year
SELECT
    strftime('%Y', order_date)                 AS year,
    ROUND(SUM(sales), 2)                       AS revenue,
    ROUND(SUM(profit), 2)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore
GROUP BY 1
ORDER BY 1;

-- Q3. Month-over-month revenue growth (CTE + LAG window function)
WITH monthly AS (
    SELECT strftime('%Y-%m', order_date) AS month, SUM(sales) AS revenue
    FROM superstore
    GROUP BY 1
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS prev_month_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
          / LAG(revenue) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Q4. Profit by category and sub-category (find the weak spots)
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2)                       AS revenue,
    ROUND(SUM(profit), 2)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore
GROUP BY category, sub_category
ORDER BY margin_pct ASC;

-- Q5. Performance by market
SELECT
    market,
    ROUND(SUM(sales), 2)                       AS revenue,
    ROUND(SUM(profit), 2)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct,
    COUNT(DISTINCT order_id)                   AS orders
FROM superstore
GROUP BY market
ORDER BY profit DESC;

-- Q6. KEY INSIGHT: Does discounting destroy profit?
SELECT
    CASE
        WHEN discount = 0     THEN '1. No discount'
        WHEN discount <= 0.10 THEN '2. 1-10%'
        WHEN discount <= 0.20 THEN '3. 11-20%'
        WHEN discount <= 0.30 THEN '4. 21-30%'
        WHEN discount <= 0.50 THEN '5. 31-50%'
        ELSE                       '6. Over 50%'
    END AS discount_band,
    COUNT(*)                                   AS order_lines,
    ROUND(SUM(sales), 2)                       AS revenue,
    ROUND(SUM(profit), 2)                      AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore
GROUP BY 1
ORDER BY 1;

-- Q7. Loss-making order lines by category
SELECT
    category,
    COUNT(*)                      AS loss_making_lines,
    ROUND(SUM(profit), 2)         AS total_loss,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct
FROM superstore
WHERE profit < 0
GROUP BY category
ORDER BY total_loss ASC;

-- Q8. Customer segment performance
SELECT
    segment,
    COUNT(DISTINCT customer_id)                        AS customers,
    ROUND(SUM(sales), 2)                               AS revenue,
    ROUND(SUM(profit), 2)                              AS profit,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM superstore
GROUP BY segment
ORDER BY revenue DESC;

-- Q9. Top 10 products by revenue
SELECT product_name, ROUND(SUM(sales), 2) AS revenue, ROUND(SUM(profit), 2) AS profit
FROM superstore
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10;

-- Q10. Bottom 10 products by profit (products losing money)
SELECT product_name, ROUND(SUM(profit), 2) AS profit, ROUND(SUM(sales), 2) AS revenue
FROM superstore
GROUP BY product_name
ORDER BY profit ASC
LIMIT 10;

-- Q11. Top 3 products in each category (RANK window function)
WITH product_profit AS (
    SELECT category, product_name, SUM(profit) AS profit
    FROM superstore
    GROUP BY category, product_name
)
SELECT *
FROM (
    SELECT
        category,
        product_name,
        ROUND(profit, 2) AS profit,
        RANK() OVER (PARTITION BY category ORDER BY profit DESC) AS rank_in_category
    FROM product_profit
) ranked
WHERE rank_in_category <= 3;

-- Q12. Customer concentration (Pareto): how much revenue do top customers drive?
WITH customer_rev AS (
    SELECT customer_id, SUM(sales) AS revenue
    FROM superstore
    GROUP BY customer_id
),
ranked AS (
    SELECT
        customer_id,
        revenue,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS running_revenue,
        SUM(revenue) OVER ()                      AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn,
        COUNT(*) OVER ()                          AS total_customers
    FROM customer_rev
)
SELECT
    ROUND(100.0 * rn / total_customers, 0)              AS top_pct_of_customers,
    ROUND(100.0 * running_revenue / total_revenue, 1)   AS cumulative_pct_of_revenue
FROM ranked
WHERE rn IN (
    CAST(total_customers * 0.10 AS INT),
    CAST(total_customers * 0.20 AS INT),
    CAST(total_customers * 0.50 AS INT)
);

-- Q13. Why is one market weak? Discount level vs margin by market
SELECT
    market,
    ROUND(AVG(discount) * 100, 1) AS avg_discount_pct,
    ROUND(100.0 * SUM(CASE WHEN discount > 0.20 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_lines_over_20_discount,
    ROUND(100.0 * SUM(profit) / SUM(sales), 2) AS margin_pct
FROM superstore
GROUP BY market
ORDER BY margin_pct ASC;

-- Q14. Shipping: average days to ship and shipping cost by ship mode
SELECT
    ship_mode,
    ROUND(AVG(julianday(ship_date) - julianday(order_date)), 1) AS avg_days_to_ship,
    ROUND(AVG(shipping_cost), 2)                                AS avg_shipping_cost,
    COUNT(DISTINCT order_id)                                    AS orders
FROM superstore
GROUP BY ship_mode
ORDER BY avg_days_to_ship;

-- Q15. Year-over-year revenue growth by category (CTE + LAG)
WITH yearly AS (
    SELECT category, strftime('%Y', order_date) AS year, SUM(sales) AS revenue
    FROM superstore
    GROUP BY 1, 2
)
SELECT
    category,
    year,
    ROUND(revenue, 2) AS revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (PARTITION BY category ORDER BY year))
          / LAG(revenue) OVER (PARTITION BY category ORDER BY year), 2) AS yoy_growth_pct
FROM yearly
ORDER BY category, year;



