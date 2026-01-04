-- ============================================
-- DATA MART: CONSOMMATION ÉNERGÉTIQUE
-- ============================================
USE greencity_dw;

-- Data Mart specific dimensions
CREATE TABLE DIM_ENERGIE (
    id_energie INT PRIMARY KEY,
    type_energie VARCHAR(50),
    unite_mesure VARCHAR(20),
    tarif_unitaire DECIMAL(10,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE DIM_COMPTEUR (
    id_compteur INT PRIMARY KEY,
    code_compteur VARCHAR(20),
    type_compteur VARCHAR(50),
    date_installation DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Fact table
CREATE TABLE FAIT_CONSOMMATION (
    id_fait INT PRIMARY KEY AUTO_INCREMENT,
    id_temps INT,
    id_batiment INT,
    id_region INT,
    id_client INT,
    id_energie INT,
    id_compteur INT,
    consommation_valeur DECIMAL(12,2),
    temperature DECIMAL(5,2),
    cout_energie DECIMAL(12,2),
    consommation_moyenne_jour DECIMAL(10,2),
    consommation_max_jour DECIMAL(10,2),
    consommation_min_jour DECIMAL(10,2),
    source_id VARCHAR(50),
    date_extraction DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_temps) REFERENCES DIM_TEMPS(id_temps),
    FOREIGN KEY (id_batiment) REFERENCES DIM_BATIMENT(id_batiment),
    FOREIGN KEY (id_region) REFERENCES DIM_REGION(id_region),
    FOREIGN KEY (id_client) REFERENCES DIM_CLIENT(id_client),
    FOREIGN KEY (id_energie) REFERENCES DIM_ENERGIE(id_energie),
    FOREIGN KEY (id_compteur) REFERENCES DIM_COMPTEUR(id_compteur)
);

-- Indexes
CREATE INDEX idx_fait_cons_temps ON FAIT_CONSOMMATION(id_temps);
CREATE INDEX idx_fait_cons_batiment ON FAIT_CONSOMMATION(id_batiment);
CREATE INDEX idx_fait_cons_energie ON FAIT_CONSOMMATION(id_energie);

-- Population of Data Mart specific dimensions
INSERT IGNORE INTO DIM_ENERGIE (id_energie, type_energie, unite_mesure, tarif_unitaire) VALUES 
(1, 'electricite', 'kWh', 1.42),
(2, 'eau', 'm3', 25.80),
(3, 'gaz', 'm3', 8.75),
(999, 'inconnu', 'N/A', 0.00);

INSERT INTO DIM_COMPTEUR (id_compteur, code_compteur, type_compteur, date_installation) VALUES
(1, 'ELEC_001', 'Compteur Électrique', '2018-06-15'),
(2, 'ELEC_002', 'Compteur Électrique', '2015-03-20'),
(3, 'EAU_001', 'Compteur Eau', '2018-06-15'),
(4, 'GAZ_001', 'Compteur Gaz', '2015-03-20'),
(5, 'ELEC_003', 'Compteur Électrique', '2020-01-01'),
(6, 'ELEC_004', 'Compteur Électrique', '2020-01-01'),
(7, 'ELEC_005', 'Compteur Électrique', '2020-01-01'),
(8, 'ELEC_006', 'Compteur Électrique', '2020-01-01'),
(9, 'ELEC_007', 'Compteur Électrique', '2020-01-01'),
(10, 'ELEC_008', 'Compteur Électrique', '2020-01-01'),
(11, 'EAU_002', 'Compteur Eau', '2020-01-01'),
(12, 'EAU_003', 'Compteur Eau', '2020-01-01'),
(13, 'EAU_004', 'Compteur Eau', '2020-01-01'),
(14, 'EAU_005', 'Compteur Eau', '2020-01-01'),
(15, 'EAU_006', 'Compteur Eau', '2020-01-01'),
(16, 'EAU_007', 'Compteur Eau', '2020-01-01'),
(17, 'GAZ_002', 'Compteur Gaz', '2020-01-01'),
(18, 'GAZ_003', 'Compteur Gaz', '2020-01-01'),
(19, 'GAZ_004', 'Compteur Gaz', '2020-01-01'),
(20, 'GAZ_005', 'Compteur Gaz', '2020-01-01'),
(21, 'GAZ_006', 'Compteur Gaz', '2020-01-01'),
(999, 'UNKNOWN', 'Compteur Inconnu', '1900-01-01');