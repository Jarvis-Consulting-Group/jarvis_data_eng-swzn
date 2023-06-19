\c exercises
-- Dumped from database version 9.2.0
-- Dumped by pg_dump version 9.2.0
-- Started on 2013-05-19 16:05:10 BST

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- TOC entry 7 (class 2615 OID 32769)
-- Name: cd; Type: SCHEMA; Schema: -; Owner: -
--

SET search_path = cd, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--- CRUD QUERIES ---

-- Question 1

INSERT INTO facilities(facid, name, membercost, guestcost, initialoutlay, monthlymaintenance) 
VALUES(9, 'Spa', 20, 30, 100000, 800);

-- Question 2
INSERT INTO facilities(facid, name, membercost, guestcost, initialoutlay, monthlymaintenance) 
VALUES((SELECT MAX(facid)+1 FROM facilities), 'Spa', 20, 30, 100000, 800);

-- Question 3
UPDATE facilities set initialoutlay=10000 WHERE name='Tennis Court 2';

-- Question 4
UPDATE facilities SET membercost=(SELECT membercost*1.1 FROM facilities WHERE name='Tennis Court 1') WHERE name='Tennis Court 2';

-- Question 5
DELETE FROM bookings *;

--- BASIC QUERIES ---

-- Question 6
select facid, name, membercost, monthlymaintenance
from facilities 
where membercost < .02 * monthlymaintenance AND membercost > 0;

-- Question 7
SELECT * from facilities 
WHERE name 
LIKE '%Tennis%'; -- Reminder; % = 0 or more characters, _ = exactly one character

-- Question 8
SELECT * from facilities 
WHERE facid=1 
UNION 
SELECT * 
from facilities
where facid=5;

-- Question 9
select memid, surname, firstname, joindate 
from members 
where joindate > '2012-09-01 00:00:00';

-- Question 10
select surname from members union select name from facilities;

--- JOIN QUERIES ---

-- Question 11
SELECT starttime
FROM bookings,members
where bookings.memid = members.memid AND members.firstname = 'David' AND members.surname = 'Farrell';

-- Question 12
SELECT starttime,facilities.name
FROM bookings,facilities
WHERE facilities.name LIKE 'Tennis Court%' 
AND bookings.starttime >= '2012-09-21 00:00:00' 
AND bookings.starttime < '2012-09-22 00:00:00'
ORDER BY starttime;

-- Question 13

SELECT m1.surname, m1.firstname, m2.surname, m2.firstname
FROM members m1 LEFT OUTER JOIN members m2
ON m1.recommendedby = m2.memid
ORDER BY m1.surname, m1.firstname;

-- Question 14
SELECT DISTINCT firstname, surname
FROM members
where memid in 
(select recommendedby from members where recommendedby IS not null)
ORDER BY surname, firstname;

-- Question 15
-- Unsure

--- AGGREGATION QUERIES ---

-- Question 16
select recommendedby, count(*) 
from members
where recommendedby is not null
group by recommendedby
order by recommendedby;

-- Question 17
SELECT facid,SUM(slots)
FROM bookings
GROUP BY facid
ORDER BY facid;

-- Question 18
SELECT facid, sum(slots)
FROM bookings
WHERE starttime >= '2012-09-01 00:00:00'
AND starttime < '2012-10-01 00:00:00'
GROUP BY facid
ORDER BY sum(slots);

-- Question 19
SELECT facid, extract(month from starttime) as month, sum(slots)
FROM bookings
WHERE starttime >= '2012-01-01 00:00:00'
AND starttime < '2013-10-01 00:00:00'
GROUP BY facid,month
ORDER BY facid,month;

-- Question 20
SELECT COUNT(DISTINCT facid)
FROM bookings;

-- Question 21
WITH minbooking AS (
    SELECT memid,min(starttime) as stamp
    FROM bookings
  	WHERE starttime >= '2012-09-01 00:00:00'
    GROUP BY memid
)
SELECT DISTINCT surname, firstname, members.memid, starttime
FROM members members,bookings bookings,minbooking
WHERE members.memid = bookings.memid
AND bookings.memid = minbooking.memid
AND minbooking.stamp = starttime
ORDER BY memid;

--- STRING QUERIES ---
SELECT surname || ', ' || firstname 
FROM members;   

SELECT memid, telephone 
FROM members 
WHERE telephone 
LIKE '(%)%';

select substr (members.surname,1,1) as sub, count(*)
from members 
group by sub
order by sub
