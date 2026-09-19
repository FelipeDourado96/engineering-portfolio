-- ============================================================
-- PostgreSQL Exercises - Joins and Subqueries section
-- https://pgexercises.com/questions/joins/
-- Dataset: cd (country club) - facilities, members, bookings
-- Solved: 2026-09-19
-- ============================================================


-- 1. Start times for bookings by members named 'David Farrell'
SELECT bks.starttime
FROM cd.bookings AS bks
INNER JOIN cd.members AS mems ON bks.memid = mems.memid
WHERE mems.firstname = 'David'
  AND mems.surname = 'Farrell';


-- 2. Start times for bookings for tennis courts on 2012-09-21,
--    returned as start time and facility name, ordered by time
SELECT bks.starttime AS start, facs.name AS name
FROM cd.bookings AS bks
INNER JOIN cd.facilities AS facs ON bks.facid = facs.facid
WHERE bks.starttime >= '2012-09-21'
  AND bks.starttime < '2012-09-22'
  AND facs.name LIKE 'Tennis Court%'
ORDER BY bks.starttime;


-- 3. All members who have recommended another member, no duplicates,
--    ordered by (surname, firstname)
SELECT firstname, surname
FROM cd.members
WHERE memid IN (SELECT recommendedby FROM cd.members)
ORDER BY surname, firstname;


-- 4. All members, including the individual who recommended them (if any),
--    ordered by (surname, firstname)
SELECT mems.firstname AS memfname,
       mems.surname   AS memsname,
       recs.firstname AS recfname,
       recs.surname   AS recsname
FROM cd.members AS mems
LEFT OUTER JOIN cd.members AS recs ON recs.memid = mems.recommendedby
ORDER BY memsname, memfname;


-- 5. All members who have used a tennis court, with the court name and the
--    member name as a single column, no duplicates, ordered by member then facility
SELECT DISTINCT mems.firstname || ' ' || mems.surname AS member,
                facs.name AS facility
FROM cd.members AS mems
INNER JOIN cd.bookings   AS bks  ON mems.memid = bks.memid
INNER JOIN cd.facilities AS facs ON bks.facid = facs.facid
WHERE facs.name LIKE 'Tennis Court%'
ORDER BY member, facility;


-- 6. Bookings on 2012-09-14 costing the member or guest more than $30.
--    Guests (memid 0) pay a different rate; costs are per half-hour slot.
--    Ordered by descending cost, without subqueries.
SELECT mems.firstname || ' ' || mems.surname AS member,
       facs.name AS facility,
       CASE WHEN mems.memid = 0 THEN bks.slots * facs.guestcost
            ELSE bks.slots * facs.membercost
       END AS cost
FROM cd.members AS mems
INNER JOIN cd.bookings   AS bks  ON mems.memid = bks.memid
INNER JOIN cd.facilities AS facs ON bks.facid = facs.facid
WHERE bks.starttime >= '2012-09-14'
  AND bks.starttime < '2012-09-15'
  AND CASE WHEN mems.memid = 0 THEN bks.slots * facs.guestcost
           ELSE bks.slots * facs.membercost
      END > 30
ORDER BY cost DESC;


-- 7. All members and their recommender, without using any joins,
--    each name pairing formatted as a single column and ordered
SELECT DISTINCT mems.firstname || ' ' || mems.surname AS member,
       (SELECT recs.firstname || ' ' || recs.surname
        FROM cd.members AS recs
        WHERE recs.memid = mems.recommendedby) AS recommender
FROM cd.members AS mems
ORDER BY member;


-- 8. The same costly-bookings list as above, simplified with a subquery
--    so the cost expression is written once
SELECT member, facility, cost
FROM (
    SELECT mems.firstname || ' ' || mems.surname AS member,
           facs.name AS facility,
           CASE WHEN mems.memid = 0 THEN bks.slots * facs.guestcost
                ELSE bks.slots * facs.membercost
           END AS cost
    FROM cd.members AS mems
    INNER JOIN cd.bookings   AS bks  ON mems.memid = bks.memid
    INNER JOIN cd.facilities AS facs ON bks.facid = facs.facid
    WHERE bks.starttime >= '2012-09-14'
      AND bks.starttime < '2012-09-15'
) AS bookings
WHERE cost > 30
ORDER BY cost DESC;
