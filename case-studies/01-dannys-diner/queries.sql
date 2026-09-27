-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id, SUM(m.price) AS total_amount
FROM dannys_diner.sales AS s 
JOIN dannys_diner.menu AS m 
ON s.product_id = m.product_id 
GROUP BY s.customer_id 
ORDER BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT
  customer_id, COUNT(DISTINCT order_date) as number_of_days
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT DISTINCT customer_id, product_name 
FROM (
  SELECT 
    s.customer_id, 
    m.product_name,
    dense_rank() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) as rank_number 
  FROM dannys_diner.sales AS s
  JOIN dannys_diner.menu AS m
  ON s.product_id = m.product_id
  ) AS t
 WHERE rank_number = 1
 ORDER BY customer_id;

-- 4. What is the most purchased item on t'he menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS times_purchased 
FROM dannys_diner.sales AS s 
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id 
GROUP BY m.product_name
ORDER BY times_purchased DESC 
LIMIT 1;

-- 5. Which item was the most popular for each customer?
SELECT 
  t.customer_id, 
 m.product_name, 
 t.times_purchased 
FROM (
	SELECT customer_id, product_id, 
  	count(*) AS times_purchased,
    rank() OVER(PARTITION BY customer_id ORDER BY count(*) DESC) AS ranking
    FROM dannys_diner.sales 
    GROUP BY customer_id, product_id
	) AS t 
JOIN dannys_diner.menu AS m 
ON t.product_id = m.product_id 
WHERE t.ranking = 1 
ORDER BY t.customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT t.customer_id, me.product_name FROM (
  SELECT m.customer_id, s.product_id, RANK() OVER(PARTITION BY m.customer_id ORDER BY s.order_date ASC) as ranking 
  FROM dannys_diner.members AS m 
  JOIN dannys_diner.sales AS s 
  ON m.customer_id = s.customer_id 
  WHERE m.join_date <= s.order_date
) AS t
JOIN dannys_diner.menu AS me 
ON t.product_id = me.product_id
WHERE ranking = 1
ORDER BY t.customer_id;

-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id, product_name 
FROM (
  SELECT m.customer_id, me.product_name,
  rank() OVER(PARTITION BY m.customer_id ORDER BY s.order_date DESC) AS ranking
  FROM dannys_diner.members AS m 
  JOIN dannys_diner.sales AS s 
  ON m.customer_id = s.customer_id
  JOIN dannys_diner.menu AS me 
  ON s.product_id = me.product_id 
WHERE m.join_date > s.order_date
) AS t
WHERE ranking = 1
ORDER BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT m.customer_id, count(*) AS total_items, sum(me.price) AS total_spent 
FROM dannys_diner.members AS m 
JOIN dannys_diner.sales AS s
ON m.customer_id = s.customer_id 
JOIN dannys_diner.menu AS me
ON s.product_id = me.product_id
WHERE m.join_date > s.order_date
GROUP BY m.customer_id
ORDER BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH points_table (product_id, points) AS (
  SELECT product_id, 
  CASE WHEN product_name = 'sushi' THEN (price * 2 * 10)
  ELSE (price * 1 * 10) END
  FROM dannys_diner.menu
) 
SELECT s.customer_id, SUM(pt.points) AS points 
FROM points_table AS pt
JOIN dannys_diner.sales AS s 
ON pt.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH menu_points AS (
  SELECT product_id,
         CASE WHEN product_name = 'sushi'
              THEN price * 2 * 10
              ELSE price * 1 * 10
         END AS points
  FROM dannys_diner.menu
)
SELECT customer_id, SUM(points) AS total_points
FROM (
  SELECT m.customer_id,
         CASE WHEN s.order_date BETWEEN m.join_date AND m.join_date + 6
              THEN mp.points * 2
              ELSE mp.points
         END AS points
  FROM dannys_diner.members AS m
  JOIN dannys_diner.sales  AS s  ON s.customer_id = m.customer_id
  JOIN menu_points         AS mp ON mp.product_id = s.product_id
  WHERE s.order_date < '2021-02-01'
) AS t
GROUP BY customer_id
ORDER BY customer_id;

