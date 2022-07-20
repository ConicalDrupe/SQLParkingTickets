CREATE TABLE Locations (
Ticket_ID varchar(50),
date_time DATETIME,
Lot_Address varchar(100),
Lot varchar(5),
[Address] varchar(100),
PRIMARY KEY(Ticket_ID)
)

CREATE TABLE Violations (
Ticket_ID varchar(50),
violation_type varchar(50),
PRIMARY KEY(Ticket_ID)
)

Select *
INTO ParkingTickets..Locations
From ParkingTickets..TicketLocations
WHERE [Ticket ID] is not null
and [Date/Time] is not null
and [Ticket Location] is not null

Select *
INTO ParkingTickets..Violations
From ParkingTickets..TicketViolations
WHERE [Ticket ID] is not null
and [Violation Code] is not null
and [Violation Description] is not null
and [Ticket ID] IN --Helps us later on, when adding a foreign key on [Ticket ID]
	(
	Select [Ticket ID] From ParkingTickets..Locations
	)

----(2) Fix [Date/Time] Error
ALTER TABLE ParkingTickets..Locations
Add date_time DATETIME

UPDATE ParkingTickets..Locations
SET [Date/Time] = Replace([Date/Time],'0020','2020')

UPDATE ParkingTickets..Locations
SET [Date/Time] = Replace([Date/Time],'0021','2021')

UPDATE ParkingTickets..Locations
SET date_time = convert(DATETIME,[Date/Time])

Select FORMAT(date_time,'MM/dd/yyyy hh:mm tt')
From ParkingTickets..Locations

--(3) Split Lot and Addresses
ALTER TABLE ParkingTickets..Locations
ADD	Lot varchar(10),
	[Address] varchar(100)

--Check Query, Notice additional error: double entry of lot number
SELECT DISTINCT
 [Ticket Location] 
,TRIM('-' FROM LEFT([Ticket Location], CHARINDEX('-',[Ticket Location]))) 
 as LotNumber
,RIGHT([Ticket Location], LEN([Ticket Location]) - CHARINDEX('-',[Ticket Location])) 
 as [Address]
FROM ParkingTickets..Locations
Where TRIM('-' FROM LEFT([Ticket Location], CHARINDEX('-',[Ticket Location]))) != ' '
Order by 3 desc

--Perform another trim, to correctly split address and lot number
UPDATE ParkingTickets..Locations
Set [Address] = RIGHT(RIGHT([Ticket Location], LEN([Ticket Location]) - CHARINDEX('-',[Ticket Location])), LEN(RIGHT([Ticket Location], LEN([Ticket Location]) - CHARINDEX('-',[Ticket Location]))) - CHARINDEX('-',RIGHT([Ticket Location], LEN([Ticket Location]) - CHARINDEX('-',[Ticket Location]))))

UPDATE ParkingTickets..Locations
Set [Lot] = CASE 
			WHEN TRIM('-' FROM LEFT([Ticket Location], CHARINDEX('-',[Ticket Location]))) = ' ' 
			THEN 'Street'
			ELSE TRIM('-' FROM LEFT([Ticket Location], CHARINDEX('-',[Ticket Location])))
			END

--(4) Categorize time of day
-- Morning 6am-noon
-- Afternoon noon-6pm
-- Evening 6pm-midnight
-- Late Night midnight-6am

ALTER TABLE ParkingTickets..Locations
ADD time_of_day varchar(20)

UPDATE ParkingTickets..Locations
Set time_of_day = CASE
	When CONVERT(varchar(255),CONVERT(Time(0),date_time)) between '06:00:00' and '12:00:00' Then 'Morning'
	When CONVERT(varchar(255),CONVERT(Time(0),date_time)) between '12:00:00' and '18:00:00' Then 'Afternoon'
	When CONVERT(varchar(255),CONVERT(Time(0),date_time)) between'18:00:00' and '24:00:00' Then 'Evening'
	Else 'Late Night'
	End

--(5) Finalize Locations table by 
-- Drop appropriate Columns
-- Add primary key

ALTER TABLE ParkingTickets..Locations
DROP COLUMN [Date/Time],[Ticket Location]

ALTER TABLE ParkingTickets..Locations
ALTER COLUMN [Ticket ID] int NOT NULL

ALTER TABLE ParkingTickets..Locations
ADD Primary Key ([Ticket ID])

------(6) Condensing Violation Types--------
ALTER TABLE ParkingTickets..Violations
Add violation_type varchar(50)

UPDATE ParkingTickets..Violations
Set violation_type = 'No Standing Parking'
Where [Violation Code] = 10 or [Violation Code] = 17 or [Violation Code] = 22 or [Violation Code] = 22 or [Violation Code] = 23 or [Violation Code] = 25 or [Violation Code] = 31 or [Violation Code] = 32 or [Violation Code] = 57
--
UPDATE ParkingTickets..Violations
Set violation_type = 'No Parking Anytime'
Where [Violation Code] = 3 or [Violation Code] = 5 or [Violation Code] = 34 or [Violation Code] = 37

UPDATE ParkingTickets..Violations
Set violation_type = 'Expired/Overtime'
Where [Violation Code] = 7 or [Violation Code] = 41 or [Violation Code] = 50

UPDATE ParkingTickets..Violations
Set violation_type = 'Sign Violation or Impeding Traffic'
Where [Violation Code] = 9 or [Violation Code] = 35 or [Violation Code] = 36 or [Violation Code] = 43 or [Violation Code] = 54

UPDATE ParkingTickets..Violations
Set violation_type = 'Prohibited Vehicle'
Where [Violation Code] = 2 or [Violation Code] = 38 or [Violation Code] = 42 or [Violation Code] = 48

UPDATE ParkingTickets..Violations
Set violation_type = 'Orientation Violation'
Where [Violation Code] = 8 or [Violation Code] = 19 or [Violation Code] = 20 or [Violation Code] = 24 or [Violation Code] = 27 or [Violation Code] = 28 or [Violation Code] = 59

--(7) Finalize Violations Table
--Dropping columns
--Adding Foreign key

ALTER TABLE ParkingTickets..Violations
DROP COLUMN [Violation Code],[Violation Description]

ALTER TABLE ParkingTickets..Violations
ALTER COLUMN [Ticket ID] int NOT NULL

ALTER TABLE ParkingTickets..Violations
ADD Foreign Key ([Ticket ID])
REFERENCES ParkingTickets..Locations([Ticket ID])
------------------------------------------------------
---(8) Metrics and Results
--Most Common Violation
--Frequency of Top Violation by months
--Most Ticketed Location
--Most Ticketed Time of Day (2020 and 2021)
--Most Ticketed Day of the Week (2020 and 2021)

--Most Common Violation
Select violation_type
,Count(violation_type) as violation_count
From ParkingTickets..Violations
Group by violation_type
Order by 2 desc

--Frequency of Top Violation by months
Select DATENAME(Month,l.date_time) as [Month]
,year(l.date_time) as [year]
,Count(DATENAME(Month,l.date_time)) as count
From ParkingTickets..Violations v
INNER JOIN ParkingTickets..Locations l
On v.[Ticket ID] = l.[Ticket ID]
Where v.violation_type = 'Expired/Overtime'
Group by year(l.date_time),DATENAME(Month,l.date_time)
Order by 2,3 desc

--Most Ticketed Location
Select [Address]
,Count([Address]) as address_count
From ParkingTickets..Locations
Group by [Address]
Order by 2 desc

--Most Ticketed Time of Day
Select time_of_day
,year(date_time) as [year]
,Count(time_of_day) as count
From ParkingTickets..Locations
Group by time_of_day, year(date_time)
Order by 2,3 desc

--Most Ticketed Day of the week
Select DATENAME(Weekday,date_time) as [day]
,year(date_time) as [year]
,Count(DATENAME(Weekday,date_time)) as count
From ParkingTickets..Locations
Group by DATENAME(Weekday,date_time), year(date_time)
Order by 2,3 desc





