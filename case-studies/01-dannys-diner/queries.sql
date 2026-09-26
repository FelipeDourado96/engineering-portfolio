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
SELECT * FROM (
  SELECT s.customer_id, m.product_name,
  dense_rank() over(partition by s.customer_id order by s.order_date ASC) as 				rank_number 
  FROM dannys_diner.sales as s
  JOIN dannys_diner.menu as m
  ON s.product_id = m.product_id
  ) as t
 where rank_number = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?


-- 5. Which item was the most popular for each customer?


-- 6. Which item was purchased first by the customer after they became a member?


-- 7. Which item was purchased just before the customer became a member?


-- 8. What is the total items and amount spent for each member before they became a member?


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?



