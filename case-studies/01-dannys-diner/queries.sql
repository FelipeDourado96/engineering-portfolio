-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
	s.customer_id, SUM(m.price) AS total_amount
FROM dannys_diner.sales AS s 
JOIN dannys_diner.menu AS m 
ON s.product_id = m.product_id 
GROUP BY s.customer_id 
ORDER BY customer_id;
