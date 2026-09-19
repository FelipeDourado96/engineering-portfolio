-- ============================================================
-- SQLBolt - exercises 6 to 18
-- Topics: multi-table joins, outer joins, NULLs, expressions,
--         aggregates, HAVING, order of execution, DML and DDL
-- Solved: 2026-09-19
-- ============================================================


-- ------------------------------------------------------------
-- Lesson 6 - Multi-table queries with JOINs
-- ------------------------------------------------------------

-- 6.1 Domestic and international sales for each movie
SELECT m.Title, b.Domestic_sales, b.International_sales
FROM Movies AS m
INNER JOIN Boxoffice AS b ON m.Id = b.Movie_id;

-- 6.2 Movies that did better internationally than domestically
SELECT m.Title, b.Domestic_sales, b.International_sales
FROM Movies AS m
INNER JOIN Boxoffice AS b ON m.Id = b.Movie_id
WHERE b.International_sales > b.Domestic_sales;

-- 6.3 All movies by rating, descending
SELECT m.Title, b.Rating
FROM Movies AS m
INNER JOIN Boxoffice AS b ON m.Id = b.Movie_id
ORDER BY b.Rating DESC;


-- ------------------------------------------------------------
-- Lesson 7 - OUTER JOINs
-- ------------------------------------------------------------

-- 7.1 All buildings that have employees
SELECT DISTINCT Building
FROM Employees
WHERE Building IS NOT NULL;

-- 7.2 All buildings and their capacity
SELECT Building_name, Capacity
FROM Buildings;

-- 7.3 All buildings and the distinct employee roles in each, including empty buildings
SELECT DISTINCT b.Building_name, e.Role
FROM Buildings AS b
LEFT JOIN Employees AS e ON b.Building_name = e.Building;


-- ------------------------------------------------------------
-- Lesson 8 - A short note on NULLs
-- ------------------------------------------------------------

-- 8.1 Employees not assigned to a building
SELECT Name, Role
FROM Employees
WHERE Building IS NULL;

-- 8.2 Buildings that hold no employees
SELECT b.Building_name
FROM Buildings AS b
LEFT JOIN Employees AS e ON b.Building_name = e.Building
WHERE e.Building IS NULL;


-- ------------------------------------------------------------
-- Lesson 9 - Queries with expressions
-- ------------------------------------------------------------

-- 9.1 Combined sales in millions of dollars
SELECT m.Title,
       (b.Domestic_sales + b.International_sales) / 1000000.0 AS Total_sales_millions
FROM Movies AS m
JOIN Boxoffice AS b ON m.Id = b.Movie_id;

-- 9.2 Ratings in percent
SELECT m.Title, b.Rating * 10 AS Rating_percent
FROM Movies AS m
JOIN Boxoffice AS b ON m.Id = b.Movie_id;

-- 9.3 Movies released on even years
SELECT Title
FROM Movies
WHERE Year % 2 = 0;


-- ------------------------------------------------------------
-- Lesson 10 - Queries with aggregates (Pt. 1)
-- ------------------------------------------------------------

-- 10.1 Longest time an employee has been at the studio
SELECT MAX(Years_employed) AS Longest_tenure
FROM Employees;

-- 10.2 Average years employed per role
SELECT Role, AVG(Years_employed) AS Avg_years
FROM Employees
GROUP BY Role;

-- 10.3 Total employee-years worked in each building
SELECT Building, SUM(Years_employed) AS Total_years
FROM Employees
GROUP BY Building;


-- ------------------------------------------------------------
-- Lesson 11 - Queries with aggregates (Pt. 2)
-- ------------------------------------------------------------

-- 11.1 Number of Artists, without a HAVING clause
SELECT COUNT(*) AS Artist_count
FROM Employees
WHERE Role = 'Artist';

-- 11.2 Number of employees of each role
SELECT Role, COUNT(*) AS Employee_count
FROM Employees
GROUP BY Role;

-- 11.3 Total years employed by all Engineers
SELECT SUM(Years_employed) AS Engineer_years
FROM Employees
WHERE Role = 'Engineer';


-- ------------------------------------------------------------
-- Lesson 12 - Order of execution of a query
-- ------------------------------------------------------------

-- 12.1 Number of movies each director has directed
SELECT Director, COUNT(*) AS Movie_count
FROM Movies
GROUP BY Director;

-- 12.2 Total sales attributable to each director
SELECT m.Director,
       SUM(b.Domestic_sales + b.International_sales) AS Total_sales
FROM Movies AS m
JOIN Boxoffice AS b ON m.Id = b.Movie_id
GROUP BY m.Director;


-- ------------------------------------------------------------
-- Lesson 13 - Inserting rows
-- ------------------------------------------------------------

-- 13.1 Add Toy Story 4 to the list of movies
INSERT INTO Movies (Id, Title, Director, Year, Length_minutes)
VALUES (4, 'Toy Story 4', 'John Lasseter', 2019, 100);

-- 13.2 Add the Toy Story 4 box office record
INSERT INTO Boxoffice (Movie_id, Rating, Domestic_sales, International_sales)
VALUES (4, 8.7, 340000000, 270000000);


-- ------------------------------------------------------------
-- Lesson 14 - Updating rows
-- ------------------------------------------------------------

-- 14.1 Correct the director of A Bug's Life
UPDATE Movies
SET Director = 'John Lasseter'
WHERE Title = 'A Bug''s Life';

-- 14.2 Correct the release year of Toy Story 2
UPDATE Movies
SET Year = 1999
WHERE Title = 'Toy Story 2';

-- 14.3 Correct both title and director of Toy Story 8
UPDATE Movies
SET Title = 'Toy Story 3',
    Director = 'Lee Unkrich'
WHERE Id = 11;


-- ------------------------------------------------------------
-- Lesson 15 - Deleting rows
-- ------------------------------------------------------------

-- 15.1 Remove all movies released before 2005
DELETE FROM Movies
WHERE Year < 2005;

-- 15.2 Remove all movies directed by Andrew Stanton
DELETE FROM Movies
WHERE Director = 'Andrew Stanton';


-- ------------------------------------------------------------
-- Lesson 16 - Creating tables
-- ------------------------------------------------------------

-- 16.1 Create the Database table
CREATE TABLE IF NOT EXISTS "Database" (
    Name           TEXT,
    Version        FLOAT,
    Download_count INTEGER
);


-- ------------------------------------------------------------
-- Lesson 17 - Altering tables
-- ------------------------------------------------------------

-- 17.1 Add the aspect ratio column
ALTER TABLE Movies ADD COLUMN Aspect_ratio FLOAT;

-- 17.2 Add the language column, defaulting to English
ALTER TABLE Movies ADD COLUMN Language TEXT DEFAULT 'English';


-- ------------------------------------------------------------
-- Lesson 18 - Dropping tables
-- ------------------------------------------------------------

-- 18.1 Remove the Movies table
DROP TABLE IF EXISTS Movies;

-- 18.2 Remove the Boxoffice table
DROP TABLE IF EXISTS Boxoffice;
