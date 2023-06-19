# Introduction

This project aims at developing and showcasing proficiency with SQL, and in particular, PostgreSQL. The PSQL server is being hosted on a Docker container. In this project, we practice setting up multiple different database tables using PSQL's DDL. This allows us to create tables that reference eachother (and even oneself) using foreign keys. We then use SQL to extract relevant information from each table, or a combination of multiple tables.

# SQL Queries

###### Table Setup (DDL)

###### CRUD

###### Question 1: Insert new facility 

```sql
INSERT INTO facilities(facid, name, membercost, guestcost, initialoutlay, monthlymaintenance) 
VALUES(9, 'Spa', 20, 30, 100000, 800);
```

###### Question 2: Insert new facility with calculated primary key

```sql
INSERT INTO facilities(facid, name, membercost, guestcost, initialoutlay, monthlymaintenance) 
VALUES((SELECT MAX(facid)+1 FROM facilities), 'Spa', 20, 30, 100000, 800);
```

###### Question 3: Update existing query
```sql
UPDATE facilities set initialoutlay=10000 WHERE name='Tennis Court 2';
```

###### Question 4: Update existing query with calculated value
```sql
UPDATE facilities SET membercost=(SELECT membercost*1.1 FROM facilities WHERE name='Tennis Court 1') WHERE name='Tennis Court 2';
```

###### Question 5: Delete all values from table
```sql
DELETE FROM bookings *;
```

###### Question 6: Delete all values from table
```sql
DELETE FROM bookings *;
```

##### Basic Queries

###### Question 1: Select all facilities with an existing cost less than 2% of monthly maintenance
```sql
select facid, name, membercost, monthlymaintenance
from facilities 
where membercost < .02 * monthlymaintenance AND membercost > 0;
```

###### Question 2: Select all facilities with a name that contains 'Tennis'
```sql
SELECT * from facilities 
WHERE name 
LIKE '%Tennis%';
```

###### Question 3: Select facilities with ID 1 and 5
```sql
SELECT * from facilities 
WHERE facid=1 
UNION 
SELECT * 
from facilities
where facid=5;
```

###### Question 4: Select the members that joined after September 2012
```sql
select memid, surname, firstname, joindate 
from members 
where joindate > '2012-09-01 00:00:00';
```

###### Question 5: Select member names and facility names
```sql
select surname from members union select name from facilities;
```

##### Join Queries

###### Question 1: Select all bookings made by David Farrell
```sql
SELECT starttime
FROM bookings,members
where bookings.memid = members.memid AND members.firstname = 'David' 
AND members.surname = 'Farrell';
```

###### Question 2: Select all Tennis Court bookings made in September 2012
```sql
SELECT starttime,facilities.name
FROM bookings,facilities
WHERE facilities.name LIKE 'Tennis Court%' 
AND bookings.starttime >= '2012-09-21 00:00:00' 
AND bookings.starttime < '2012-09-22 00:00:00'
ORDER BY starttime;
```

##### Question 3: Select the names of people and the person that recommended them (if any)
```sql
SELECT m1.surname, m1.firstname, m2.surname, m2.firstname
FROM members m1 LEFT OUTER JOIN members m2
ON m1.recommendedby = m2.memid
ORDER BY m1.surname, m1.firstname;
```

##### Question 4: Select the names people that recommended others
```sql
SELECT m1.surname, m1.firstname, m2.surname, m2.firstname
FROM members m1 LEFT OUTER JOIN members m2
ON m1.recommendedby = m2.memid
ORDER BY m1.surname, m1.firstname;
```

##### Aggregation Queries

##### Question 1: Count how many people each person has recommended after they've recommended at least 1
```sql
select recommendedby, count(*) 
from members
where recommendedby is not null
group by recommendedby
order by recommendedby;
```

##### Question 2: Count how many total slots each facility uses
```sql
SELECT facid,SUM(slots)
FROM bookings
GROUP BY facid
ORDER BY facid;
```

##### Question 3: Count how many total slots each facility used in the month of September 2012
```sql
SELECT facid, sum(slots)
FROM bookings
WHERE starttime >= '2012-09-01 00:00:00'
AND starttime < '2012-10-01 00:00:00'
GROUP BY facid
ORDER BY sum(slots);
```

##### Question 4: Count how many total slots each facility each month of 2012
```sql
SELECT facid, extract(month from starttime) as month, sum(slots)
FROM bookings
WHERE starttime >= '2012-01-01 00:00:00'
AND starttime < '2013-10-01 00:00:00'
GROUP BY facid,month
ORDER BY facid,month;
```

##### Question 5: Count how many facilities have made at least 1 booking
```sql
SELECT COUNT(DISTINCT facid)
FROM bookings;
```

##### Question 6: Select the first booking of every person who's made a booking
```sql
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
```

##### String Queries

##### Question 1: Concatenate the surname and first name of each member in one column
```sql
SELECT surname || ', ' || firstname 
FROM members;  
```

##### Question 2: Select all phone numbers that have the parentheses pattern
```sql
SELECT memid, telephone 
FROM members 
WHERE telephone 
LIKE '(%)%'; 
```

##### Question 3: Count how many names start with each letter
```sql
select substr (members.surname,1,1) as sub, count(*)
from members 
group by sub
order by sub
```