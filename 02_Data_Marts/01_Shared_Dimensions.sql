-- ============================================
-- SHARED DIMENSIONS (for all Data Marts)
-- ============================================
DROP DATABASE IF EXISTS greencity_dw;
CREATE DATABASE greencity_dw;
USE greencity_dw;

-- DIM_TEMPS
CREATE TABLE DIM_TEMPS (
    id_temps INT PRIMARY KEY,
    date_complete DATE,
    annee INT,
    mois INT,
    jour INT,
    trimestre INT,
    semaine_annee INT,
    jour_semaine VARCHAR(20),
    est_weekend VARCHAR(1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- DIM_REGION
CREATE TABLE DIM_REGION (
    id_region INT PRIMARY KEY,
    code_region VARCHAR(10),
    nom_region VARCHAR(100),
    pays VARCHAR(50) DEFAULT 'Maroc',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- DIM_BATIMENT
CREATE TABLE DIM_BATIMENT (
    id_batiment INT PRIMARY KEY,
    code_batiment VARCHAR(20),
    nom_batiment VARCHAR(150),
    surface DECIMAL(10,2),
    annee_construction INT,
    type_batiment VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- DIM_CLIENT
CREATE TABLE DIM_CLIENT (
    id_client INT PRIMARY KEY,
    code_client VARCHAR(20),
    nom_client VARCHAR(150),
    secteur_activite VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- POPULATION OF SHARED DIMENSIONS
-- ============================================

-- DIM_TEMPS
INSERT IGNORE INTO DIM_TEMPS (id_temps, date_complete, annee, mois, jour, trimestre, semaine_annee, jour_semaine, est_weekend)
WITH RECURSIVE dates AS (
    SELECT '2025-01-01' as date_value
    UNION ALL
    SELECT DATE_ADD(date_value, INTERVAL 1 DAY)
    FROM dates
    WHERE date_value < '2025-12-31'
)
SELECT 
    DATE_FORMAT(date_value, '%Y%m%d'),
    date_value,
    YEAR(date_value),
    MONTH(date_value),
    DAY(date_value),
    QUARTER(date_value),
    WEEK(date_value, 1),
    DAYNAME(date_value),
    CASE WHEN DAYOFWEEK(date_value) IN (1,7) THEN 'O' ELSE 'N' END
FROM dates;

-- DIM_REGION
INSERT IGNORE INTO DIM_REGION (id_region, code_region, nom_region, pays) VALUES
(1, 'REG01', 'Tanger-Tétouan-Al Hoceïma', 'Maroc'),
(2, 'REG02', 'Oriental', 'Maroc'),
(3, 'REG03', 'Fès-Meknès', 'Maroc'),
(4, 'REG04', 'Rabat-Salé-Kénitra', 'Maroc'),
(5, 'REG05', 'Béni Mellal-Khénifra', 'Maroc'),
(6, 'REG06', 'Casablanca-Settat', 'Maroc'),
(7, 'REG07', 'Marrakech-Safi', 'Maroc'),
(8, 'REG08', 'Drâa-Tafilalet', 'Maroc'),
(9, 'REG09', 'Souss-Massa', 'Maroc'),
(10, 'REG10', 'Guelmim-Oued Noun', 'Maroc'),
(11, 'REG11', 'Laâyoune-Sakia El Hamra', 'Maroc'),
(12, 'REG12', 'Dakhla-Oued Ed-Dahab', 'Maroc'),
(999, 'NON_R', 'Région Non Renseignée', 'Maroc');

-- DIM_BATIMENT
INSERT IGNORE INTO DIM_BATIMENT (id_batiment, code_batiment, nom_batiment, surface, annee_construction, type_batiment) VALUES
(1, 'BAT001', 'DataCenter North', 5000.00, 2018, 'Industrial'),
(2, 'BAT002', 'Office Tower Downtown', 8000.00, 2015, 'Commercial'),
(3, 'BAT003', 'Mall South', 12000.00, 2020, 'Retail'),
(4, 'BAT004', 'Eco Residence A', 3200.00, 2019, 'Residential'),
(5, 'BAT005', 'Eco Residence B', 2800.00, 2021, 'Residential'),
(6, 'BAT006', 'City Mall East', 15000.00, 2017, 'Commercial'),
(7, 'BAT007', 'City Mall West', 13000.00, 2016, 'Commercial'),
(8, 'BAT008', 'Central Hospital', 20000.00, 2014, 'Healthcare'),
(9, 'BAT009', 'Private Clinic', 6000.00, 2018, 'Healthcare'),
(10, 'BAT010', 'Smart School', 7000.00, 2020, 'Education'),
(11, 'BAT011', 'Logistics Hub', 18000.00, 2015, 'Industrial'),
(12, 'BAT012', 'Cloud HQ', 9000.00, 2022, 'Office'),
(13, 'BAT013', 'Port Logistics Tanger', 11000.00, 2019, 'Industrial'),
(14, 'BAT014', 'Cultural Center Fès', 6200.00, 2021, 'Public'),
(15, 'BAT015', 'Medina Hotel', 5400.00, 2018, 'Hospitality'),
(16, 'BAT016', 'Tech Park Tanger', 8500.00, 2020, 'Office'),
(999, 'NON_RE', 'Bâtiment Non Renseigné', 0.00, 2000, 'Non Défini');

-- DIM_CLIENT
INSERT IGNORE INTO DIM_CLIENT (id_client, code_client, nom_client, secteur_activite) VALUES
(1, 'CLI001', 'Tech Solutions Corp', 'Technology'),
(2, 'CLI002', 'Green Industries', 'Manufacturing'),
(3, 'CLI003', 'Commerce Hub', 'Retail'),
(4, 'CLI004', 'Urban Services', 'Services'),
(5, 'CLI005', 'Eco Housing Group', 'Real Estate'),
(6, 'CLI006', 'City Mall Group', 'Retail'),
(7, 'CLI007', 'HealthCare Plus', 'Healthcare'),
(8, 'CLI008', 'EduSmart', 'Education'),
(9, 'CLI009', 'LogiTrans', 'Logistics'),
(10, 'CLI010', 'DataCloud', 'Technology');