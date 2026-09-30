
-- ============================================================================================================
-- DATA CLEANING & PREPARATION
-- ============================================================================================================
UPDATE runner_orders
SET 
  pickup_time = CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END,
  distance = CASE WHEN distance LIKE '%null%' THEN NULL ELSE REGEXP_REPLACE(distance, '[^0-9.]', '', 'g') END,
  duration = CASE WHEN duration LIKE '%null%' THEN NULL ELSE REGEXP_REPLACE(duration, '[^0-9]', '', 'g') END,
  cancellation = CASE WHEN cancellation IN ('', 'null') THEN NULL ELSE cancellation END;

ALTER TABLE runner_orders 
  ALTER COLUMN pickup_time TYPE TIMESTAMP USING pickup_time::TIMESTAMP,
  ALTER COLUMN distance TYPE NUMERIC USING distance::NUMERIC,
  ALTER COLUMN duration TYPE INTEGER USING duration::INTEGER;

-- =============================================================================================================

-- A - Pizza Metrics:

-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS total_amount_of_pizzas FROM customer_orders;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS total_orders FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) AS successful_deliveries
FROM runner_orders
WHERE cancellation IS NULL OR cancellation IN ('null', '')
GROUP BY runner_id
ORDER BY runner_id;


-- 4. How many of each type of pizza was delivered?
SELECT co.pizza_id, COUNT(pizza_id) as amount_delivered
FROM runner_orders AS ru 
JOIN customer_orders AS co 
ON ru.order_id = co.order_id
WHERE cancellation IS NULL OR cancellation IN ('null', '')
GROUP BY pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, 
SUM(CASE WHEN pn.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS veg_count,
SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS meatlovers_count
FROM customer_orders AS co
JOIN pizza_names AS pn
ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT COUNT(co.order_id) AS max_amount_of_pizzas_delivered
FROM runner_orders AS ru
JOIN customer_orders AS co
ON ru.order_id = co.order_id
WHERE cancellation IS NULL OR cancellation IN('null', '')
GROUP BY co.order_id
ORDER BY COUNT(co.order_id) DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT co.customer_id, 
  SUM(CASE WHEN (co.exclusions IS NULL OR co.exclusions IN ('', 'null'))
       AND (co.extras IS NULL OR co.extras IN ('', 'null')) THEN 0 ELSE 1 END) AS at_least_1_change, 
  SUM(CASE WHEN (co.exclusions IS NULL OR co.exclusions IN ('', 'null'))
       AND (co.extras IS NULL OR co.extras IN ('', 'null')) THEN 1 ELSE 0 END) AS no_changes 
FROM customer_orders AS co 
JOIN runner_orders AS ru
ON co.order_id = ru.order_id 
WHERE ru.cancellation IS NULL OR ru.cancellation IN ('', 'null') 
GROUP BY co.customer_id
ORDER BY co.customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS amount_delivered 
FROM customer_orders co
JOIN runner_orders ru 
ON co.order_id = ru.order_id 
WHERE (ru.cancellation IS NULL OR ru.cancellation IN ('null', '')) AND 
(co.exclusions IS NOT NULL AND co.exclusions NOT IN ('null', '')) AND (co.extras IS NOT NULL AND co.extras NOT IN ('null', ''));

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT EXTRACT(HOUR FROM order_time) AS hour_of_the_day, COUNT(*) AS amount_ordered
FROM customer_orders
GROUP BY hour_of_the_day
ORDER BY hour_of_the_day;

-- 10. What was the volume of orders for each day of the week?
SELECT TO_CHAR(order_time, 'FMDay') AS day_of_the_week, COUNT(*) AS amount_ordered
FROM customer_orders
GROUP BY TO_CHAR(order_time, 'FMDay'), EXTRACT(DOW FROM order_time)
ORDER BY EXTRACT(DOW FROM order_time);



-- B - Runner and Customer Experience:

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT (registration_date - '2021-01-01')/7 + 1 AS registration_week, COUNT(*) AS runners_signed_up 
FROM runners
GROUP BY registration_week
ORDER BY registration_week;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT ru.runner_id, ROUND(AVG(EXTRACT(EPOCH FROM (ru.pickup_time - co.order_time)) / 60)::NUMERIC, 2) AS avg_pickup_minutes 
FROM runner_orders ru
JOIN customer_orders co
ON ru.order_id = co.order_id
GROUP BY ru.runner_id
ORDER BY ru.runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
WITH order_prep_time AS (
  SELECT 
    co.order_id, 
    COUNT(co.pizza_id) AS pizza_amount, 
    EXTRACT(EPOCH FROM (ru.pickup_time - co.order_time)) / 60 AS tempo_minutos
  FROM customer_orders AS co
  JOIN runner_orders AS ru
    ON co.order_id = ru.order_id
  GROUP BY co.order_id, ru.pickup_time, co.order_time
)
SELECT 
  pizza_amount, 
  ROUND(AVG(tempo_minutos)::NUMERIC, 2) AS avg_tempo_minutos
FROM order_prep_time
GROUP BY pizza_amount
ORDER BY pizza_amount;

-- 4. What was the average distance travelled for each customer?
WITH customer_orders_unique AS (
  SELECT DISTINCT customer_id, order_id
  FROM customer_orders
)
SELECT cou.customer_id, round(AVG(ru.distance), 2) AS avg_distance_km
FROM customer_orders_unique cou
JOIN runner_orders AS ru
ON cou.order_id = ru.order_id
WHERE ru.distance IS NOT NULL
GROUP BY customer_id
ORDER BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) AS max_duration_mins,
MIN(duration) AS min_duration_mins,
MAX(duration) - MIN(duration) AS difference_mins
FROM runner_orders;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, distance as distance_km, duration as duration_mins, 
ROUND(distance/(duration/60)::NUMERIC, 2) AS speed_km_per_hour
FROM runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id, order_id;

-- 7. What is the successful delivery percentage for each runner?
WITH runners_total_deliveries AS (
  SELECT runner_id, COUNT(*) AS total_deliveries
  FROM runner_orders
  GROUP BY runner_id
),
runners_successful_deliveries AS (
  SELECT runner_id, COUNT(*) AS successful_deliveries
  FROM runner_orders
  WHERE cancellation IS NULL
  GROUP BY runner_id
)
SELECT 
  rtd.runner_id, 
  ROUND((rsd.successful_deliveries * 100.0 / rtd.total_deliveries), 2) AS successful_percentage_rate
FROM runners_total_deliveries rtd
JOIN runners_successful_deliveries rsd
  ON rtd.runner_id = rsd.runner_id
ORDER BY rtd.runner_id;



-- C - Ingredient Optimisation:

-- 1. What are the standard ingredients for each pizza?
WITH new_pizza_recipes AS (
	SELECT pizza_id, REGEXP_SPLIT_TO_TABLE(toppings, ',\s*')::NUMERIC as topping_id
	FROM pizza_recipes
)
SELECT pn.pizza_name, STRING_AGG(pt.topping_name, ', ') AS toppings
FROM new_pizza_recipes npr
JOIN pizza_toppings pt
ON npr.topping_id = pt.topping_id
JOIN pizza_names as pn
ON npr.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 2. What was the most commonly added extra?
WITH extra_toppings AS (
SELECT order_id, REGEXP_SPLIT_TO_TABLE(extras, ',\s*')::NUMERIC as extras
FROM customer_orders
WHERE extras is not null and extras not in ('', 'null')
)
SELECT pt.topping_name, COUNT(et.extras) AS most_added_topping
FROM extra_toppings et
JOIN pizza_toppings as pt
ON et.extras = pt.topping_id
GROUP BY pt.topping_name
ORDER BY COUNT(et.extras) DESC
LIMIT 1;

-- 3. What was the most common exclusion?
WITH toppings_excluded AS (
SELECT order_id, REGEXP_SPLIT_TO_TABLE(exclusions, ',\s*')::NUMERIC as exclusions
FROM customer_orders
WHERE exclusions is not null and exclusions not in ('', 'null')
)
SELECT pt.topping_name, COUNT(et.exclusions) AS most_excluded_topping
FROM toppings_excluded et
JOIN pizza_toppings as pt
ON et.exclusions = pt.topping_id
GROUP BY pt.topping_name
ORDER BY COUNT(et.exclusions) DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

orders_base AS (
SELECT 
ROW_NUMBER() OVER () AS record_id, 
co.order_id, 
co.customer_id,
pn.pizza_name, 
co.exclusions, 
co.extras
FROM customer_orders AS co 
JOIN pizza_names AS pn 
ON co.pizza_id = pn.pizza_id
),

split_exclusions AS (
SELECT 
record_id, 
REGEXP_SPLIT_TO_TABLE(exclusions, ',\s*')::INTEGER AS topping_id
FROM orders_base 
WHERE exclusions IS NOT NULL AND exclusions NOT IN ('', 'null')
),
exclusions_summary AS (
SELECT 
se.record_id, 
CONCAT(' - Exclude ', STRING_AGG(pt.topping_name, ', ')) AS exclusion_text
FROM split_exclusions AS se
JOIN pizza_toppings AS pt 
ON se.topping_id = pt.topping_id
GROUP BY se.record_id
),

split_extras AS (
SELECT 
record_id, 
REGEXP_SPLIT_TO_TABLE(extras, ',\s*')::INTEGER AS topping_id
FROM orders_base 
WHERE extras IS NOT NULL AND extras NOT IN ('', 'null')
),
extras_summary AS (
SELECT 
st.record_id, 
CONCAT(' - Extra ', STRING_AGG(pt.topping_name, ', ')) AS extra_text
FROM split_extras AS st
JOIN pizza_toppings AS pt 
ON st.topping_id = pt.topping_id
GROUP BY st.record_id
)

SELECT 
ob.order_id,
ob.customer_id,
CONCAT(
ob.pizza_name, 
COALESCE(es.exclusion_text, ''), 
COALESCE(ex.extra_text, '')
) AS order_item
FROM orders_base AS ob
LEFT JOIN exclusions_summary AS es 
ON ob.record_id = es.record_id
LEFT JOIN extras_summary AS ex
ON ob.record_id = ex.record_id
ORDER BY ob.record_id;


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- Parte 1:
WITH orders_base AS (
SELECT co.order_id, co.customer_id, co.pizza_id, pn.pizza_name, co.exclusions, co.extras,
ROW_NUMBER() OVER() AS record_id
FROM customer_orders as co
JOIN pizza_names AS pn
ON co.pizza_id = pn.pizza_id
),
excluded_items AS (
SELECT ob.record_id, REGEXP_SPLIT_TO_TABLE(ob.exclusions, ',\s*')::INTEGER AS topping_id
FROM orders_base AS ob
WHERE exclusions IS NOT NULL AND exclusions NOT IN ('null', '')
),
added_items AS (
SELECT ob.record_id, REGEXP_SPLIT_TO_TABLE(ob.extras, ',\s*')::INTEGER AS topping_id
FROM orders_base AS ob
WHERE extras IS NOT NULL AND extras NOT IN ('null', '')
),
standard_items AS (
SELECT ob.record_id, 
REGEXP_SPLIT_TO_TABLE(pr.toppings, ',\s*')::INTEGER AS topping_id
FROM orders_base AS ob
JOIN pizza_recipes AS pr
ON ob.pizza_id = pr.pizza_id
),
all_pizza_toppings AS (
(
SELECT record_id, topping_id FROM standard_items 
EXCEPT 
SELECT record_id, topping_id FROM excluded_items
)
UNION ALL SELECT record_id, topping_id FROM added_items
),
toppings_labelled AS (
SELECT apt.record_id, pt.topping_name, 
CASE WHEN COUNT(*) > 1 THEN CONCAT(COUNT(*), 'x', pt.topping_name)
ELSE pt.topping_name END AS topping_label
FROM all_pizza_toppings AS apt
JOIN pizza_toppings AS pt
ON apt.topping_id = pt.topping_id
GROUP BY apt.record_id, pt.topping_name
)
SELECT ob.record_id, CONCAT(ob.pizza_name, ': ', STRING_AGG(tl.topping_label, ', ' ORDER BY tl.topping_name ASC)) AS ingredient_list 
FROM orders_base AS ob
JOIN toppings_labelled AS tl
ON ob.record_id = tl.record_id
GROUP BY ob.record_id, ob.pizza_name
ORDER BY record_id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
WITH orders_base AS (
SELECT co.order_id, co.customer_id, co.pizza_id, pn.pizza_name, co.exclusions, co.extras,
ROW_NUMBER() OVER() AS record_id
FROM customer_orders as co
JOIN pizza_names AS pn
ON co.pizza_id = pn.pizza_id
JOIN runner_orders as ro 
ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL OR cancellation IN ('null', '')
),
excluded_items AS (
SELECT ob.record_id, REGEXP_SPLIT_TO_TABLE(ob.exclusions, ',\s*')::INTEGER AS topping_id
FROM orders_base AS ob
WHERE exclusions IS NOT NULL AND exclusions NOT IN ('null', '')
),
added_items AS (
SELECT ob.record_id, REGEXP_SPLIT_TO_TABLE(ob.extras, ',\s*')::INTEGER AS topping_id
FROM orders_base AS ob
WHERE extras IS NOT NULL AND extras NOT IN ('null', '')
),
standard_items AS (
SELECT ob.record_id, 
REGEXP_SPLIT_TO_TABLE(pr.toppings, ',\s*')::INTEGER AS topping_id
FROM orders_base AS ob
JOIN pizza_recipes AS pr
ON ob.pizza_id = pr.pizza_id
),
all_pizza_toppings AS (
(
SELECT record_id, topping_id FROM standard_items 
EXCEPT 
SELECT record_id, topping_id FROM excluded_items
)
UNION ALL SELECT record_id, topping_id FROM added_items
),
toppings_count AS (
SELECT apt.record_id, pt.topping_name, 
COUNT(*) AS amount
FROM all_pizza_toppings AS apt
JOIN pizza_toppings AS pt
ON apt.topping_id = pt.topping_id
GROUP BY apt.record_id, pt.topping_name
)
SELECT tc.topping_name, SUM(tc.amount) as ct
FROM orders_base AS ob
JOIN toppings_count AS tc
ON ob.record_id = tc.record_id
GROUP BY tc.topping_name
ORDER BY SUM(tc.amount) DESC;



-- D - Pricing and Ratings:

-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
WITH pizza_price AS (
SELECT co.order_id, co.pizza_id, 
CASE WHEN co.pizza_id = 1 THEN 12
ELSE 10 END AS price
FROM runner_orders AS ro
JOIN customer_orders AS co
ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
)
SELECT CONCAT('$', SUM(price)) AS total
FROM pizza_price;

-- 2. What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
WITH pizza_price AS (
SELECT co.order_id AS order_id, co.pizza_id AS pizza_id, co.customer_id AS customer_id, co.extras AS extras, 
CASE WHEN co.pizza_id = 1 THEN 12
ELSE 10 END AS price
FROM runner_orders AS ro
JOIN customer_orders AS co
ON ro.order_id = co.order_id
WHERE ro.cancellation IS NULL OR ro.cancellation IN ('', 'null')
),
extra_items AS (
SELECT order_id, customer_id, pizza_id, 
REGEXP_SPLIT_TO_TABLE(extras, ',\s*')::INTEGER AS extras
FROM pizza_price
WHERE extras IS NOT NULL AND extras NOT IN ('null', '')
),
extras_price AS (
SELECT COUNT(extras) AS total_extras
FROM extra_items
),
pizzas AS (
SELECT SUM(pp.price) AS total
FROM pizza_price AS pp
)
SELECT ((SELECT total FROM pizzas) + (SELECT total_extras FROM extras_price)) AS total_amount;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  order_id INT PRIMARY KEY,
  runner_id INT,
  rating INT CHECK (rating BETWEEN 1 AND 5)
);
INSERT INTO runner_ratings (order_id, runner_id, rating) VALUES
  (1, 1, 5),
  (2, 1, 4),
  (3, 1, 5),
  (4, 2, 3),
  (5, 3, 4),
  (7, 2, 5),
  (8, 2, 4),
  (10, 1, 5);


-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  order_id INT PRIMARY KEY,
  runner_id INT,
  rating INT CHECK (rating BETWEEN 1 AND 5)
);
INSERT INTO runner_ratings (order_id, runner_id, rating) VALUES
  (1, 1, 5),
  (2, 1, 4),
  (3, 1, 5),
  (4, 2, 3),
  (5, 3, 4),
  (7, 2, 5),
  (8, 2, 4),
  (10, 1, 5);

WITH new_runner_orders AS (
SELECT order_id, runner_id, NULLIF(pickup_time, 'null')::TIMESTAMP AS pickup_time, NULLIF(REGEXP_REPLACE(distance, '[^0-9.]', '', 'g'), '')::FLOAT AS distance, NULLIF(REGEXP_REPLACE(duration, '[^0-9]', '', 'g'), '')::FLOAT AS duration, CASE WHEN cancellation IS NULL OR cancellation IN ('null', '') THEN NULL ELSE cancellation END AS cancellation FROM runner_orders
)

SELECT co.order_id, co.customer_id, nro.runner_id, rr.rating, co.order_time, nro.pickup_time, ROUND((EXTRACT(EPOCH FROM (nro.pickup_time - co.order_time)) / 60)::NUMERIC, 2) AS time_between_order_and_pickup, nro.duration, ROUND((nro.distance/(nro.duration/60))::NUMERIC, 2) AS average_speed, COUNT(*) AS total_number_of_pizzas
FROM customer_orders AS co
JOIN runner_ratings AS rr
ON co.order_id = rr.order_id
JOIN new_runner_orders AS nro
ON co.order_id = nro.order_id
GROUP BY co.order_id, co.customer_id, nro.runner_id, rr.rating, co.order_time, nro.pickup_time, nro.duration, nro.distance;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
WITH new_runner_orders AS (
SELECT ro.order_id AS order_id, co.customer_id AS customer_id, co.pizza_id AS pizza_id, ro.runner_id AS runner_id, NULLIF(ro.pickup_time, 'null')::TIMESTAMP AS pickup_time, NULLIF(REGEXP_REPLACE(ro.distance, '[^0-9.]', '', 'g'), '')::FLOAT AS distance, NULLIF(REGEXP_REPLACE(ro.duration, '[^0-9]', '', 'g'), '')::FLOAT AS duration, CASE WHEN ro.cancellation IS NULL OR ro.cancellation IN ('null', '') THEN NULL ELSE ro.cancellation END AS cancellation FROM runner_orders AS ro JOIN customer_orders AS co ON ro.order_id = co.order_id
),
payment AS (
SELECT nro.order_id, nro.customer_id, nro.runner_id, 
SUM(
CASE WHEN nro.pizza_id = 1 THEN 12
ELSE 10 END
) AS price, 
nro.distance,
(nro.distance * 0.3) as runners_payment
FROM new_runner_orders AS nro
WHERE cancellation IS NULL
GROUP BY nro.order_id, nro.customer_id, nro.runner_id, nro.distance
ORDER BY nro.order_id
)
SELECT CONCAT('$', ROUND((SUM(price) - SUM(runners_payment))::NUMERIC, 2)) AS total_amount_left
FROM payment



-- E - Bonus Questions:

-- If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?

-- Expanding the menu exposes a different weakness. pizza_recipes keeps a whole recipe in one comma-separated string, so adding the Supreme pizza means typing that list by hand and the database has no way to check that those topping ids actually exist. Storing one row per pizza-topping pair would remove both problems.

INSERT INTO pizza_names ("pizza_id", "pizza_name") VALUES (3, 'Supreme');

INSERT INTO pizza_recipes ("pizza_id", "toppings") VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');



-- Notes on the data design
-- The database was poorly designed. Several columns hold the wrong data type — distance and duration are stored as text with their units glued on, and missing values are written as the literal string 'null' instead of being left empty.
-- Problems like these make every interaction heavier than it needs to be. The data has to be cleaned before it can be read, and inserting or editing a row is just as awkward.
-- The tables should be rebuilt with the correct types from the start, so that future work on this database is simpler.