-- GreenCity Operational Database Schema 
CREATE DATABASE IF NOT EXISTS greencity_operational;
USE greencity_operational;
-- =====================================================
-- 1. SUPPRESSION DES TABLES EXISTANTES
-- =====================================================
DROP TABLE IF EXISTS Environmental_Reports;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Invoice_Items;
DROP TABLE IF EXISTS Invoices;
DROP TABLE IF EXISTS Meter_Readings;
DROP TABLE IF EXISTS Meters;
DROP TABLE IF EXISTS Buildings;
DROP TABLE IF EXISTS Clients;
DROP TABLE IF EXISTS Regions;

-- =====================================================
-- 2. CRÉATION DES TABLES (avec timestamps)
-- =====================================================

-- Regions Table
CREATE TABLE Regions (
    region_id INT PRIMARY KEY AUTO_INCREMENT,
    region_code VARCHAR(10) UNIQUE NOT NULL,
    region_name VARCHAR(100) NOT NULL,
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Clients Table
CREATE TABLE Clients (
    client_id INT PRIMARY KEY AUTO_INCREMENT,
    client_code VARCHAR(20) UNIQUE NOT NULL,
    client_name VARCHAR(150) NOT NULL,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    address VARCHAR(255),
    postal_code VARCHAR(20),
    city VARCHAR(100),
    sector VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Buildings Table
CREATE TABLE Buildings (
    building_id INT PRIMARY KEY AUTO_INCREMENT,
    building_code VARCHAR(20) UNIQUE NOT NULL,
    building_name VARCHAR(150) NOT NULL,
    region_id INT NOT NULL,
    client_id INT NOT NULL,
    address VARCHAR(255),
    surface_area DECIMAL(10, 2),
    construction_year INT,
    building_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (region_id) REFERENCES Regions(region_id),
    FOREIGN KEY (client_id) REFERENCES Clients(client_id)
);

-- Meters Table
CREATE TABLE Meters (
    meter_id INT PRIMARY KEY AUTO_INCREMENT,
    meter_code VARCHAR(20) UNIQUE NOT NULL,
    building_id INT NOT NULL,
    meter_type VARCHAR(50) NOT NULL,
    meter_unit VARCHAR(20),
    installation_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (building_id) REFERENCES Buildings(building_id)
);

-- Meter Readings (Heures 2025)
CREATE TABLE Meter_Readings (
    reading_id INT PRIMARY KEY AUTO_INCREMENT,
    meter_id INT NOT NULL,
    reading_date DATETIME NOT NULL,
    consumption_value DECIMAL(10, 2),
    temperature DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (meter_id) REFERENCES Meters(meter_id)
);

-- Invoices (Factures 2025)
CREATE TABLE Invoices (
    invoice_id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_number VARCHAR(30) UNIQUE NOT NULL,
    client_id INT NOT NULL,
    building_id INT NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE,
    total_ht DECIMAL(12, 2),
    tva_amount DECIMAL(12, 2),
    total_ttc DECIMAL(12, 2),
    energy_cost DECIMAL(12, 2),
    status VARCHAR(20) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES Clients(client_id),
    FOREIGN KEY (building_id) REFERENCES Buildings(building_id)
);

-- Invoice Items
CREATE TABLE Invoice_Items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_id INT NOT NULL,
    meter_type VARCHAR(50),
    quantity DECIMAL(10, 2),
    unit_price DECIMAL(10, 2),
    subtotal DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id)
);

-- Payments
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    invoice_id INT NOT NULL,
    payment_date DATE NOT NULL,
    amount DECIMAL(12, 2),
    payment_method VARCHAR(50),
    reference VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id)
);

-- Environmental Reports (Nouvelle table) - CORRIGÉ : FKs NULL autorisées
CREATE TABLE Environmental_Reports (
    report_id INT PRIMARY KEY AUTO_INCREMENT,
    region_id INT NULL,  -- CORRECTION : NULL autorisé
    building_id INT NULL, -- CORRECTION : NULL autorisé
    report_date DATE NOT NULL,
    emission_co2_kg DECIMAL(10, 2),
    recycling_rate DECIMAL(5, 4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (region_id) REFERENCES Regions(region_id),
    FOREIGN KEY (building_id) REFERENCES Buildings(building_id)
);

-- =====================================================
-- 3. INSERTION DES DONNÉES 
-- =====================================================

-- Regions 
INSERT INTO Regions (region_code, region_name, country) VALUES
('REG01', 'Casablanca-Settat', 'Morocco'),
('REG02', 'Rabat-Salé-Kénitra', 'Morocco'),
('REG03', 'Marrakech-Safi', 'Morocco'),
('REG04', 'Tanger-Tétouan-Al Hoceïma', 'Morocco'),
('REG05', 'Fès-Meknès', 'Morocco');

-- Clients
INSERT INTO Clients (client_code, client_name, contact_email, sector) VALUES
('CLI001', 'Tech Solutions Corp', 'contact@techsol.fr', 'Technology'),
('CLI002', 'Green Industries', 'info@greenind.fr', 'Manufacturing'),
('CLI003', 'Commerce Hub', 'hello@commercehub.fr', 'Retail'),
('CLI004', 'Urban Services', 'contact@urban.fr', 'Services'),
('CLI005', 'Eco Housing Group', 'info@ecohousing.fr', 'Real Estate'),
('CLI006', 'City Mall Group', 'admin@citymall.fr', 'Retail'),
('CLI007', 'HealthCare Plus', 'contact@hcp.fr', 'Healthcare'),
('CLI008', 'EduSmart', 'info@edusmart.fr', 'Education'),
('CLI009', 'LogiTrans', 'contact@logitrans.fr', 'Logistics'),
('CLI010', 'DataCloud', 'hello@datacloud.fr', 'Technology');

-- Buildings 
INSERT INTO Buildings (building_code, building_name, region_id, client_id, surface_area, construction_year, building_type) VALUES
('BAT001', 'DataCenter North', 1, 1, 5000.00, 2018, 'Industrial'),
('BAT002', 'Office Tower Downtown', 1, 2, 8000.00, 2015, 'Commercial'),
('BAT003', 'Mall South', 2, 3, 12000.00, 2020, 'Retail'),
('BAT004', 'Eco Residence A', 2, 5, 3200, 2019, 'Residential'),
('BAT005', 'Eco Residence B', 2, 5, 2800, 2021, 'Residential'),
('BAT006', 'City Mall East', 3, 6, 15000, 2017, 'Commercial'),
('BAT007', 'City Mall West', 1, 6, 13000, 2016, 'Commercial'),
('BAT008', 'Central Hospital', 1, 7, 20000, 2014, 'Healthcare'),
('BAT009', 'Private Clinic', 3, 7, 6000, 2018, 'Healthcare'),
('BAT010', 'Smart School', 2, 8, 7000, 2020, 'Education'),
('BAT011', 'Logistics Hub', 3, 9, 18000, 2015, 'Industrial'),
('BAT012', 'Cloud HQ', 1, 10, 9000, 2022, 'Office'),
('BAT013', 'Port Logistics Tanger', 4, 9, 11000, 2019, 'Industrial'),
('BAT014', 'Cultural Center Fès', 5, 8, 6200, 2021, 'Public'),
('BAT015', 'Medina Hotel', 5, 4, 5400, 2018, 'Hospitality'),
('BAT016', 'Tech Park Tanger', 4, 1, 8500, 2020, 'Office');

-- Meters
INSERT INTO Meters (meter_code, building_id, meter_type, meter_unit, installation_date) VALUES
-- Électricité
('ELEC_001', 1, 'electricity', 'kWh', '2018-06-15'),
('ELEC_002', 2, 'electricity', 'kWh', '2015-03-20'),
('ELEC_003', 3, 'electricity', 'kWh', '2020-01-01'),
('ELEC_004', 4, 'electricity', 'kWh', '2019-05-01'),
('ELEC_005', 5, 'electricity', 'kWh', '2021-02-01'),
('ELEC_006', 6, 'electricity', 'kWh', '2017-06-01'),
('ELEC_007', 7, 'electricity', 'kWh', '2016-06-01'),
('ELEC_008', 8, 'electricity', 'kWh', '2014-03-01'),
('ELEC_009', 9, 'electricity', 'kWh', '2018-07-01'),
('ELEC_010', 10, 'electricity', 'kWh', '2020-09-01'),
('ELEC_011', 11, 'electricity', 'kWh', '2015-11-01'),
('ELEC_012', 12, 'electricity', 'kWh', '2022-01-01'),
('ELEC_013', 13, 'electricity', 'kWh', '2019-08-01'),
('ELEC_014', 14, 'electricity', 'kWh', '2021-04-01'),
('ELEC_015', 15, 'electricity', 'kWh', '2018-10-01'),
('ELEC_016', 16, 'electricity', 'kWh', '2020-06-01'),

-- Eau
('EAU_001', 1, 'water', 'm3', '2018-06-15'),
('EAU_002', 3, 'water', 'm3', '2020-01-01'),
('EAU_003', 4, 'water', 'm3', '2019-05-01'),
('EAU_004', 6, 'water', 'm3', '2017-06-01'),
('EAU_005', 8, 'water', 'm3', '2014-03-01'),
('EAU_006', 13, 'water', 'm3', '2019-08-01'),
('EAU_007', 14, 'water', 'm3', '2021-04-01'),

-- Gaz
('GAZ_001', 2, 'gas', 'm3', '2015-03-20'),
('GAZ_002', 6, 'gas', 'm3', '2017-06-01'),
('GAZ_003', 7, 'gas', 'm3', '2016-06-01'),
('GAZ_004', 8, 'gas', 'm3', '2014-03-01'),
('GAZ_005', 13, 'gas', 'm3', '2019-08-01'),
('GAZ_006', 15, 'gas', 'm3', '2018-10-01');

-- =====================================================
-- 4. DONNÉES TRANSACTIONNELLES (2025)
-- =====================================================

-- Invoices 
INSERT INTO Invoices (invoice_number, client_id, building_id, invoice_date, due_date, total_ht, tva_amount, total_ttc, energy_cost, status)
SELECT
    CONCAT('INV-', b.building_id, '-2025-01'),
    b.client_id,
    b.building_id,
    '2025-01-31',
    '2025-02-15',
    ROUND(RAND()*5000 + 2000, 2),
    ROUND(RAND()*1000 + 400, 2),
    ROUND(RAND()*6000 + 2400, 2),
    ROUND(RAND()*4000 + 1800, 2),
    CASE WHEN RAND() > 0.2 THEN 'paid' ELSE 'pending' END
FROM Buildings b;

-- Invoice Items 
INSERT INTO Invoice_Items (invoice_id, meter_type, quantity, unit_price, subtotal)
SELECT
    i.invoice_id,
    'electricity',
    ROUND(RAND()*10000 + 3000, 2),
    0.18,
    ROUND((RAND()*10000 + 3000) * 0.18, 2)
FROM Invoices i
WHERE RAND() > 0.1  -- 90% ont électricité

UNION ALL

SELECT
    i.invoice_id,
    'water',
    ROUND(RAND()*800 + 200, 2),
    1.20,
    ROUND((RAND()*800 + 200) * 1.20, 2)
FROM Invoices i
WHERE RAND() > 0.3  -- 70% ont eau

UNION ALL

SELECT
    i.invoice_id,
    'gas',
    ROUND(RAND()*1500 + 500, 2),
    0.09,
    ROUND((RAND()*1500 + 500) * 0.09, 2)
FROM Invoices i
WHERE RAND() > 0.4; -- 60% ont gaz

-- Payments (seulement pour les factures payées)
INSERT INTO Payments (invoice_id, payment_date, amount, payment_method, reference)
SELECT
    i.invoice_id,
    DATE_ADD(i.invoice_date, INTERVAL FLOOR(RAND()*10) DAY),
    i.total_ttc,
    CASE 
        WHEN RAND() > 0.7 THEN 'card'
        WHEN RAND() > 0.4 THEN 'bank_transfer'
        ELSE 'check'
    END,
    CONCAT('PAY-', i.invoice_id)
FROM Invoices i
WHERE i.status = 'paid';

-- Meter Readings (Janvier 2025, données horaires simulées)
-- Électricité (avec température)
INSERT INTO Meter_Readings (meter_id, reading_date, consumption_value, temperature)
SELECT
    m.meter_id,
    DATE_ADD('2025-01-01 00:00:00', INTERVAL (h.hour + d.day*24) HOUR),
    ROUND(RAND() * 30 + 10, 2),  -- kWh entre 10 et 40
    ROUND(RAND() * 15 + 10, 2)   -- température 10-25°C
FROM Meters m
JOIN (SELECT 0 AS hour UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15 UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20 UNION SELECT 21 UNION SELECT 22 UNION SELECT 23) h
JOIN (SELECT 0 AS day UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10 UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION SELECT 15 UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19 UNION SELECT 20 UNION SELECT 21 UNION SELECT 22 UNION SELECT 23 UNION SELECT 24 UNION SELECT 25 UNION SELECT 26 UNION SELECT 27 UNION SELECT 28 UNION SELECT 29) d
WHERE m.meter_type = 'electricity'
AND m.meter_id <= 8;  

-- Eau et Gaz (sans température)
INSERT INTO Meter_Readings (meter_id, reading_date, consumption_value, temperature)
SELECT
    m.meter_id,
    DATE_ADD('2025-01-15 00:00:00', INTERVAL (h.hour + d.day*24) HOUR),
    CASE 
        WHEN m.meter_type = 'water' THEN ROUND(RAND() * 5 + 1, 2)
        ELSE ROUND(RAND() * 20 + 5, 2)
    END,
    NULL
FROM Meters m
JOIN (SELECT 0 AS hour UNION SELECT 6 UNION SELECT 12 UNION SELECT 18) h  -- 4 relevés par jour
JOIN (SELECT 0 AS day UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) d
WHERE m.meter_type IN ('water', 'gas');

-- =====================================================
-- 5. DONNÉES ENVIRONNEMENTALES (pour CSV) 
-- =====================================================
INSERT INTO Environmental_Reports (region_id, building_id, report_date, emission_co2_kg, recycling_rate)
SELECT
    b.region_id,
    b.building_id,
    '2025-01-31',
    ROUND(RAND() * 1000 + 200, 2),
    ROUND(RAND() * 0.5 + 0.3, 3)  -- 30% à 80%
FROM Buildings b
WHERE RAND() > 0.2  -- 80% des bâtiments ont un rapport

UNION ALL


SELECT NULL, 1, '2025-01-31', 450.00, 0.65
UNION ALL
SELECT 2, NULL, '2025-01-31', 380.00, 0.72  
UNION ALL
SELECT 3, 6, '2025-01-31', -150.00, 1.5
UNION ALL
SELECT 4, 13, '2025-01-31', NULL, 0.68
UNION ALL
SELECT 5, 14, '2025-01-31', 520.00, NULL;

-- =====================================================
-- 6. INDEX POUR PERFORMANCE
-- =====================================================
CREATE INDEX idx_meter_type ON Meters(meter_type);
CREATE INDEX idx_building_region ON Buildings(region_id);
CREATE INDEX idx_reading_date ON Meter_Readings(reading_date);
CREATE INDEX idx_invoice_date ON Invoices(invoice_date);
CREATE INDEX idx_payment_date ON Payments(payment_date);
CREATE INDEX idx_env_report_date ON Environmental_Reports(report_date);