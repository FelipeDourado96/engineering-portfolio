-- PostgreSQL Exercises - Basic section
-- https://pgexercises.com/questions/basic/
-- Dataset: cd (country club) - facilities, members, bookings
-- Solved: 2026-09-19


-- 1. Retrieve all the information from the cd.facilities table
SELECT *
FROM cd.facilities;


-- 2. Retrieve a list of only facility names and costs to members
SELECT name, membercost
FROM cd.facilities;


-- 3. Produce a list of facilities that charge a fee to members
SELECT *
FROM cd.facilities
WHERE membercost > 0;


-- 4. Facilities that charge a fee to members, where the fee is less than
--    1/50th of the monthly maintenance cost
SELECT facid, name, membercost, monthlymaintenance
FROM cd.facilities
WHERE membercost > 0
  AND membercost < monthlymaintenance / 50.0;


-- 5. All facilities with the word 'Tennis' in their name
SELECT *
FROM cd.facilities
WHERE name LIKE '%Tennis%';


-- 6. Details of facilities with ID 1 and 5, without using OR
SELECT *
FROM cd.facilities
WHERE facid IN (1, 5);


-- 7. Label each facility 'cheap' or 'expensive' depending on whether its
--    monthly maintenance cost is more than $100
SELECT name,
       CASE WHEN monthlymaintenance > 100 THEN 'expensive'
            ELSE 'cheap'
       END AS cost
FROM cd.facilities;


-- 8. Members who joined after the start of September 2012
SELECT memid, surname, firstname, joindate
FROM cd.members
WHERE joindate >= '2012-09-01';


-- 9. Ordered list of the first 10 surnames in the members table, no duplicates
SELECT DISTINCT surname
FROM cd.members
ORDER BY surname
LIMIT 10;


-- 10. Combined list of all surnames and all facility names
SELECT surname FROM cd.members
UNION
SELECT name FROM cd.facilities;


-- 11. Signup date of the last member
SELECT MAX(joindate) AS latest
FROM cd.members;


-- 12. First and last name of the last member who signed up
SELECT firstname, surname, joindate
FROM cd.members
ORDER BY joindate DESC
LIMIT 1;
