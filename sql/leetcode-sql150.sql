-- LeetCode Exercises - Basic Joins and Basic Aggregation Functions
-- https://leetcode.com/studyplan/top-sql-50/
-- Solved: 2026-09-19

--1378. Replace Employee ID With The Unique Identifier
-- Write a solution to show the unique ID of each user, If a user does not have a unique ID replace just show null.
-- Return the result table in any order.

SELECT u.unique_id, e.name
FROM EmployeeUNI AS u
RIGHT JOIN Employees AS e
ON u.id = e.id;


-- 1068. Product Sales Analysis I
-- Write a solution to report the product_name, year, and price for each sale_id in the Sales table.
-- Return the resulting table in any order.

SELECT p.product_name, s.year, s.price 
FROM Sales AS s 
LEFT JOIN Product AS p
ON s.product_id = p.product_id


-- 1581. Customer Who Visited but Did Not Make Any Transactions
-- Write a solution to find the IDs of the users who visited without making any transactions and the number of times they made these types of visits.
-- Return the result table sorted in any order.

SELECT customer_id, COUNT(customer_id) AS count_no_trans 
FROM Visits 
WHERE visit_id NOT IN (SELECT visit_id FROM Transactions) 
GROUP BY customer_id;


-- 197. Rising Temperature
-- Write a solution to find all dates' id with higher temperatures compared to its previous dates (yesterday).
-- Return the result table in any order.

SELECT id 
FROM (
    SELECT id, temperature, recordDate, 
    LAG(temperature) OVER (ORDER BY recordDate) AS temp_yest, 
    LAG(recordDate) OVER (ORDER BY recordDate) AS date_yest
    FROM Weather
    ) AS t
WHERE temperature > temp_yest 
AND DATEDIFF(recordDate, date_yest) = 1;


-- 1661. Average Time of Process per Machine
-- There is a factory website that has several machines each running the same number of processes. Write a solution to find the average time each machine takes to complete a process.
-- The time to complete a process is the 'end' timestamp minus the 'start' timestamp. The average time is calculated by the total time to complete every process on the machine divided by the number of processes that were run.
-- The resulting table should have the machine_id along with the average time as processing_time, which should be rounded to 3 decimal places.

SELECT e.machine_id, ROUND(AVG(e.timestamp - s.timestamp), 3) AS processing_time 
FROM Activity AS e 
JOIN Activity AS s ON e.machine_id = s.machine_id AND e.process_id = s.process_id AND e.activity_type = 'end' AND s.activity_type = 'start' 
GROUP BY e.machine_id;


-- 577. Employee Bonus
-- Write a solution to report the name and bonus amount of each employee who satisfies either of the following:
-- The employee has a bonus less than 1000.
-- The employee did not get any bonus.
-- Return the result table in any order.

SELECT e.name, b.bonus 
FROM Employee AS e 
LEFT JOIN Bonus AS b 
ON e.empId = b.empId 
WHERE b.bonus < 1000 OR b.bonus IS NULL;


-- 1280. Students and Examinations
-- Write a solution to find the number of times each student attended each exam.
-- Return the result table ordered by student_id and subject_name.

select st.student_id, st.student_name, su.subject_name,
count(e.student_id) as attended_exams
from students as st
cross join subjects as su
left join examinations as e
    on st.student_id = e.student_id
    and su.subject_name = e.subject_name
group by st.student_id, st.student_name, su.subject_name
order by st.student_id, st.student_name, su.subject_name


-- 570. Managers with at Least 5 Direct Reports
-- Write a solution to find managers with at least five direct reports.
-- Return the result table in any order.

SELECT e.name
FROM employee AS e
WHERE e.id IN (
    SELECT managerId
    FROM employee
    GROUP BY managerId
    HAVING count(managerID) >= 5
);


-- 1934. Confirmation Rate
-- The confirmation rate of a user is the number of 'confirmed' messages divided by the total number of requested confirmation messages. The confirmation rate of a user that did not request any confirmation messages is 0. Round the confirmation rate to two decimal places.
-- Write a solution to find the confirmation rate of each user.
-- Return the result table in any order.
SELECT s.user_id,
ROUND(AVG(CASE WHEN c.action = 'confirmed' THEN 1 ELSE 0 END), 2) AS confirmation_rate
FROM Confirmations AS c
RIGHT JOIN signups AS s ON c.user_id = s.user_id
GROUP BY user_id;

-- 620. Not Boring Movies
-- Write a solution to report the movies with an odd-numbered ID and a description that is not "boring".
-- Return the result table ordered by rating in descending order.

SELECT *
FROM cinema
WHERE id % 2 != 0 AND description != 'boring'
ORDER BY rating DESC;


-- 1251. Average Selling Price
-- Write a solution to find the average selling price for each product. average_price should be rounded to 2 decimal places. If a product does not have any sold units, its average selling price is assumed to be 0.
-- Return the result table in any order.

SELECT p.product_id, ROUND(SUM(p.price * u.units)/SUM(u.units), 2) AS average_price
FROM prices AS p
JOIN unitssold AS u
ON p.product_id = u.product_id
WHERE u.purchase_date BETWEEN p.start_date AND p.end_date
GROUP BY p.product_id;


-- 1075. Project Employees I
-- Write an SQL query that reports the average experience years of all the employees for each project, rounded to 2 digits.
-- Return the result table in any order.

SELECT p.project_id, ROUND(AVG(e.experience_years), 2) AS average_years 
FROM Project AS p
JOIN Employee AS e
ON p.employee_id = e.employee_id
GROUP BY p.project_id;


-- 1633. Percentage of Users Attended a Contest
-- Write a solution to find the percentage of the users registered in each contest rounded to two decimals.
-- Return the result table ordered by percentage in descending order. In case of a tie, order it by contest_id in ascending order.

SELECT r.contest_id, ROUND((COUNT(r.user_id)/(SELECT COUNT(*) FROM users) * 100), 2) AS percentage
FROM Users AS u
JOIN Register AS r
ON u.user_id = r.user_id
GROUP BY r.contest_id   
ORDER BY percentage DESC, contest_id ASC;


-- 1211. Queries Quality and Percentage
-- We define query quality as:
-- The average of the ratio between query rating and its position.
-- We also define poor query percentage as:
-- The percentage of all queries with rating less than 3.
-- Write a solution to find each query_name, the quality and poor_query_percentage.
-- Both quality and poor_query_percentage should be rounded to 2 decimal places.
-- Return the result table in any order.

SELECT query_name, 
ROUND(AVG(rating/position), 2) AS quality, 
ROUND(SUM(CASE WHEN rating < 3 THEN 1 ELSE 0 END)*100.0/COUNT(*), 2) AS poor_query_percentage 
FROM Queries
GROUP BY query_name;


-- 1193. Monthly Transactions I
-- Write a solution to find for each month and country, the number of transactions and their total amount, the number of approved transactions and their total amount.
-- Return the result table in any order.

SELECT DATE_FORMAT(trans_date, '%Y-%m') AS month, country, 
COUNT(*) AS trans_count, 
SUM(CASE WHEN state = 'approved' THEN 1 ELSE 0 END) AS approved_count, 
SUM(amount) AS trans_total_amount,
SUM(CASE WHEN state = 'approved' THEN amount ELSE 0 END) AS approved_total_amount
FROM transactions
GROUP BY DATE_FORMAT(trans_date, '%Y-%m'), country


-- 1174. Immediate Food Delivery II
-- If the customer's preferred delivery date is the same as the order date, then the order is called immediate; otherwise, it is called scheduled.
-- The first order of a customer is the order with the earliest order date that the customer made. It is guaranteed that a customer has precisely one first order.
-- Write a solution to find the percentage of immediate orders in the first orders of all customers, rounded to 2 decimal places.

SELECT ROUND(SUM(CASE WHEN order_date = customer_pref_delivery_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS immediate_percentage
FROM delivery
WHERE (customer_id, order_date) IN (
    SELECT customer_id, MIN(order_date)
    FROM delivery
    GROUP BY customer_id
);


-- 550. Game Play Analysis IV
-- Write a solution to report the fraction of players that logged in again on the day after the day they first logged in, rounded to 2 decimal places. In other words, you need to determine the number of players who logged in on the day immediately following their initial login, and divide it by the number of total players.

SELECT ROUND(COUNT(DISTINCT player_id) / (SELECT COUNT(DISTINCT player_id) AS total FROM activity), 2) AS fraction
FROM activity
WHERE (player_id, event_date) IN (SELECT player_id, DATE_ADD(MIN(event_date),INTERVAL 1 day) FROM activity GROUP BY player_id);


-- 2356. Number of Unique Subjects Taught by Each Teacher
-- Write a solution to calculate the number of unique subjects each teacher teaches in the university.

SELECT teacher_id, count(DISTINCT subject_id) AS cnt FROM teacher GROUP BY teacher_id;


-- 1141. User Activity for the Past 30 Days I
-- Write a solution to find the daily active user count for a period of 30 days ending 2019-07-27 inclusively. A user was active on someday if they made at least one activity on that day.
-- Return the result table in any order.
-- Note: Any activity from ('open_session', 'end_session', 'scroll_down', 'send_message') will be considered valid activity for a user to be considered active on a day.

SELECT activity_date AS day, COUNT(DISTINCT user_id) AS active_users
FROM activity
WHERE activity_date > DATE_SUB('2019-07-27', INTERVAL 30 DAY) AND activity_date <= '2019-07-27'
GROUP BY activity_date


-- 1070. Product Sales Analysis III
-- Write a solution to find all sales that occurred in the first year each product was sold.
-- For each product_id, identify the earliest year it appears in the Sales table.
-- Return all sales entries for that product in that year.
-- Return a table with the following columns: product_id, first_year, quantity, and price.

SELECT product_id, year AS first_year, quantity, price
FROM sales
WHERE (product_id, year) IN (
    SELECT product_id, MIN(year)
    FROM sales
    GROUP BY product_id
);


-- 596. Classes With at Least 5 Students
-- Write a solution to find all the classes that have at least five students.

SELECT class
FROM courses
GROUP BY class
HAVING COUNT(student) >= 5;


-- 1729. Find Followers Count
-- Write a solution that will, for each user, return the number of followers.

SELECT user_id, COUNT(follower_id) AS followers_count 
FROM followers 
GROUP BY user_id
ORDER BY user_id;   


-- 619. Biggest Single Number
-- A single number is a number that appeared only once in the MyNumbers table.
-- Find the largest single number. If there is no single number, report null.

SELECT MAX(num) AS num FROM MyNumbers WHERE num IN (
    SELECT num FROM MyNumbers GROUP BY num HAVING COUNT(*) = 1
)


-- 1045. Customers Who Bought All Products
-- Write a solution to report the customer ids from the Customer table that bought all the products in the Product table.

SELECT customer_id
FROM Customer
GROUP BY customer_id
HAVING COUNT(DISTINCT product_key) = (SELECT COUNT(*) FROM Product);


-- 1978. Employees Whose Manager Left the Company
-- Find the IDs of the employees whose salary is strictly less than $30000 and whose manager left the company. When a manager leaves the company, their information is deleted from the Employees table, but the reports still have their manager_id set to the manager that left.
-- Return the result table ordered by employee_id.

SELECT employee_id
FROM Employees
WHERE salary < 30000 AND manager_id NOT IN (SELECT employee_id FROM Employees)
ORDER BY employee_id;


-- 626. Exchange Seats
-- Write a solution to swap the seat id of every two consecutive students. If the number of students is odd, the id of the last student is not swapped.
-- Return the result table ordered by id in ascending order.

SELECT 
    CASE 
        WHEN id % 2 = 1 AND id = (SELECT MAX(id) FROM seat) THEN id 
        WHEN id % 2 = 0 THEN id - 1 
        ELSE id + 1 
    END AS id,
    student 
FROM seat
ORDER BY id;


-- 1341. Movie Rating
-- Write a solution to:
-- 1. Find the name of the user who has rated the greatest number of movies. 
--    In case of a tie, return the lexicographically smaller user name.
-- 2. Find the movie name with the highest average rating in February 2020. 
--    In case of a tie, return the lexicographically smaller movie name.

(
    SELECT u.name AS results
    FROM Users AS u 
    JOIN MovieRating AS r 
    ON u.user_id = r.user_id 
    GROUP BY u.user_id
    ORDER BY COUNT(rating) DESC, u.name ASC 
    LIMIT 1
)
UNION ALL
(
    SELECT m.title AS results
    FROM Movies AS m
    JOIN MovieRating AS r
    ON m.movie_id = r.movie_id
    WHERE DATE_FORMAT(created_at, '%Y-%m') = '2020-02'
    GROUP BY m.movie_id
    ORDER BY AVG(rating) DESC, m.title ASC
    LIMIT 1
)


-- 1321. Restaurant Growth
-- You are the restaurant owner and you want to analyze a possible expansion (there will be at least one customer every day).
-- Compute the moving average of how much the customer paid in a seven days window (i.e., current day + 6 days before). average_amount should be rounded to two decimal places.
-- Return the result table ordered by visited_on in ascending order.

SELECT * 
FROM (
        SELECT visited_on, 
        SUM(amount) OVER (ORDER BY visited_on ROWS BETWEEN 6 preceding AND current ROW) AS amount, 
        ROUND(AVG(amount) OVER (ORDER BY visited_on ROWS BETWEEN 6 preceding AND current ROW), 2) AS average_amount
        FROM (
            SELECT visited_on, SUM(amount) AS amount FROM customer GROUP BY visited_on
        ) AS t 
    ) AS result
WHERE visited_on >= (SELECT DATE_ADD(MIN(visited_on), INTERVAL 6 DAY) FROM customer)
ORDER BY visited_on ASC


-- 602. Friend Requests II: Who Has the Most Friends
-- Write a solution to find the people who have the most friends and the most friends number.
-- The test cases are generated so that only one person has the most friends.

SELECT id, COUNT(*) AS num
FROM (
    (SELECT requester_id AS id FROM RequestAccepted)
    UNION ALL
    (SELECT accepter_id AS id FROM RequestAccepted)
) AS t
GROUP BY id
ORDER BY num DESC
LIMIT 1;


-- 585. Investments in 2016
-- Write a solution to report the sum of all total investment values in 2016 tiv_2016, for all policyholders who:
-- have the same tiv_2015 value as one or more other policyholders, and
-- are not located in the same city as any other policyholder (i.e., the (lat, lon) attribute pairs must be unique).
-- Round tiv_2016 to two decimal places.

SELECT ROUND(SUM(tiv_2016), 2) AS tiv_2016 
FROM insurance 
WHERE tiv_2015 IN (
    SELECT tiv_2015 
    FROM insurance 
    GROUP BY tiv_2015 
    HAVING COUNT(*) >= 2
) AND (lat, lon) IN (
    SELECT lat, lon 
    FROM insurance 
    GROUP BY lat, lon 
    HAVING COUNT(*) = 1
);


-- 185. Department Top Three Salaries
-- A company's executives are interested in seeing who earns the most money in each of the company's departments. A high earner in a department is an employee who has a salary in the top three unique salaries for that department.
-- Write a solution to find the employees who are high earners in each of the departments.
-- Return the result table in any order.

SELECT Department, Employee, Salary 
FROM 
(
    SELECT d.name as Department, e.departmentId as Id, e.name as Employee, salary as Salary,
    DENSE_RANK() OVER (partition by e.departmentId ORDER BY salary DESC) as rnk
    FROM Employee AS e 
    JOIN Department AS d
ON e.departmentId = d.id
) AS t 
WHERE rnk <= 3;






























































































