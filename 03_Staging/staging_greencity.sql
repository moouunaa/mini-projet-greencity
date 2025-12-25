-- STAGING DATABASE
CREATE DATABASE IF NOT EXISTS staging_greencity;
USE staging_greencity;

-- Staging table for IoT JSON data (electricity, water, gas)
CREATE TABLE stg_iot_consumption (
    id INT PRIMARY KEY AUTO_INCREMENT,
    source_file VARCHAR(100),
    id_region VARCHAR(10),
    id_batiment VARCHAR(20),
    type_energie VARCHAR(20),
    unite VARCHAR(10),
    date_generation DATE,
    compteur_id VARCHAR(20),
    date_mesure DATETIME,
    consommation_value DECIMAL(12,2),
    temperature DECIMAL(5,2),
    extraction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
);

-- Staging table for environmental CSV data
CREATE TABLE stg_environmental_reports (
    id INT PRIMARY KEY AUTO_INCREMENT,
    source_file VARCHAR(100),
    id_region VARCHAR(10),
    id_batiment VARCHAR(20),
    date_rapport DATE,
    emission_CO2_kg DECIMAL(12,2),
    taux_recyclage DECIMAL(5,4),
    extraction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed BOOLEAN DEFAULT FALSE
);

-- Staging table for incremental extraction tracking
CREATE TABLE stg_extraction_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    table_name VARCHAR(50),
    last_extraction_date DATETIME,
    rows_extracted INT,
    extraction_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);