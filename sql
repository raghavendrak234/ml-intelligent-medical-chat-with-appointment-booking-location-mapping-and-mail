
-- Cleanup existing doctor records to avoid duplicate key errors

-- Create database
DROP DATABASE IF EXISTS chatbot;
CREATE DATABASE chatbot;
USE chatbot;


-- Users table (for both patients and doctors)
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    user_type ENUM('patient', 'doctor') NOT NULL,
    specialization VARCHAR(100), -- For doctors only
    date_registered DATETIME DEFAULT CURRENT_TIMESTAMP
);
-- Hospital Location Table
CREATE TABLE hospital_location (
    id INT AUTO_INCREMENT PRIMARY KEY,
    location VARCHAR(255),
    hospital VARCHAR(255)
);
-- Doctor details table (for additional doctor information)
-- Doctor details table (with correct foreign key for location_id)
CREATE TABLE doctor_details (
    doctor_id INT PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    qualification VARCHAR(255) NOT NULL,
    experience_years INT,
    consultation_fee DECIMAL(10, 2),
    location_id INT,  -- This links to hospital_location.id
    FOREIGN KEY (doctor_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (location_id) REFERENCES hospital_location(id) ON DELETE SET NULL -- Link to hospital_location table
);




-- Patient details table (for additional patient information)
CREATE TABLE patient_details (
    patient_id INT PRIMARY KEY,
    date_of_birth DATE,
    gender ENUM('Male', 'Female', 'Other'),
    blood_group VARCHAR(10),
    allergies TEXT,
    chronic_conditions TEXT,
    FOREIGN KEY (patient_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Appointments table
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    reason TEXT NOT NULL,
    status ENUM('Pending', 'Confirmed', 'Completed', 'Cancelled') DEFAULT 'Pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Chat messages table (for AI chat history)
CREATE TABLE chat_messages (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    message_text TEXT NOT NULL,
    is_bot_message BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Medical records table
CREATE TABLE medical_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_id INT,
    diagnosis TEXT NOT NULL,
    prescription TEXT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL
);

-- Contact messages table
-- Contact messages table
CREATE TABLE contact_messages (
    message_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    status ENUM('Unread', 'Read', 'Responded') DEFAULT 'Unread',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Cleanup existing doctor records to avoid duplicate key errors
DELETE FROM doctor_details;
DELETE FROM users WHERE user_type = 'doctor';


ALTER TABLE doctor_details
ADD COLUMN hospital_location VARCHAR(255) DEFAULT 'Not Specified';
-- Insert sample doctors
INSERT INTO users (name, email, password, phone, user_type) VALUES
('Dr. Sarah Johnson', 'sarah.johnson@example.com', 'hashed_password_here', '+1 (555) 123-4567', 'doctor'),
('Dr. Michael Chen', 'michael.chen@example.com', 'hashed_password_here', '+1 (555) 234-5678', 'doctor'),
('Dr. Emily Rodriguez', 'emily.rodriguez@example.com', 'hashed_password_here', '+1 (555) 345-6789', 'doctor'),
('Dr. David Smith', 'david.smith@example.com', 'hashed_password_here', '+1 (555) 456-7890', 'doctor');


CREATE TABLE appointment_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    time DATETIME,
    status VARCHAR(50) DEFAULT 'pending'
);
CREATE TABLE appointment_requests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    time DATETIME,
    status VARCHAR(50) DEFAULT 'pending'
);

-- Insert doctor details
INSERT INTO doctor_details (doctor_id, specialization, qualification, experience_years, consultation_fee) VALUES
(1, 'Cardiologist', 'MD, Cardiology', 15, 150.00),
(2, 'General Physician', 'MBBS, MD', 10, 100.00),
(3, 'Dermatologist', 'MD, Dermatology', 8, 120.00),
(4, 'Neurologist', 'MD, Neurology', 12, 170.00);

-- Sample patient registration query
INSERT INTO users (name, email, password, phone, user_type) VALUES
('John Doe', 'john.doe@example.com', 'hashed_password_here', '+1 (555) 987-6543', 'patient');

-- Insert patient details
INSERT INTO patient_details (patient_id, date_of_birth, gender, blood_group) VALUES
(5, '1983-06-15', 'Male', 'O+');

-- Sample appointment booking query
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, reason, status) VALUES
(5, 2, '2025-04-05', '10:00:00', 'Regular checkup', 'Confirmed'),
(5, 1, '2025-04-10', '14:00:00', 'Heart palpitations', 'Pending'),
(5, 3, '2025-03-21', '11:00:00', 'Skin rash assessment', 'Completed');

-- Query to get all appointments for a patient
SELECT a.appointment_id, a.appointment_date, a.appointment_time, u.name AS doctor_name, a.reason, a.status 
FROM appointments a
JOIN users u ON a.doctor_id = u.user_id
WHERE a.patient_id = 5
ORDER BY a.appointment_date DESC;

-- Query to get all appointments for a doctor
SELECT a.appointment_id, a.appointment_date, a.appointment_time, u.name AS patient_name, a.reason, a.status 
FROM appointments a
JOIN users u ON a.patient_id = u.user_id
WHERE a.doctor_id = 1
ORDER BY a.appointment_date DESC;

-- Query to get pending appointment requests for a doctor
SELECT a.appointment_id, a.appointment_date, a.appointment_time, u.name AS patient_name, a.reason
FROM appointments a
JOIN users u ON a.patient_id = u.user_id
WHERE a.doctor_id = 1 AND a.status = 'Pending'
ORDER BY a.appointment_date, a.appointment_time;

-- Update appointment status (accept or decline)
UPDATE appointments SET status = 'Confirmed' WHERE appointment_id = 2;
-- OR
UPDATE appointments SET status = 'Cancelled' WHERE appointment_id = 2;




-- Save chat message
INSERT INTO chat_messages (user_id, message_text, is_bot_message) VALUES
(5, 'I have a persistent headache for the last 3 days', FALSE),
(5, 'Headaches can be caused by various factors including stress, dehydration, or eye strain. If it\'s persistent or severe, I recommend consulting with a doctor. Would you like to book an appointment?', TRUE);

-- Get chat history for a user
SELECT message_text, is_bot_message, created_at 
FROM chat_messages 
WHERE user_id = 5 
ORDER BY created_at;

-- Get all patients for a doctor
SELECT u.user_id, u.name, pd.gender, TIMESTAMPDIFF(YEAR, pd.date_of_birth, CURDATE()) AS age,
       MAX(a.appointment_date) AS last_visit
FROM users u
JOIN patient_details pd ON u.user_id = pd.patient_id
LEFT JOIN appointments a ON u.user_id = a.patient_id AND a.doctor_id = 1 AND a.status = 'Completed'
WHERE u.user_type = 'patient' AND EXISTS (
    SELECT 1 FROM appointments WHERE patient_id = u.user_id AND doctor_id = 1
)
GROUP BY u.user_id, u.name, pd.gender, pd.date_of_birth;

-- Store contact form message
INSERT INTO contact_messages (name, email, subject, message) VALUES
('Jane Smith', 'jane.smith@example.com', 'Question about services', 'I would like to know more about your telemedicine services.');

-- Get all contact form messages (for admin)
SELECT * FROM contact_messages ORDER BY created_at DESC;







-- Insert Hospital Locations
INSERT INTO hospital_location (location, hospital) VALUES
('https://maps.app.goo.gl/VL1kmZPrBcuiTL7ZA', 'Apollo BGS Hospitals'),
('https://maps.app.goo.gl/AxMjeurnbk7P5v2r9', 'Kamakshi hospital UNIT -II JP nagar'),
('https://maps.app.goo.gl/jwrubi2pgSsTrkVY6', 'SUYOG HOSPITAL'),
('https://maps.app.goo.gl/zBHYaTywQFedz8316', 'Kamakshi Hospital'),
('https://maps.app.goo.gl/zhXJ2fWfP6KCxQtH9', 'Apollo BGS Hospitals'),
('https://maps.app.goo.gl/68gMhFykzQHdNRv29', 'JSS Hospital'),
('https://maps.app.goo.gl/iCdnc5j3Y8v81W1E6', 'Manipal Hospital'),
('https://maps.app.goo.gl/kGtschnYMB98tSPP8', 'Sigma Hospital'),
('https://maps.app.goo.gl/oJkkxkRdbWRu26gG7', 'Anagha Hospital'),
('https://maps.app.goo.gl/hgrd7s7HoMwtN7LE6', 'Brindavan Hospital'),
('https://maps.app.goo.gl/VDKLTvea2n9KqmKXA', 'Sushrutha Clinic'),
('https://maps.app.goo.gl/9H6QhYaRiJHioL536', 'K R Hospital'),
('https://maps.app.goo.gl/1HDrfUGNHBscwan26', 'A R Hospital'),
('https://maps.app.goo.gl/LNbut6FcyU3YV92c9', 'Bhanavi Hospital'),
('https://maps.app.goo.gl/2mxVr8iPGi3RMSqX8', 'Gupthas Clinic');






-- Insert Doctors into Users Table
INSERT INTO users (name, email, password, phone, user_type) VALUES
('Dr. Shashank', 'shashank@example.com', 'password123', '9000000001', 'doctor'),
('Dr. Mahadev', 'mahadev@example.com', 'password123', '9000000002', 'doctor'),
('Dr. Sagar', 'sagar@example.com', 'password123', '9000000003', 'doctor'),
('Dr. Shankar', 'shankar@example.com', 'password123', '9000000004', 'doctor'),
('Dr. Sushant Singh', 'sushant@example.com', 'password123', '9000000005', 'doctor'),
('Dr. Ravi', 'ravi@example.com', 'password123', '9000000006', 'doctor'),
('Dr. Govind', 'govind@example.com', 'password123', '9000000007', 'doctor'),
('Dr. Hemalatha', 'hemalatha@example.com', 'password123', '9000000008', 'doctor'),
('Dr. Geetha', 'geetha@example.com', 'password123', '9000000009', 'doctor'),
('Dr. Seetha', 'seetha@example.com', 'password123', '9000000010', 'doctor'),
('Dr. Dhruthi', 'dhruthi@example.com', 'password123', '9000000011', 'doctor'),
('Dr. Akhil', 'akhil@example.com', 'password123', '9000000012', 'doctor'),
('Dr. Vinay', 'vinay@example.com', 'password123', '9000000013', 'doctor'),
('Dr. Nishwal', 'nishwal@example.com', 'password123', '9000000014', 'doctor'),
('Dr. Karthik', 'karthik@example.com', 'password123', '9000000015', 'doctor');

-- Insert into doctor_details
INSERT INTO doctor_details (doctor_id, doctor_name, specialization, qualification, experience_years, consultation_fee, location_id) VALUES
(1, 'Dr. Shashank', 'Cardiologist', 'MBBS, MD', 10, 150.00, 1),
(2, 'Dr. Mahadev', 'Dermatologist', 'MBBS, MD', 8, 130.00, 2),
(3, 'Dr. Sagar', 'Pediatrician', 'MBBS, DCH', 7, 120.00, 3),
(4, 'Dr. Shankar', 'Neurologist', 'MBBS, MD', 12, 180.00, 4),
(5, 'Dr. Sushant Singh', 'Psychiatrist', 'MBBS, MD', 9, 140.00, 5),
(6, 'Dr. Ravi', 'Orthopedic', 'MBBS, MS', 11, 160.00, 6),
(7, 'Dr. Govind', 'ENT Specialist', 'MBBS, DLO', 6, 110.00, 7),
(8, 'Dr. Hemalatha', 'Gynecologist', 'MBBS, MD', 13, 170.00, 8),
(9, 'Dr. Geetha', 'Oncologist', 'MBBS, DM', 10, 200.00, 9),
(10, 'Dr. Seetha', 'Dermatologist', 'MBBS, MD', 7, 130.00, 10),
(11, 'Dr. Dhruthi', 'Psychologist', 'PhD Clinical Psych', 5, 100.00, 11),
(12, 'Dr. Akhil', 'General Physician', 'MBBS', 4, 90.00, 12),
(13, 'Dr. Vinay', 'Urologist', 'MBBS, MCh', 8, 150.00, 13),
(14, 'Dr. Nishwal', 'Pulmonologist', 'MBBS, MD', 6, 125.00, 14),
(15, 'Dr. Karthik', 'Dentist', 'BDS, MDS', 10, 110.00, 15);
