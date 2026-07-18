/*
项目名称：电商订单履约与销售运营分析
数据来源：Olist Brazilian E-Commerce Public Dataset
工具：MySQL 8.0

说明：
1. 文件路径按当前 Windows 环境设置为 D:/olist_project/data/。
2. 第 01—02 部分用于首次建库和导入；数据已导入后不要重复执行 TRUNCATE/LOAD DATA。
3. 第 03 部分以后为可重复运行的数据检查与业务分析。
4. 延迟口径统一为：实际送达日期晚于预计送达日期，即 DATEDIFF(...) > 0。
*/


/* ============================================================
   01. 建库与建表
   ============================================================ */

CREATE DATABASE IF NOT EXISTS olist_project
CHARACTER SET utf8mb4
COLLATE utf8mb4_0900_ai_ci;

USE olist_project;

CREATE TABLE IF NOT EXISTS product_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(32),
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS orders (
    order_id VARCHAR(32),
    customer_id VARCHAR(32),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

CREATE TABLE IF NOT EXISTS order_items (
    order_id VARCHAR(32),
    order_item_id INT,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2)
);

CREATE TABLE IF NOT EXISTS products (
    product_id VARCHAR(32),
    product_category_name VARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE IF NOT EXISTS payments (
    order_id VARCHAR(32),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(12, 2)
);

CREATE TABLE IF NOT EXISTS reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32),
    review_score INT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);


/* ============================================================
   02. CSV 快速导入
   仅在需要重新构建数据库时运行本部分
   ============================================================ */

SET GLOBAL local_infile = ON;

TRUNCATE TABLE product_category_name_translation;

LOAD DATA LOCAL INFILE
'D:/olist_project/data/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    product_category_name,
    @product_category_name_english
)
SET product_category_name_english =
    TRIM(TRAILING '\r' FROM @product_category_name_english);


TRUNCATE TABLE customers;

LOAD DATA LOCAL INFILE
'D:/olist_project/data/olist_customers_dataset.csv'
INTO TABLE customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    @customer_state
)
SET customer_state = TRIM(TRAILING '\r' FROM @customer_state);


TRUNCATE TABLE orders;

LOAD DATA LOCAL INFILE
'D:/olist_project/data/olist_orders_dataset.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    customer_id,
    order_status,
    @purchase_time,
    @approved_time,
    @carrier_time,
    @delivered_time,
    @estimated_time
)
SET
    order_purchase_timestamp = NULLIF(@purchase_time, ''),
    order_approved_at = NULLIF(@approved_time, ''),
    order_delivered_carrier_date = NULLIF(@carrier_time, ''),
    order_delivered_customer_date = NULLIF(@delivered_time, ''),
    order_estimated_delivery_date =
        NULLIF(TRIM(TRAILING '\r' FROM @estimated_time), '');


TRUNCATE TABLE order_items;

LOAD DATA LOCAL INFILE
'D:/olist_project/data/olist_order_items_dataset.csv'
INTO TABLE order_items
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    @shipping_limit_time,
    price,
    @freight_value
)
SET
    shipping_limit_date = NULLIF(@shipping_limit_time, ''),
    freight_value = NULLIF(TRIM(TRAILING '\r' FROM @freight_value), '');


TRUNCATE TABLE products;

LOAD DATA LOCAL INFILE
'D:/olist_project/data/olist_products_dataset.csv'
INTO TABLE products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    product_id,
    @category_name,
    @name_length,
    @description_length,
    @photos_qty,
    @weight_g,
    @length_cm,
    @height_cm,
    @width_cm
)
SET
    product_category_name = NULLIF(@category_name, ''),
    product_name_length = NULLIF(@name_length, ''),
    product_description_length = NULLIF(@description_length, ''),
    product_photos_qty = NULLIF(@photos_qty, ''),
    product_weight_g = NULLIF(@weight_g, ''),
    product_length_cm = NULLIF(@length_cm, ''),
    product_height_cm = NULLIF(@height_cm, ''),
    product_width_cm = NULLIF(TRIM(TRAILING '\r' FROM @width_cm), '');


TRUNCATE TABLE payments;

LOAD DATA LOCAL INFILE
'D:/olist_project/data/olist_order_payments_dataset.csv'
INTO TABLE payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    @payment_value
)
SET payment_value = NULLIF(TRIM(TRAILING '\r' FROM @payment_value), '');


TRUNCATE TABLE reviews;

LOAD DATA LOCAL INFILE
'D:/olist_project/data/olist_order_reviews_dataset.csv'
INTO TABLE reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    review_id,
    order_id,
    review_score,
    @review_comment_title,
    @review_comment_message,
    @creation_time,
    @answer_time
)
SET
    review_creation_date = NULLIF(@creation_time, ''),
    review_answer_timestamp =
        NULLIF(TRIM(TRAILING '\r' FROM @answer_time), '');


/* ============================================================
   03. 数据规模与质量检查
   ============================================================ */

SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews
UNION ALL
SELECT 'category_translation', COUNT(*)
FROM product_category_name_translation;

SELECT
    COUNT(*) AS product_rows,
    COUNT(DISTINCT product_id) AS unique_products,
    SUM(product_category_name IS NULL) AS missing_category
FROM products;

SELECT
    MIN(review_score) AS min_score,
    MAX(review_score) AS max_score,
    SUM(review_score NOT BETWEEN 1 AND 5) AS invalid_score_rows,
    SUM(review_id IS NULL) AS missing_review_id,
    SUM(order_id IS NULL) AS missing_order_id,
    SUM(review_creation_date IS NULL) AS missing_creation_date,
    SUM(review_answer_timestamp IS NULL) AS missing_answer_time
FROM reviews;

SELECT COUNT(*) AS multi_payment_orders
FROM (
    SELECT order_id
    FROM payments
    GROUP BY order_id
    HAVING COUNT(*) > 1
) t;


/* ============================================================
   04. 整体经营指标
   GMV 口径：已交付订单的商品金额，不含运费
   ============================================================ */

WITH order_level AS (
    SELECT
        o.order_id,
        o.order_status,
        c.customer_unique_id,
        SUM(oi.price) AS merchandise_amount,
        SUM(oi.freight_value) AS freight_amount
    FROM orders o
    LEFT JOIN customers c
        ON o.customer_id = c.customer_id
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.order_id,
        o.order_status,
        c.customer_unique_id
)
SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        AS delivered_orders,
    ROUND(
        SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS delivery_rate_pct,
    COUNT(DISTINCT CASE
        WHEN order_status = 'delivered' THEN customer_unique_id
    END) AS delivered_customers,
    ROUND(SUM(CASE
        WHEN order_status = 'delivered' THEN merchandise_amount ELSE 0
    END), 2) AS delivered_gmv,
    ROUND(
        SUM(CASE
            WHEN order_status = 'delivered' THEN merchandise_amount ELSE 0
        END)
        / COUNT(CASE
            WHEN order_status = 'delivered'
                 AND merchandise_amount IS NOT NULL
            THEN order_id
        END),
        2
    ) AS avg_order_value,
    ROUND(SUM(CASE
        WHEN order_status = 'delivered' THEN freight_amount ELSE 0
    END), 2) AS total_freight
FROM order_level;


/* ============================================================
   05. 月度趋势与 GMV 环比
   仅保留 2017-01 至 2018-08 的完整经营月份
   ============================================================ */

WITH order_level AS (
    SELECT
        o.order_id,
        o.order_purchase_timestamp,
        c.customer_unique_id,
        SUM(oi.price) AS merchandise_amount
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
    GROUP BY
        o.order_id,
        o.order_purchase_timestamp,
        c.customer_unique_id
),
monthly_sales AS (
    SELECT
        DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
        COUNT(*) AS order_count,
        COUNT(DISTINCT customer_unique_id) AS customer_count,
        ROUND(SUM(merchandise_amount), 2) AS gmv,
        ROUND(AVG(merchandise_amount), 2) AS avg_order_value
    FROM order_level
    GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
),
monthly_with_previous AS (
    SELECT
        *,
        LAG(gmv) OVER (ORDER BY order_month) AS previous_month_gmv
    FROM monthly_sales
)
SELECT
    order_month,
    order_count,
    customer_count,
    gmv,
    avg_order_value,
    ROUND(
        (gmv - previous_month_gmv) / previous_month_gmv * 100,
        2
    ) AS gmv_mom_pct
FROM monthly_with_previous
ORDER BY order_month;


/* ============================================================
   06. 整体履约表现
   延迟口径：实际送达日期晚于预计送达日期
   ============================================================ */

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(AVG(DATEDIFF(
        order_delivered_customer_date,
        order_purchase_timestamp
    )), 2) AS avg_delivery_days,
    SUM(CASE WHEN DATEDIFF(
        order_delivered_customer_date,
        order_estimated_delivery_date
    ) > 0 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        SUM(CASE WHEN DATEDIFF(
            order_delivered_customer_date,
            order_estimated_delivery_date
        ) > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100,
        2
    ) AS late_delivery_rate_pct,
    ROUND(AVG(CASE WHEN DATEDIFF(
        order_delivered_customer_date,
        order_estimated_delivery_date
    ) > 0 THEN DATEDIFF(
        order_delivered_customer_date,
        order_estimated_delivery_date
    ) END), 2) AS avg_late_days
FROM orders
WHERE order_status = 'delivered'
  AND order_purchase_timestamp IS NOT NULL
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


/* ============================================================
   07. 延迟天数与客户评分
   ============================================================ */

WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
),
delivery_review AS (
    SELECT
        o.order_id,
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) AS delay_days,
        r.avg_review_score
    FROM orders o
    JOIN review_by_order r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    CASE
        WHEN delay_days <= 0 THEN '0. On time'
        WHEN delay_days BETWEEN 1 AND 3 THEN '1. Late 1-3 days'
        WHEN delay_days BETWEEN 4 AND 7 THEN '2. Late 4-7 days'
        WHEN delay_days BETWEEN 8 AND 14 THEN '3. Late 8-14 days'
        ELSE '4. Late 15+ days'
    END AS delay_bucket,
    COUNT(*) AS reviewed_orders,
    ROUND(AVG(avg_review_score), 2) AS avg_review_score,
    ROUND(
        SUM(CASE WHEN avg_review_score <= 2 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS low_score_rate_pct
FROM delivery_review
GROUP BY CASE
    WHEN delay_days <= 0 THEN '0. On time'
    WHEN delay_days BETWEEN 1 AND 3 THEN '1. Late 1-3 days'
    WHEN delay_days BETWEEN 4 AND 7 THEN '2. Late 4-7 days'
    WHEN delay_days BETWEEN 8 AND 14 THEN '3. Late 8-14 days'
    ELSE '4. Late 15+ days'
END
ORDER BY delay_bucket;


/* ============================================================
   08. 品类履约优先级
   ============================================================ */

WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
),
order_category AS (
    SELECT DISTINCT
        o.order_id,
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS category_name,
        DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) AS delay_days,
        r.avg_review_score
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    LEFT JOIN review_by_order r
        ON o.order_id = r.order_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)
SELECT
    category_name,
    COUNT(*) AS delivered_orders,
    SUM(CASE WHEN delay_days > 0 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        SUM(CASE WHEN delay_days > 0 THEN 1 ELSE 0 END)
        / COUNT(*) * 100,
        2
    ) AS late_rate_pct,
    ROUND(AVG(CASE
        WHEN delay_days > 0 THEN avg_review_score
    END), 2) AS late_avg_review_score,
    ROUND(
        SUM(CASE
            WHEN delay_days > 0 AND avg_review_score <= 2 THEN 1 ELSE 0
        END)
        / NULLIF(COUNT(CASE
            WHEN delay_days > 0 AND avg_review_score IS NOT NULL
            THEN order_id
        END), 0) * 100,
        2
    ) AS late_low_score_rate_pct
FROM order_category
GROUP BY category_name
HAVING COUNT(*) >= 500
ORDER BY late_orders DESC
LIMIT 10;


/* ============================================================
   09. 地区履约优先级
   ============================================================ */

WITH review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
)
SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    SUM(CASE WHEN DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    ) > 0 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        SUM(CASE WHEN DATEDIFF(
            o.order_delivered_customer_date,
            o.order_estimated_delivery_date
        ) > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100,
        2
    ) AS late_rate_pct,
    ROUND(AVG(DATEDIFF(
        o.order_delivered_customer_date,
        o.order_purchase_timestamp
    )), 2) AS avg_delivery_days,
    ROUND(AVG(CASE WHEN DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    ) > 0 THEN r.avg_review_score END), 2) AS late_avg_review_score
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN review_by_order r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 500
ORDER BY late_orders DESC
LIMIT 10;


/* ============================================================
   10. Tableau 数据视图

   vw_order_dashboard：订单粒度，一行一个订单。
   vw_category_dashboard：订单-品类粒度，一行一个订单品类组合。
   ============================================================ */

DROP VIEW IF EXISTS vw_order_dashboard;

CREATE VIEW vw_order_dashboard AS
WITH item_by_order AS (
    SELECT
        order_id,
        COUNT(*) AS item_count,
        SUM(price) AS merchandise_amount,
        SUM(freight_value) AS freight_amount
    FROM order_items
    GROUP BY order_id
),
payment_by_order AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_amount
    FROM payments
    GROUP BY order_id
),
review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
)
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    DATE(o.order_purchase_timestamp) AS order_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN CASE
            WHEN DATEDIFF(
                o.order_delivered_customer_date,
                o.order_estimated_delivery_date
            ) > 0 THEN 'Late'
            ELSE 'On time'
        END
        ELSE NULL
    END AS delivery_status,
    DATEDIFF(
        o.order_delivered_customer_date,
        o.order_purchase_timestamp
    ) AS delivery_days,
    DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    ) AS delay_days,
    COALESCE(i.item_count, 0) AS item_count,
    COALESCE(i.merchandise_amount, 0) AS merchandise_amount,
    COALESCE(i.freight_amount, 0) AS freight_amount,
    COALESCE(p.payment_amount, 0) AS payment_amount,
    r.avg_review_score,
    CASE
        WHEN r.avg_review_score <= 2 THEN 1
        ELSE 0
    END AS low_score_flag
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
LEFT JOIN item_by_order i
    ON o.order_id = i.order_id
LEFT JOIN payment_by_order p
    ON o.order_id = p.order_id
LEFT JOIN review_by_order r
    ON o.order_id = r.order_id;


DROP VIEW IF EXISTS vw_category_dashboard;

CREATE VIEW vw_category_dashboard AS
WITH item_by_order_category AS (
    SELECT
        oi.order_id,
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS category_name,
        COUNT(*) AS category_item_count,
        SUM(oi.price) AS category_gmv,
        SUM(oi.freight_value) AS category_freight
    FROM order_items oi
    JOIN products p
        ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation t
        ON p.product_category_name = t.product_category_name
    GROUP BY
        oi.order_id,
        COALESCE(
            t.product_category_name_english,
            p.product_category_name,
            'unknown'
        )
),
review_by_order AS (
    SELECT
        order_id,
        AVG(review_score) AS avg_review_score
    FROM reviews
    GROUP BY order_id
)
SELECT
    o.order_id,
    c.customer_state,
    o.order_status,
    DATE(o.order_purchase_timestamp) AS order_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    i.category_name,
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN CASE
            WHEN DATEDIFF(
                o.order_delivered_customer_date,
                o.order_estimated_delivery_date
            ) > 0 THEN 'Late'
            ELSE 'On time'
        END
        ELSE NULL
    END AS delivery_status,
    DATEDIFF(
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date
    ) AS delay_days,
    i.category_item_count,
    i.category_gmv,
    i.category_freight,
    r.avg_review_score,
    CASE
        WHEN r.avg_review_score <= 2 THEN 1
        ELSE 0
    END AS low_score_flag
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN item_by_order_category i
    ON o.order_id = i.order_id
LEFT JOIN review_by_order r
    ON o.order_id = r.order_id;


/* 视图结果核对 */
SELECT
    COUNT(*) AS view_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM vw_order_dashboard;

SELECT
    COUNT(*) AS view_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT category_name) AS category_count
FROM vw_category_dashboard;


/* ============================================================
   已验证的关键结果（用于结果核对，不作为硬编码计算依据）
   ============================================================

总订单量：99,441
已交付订单：96,478
已交付 GMV：13,221,498.11 BRL
客单价：137.04 BRL

可分析已交付订单：96,470
平均交付时长：12.50 天
延迟订单：6,534
延迟率：6.77%
延迟订单平均超期：10.62 天

月度 GMV 峰值：2017-11，987,765.37 BRL，环比 +52.37%
重点品类：bed_bath_table、health_beauty
重点地区：RJ、BA、CE
*/
