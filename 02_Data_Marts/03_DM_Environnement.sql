-- ============================================
-- DATA MART: IMPACT ENVIRONNEMENTAL
-- ============================================
USE greencity_dw;

-- Data Mart specific dimension
CREATE TABLE DIM_ENVIRONNEMENT (
    id_environnement INT PRIMARY KEY,
    type_indicateur VARCHAR(50),
    unite_mesure VARCHAR(20),
    seuil_optimal DECIMAL(10,2),
    seuil_alerte DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Fact table
CREATE TABLE FAIT_ENVIRONNEMENT (
    id_fait INT PRIMARY KEY AUTO_INCREMENT,
    id_temps INT,
    id_batiment INT,
    id_region INT,
    id_client INT,
    id_environnement INT,
    valeur_mesuree DECIMAL(12,2),
    valeur_reference DECIMAL(12,2),
    ecart_reference DECIMAL(12,2),
    taux_variation DECIMAL(5,2),
    ratio_co2_energie DECIMAL(10,4),
    efficacite_energetique DECIMAL(10,2),
    categorie_performance VARCHAR(20),
    source_id VARCHAR(50),
    date_extraction DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_temps) REFERENCES DIM_TEMPS(id_temps),
    FOREIGN KEY (id_batiment) REFERENCES DIM_BATIMENT(id_batiment),
    FOREIGN KEY (id_region) REFERENCES DIM_REGION(id_region),
    FOREIGN KEY (id_client) REFERENCES DIM_CLIENT(id_client),
    FOREIGN KEY (id_environnement) REFERENCES DIM_ENVIRONNEMENT(id_environnement)
);

-- Indexes
CREATE INDEX idx_fait_env_temps ON FAIT_ENVIRONNEMENT(id_temps);
CREATE INDEX idx_fait_env_batiment ON FAIT_ENVIRONNEMENT(id_batiment);
CREATE INDEX idx_fait_env_indicateur ON FAIT_ENVIRONNEMENT(id_environnement);

-- Population of Data Mart specific dimension
INSERT IGNORE INTO DIM_ENVIRONNEMENT (id_environnement, type_indicateur, unite_mesure, seuil_optimal, seuil_alerte) VALUES 
(1, 'CO2', 'kg', 500.00, 800.00),
(2, 'Recyclage', 'pourcentage', 0.70, 0.50),
(3, 'Eau_reutilisee', 'm3', 100.00, 50.00),
(999, 'Indicateur Inconnu', 'N/A', 0.00, 0.00);