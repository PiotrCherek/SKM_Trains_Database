-- 1. Show the price of tickets, also including discounts
GO
CREATE VIEW Ticket_Distances AS
SELECT 
    t.id AS Ticket_ID,
    ABS(rs_end.current_km - rs_start.current_km) AS Distance
FROM Tickets AS t
JOIN Runs AS r 
	ON t.run_id = r.id
JOIN Planned_Schedules AS ps 
	ON r.schedule_id = ps.id
JOIN Route_Stops AS rs_start 
    ON ps.line_number = rs_start.line_number 
    AND t.starting_station = rs_start.station_id
JOIN Route_Stops AS rs_end 
    ON ps.line_number = rs_end.line_number 
    AND t.ending_station = rs_end.station_id;
GO

SELECT 
    t.id AS Ticket_ID,
    ROUND(bp.price - (bp.price * d.discount_percentage),2) AS Price
FROM Tickets AS t
JOIN Ticket_Distances AS td
	ON t.id = td.Ticket_ID
JOIN Base_Prices AS bp 
    ON td.Distance BETWEEN bp.lower_bound AND bp.upper_bound
JOIN Discounts AS d 
    ON t.discount_id = d.id
WHERE td.Distance IS NOT NULL;

-- 2. How much money saved by each discount in a quarter
SELECT
	'Quarter 1 of 2024' AS Q,
    ROUND(SUM(bp.price * d.discount_percentage),2) AS Discounts
FROM Tickets AS t
JOIN Ticket_Distances td
	ON t.id = td.Ticket_ID
JOIN Base_Prices AS bp 
    ON td.Distance BETWEEN bp.lower_bound AND bp.upper_bound
JOIN Discounts AS d 
    ON t.discount_id = d.id
WHERE td.Distance IS NOT NULL
AND t.date_of_purchase BETWEEN '2024-01-01' AND '2024-03-31';

-- 3. Show how long it takes on average to complete each line
SELECT 
    ps.line_number AS Line,
    ROUND(AVG(Travel_Time),2) AS Avg_Travel_Time_Minutes
FROM Planned_Schedules AS ps
JOIN (
    SELECT 
        ps.line_number AS Line_Number,
        r.id AS Run_ID,
        MAX(st.current_travel_time) - MIN(st.current_travel_time) AS Travel_Time
    FROM Stop_Times AS st
    JOIN Runs AS r 
		ON st.run_id = r.id
    JOIN Planned_Schedules AS ps 
		ON r.schedule_id = ps.id
    GROUP BY ps.line_number, r.id
) subquery ON ps.line_number = subquery.Line_Number
GROUP BY ps.line_number
ORDER BY Avg_Travel_Time_Minutes ASC;

-- 4. Generate monthly raport of ticket income at each station
SELECT 
    s.station_name AS Name_of_Station,
	MONTH(t.date_of_purchase) AS Months,
    ROUND(SUM(bp.price - (bp.price * d.discount_percentage)),2) AS Price
FROM Tickets AS t
JOIN (
    SELECT 
        t.id AS Ticket_ID,
        ABS(rs_end.current_km - rs_start.current_km) AS Distance,
        ps.line_number AS Route_Line
    FROM Tickets AS t
    JOIN Runs AS r 
		ON t.run_id = r.id
    JOIN Planned_Schedules AS ps 
		ON r.schedule_id = ps.id
    JOIN Route_Stops AS rs_start 
        ON ps.line_number = rs_start.line_number 
        AND t.starting_station = rs_start.station_id
    JOIN Route_Stops AS rs_end 
        ON ps.line_number = rs_end.line_number 
        AND t.ending_station = rs_end.station_id
) subquery ON t.id = subquery.Ticket_ID
JOIN Base_Prices AS bp 
    ON subquery.Distance BETWEEN bp.lower_bound AND bp.upper_bound
JOIN Discounts AS d 
    ON t.discount_id = d.id
JOIN Stations AS s
	ON t.starting_station = s.id
GROUP BY s.station_name, MONTH(t.date_of_purchase);

-- 5. Check train delays raport monthly from the best month to the worst
SELECT 
	MONTH(st.time_of_stop) AS Month_Number, 
	SUM(st.current_travel_time - rs.current_travel_time) AS Sum_of_Delays_in_Minutes
FROM Stop_Times AS st
JOIN Runs
	ON st.run_id = Runs.id
JOIN Planned_Schedules AS ps
	ON Runs.schedule_id = ps.id
JOIN Route_Stops AS rs
	ON st.stop_number = rs.stop_number AND ps.line_number = rs.line_number
WHERE (st.current_travel_time - rs.current_travel_time) > 0
GROUP BY MONTH(st.time_of_stop)
ORDER BY SUM(st.current_travel_time - rs.current_travel_time) ASC;

-- 6. What day type bring the most of SKM revenue
SELECT 
    ps.day_type,
    ROUND(SUM(bp.price - (bp.price * d.discount_percentage)),2) AS Revenue
FROM Tickets AS t
JOIN (
    SELECT
		t.id AS Ticket_ID,
        ps.day_type AS day_type,
        ABS(rs_end.current_km - rs_start.current_km) AS Distance,
        ps.line_number AS Route_Line
    FROM Tickets AS t
    JOIN Runs AS r 
		ON t.run_id = r.id
    JOIN Planned_Schedules AS ps 
		ON r.schedule_id = ps.id
    JOIN Route_Stops AS rs_start 
        ON ps.line_number = rs_start.line_number 
        AND t.starting_station = rs_start.station_id
    JOIN Route_Stops AS rs_end 
        ON ps.line_number = rs_end.line_number 
        AND t.ending_station = rs_end.station_id
) subquery ON t.id = subquery.Ticket_ID
JOIN Base_Prices AS bp 
    ON subquery.Distance BETWEEN bp.lower_bound AND bp.upper_bound
JOIN Discounts AS d 
    ON t.discount_id = d.id
JOIN Runs AS r
	ON t.run_id = r.id
JOIN Planned_Schedules AS ps
	ON ps.id = r.schedule_id
GROUP BY ps.day_type
ORDER BY Revenue DESC;

-- 7. Which stations have the most senior passengers on average every week
SELECT
    st.station_name AS Station_Name,
    AVG(ticket_count) AS Avg_Seniors_Per_Week
FROM (
    SELECT 
        t.starting_station,
        COUNT(t.id) AS ticket_count,
        DATEPART(week, t.date_of_purchase) AS week_number
    FROM Tickets AS t
    JOIN Discounts AS d 
		ON t.discount_id = d.id
    JOIN Stations AS s 
		ON t.starting_station = s.id
    WHERE d.name_of_type = 'Senior'
    GROUP BY t.starting_station, DATEPART(week, t.date_of_purchase)
) subquery
JOIN Stations AS st
	ON subquery.starting_station = st.id
GROUP BY st.station_name
ORDER BY Avg_Seniors_Per_Week DESC;