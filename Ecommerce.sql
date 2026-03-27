USE ecommerce;

-- 1. Weekday Vs Weekend (order_purchase_timestamp) Payment Statistics

SELECT CASE WHEN dayofweek(str_to_date(o.order_purchase_timestamp,'%Y-%m-%d'))
 IN (1,7) THEN 'WEEKEND' ELSE 'WEEKDAY'END AS DataType,
 COUNT(DISTINCT o.order_id) AS TotalOrders,
 ROUND(SUM(p.payment_value)) AS TotalPayments,
 ROUND(AVG(p.payment_value)) AS AveragePayment
FROM
  olist_orders o
JOIN
  olist_order_payments p ON o.order_id = p.order_id
GROUP BY
  DataType;
  
-- 2. Number of Orders with review score 5 and payment type as credit card.
SELECT 
    COUNT(DISTINCT o.order_id) AS high_rated_credit_card_orders
FROM olist_orders o
JOIN olist_review r ON o.order_id = r.order_id
JOIN olist_order_payments p ON o.order_id = p.order_id
WHERE r.review_score = 5
  AND p.payment_type = 'credit_card'
  AND o.order_status = 'delivered';
  
-- 3. Average number of days taken for order_delivered_customer_date for pet_shop
SELECT 
    ROUND(AVG(
        EXTRACT(DAY FROM (o.order_delivered_customer_date - o.order_purchase_timestamp))
    ), 2) AS avg_delivery_days_pet_shop
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
JOIN olist_products pd ON i.product_id = pd.product_id
JOIN product_category_name_translation t ON pd.product_category_name = t.product_category_name
WHERE t.product_category_name_english = 'pet_shop'
  AND o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;
  
-- 4. Average Price & Payment Values for São Paulo City Customers
SELECT 
    ROUND(AVG(p.payment_value), 2) AS avg_payment_value,
    ROUND(AVG(i.price), 2) AS avg_product_price
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id
JOIN olist_order_items i ON o.order_id = i.order_id
JOIN olist_order_payments p ON o.order_id = p.order_id
WHERE LOWER(c.customer_city) = 'sao paulo'
  AND o.order_status = 'delivered';
  
-- 5. Shipping Days vs Review Scores Relationship
SELECT 
    r.review_score,
    ROUND(AVG(
        DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)
    ), 2) AS shipping_days
FROM olist_orders o
JOIN olist_review r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score;

-- 6. Monthly Revenue & Order Growth
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01') AS order_month,
    COUNT(DISTINCT o.order_id) AS monthly_orders,
    ROUND(SUM(p.payment_value), 2) AS monthly_revenue,
    ROUND(
        (COUNT(DISTINCT o.order_id) - LAG(COUNT(DISTINCT o.order_id)) OVER (ORDER BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01'))) * 100.0 / 
        LAG(COUNT(DISTINCT o.order_id)) OVER (ORDER BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')), 2
    ) AS order_growth_percentage
FROM olist_orders o
JOIN olist_order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m-01')
ORDER BY order_month;

-- 7. Top 10 Product Categories by Revenue & Volume
SELECT 
    t.product_category_name_english AS category,
    COUNT(DISTINCT o.order_id) AS order_count,
    COUNT(i.order_item_id) AS item_count,
    ROUND(SUM(i.price), 2) AS total_product_revenue,
    ROUND(SUM(p.payment_value), 2) AS total_payment_revenue
FROM olist_orders o
JOIN olist_order_items i ON o.order_id = i.order_id
JOIN olist_products pd ON i.product_id = pd.product_id
JOIN product_category_name_translation t ON pd.product_category_name = t.product_category_name
JOIN olist_order_payments p ON o.order_id = p.order_id
LEFT JOIN olist_review r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_payment_revenue DESC
LIMIT 10;

-- 8. Payment Method Analysis & Performance
SELECT 
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value
FROM olist_orders o
JOIN olist_order_payments p ON o.order_id = p.order_id
LEFT JOIN olist_review r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY total_revenue DESC;

-- 9. State-wise Delivery Performance & Customer Satisfaction
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 2) AS avg_delivery_days,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_customers c
JOIN olist_orders o ON c.customer_id = o.customer_id
JOIN olist_order_payments p ON o.order_id = p.order_id
LEFT JOIN olist_review r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_review_score DESC, avg_delivery_days;

-- 10. Time of Day Order Analysis

SELECT CASE 
        WHEN HOUR(o.order_purchase_timestamp) BETWEEN 0 AND 5 THEN 'Night (00-06)'
        WHEN HOUR(o.order_purchase_timestamp) BETWEEN 6 AND 11 THEN 'Morning (06-12)'
        WHEN HOUR(o.order_purchase_timestamp) BETWEEN 12 AND 17 THEN 'Afternoon (12-18)'
        ELSE 'Evening (18-24)'
    END AS time_of_day,
    COUNT(DISTINCT o.order_id) AS order_count,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_order_value,
    ROUND(100.0 * COUNT(DISTINCT o.order_id) / SUM(COUNT(DISTINCT o.order_id)) OVER(), 2) AS order_percentage
FROM olist_orders o
JOIN olist_order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY time_of_day
ORDER BY total_revenue DESC;


