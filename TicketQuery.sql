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
ALTER COLUMN [Ticket ID] varchar(30) NOT NULL

ALTER TABLE ParkingTickets..Locations
ADD Primary Key ([Ticket ID])

Select TABLE_NAME
From INFORMATION_SCHEMA.TABLES
