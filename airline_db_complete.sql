-- ============================================================
--  AIRLINE MANAGEMENT SYSTEM - Complete Database Setup
--  Run this in MySQL: source airline_db_complete.sql
--  Or: mysql -u root -p < airline_db_complete.sql
-- ============================================================

DROP DATABASE IF EXISTS airline_db;
CREATE DATABASE airline_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE airline_db;

-- ── USERS ────────────────────────────────────────────────────
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    role ENUM('ADMIN', 'CUSTOMER') NOT NULL DEFAULT 'CUSTOMER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB;

-- ── AIRLINES ─────────────────────────────────────────────────
CREATE TABLE airlines (
    airline_id INT PRIMARY KEY AUTO_INCREMENT,
    airline_code VARCHAR(10) UNIQUE NOT NULL,
    airline_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_airline_code (airline_code)
) ENGINE=InnoDB;

-- ── AIRPORTS ─────────────────────────────────────────────────
CREATE TABLE airports (
    airport_id INT PRIMARY KEY AUTO_INCREMENT,
    airport_code VARCHAR(10) UNIQUE NOT NULL,
    airport_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_airport_code (airport_code),
    INDEX idx_city (city)
) ENGINE=InnoDB;

-- ── FLIGHTS ──────────────────────────────────────────────────
CREATE TABLE flights (
    flight_id INT PRIMARY KEY AUTO_INCREMENT,
    flight_number VARCHAR(20) UNIQUE NOT NULL,
    airline_id INT NOT NULL,
    origin_airport_id INT NOT NULL,
    destination_airport_id INT NOT NULL,
    total_seats INT NOT NULL DEFAULT 150,
    base_price DECIMAL(10, 2) NOT NULL,
    status ENUM('ACTIVE', 'CANCELLED', 'COMPLETED') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (airline_id) REFERENCES airlines(airline_id) ON DELETE CASCADE,
    FOREIGN KEY (origin_airport_id) REFERENCES airports(airport_id) ON DELETE CASCADE,
    FOREIGN KEY (destination_airport_id) REFERENCES airports(airport_id) ON DELETE CASCADE,
    INDEX idx_flight_number (flight_number),
    INDEX idx_airline (airline_id)
) ENGINE=InnoDB;

-- ── SCHEDULES ────────────────────────────────────────────────
CREATE TABLE schedules (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    flight_id INT NOT NULL,
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    available_seats INT NOT NULL,
    status ENUM('SCHEDULED', 'DEPARTED', 'ARRIVED', 'CANCELLED') DEFAULT 'SCHEDULED',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id) ON DELETE CASCADE,
    INDEX idx_flight_schedule (flight_id, departure_time),
    INDEX idx_departure_time (departure_time)
) ENGINE=InnoDB;

-- ── BOOKINGS ─────────────────────────────────────────────────
CREATE TABLE bookings (
    booking_id INT PRIMARY KEY AUTO_INCREMENT,
    pnr VARCHAR(10) UNIQUE NOT NULL,
    user_id INT NOT NULL,
    schedule_id INT NOT NULL,
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_passengers INT NOT NULL DEFAULT 1,
    total_amount DECIMAL(10, 2) NOT NULL,
    status ENUM('CONFIRMED', 'CANCELLED', 'COMPLETED') DEFAULT 'CONFIRMED',
    payment_status ENUM('PENDING', 'PAID', 'REFUNDED') DEFAULT 'PENDING',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES schedules(schedule_id) ON DELETE CASCADE,
    INDEX idx_pnr (pnr),
    INDEX idx_user_booking (user_id, booking_date)
) ENGINE=InnoDB;

-- ── PASSENGERS ───────────────────────────────────────────────
CREATE TABLE passengers (
    passenger_id INT PRIMARY KEY AUTO_INCREMENT,
    booking_id INT NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    age INT NOT NULL,
    gender ENUM('MALE', 'FEMALE', 'OTHER') NOT NULL,
    seat_number VARCHAR(10),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE,
    INDEX idx_booking (booking_id)
) ENGINE=InnoDB;

-- ── VIEWS ────────────────────────────────────────────────────
CREATE VIEW booking_summary AS
SELECT
    b.booking_id, b.pnr,
    u.full_name AS customer_name, u.email AS customer_email,
    f.flight_number,
    a1.city AS origin, a2.city AS destination,
    s.departure_time, s.arrival_time,
    b.total_passengers, b.total_amount,
    b.status AS booking_status, b.booking_date
FROM bookings b
JOIN users u ON b.user_id = u.user_id
JOIN schedules s ON b.schedule_id = s.schedule_id
JOIN flights f ON s.flight_id = f.flight_id
JOIN airports a1 ON f.origin_airport_id = a1.airport_id
JOIN airports a2 ON f.destination_airport_id = a2.airport_id;

CREATE VIEW flight_occupancy AS
SELECT
    f.flight_number, al.airline_name, s.schedule_id, s.departure_time,
    f.total_seats, s.available_seats,
    (f.total_seats - s.available_seats) AS booked_seats,
    ROUND(((f.total_seats - s.available_seats) / f.total_seats * 100), 2) AS occupancy_percentage
FROM schedules s
JOIN flights f ON s.flight_id = f.flight_id
JOIN airlines al ON f.airline_id = al.airline_id
WHERE s.status = 'SCHEDULED';

-- ── SEED DATA ────────────────────────────────────────────────
-- Passwords: admin → admin123 | john_doe / jane_smith → user123 (BCrypt)
INSERT INTO users (username, password_hash, full_name, email, phone, role) VALUES
('admin',      '$2a$10$X7d2K5Z8n0FKzHjGH7YGS.rN0l5U9cQ8LrYJQz5sK2aYRZY8YJzIK', 'System Administrator', 'admin@airline.com', '1234567890', 'ADMIN'),
('john_doe',   '$2a$10$Y8e3L6A9o1GLAiKjI8ZHT.sO1m6V0dR9MsZKRa6tL3bZSaZ9ZKaJL', 'John Doe',             'john@email.com',  '9876543210', 'CUSTOMER'),
('jane_smith', '$2a$10$Y8e3L6A9o1GLAiKjI8ZHT.sO1m6V0dR9MsZKRa6tL3bZSaZ9ZKaJL', 'Jane Smith',           'jane@email.com',  '9876543211', 'CUSTOMER');

INSERT INTO airlines (airline_code, airline_name, country) VALUES
('AI', 'Air India',       'India'),
('6E', 'IndiGo',          'India'),
('SG', 'SpiceJet',        'India'),
('UK', 'Vistara',         'India'),
('BA', 'British Airways', 'United Kingdom'),
('EK', 'Emirates',        'UAE');

INSERT INTO airports (airport_code, airport_name, city, country) VALUES
('DEL', 'Indira Gandhi International Airport',              'Delhi',     'India'),
('BOM', 'Chhatrapati Shivaji Maharaj International Airport','Mumbai',    'India'),
('BLR', 'Kempegowda International Airport',                 'Bangalore', 'India'),
('MAA', 'Chennai International Airport',                    'Chennai',   'India'),
('CCU', 'Netaji Subhas Chandra Bose International Airport', 'Kolkata',   'India'),
('HYD', 'Rajiv Gandhi International Airport',               'Hyderabad', 'India'),
('GOI', 'Goa International Airport',                        'Goa',       'India'),
('AMD', 'Sardar Vallabhbhai Patel International Airport',   'Ahmedabad', 'India'),
('LHR', 'London Heathrow Airport',                         'London',    'United Kingdom'),
('DXB', 'Dubai International Airport',                     'Dubai',     'UAE');

INSERT INTO flights (flight_number, airline_id, origin_airport_id, destination_airport_id, total_seats, base_price, status) VALUES
('AI101', 1, 1, 2, 180, 4500.00, 'ACTIVE'),
('6E202', 2, 2, 3, 150, 3200.00, 'ACTIVE'),
('SG303', 3, 3, 4, 160, 2800.00, 'ACTIVE'),
('UK404', 4, 1, 3, 170, 4000.00, 'ACTIVE'),
('AI505', 1, 2, 5, 180, 5000.00, 'ACTIVE'),
('6E606', 2, 4, 6, 150, 3500.00, 'ACTIVE'),
('SG707', 3, 1, 7, 140, 6500.00, 'ACTIVE'),
('UK808', 4, 3, 8, 170, 3000.00, 'ACTIVE'),
('BA901', 5, 1, 9, 250, 35000.00,'ACTIVE'),
('EK902', 6, 2,10, 300, 28000.00,'ACTIVE');

INSERT INTO schedules (flight_id, departure_time, arrival_time, available_seats, status) VALUES
(1, DATE_ADD(NOW(), INTERVAL 5 HOUR),                                            DATE_ADD(NOW(), INTERVAL 7 HOUR),                                            180, 'SCHEDULED'),
(2, DATE_ADD(NOW(), INTERVAL 8 HOUR),                                            DATE_ADD(NOW(), INTERVAL 10 HOUR),                                           150, 'SCHEDULED'),
(3, DATE_ADD(NOW(), INTERVAL 12 HOUR),                                           DATE_ADD(NOW(), INTERVAL 14 HOUR),                                           160, 'SCHEDULED'),
(4, DATE_ADD(NOW(), INTERVAL 1 DAY),                                             DATE_ADD(NOW(), INTERVAL 1 DAY) + INTERVAL 2 HOUR,                          170, 'SCHEDULED'),
(5, DATE_ADD(NOW(), INTERVAL 1 DAY) + INTERVAL 6 HOUR,                          DATE_ADD(NOW(), INTERVAL 1 DAY) + INTERVAL 8 HOUR,                          180, 'SCHEDULED'),
(6, DATE_ADD(NOW(), INTERVAL 1 DAY) + INTERVAL 10 HOUR,                         DATE_ADD(NOW(), INTERVAL 1 DAY) + INTERVAL 12 HOUR,                         150, 'SCHEDULED'),
(7, DATE_ADD(NOW(), INTERVAL 2 DAY),                                             DATE_ADD(NOW(), INTERVAL 2 DAY) + INTERVAL 2 HOUR,                          140, 'SCHEDULED'),
(8, DATE_ADD(NOW(), INTERVAL 2 DAY) + INTERVAL 8 HOUR,                          DATE_ADD(NOW(), INTERVAL 2 DAY) + INTERVAL 10 HOUR,                         170, 'SCHEDULED'),
(9, DATE_ADD(NOW(), INTERVAL 3 DAY),                                             DATE_ADD(NOW(), INTERVAL 3 DAY) + INTERVAL 9 HOUR,                          250, 'SCHEDULED'),
(10,DATE_ADD(NOW(), INTERVAL 3 DAY) + INTERVAL 4 HOUR,                          DATE_ADD(NOW(), INTERVAL 3 DAY) + INTERVAL 8 HOUR,                          300, 'SCHEDULED'),
(1, DATE_ADD(NOW(), INTERVAL 4 DAY),                                             DATE_ADD(NOW(), INTERVAL 4 DAY) + INTERVAL 2 HOUR,                          180, 'SCHEDULED'),
(2, DATE_ADD(NOW(), INTERVAL 5 DAY),                                             DATE_ADD(NOW(), INTERVAL 5 DAY) + INTERVAL 2 HOUR,                          150, 'SCHEDULED'),
(3, DATE_ADD(NOW(), INTERVAL 6 DAY),                                             DATE_ADD(NOW(), INTERVAL 6 DAY) + INTERVAL 2 HOUR,                          160, 'SCHEDULED');

INSERT INTO bookings (pnr, user_id, schedule_id, total_passengers, total_amount, status, payment_status) VALUES
('PNR001', 2, 1, 2, 9000.00, 'CONFIRMED', 'PAID'),
('PNR002', 2, 4, 1, 4000.00, 'CONFIRMED', 'PAID');

INSERT INTO passengers (booking_id, first_name, last_name, age, gender, seat_number) VALUES
(1, 'John', 'Doe',  35, 'MALE',   '12A'),
(1, 'Mary', 'Doe',  32, 'FEMALE', '12B'),
(2, 'John', 'Doe',  35, 'MALE',   '15C');

UPDATE schedules SET available_seats = available_seats - 2 WHERE schedule_id = 1;
UPDATE schedules SET available_seats = available_seats - 1 WHERE schedule_id = 4;

SELECT 'Database setup complete!' AS status;
SELECT CONCAT('Users: ', COUNT(*)) AS info FROM users
UNION ALL SELECT CONCAT('Airlines: ', COUNT(*)) FROM airlines
UNION ALL SELECT CONCAT('Airports: ', COUNT(*)) FROM airports
UNION ALL SELECT CONCAT('Flights: ', COUNT(*)) FROM flights
UNION ALL SELECT CONCAT('Schedules: ', COUNT(*)) FROM schedules;
