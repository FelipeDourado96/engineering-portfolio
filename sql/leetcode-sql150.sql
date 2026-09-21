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
















