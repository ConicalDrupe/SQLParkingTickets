Original Table was split into two tables

-TicketLocations <Ticket ID,Date/Time,Locations>
-TicketViolations <Ticket ID,Violation Code,Violation Description>

And imported into SQL

Errors in data:
-Now we update our tables Where row values are not null (at this point our tables may have a different number of rows, good data will obtained through proper use of joins)
-Date/Time has year errors, 0020 and 0021 instead of 2020 2021 respectively
