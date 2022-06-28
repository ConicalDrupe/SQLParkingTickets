
Select [Date/Time]
From MontgomeryTickets..TicketLocations$

UPDATE MontgomeryTickets..TicketLocations$
SET [Date/Time] = Replace([Date/Time],'0020','2020')

UPDATE MontgomeryTickets..TicketLocations$
SET [Date/Time] = Replace([Date/Time],'0021','2021')

Select [ Ticket ID] as ID, FORMAT(convert(DATETIME,[Date/Time]),'MM/dd/yyyy hh:mm tt') as [Date], 
[Ticket Location] 
From MontgomeryTickets..TicketLocations$
Where [Date/Time] is not null and [Ticket Location] is not null
-----------------------------------------------------------------
--Most frequent violation
Select [Violation Code],[Violation Description], Count([Violation Code]) as vio_count
From MontgomeryTickets..TicketViolations$
Where [Violation Code] is not null 
and [Violation Description] is not null
GROUP by [Violation Code],[Violation Description]
order by 3 desc

-------------------------------------------------------------
Select loc.[ Ticket ID],FORMAT(convert(DATETIME,loc.[Date/Time]),'MM/dd/yyyy hh:mm tt') as [Date],
loc.[Ticket Location], vio.[Violation Code],vio.[Violation Description]
From MontgomeryTickets..TicketLocations$ as loc
FULL OUTER JOIN MontgomeryTickets..TicketViolations$ as vio
on loc.[ Ticket ID] = vio.[ Ticket ID]
Where loc.[Date/Time] is not null 
and loc.[Ticket Location] is not null 
and vio.[Violation Code] is not null 
and vio.[Violation Description] is not null

Select vio.[Violation Code],
Cast(Count(vio.[Violation Code]) as float)/cast(Count(vio.[Violation Description]) as float) as rel_freq
From MontgomeryTickets..TicketLocations$ as loc
FULL OUTER JOIN MontgomeryTickets..TicketViolations$ as vio
on loc.[ Ticket ID] = vio.[ Ticket ID]
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
	FROM MontgomeryTickets..TicketViolations$
	Where [Violation Description] is not null
	and [Violation Code] is not null
	GROUP BY [Violation Description]
	) TicketViolations$
	GROUP BY [Violation Description]

SELECT 
FROM (
	Select SUM(CAST(v2.vioCount as float))
	From MontgomeryTickets..TicketViolations$ v1
	LEFT JOIN ( 
		SELECT [Violation Description], Count([Violation Description]) as vioCount
		FROM MontgomeryTickets..TicketViolations$
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
	FROM MontgomeryTickets..TicketViolations$
	WHERE [Violation Description] is not null
	and [Violation Code] is not null)

SELECT [Violation Description], Count([Violation Description]) as vioCount ,
(CAST(Count([Violation Description]) as decimal(16,2))/@vio_total)*100 as rel_freq
FROM MontgomeryTickets..TicketViolations$
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
