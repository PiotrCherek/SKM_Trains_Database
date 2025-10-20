CREATE TABLE Stations (
	id tinyint PRIMARY KEY IDENTITY(1,1),
	station_name varchar(50) NOT NULL CHECK (station_name LIKE '[A-Z¥ÆÊ£ÑÓŒ¯]%'
	AND station_name NOT LIKE '%[^A-Z¥ÆÊ£ÑÓŒ¯a-z¹æê³ñóœŸ¿ ]%'
	AND station_name NOT LIKE '% [^A-Z¥ÆÊ£ÑÓŒ¯]%'),
	num_of_platforms tinyint NOT NULL,
	station_address varchar(100),
	phone_number char(15) CHECK (phone_number LIKE '+[0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9]'),
	city varchar(50) NOT NULL CHECK (city LIKE '[A-Z¥ÆÊ£ÑÓŒ¯]%'
	AND city NOT LIKE '%[^A-Z¥ÆÊ£ÑÓŒ¯a-z¹æê³ñóœŸ¿ ]%'
	AND city NOT LIKE '% [^A-Z¥ÆÊ£ÑÓŒ¯]%')
);

CREATE TABLE Passengers (
	id int PRIMARY KEY IDENTITY(1,1) ,
	passenger_name varchar(50) NOT NULL CHECK (passenger_name LIKE '[A-Z¥ÆÊ£ÑÓŒ¯]%'
	AND passenger_name NOT LIKE '%[^A-Z¥ÆÊ£ÑÓŒ¯a-z¹æê³ñóœŸ¿ ]%'
	AND passenger_name NOT LIKE '% [^A-Z¥ÆÊ£ÑÓŒ¯]%'),
	passenger_surname varchar(55) NOT NULL CHECK (passenger_surname LIKE '[A-Z¥ÆÊ£ÑÓŒ¯]%'
	AND passenger_surname NOT LIKE '%[^A-Z¥ÆÊ£ÑÓŒ¯a-z¹æê³ñóœŸ¿ ]%'
	AND passenger_surname NOT LIKE '% [^A-Z¥ÆÊ£ÑÓŒ¯]%'),
	date_of_birth date NOT NULL
);

CREATE TABLE Discounts (
	id tinyint PRIMARY KEY IDENTITY(1,1),
	name_of_type varchar(50) NOT NULL,
	discount_percentage decimal(3,2) NOT NULL CHECK (discount_percentage >= 0.00 AND discount_percentage <= 1.00),
	requirements varchar(700) NOT NULL,
	finish_date date
);

CREATE TABLE Base_Prices (
	range_id tinyint PRIMARY KEY IDENTITY(1,1),
	price money NOT NULL,
	lower_bound smallint NOT NULL,
	upper_bound smallint NOT NULL,
	CHECK (lower_bound < upper_bound)
);

CREATE TABLE SKM_Routes (
	line_number varchar(4) PRIMARY KEY CHECK (line_number LIKE 'S[0-9]' OR 
    line_number LIKE 'S[0-9][0-9]' OR 
    line_number LIKE 'S[0-9][0-9][0-9]'),
	starting_station tinyint NOT NULL,
	ending_station tinyint NOT NULL,
	travel_time decimal(5,2) NOT NULL,
    num_of_stops int NOT NULL,
    distance_km decimal(10, 2) NOT NULL,
	CONSTRAINT FK_SKM_Routes_starting_station FOREIGN KEY (starting_station) REFERENCES Stations(id),
    CONSTRAINT FK_SKM_Routes_ending_station FOREIGN KEY (ending_station) REFERENCES Stations(id)
);

CREATE TABLE Planned_Schedules (
	id smallint PRIMARY KEY IDENTITY(1,1),
	line_number varchar(4) NOT NULL,
	departure_time time NOT NULL,
	arrival_time time NOT NULL,
	day_of_the_week varchar(15) NOT NULL CHECK (day_of_the_week LIKE 'Monday' OR
	day_of_the_week LIKE 'Tuesday' OR
	day_of_the_week LIKE 'Wednesday' OR
	day_of_the_week LIKE 'Thursday' OR
	day_of_the_week LIKE 'Friday' OR
	day_of_the_week LIKE 'Saturday' OR
	day_of_the_week LIKE 'Sunday'),
	day_type varchar(100) NOT NULL,
	valid_from date NOT NULL,
	valid_to date NOT NULL,
	CONSTRAINT FK_Planned_Schedules_line_number FOREIGN KEY (line_number) REFERENCES SKM_Routes(line_number)
);

CREATE TABLE Runs (
	id smallint PRIMARY KEY IDENTITY(1,1),
	schedule_id smallint NOT NULL,
	run_date date NOT NULL,
	CONSTRAINT FK_Runs_schedule_id FOREIGN KEY (schedule_id) REFERENCES Planned_Schedules(id)
);

CREATE TABLE Route_Stops (
	line_number varchar(4) NOT NULL,
	stop_number tinyint NOT NULL,
	station_id tinyint NOT NULL,
	current_km decimal(7,2) NOT NULL,
	current_travel_time decimal(6,2) NOT NULL,
	platform_num tinyint NOT NULL,
	stop_duration decimal(5,2) NOT NULL
	PRIMARY KEY (line_number, stop_number),
    CONSTRAINT FK_Route_Stops_line_number FOREIGN KEY (line_number) REFERENCES SKM_Routes(line_number),
    CONSTRAINT FK_Route_Stops_station_id FOREIGN KEY (station_id) REFERENCES Stations(id)
);

CREATE TABLE Tickets (
	id int PRIMARY KEY IDENTITY(1,1),
	passenger_id int NOT NULL,
	discount_id tinyint,
	run_id smallint NOT NULL,
	date_of_purchase date NOT NULL,
	starting_station tinyint NOT NULL,
	ending_station tinyint NOT NULL,
	CONSTRAINT FK_Tickets_passenger_id FOREIGN KEY (passenger_id) REFERENCES Passengers(id),
    CONSTRAINT FK_Tickets_discount_id FOREIGN KEY (discount_id) REFERENCES Discounts(id),
    CONSTRAINT FK_Tickets_run_id FOREIGN KEY (run_id) REFERENCES Runs(id),
    CONSTRAINT FK_Tickets_starting_station FOREIGN KEY (starting_station) REFERENCES Stations(id),
    CONSTRAINT FK_Tickets_ending_station FOREIGN KEY (ending_station) REFERENCES Stations(id)
);

CREATE TABLE Stop_Times (
	run_id smallint NOT NULL,
	stop_number tinyint NOT NULL,
	station_id tinyint NOT NULL,
	stop_duration decimal(7,2) NOT NULL,
	time_of_stop datetime NOT NULL,
	platform_num tinyint NOT NULL,
	current_travel_time decimal(6,2) NOT NULL,
	PRIMARY KEY (run_id, stop_number),
	CONSTRAINT FK_Stop_Times_run_id FOREIGN KEY (run_id) REFERENCES Runs(id),
	CONSTRAINT FK_Stop_Times_station_id FOREIGN KEY (station_id) REFERENCES Stations(id)
);