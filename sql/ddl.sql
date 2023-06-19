CREATE SCHEMA cd;

CREATE TABLE cd.facilities
(
    facid               INTEGER NOT NULL,
    name                VARCHAR(100) NOT NULL,
    membercost          NUMERIC NOT NULL,
    guestcost           NUMERIC NOT NULL,
    initialoutlay       NUMERIC NOT NULL,
    monthlymaintenance  NUMERIC NOT NULL,
    PRIMARY KEY (facid)
);

CREATE TABLE cd.members
(
    memid           INTEGER NOT NULL,
    surname         VARCHAR(200) NOT NULL,
    firstname       VARCHAR(200) NOT NULL,
    address         VARCHAR(300) NOT NULL,
    zipcode         INTEGER NOT NULL,
    telephone       VARCHAR(20) NOT NULL,
    recommendedby   INTEGER,
    joindate        timestamp NOT NULL,
    PRIMARY KEY (memid),
    CONSTRAINT recommendation FOREIGN KEY(recommendedby) REFERENCES cd.members(memid)
);

CREATE TABLE cd.bookings
(
    facid INTEGER NOT NULL,
    memid INTEGER NOT NULL,
    starttime timestamp NOT NULL,
    slots INTEGER NOT NULL,
    PRIMARY KEY (facid),
    CONSTRAINT facid_bookings FOREIGN KEY (facid) REFERENCES cd.facilities(facid),
    CONSTRAINT memid_bookings FOREIGN KEY (memid) REFERENCES cd.members(memid)
)