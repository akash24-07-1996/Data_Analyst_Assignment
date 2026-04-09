CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    phone_number VARCHAR(20),
    mail_id VARCHAR(100),
    billing_address VARCHAR(255)
);

SELECT * FROM booking_commercials

CREATE TABLE items (
    item_id VARCHAR(50) PRIMARY KEY,
    item_name VARCHAR(100),
    item_rate DECIMAL(10, 2)
);

CREATE TABLE bookings (
    booking_id VARCHAR(50) PRIMARY KEY,
    booking_date TIMESTAMP,
    room_no VARCHAR(50),
    user_id VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE booking_commercials (
    id VARCHAR(50) PRIMARY KEY,
    booking_id VARCHAR(50),
    bill_id VARCHAR(50),
    bill_date TIMESTAMP,
    item_id VARCHAR(50),
    item_quantity DECIMAL(10, 2),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);


INSERT INTO users VALUES ('21wrcxuy-67erfn', 'John Doe', '9788552489', 'john.doe@example.com', 'XX, Street Y, ABC City');
INSERT INTO items VALUES ('itm-a9e8-q8fu', 'Tawa Paratha', 18);
INSERT INTO items VALUES ('itm-a07vh-aer8', 'Mix Veg', 89);
INSERT INTO bookings VALUES ('bk-09f3e-95hj', '2021-09-23 7:36:48', 'rm-bhf9-aerjn', '21wrcxuy-67erfn');
INSERT INTO booking_commercials VALUES ('q34r-3q4o8-q34u', 'bk-09f3e-95hj', 'bl-0a87y-q340', '2021-09-23 12:03:22', 'itm-a9e8-q8fu', 3);


SELECT * FROM users;
SELECT * FROM items;
SELECT * FROM bookings;
SELECT * FROM booking_commercials;


-- Join Tables
SELECT 
    u.name,
    b.booking_id,
    b.room_no,
    i.item_name,
    bc.item_quantity,
    i.item_rate,
    (bc.item_quantity * i.item_rate) AS total_price
FROM booking_commercials bc
JOIN bookings b ON bc.booking_id = b.booking_id
JOIN users u ON b.user_id = u.user_id
JOIN items i ON bc.item_id = i.item_id;

-- Calculate Total Revenue
SELECT 
    SUM(bc.item_quantity * i.item_rate) AS total_revenue
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id;


--Revenue Per User

SELECT 
    u.name,
    SUM(bc.item_quantity * i.item_rate) AS total_spent
FROM booking_commercials bc
JOIN bookings b ON bc.booking_id = b.booking_id
JOIN users u ON b.user_id = u.user_id
JOIN items i ON bc.item_id = i.item_id
GROUP BY u.name;


--Top Customer

SELECT 
    u.name,
    SUM(bc.item_quantity * i.item_rate) AS total_spent
FROM booking_commercials bc
JOIN bookings b ON bc.booking_id = b.booking_id
JOIN users u ON b.user_id = u.user_id
JOIN items i ON bc.item_id = i.item_id
GROUP BY u.name
ORDER BY total_spent DESC
LIMIT 1;

--Date-wise Revenue
SELECT 
    DATE(bc.bill_date) AS bill_day,
    SUM(bc.item_quantity * i.item_rate) AS daily_revenue
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id
GROUP BY DATE(bc.bill_date)
ORDER BY bill_day;


-- Last booked room

SELECT 
    u.user_id,
    b.room_no
FROM users u
JOIN bookings b ON u.user_id = b.user_id
WHERE b.booking_date = (
    SELECT MAX(b2.booking_date)
    FROM bookings b2
    WHERE b2.user_id = u.user_id
);

-- Total billing per booking (November 2021)
SELECT 
    b.booking_id,
    SUM(bc.item_quantity * i.item_rate) AS total_bill
FROM bookings b
JOIN booking_commercials bc ON b.booking_id = bc.booking_id
JOIN items i ON bc.item_id = i.item_id
WHERE EXTRACT(MONTH FROM b.booking_date) = 11
  AND EXTRACT(YEAR FROM b.booking_date) = 2021
GROUP BY b.booking_id;

--Bills > 1000 (October 2021)
SELECT 
    bc.bill_id,
    SUM(bc.item_quantity * i.item_rate) AS bill_amount
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id
WHERE EXTRACT(MONTH FROM bc.bill_date) = 10
  AND EXTRACT(YEAR FROM bc.bill_date) = 2021
GROUP BY bc.bill_id
HAVING SUM(bc.item_quantity * i.item_rate) > 1000;

--Most & Least ordered item per month
WITH item_orders AS (
    SELECT 
        EXTRACT(MONTH FROM bc.bill_date) AS month,
        i.item_name,
        SUM(bc.item_quantity) AS total_qty
    FROM booking_commercials bc
    JOIN items i ON bc.item_id = i.item_id
    WHERE EXTRACT(YEAR FROM bc.bill_date) = 2021
    GROUP BY month, i.item_name
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY month ORDER BY total_qty DESC) AS rnk_desc,
           RANK() OVER (PARTITION BY month ORDER BY total_qty ASC) AS rnk_asc
    FROM item_orders
)
SELECT *
FROM ranked
WHERE rnk_desc = 1 OR rnk_asc = 1;


-- Second highest bill per month

WITH bill_values AS (
    SELECT 
        bc.bill_id,
        EXTRACT(MONTH FROM bc.bill_date) AS month,
        SUM(bc.item_quantity * i.item_rate) AS bill_amount
    FROM booking_commercials bc
    JOIN items i ON bc.item_id = i.item_id
    WHERE EXTRACT(YEAR FROM bc.bill_date) = 2021
    GROUP BY bc.bill_id, month
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY month ORDER BY bill_amount DESC) AS rnk
    FROM bill_values
)
SELECT *
FROM ranked
WHERE rnk = 2;

