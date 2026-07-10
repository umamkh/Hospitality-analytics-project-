-- CREATE DATABASE hospitality;
-- USE hospitality;
SELECT * FROM dim_hotels;
SELECT * FROM dim_date;
SELECT * FROM dim_rooms;
SELECT * FROM fact_aggregated_bookings;
SELECT * FROM fact_bookings;
SELECT * FROM dim_hotels;
CREATE TABLE fact_bookings (
    booking_id VARCHAR(255) PRIMARY KEY,
    property_id INT, -- This will link to dim_hotels
    booking_date DATE,
    check_in_date DATE,
    checkout_date DATE,
    no_guests INT,
    room_category VARCHAR(10),
    booking_platform VARCHAR(100),
    ratings_given FLOAT NULL,
    booking_status VARCHAR(100),
    revenue_generated INT,
    revenue_realized INT
);
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_bookings.csv' 
INTO TABLE fact_bookings 
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' 
IGNORE 1 ROWS;


SELECT * FROM fact_bookings;
SELECT 
    CONCAT(ROUND(SUM(revenue_realized) / 1000000, 0), 'M') AS Total_Revenue
FROM fact_bookings;
SELECT COUNT(booking_id) AS Total_Bookings FROM fact_bookings;

SELECT 
    CONCAT(ROUND(COUNT(CASE WHEN booking_status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(booking_id), 2),'%') AS Cancellation_Rate_Pct
FROM fact_bookings;
SELECT SUM(no_guests) AS Total_Guests FROM fact_bookings;
SELECT 
    CONCAT(ROUND(SUM(max_success) * 100.0 / SUM(max_cap), 2),'%') AS occupancy_rate
FROM (
    SELECT 
        property_id, 
        MAX(successful_bookings) AS max_success, 
        MAX(capacity) AS max_cap
    FROM fact_aggregated_bookings
    GROUP BY property_id
) AS hotel_summary;

SELECT 
    booking_date,
    -- 1. Total Revenue By Day
    SUM(revenue_realized) AS total_revenue,
    
    -- 2. Occupancy Rate By Day
    -- (Booked Rooms / Total Available Rooms)
    
    
    -- Assuming a constant total_rooms for this example
    CAST(COUNT(booking_id) AS FLOAT) / 1200 AS occupancy_rate,
    
    -- 3. Cancellation Rate By Day
    -- (Cancelled Bookings / Total Bookings)
    CAST(SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS FLOAT) 
        / COUNT(*) AS cancellation_rate,
    
    -- 4. Booking Rate Per Day (Total Volume)
    COUNT(booking_id) AS total_bookings

FROM fact_bookings
WHERE booking_date BETWEEN '2022-04-01' AND '2022-08-01'
GROUP BY booking_date
ORDER BY booking_date;

SELECT 
    h.city, 
    h.property_name, 
    SUM(b.revenue_realized) / 1000000 AS revenue_M
FROM 
    fact_bookings b
JOIN 
    dim_hotels h ON b.property_id = h.property_id
GROUP BY 
    h.city, 
    h.property_name
ORDER BY 
    revenue_M DESC;

SELECT 
    r.room_class, 
    CONCAT(ROUND(SUM(revenue_realized) / 1000000, 0), 'M') AS total_revenue
FROM fact_bookings b
JOIN dim_rooms r 
    ON b.room_category = r.room_id
GROUP BY r.room_class
ORDER BY total_revenue DESC;

SELECT 
    booking_status, 
    COUNT(booking_id) AS total_bookings,
    ROUND(COUNT(booking_id) * 100.0 / SUM(COUNT(booking_id)) OVER(), 2) AS percentage
FROM fact_bookings
GROUP BY booking_status
ORDER BY total_bookings DESC;


