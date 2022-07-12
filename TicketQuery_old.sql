
------(1)---------Selecting Useful Data (ignoring Blank rows)-----------
Select *
From ParkingTickets..TicketLocations$
Where [Ticket Number] is not null
and [Date/Time] is not null
and [Ticket Location] is not null

---TESTING---Before we update we make a copy of the table and check our UPDATE strategy

DROP TABLE IF EXISTS #temp_locations
SELECT * INTO #temp_locations
FROM ParkingTickets..TicketLocations$
--Where clause be used here, but our purpose is to check if the UPDATE works before implementing

DELETE FROM #temp_locations
Where [Ticket Number] is null
or [Date/Time] is null
or [Ticket Location] is null
-- 936 rows affected with 102,467 rows remaining, Great! DELETE works as we wanted!

Select *
From #temp_locations
--Updating Our two Tables
UPDATE ParkingTickets..TicketLocations$
SET [Ticket Number]=[Ticket Number],[Date/Time]=[Date/Time],[Ticket Location]=[Ticket Location]
Where [Ticket Number] is not null
and [Date/Time] is not null
and [Ticket Location] is not null
---- DOES NOT REMOVE ROWS WITH NULL VALUES

UPDATE ParkingTickets..TicketViolations$
SET [Ticket Number]=[Ticket Number],[Violation Code]=[Violation Code],
[Violation Description]=[Violation Description]
Where [Ticket Number] is not null
and [Violation Code] is not null
and [Violation Description] is not null

---------------------------------------------Removal of Blank data complete--------------

----(2)-------------Date Time Error---------------------------

Select [Date/Time]
From ParkingTickets..TicketLocations$

UPDATE ParkingTickets..TicketLocations$
SET [Date/Time] = Replace([Date/Time],'0020','2020')

UPDATE ParkingTickets..TicketLocations$
SET [Date/Time] = Replace([Date/Time],'0021','2021')

UPDATE ParkingTickets..TicketLocations$
SET [Date/Time] = FORMAT(convert(DATETIME,[Date/Time]),'MM/dd/yyyy hh:mm tt')
----------------------DATE Error Fix Complete--------------------------------

---(3)----Calculating Measures-------------------------------------------------------
--Most frequent violation
Select [Violation Code],[Violation Description], Count([Violation Code]) as vio_count
From ParkingTickets..TicketViolations$
Where [Violation Code] is not null 
and [Violation Description] is not null
GROUP by [Violation Code],[Violation Description]
order by 3 desc

-------------------------------------------------------------
Select loc.[Ticket Number],FORMAT(convert(DATETIME,loc.[Date/Time]),'MM/dd/yyyy hh:mm tt') as [Date],
loc.[Ticket Location], vio.[Violation Code],vio.[Violation Description]
From ParkingTickets..TicketLocations$ as loc
FULL OUTER JOIN ParkingTickets..TicketViolations$ as vio
on loc.[Ticket Number] = vio.[Ticket Number]
Where loc.[Date/Time] is not null 
and loc.[Ticket Location] is not null 
and vio.[Violation Code] is not null 
and vio.[Violation Description] is not null

Select vio.[Violation Code],
Cast(Count(vio.[Violation Code]) as float)/cast(Count(vio.[Violation Description]) as float) as rel_freq
From ParkingTickets..TicketLocations$ as loc
FULL OUTER JOIN ParkingTickets..TicketViolations$ as vio
on loc.[Ticket Number] = vio.[Ticket Number]
Where loc.[Date/Time] is not null 
and loc.[Ticket Location] is not null 
and vio.[Violation Code] is not null 
and vio.[Violation Description] is not null
Group by vio.[Violation Code]
Order by 2 desc

--Cast(vioCount as numeric)/Cast(sum(vioCount) as numeric) as rel_freq
Select [Violation Description] , Cast(vioCount as numeric)/Cast(sum(vioCount) as numeric) as rel_freq
FROM (
	Select [Violation Description], COUNT([Violation Description]) as vioCount
	FROM ParkingTickets..TicketViolations$
	Where [Violation Description] is not null
	and [Violation Code] is not null
	GROUP BY [Violation Description]
	) TicketViolations$
	GROUP BY [Violation Description]

SELECT 
FROM (
	Select SUM(CAST(v2.vioCount as float))
	From ParkingTickets..TicketViolations$ v1
	LEFT JOIN ( 
		SELECT [Violation Description], Count([Violation Description]) as vioCount
		FROM ParkingTickets..TicketViolations$
		Where [Violation Description] is not null
		and [Violation Code] is not null
		GROUP BY [Violation Description]
		) v2
	on v1.[Violation Description] = v2.[Violation Description]
	)

---------------------------------------
DECLARE @vio_total decimal(16,2)
SET @vio_total = (
	SELECT cast(COUNT(*) as decimal(16,2))
	FROM ParkingTickets..TicketViolations$
	WHERE [Violation Description] is not null
	and [Violation Code] is not null)

SELECT [Violation Description], Count([Violation Description]) as vioCount ,
(CAST(Count([Violation Description]) as decimal(16,2))/@vio_total)*100 as rel_freq
FROM ParkingTickets..TicketViolations$
Where [Violation Description] is not null
and [Violation Code] is not null
GROUP BY [Violation Description]
Order by 3 desc

----------

DROP TABLE IF EXISTS #temp_Tickets
CREATE TABLE #temp_Tickets (
Ticket_id int,
[Date] DATETIME,
Ticket_location varchar(255),
violation_type varchar(255))
