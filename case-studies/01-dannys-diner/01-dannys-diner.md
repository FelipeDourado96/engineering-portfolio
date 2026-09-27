# Case Study #1 — Danny's Diner

Source: [8 Week SQL Challenge — Case Study #1](https://8weeksqlchallenge.com/case-study-1/)
Database: PostgreSQL · Schema: `dannys_diner` (`sales`, `menu`, `members`)

Danny runs a small Japanese restaurant and has three months of sales data for three
customers. He wants to know how often they visit, what they spend, and whether his
loyalty program is worth keeping. The ten questions below answer that.

---

## 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT 
	s.customer_id, SUM(m.price) AS total_amount
FROM dannys_diner.sales AS s 
JOIN dannys_diner.menu AS m 
ON s.product_id = m.product_id 
GROUP BY s.customer_id 
ORDER BY customer_id;
```

| customer_id | total_spent |
| --- | --- |
| A | 76 |
| B | 74 |
| C | 36 |

A and B spend about twice what C does, on a similar number of items — C only ever
orders the cheapest dish.

---

## 2. How many days has each customer visited the restaurant?

```sql
SELECT customer_id,
       COUNT(DISTINCT order_date) AS number_of_days
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id;
```

| customer_id | number_of_days |
| --- | --- |
| A | 4 |
| B | 6 |
| C | 2 |

`COUNT(DISTINCT order_date)` rather than `COUNT(*)`: the question asks for days, not
orders. A bought two items on the same day, which is one visit, not two.

---

## 3. What was the first item from the menu purchased by each customer?

```sql
SELECT DISTINCT s.customer_id, m.product_name
FROM (
  SELECT customer_id, product_id,
         DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS rank_number
  FROM dannys_diner.sales
) AS s
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
WHERE s.rank_number = 1
ORDER BY s.customer_id;
```

| customer_id | product_name |
| --- | --- |
| A | sushi |
| A | curry |
| B | curry |
| C | ramen |

A appears twice on purpose. `order_date` is a `DATE` with no time component, so both
of A's first-day items tie for first place — the data cannot tell them apart.
`DENSE_RANK` keeps the tie visible; `ROW_NUMBER` would have picked an arbitrary winner
and hidden the fact that the question has no single answer for A.

`DISTINCT` is there because C ordered ramen twice on the same first day, which would
otherwise produce two identical rows.

---

## 4. What is the most purchased item on the menu, and how many times was it purchased by all customers?

```sql
SELECT m.product_name,
       COUNT(s.product_id) AS times_purchased
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY times_purchased DESC
LIMIT 1;
```

| product_name | times_purchased |
| --- | --- |
| ramen | 8 |

Ramen accounts for 8 of 15 total orders. `LIMIT 1` is safe here because I checked the
full distribution first (ramen 8, curry 4, sushi 3) — no tie at the top.

---

## 5. Which item was the most popular for each customer?

```sql
SELECT t.customer_id, m.product_name, t.times_purchased
FROM (
  SELECT customer_id, product_id,
         COUNT(*) AS times_purchased,
         RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS ranking
  FROM dannys_diner.sales
  GROUP BY customer_id, product_id
) AS t
JOIN dannys_diner.menu AS m ON t.product_id = m.product_id
WHERE t.ranking = 1
ORDER BY t.customer_id;
```

| customer_id | product_name | times_purchased |
| --- | --- | --- |
| A | ramen | 3 |
| B | sushi | 2 |
| B | curry | 2 |
| B | ramen | 2 |
| C | ramen | 3 |

B has three rows because B bought each item exactly twice — a genuine three-way tie,
not duplicated output. `RANK` is the right function here for the same reason as in
question 3: the tie is information, and collapsing it would misrepresent B as having a
favourite dish.

---

## 6. Which item was purchased first by the customer after they became a member?

```sql
SELECT t.customer_id, me.product_name
FROM (
  SELECT m.customer_id,
         s.product_id,
         RANK() OVER (PARTITION BY m.customer_id ORDER BY s.order_date ASC) AS ranking
  FROM dannys_diner.members AS m
  JOIN dannys_diner.sales AS s ON m.customer_id = s.customer_id
  WHERE m.join_date <= s.order_date
) AS t
JOIN dannys_diner.menu AS me ON t.product_id = me.product_id
WHERE ranking = 1
ORDER BY t.customer_id;
```

| customer_id | product_name |
| --- | --- |
| A | curry |
| B | sushi |

`<=` rather than `<`: a purchase made on the join date itself counts as being made
after joining. The filter runs before the window function, so the ranking covers only
post-membership purchases — which is the intent.

Only A and B appear because C never joined the program.

---

## 7. Which item was purchased just before the customer became a member?

```sql
SELECT customer_id, product_name
FROM (
  SELECT m.customer_id,
         me.product_name,
         RANK() OVER (PARTITION BY m.customer_id ORDER BY s.order_date DESC) AS ranking
  FROM dannys_diner.members AS m
  JOIN dannys_diner.sales AS s ON m.customer_id = s.customer_id
  JOIN dannys_diner.menu AS me ON s.product_id = me.product_id
  WHERE m.join_date > s.order_date
) AS t
WHERE ranking = 1
ORDER BY customer_id;
```

| customer_id | product_name |
| --- | --- |
| A | sushi |
| A | curry |
| B | sushi |

The mirror of question 6: `>` is now strict, because a purchase on the join date
belongs to the "after" side, and `ORDER BY ... DESC` brings the latest pre-membership
purchase to rank 1.

A has two rows again — sushi and curry were both bought on 2021-01-01, the last day
before A joined.

---

## 8. What is the total number of items and amount spent for each member before they became a member?

```sql
SELECT m.customer_id,
       COUNT(*) AS total_items,
       SUM(me.price) AS total_spent
FROM dannys_diner.members AS m
JOIN dannys_diner.sales AS s ON m.customer_id = s.customer_id
JOIN dannys_diner.menu AS me ON s.product_id = me.product_id
WHERE m.join_date > s.order_date
GROUP BY m.customer_id
ORDER BY m.customer_id;
```

| customer_id | total_items | total_spent |
| --- | --- | --- |
| A | 2 | 25 |
| B | 3 | 40 |

Same date boundary as question 7, so the two answers are consistent with each other.

---

## 9. If each $1 spent equates to 10 points, and sushi has a 2x points multiplier, how many points would each customer have?

```sql
WITH menu_points (product_id, points) AS (
  SELECT product_id,
         CASE WHEN product_name = 'sushi'
              THEN price * 2 * 10
              ELSE price * 1 * 10
         END
  FROM dannys_diner.menu
)
SELECT s.customer_id,
       SUM(mp.points) AS points
FROM menu_points AS mp
JOIN dannys_diner.sales AS s ON mp.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;
```

| customer_id | points |
| --- | --- |
| A | 860 |
| B | 940 |
| C | 360 |

I put the points rule in a CTE rather than inline so that the business rule lives in
one place, expressed as data. If marketing changes the promotion, one `CASE` branch
changes and the aggregation below is untouched.

The arithmetic is written as `price * 2 * 10` instead of `price * 20` so that the two
separate rules — 10 points per dollar, and a 2x multiplier for sushi — stay visible to
whoever reads this next.

**Validation:** re-running with the multiplier removed gives A 760, B 740, C 360.
C is unchanged, which is the expected result: C never bought sushi. If C had moved,
the `CASE` would have been matching the wrong rows.

---

## 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customers A and B have at the end of January?

```sql
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
```

| customer_id | total_points |
| --- | --- |
| A | 1370 |
| B | 1020 |

Three decisions worth stating.

**The bonus week is 7 days including the join date**, so it runs from `join_date` to
`join_date + 6`, not `+ 7`. A joined on 2021-01-07, so A's window closes on 2021-01-13.

**"End of January" is written as `< '2021-02-01'`, not `<= '2021-01-31'`.** Both are
correct for a `DATE` column, but the first stays correct if the column ever becomes a
timestamp. This matters: B has a purchase on 2021-02-01 that must be excluded.

**The multipliers stack.** The question does not say whether the first-week 2x replaces
the sushi 2x or compounds with it. I read them as two independent bonuses with
different origins — one from the product, one from the membership — so sushi bought
during the first week earns 4x. Under this reading B has **1020** points.

The alternative reading, in which the week bonus replaces the product bonus, gives B
**820**, which is the figure most published solutions report. That version:

```sql
SELECT m.customer_id,
       SUM(me.price * 10 *
           CASE WHEN s.order_date BETWEEN m.join_date AND m.join_date + 6 THEN 2
                WHEN me.product_name = 'sushi'                            THEN 2
                ELSE 1
           END) AS total_points
FROM dannys_diner.members AS m
JOIN dannys_diner.sales   AS s  ON s.customer_id = m.customer_id
JOIN dannys_diner.menu    AS me ON me.product_id = s.product_id
WHERE s.order_date < '2021-02-01'
GROUP BY m.customer_id
ORDER BY m.customer_id;
```

`CASE` evaluates its branches in order and stops at the first match, so the week
condition wins over the sushi condition without needing a subquery.

A scores 1370 under both readings, because A bought no sushi during the bonus week.
The two answers differ only for B.

---

## What the data says

Curry is the most expensive item on the menu ($15) and was ordered 4 times
in total, while ramen, at $12, is the most popular, with 8 orders. Ramen is
20% cheaper than curry and has twice as many orders.

Customers A and B are both regulars, but A spent $76 while B spent $74, 
a difference of only $2.

Customer C has yet to become a member, even though they bought 3 times in
less than a week.

---

## Notes

- All queries run on PostgreSQL.
- Where a question has a tie, the tie is returned rather than resolved arbitrarily.
  Questions 3, 5 and 7 each have one.