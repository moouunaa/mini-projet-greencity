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
(3, 'gaz', 'm3', 8.75);

INSERT IGNORE INTO DIM_COMPTEUR (id_compteur, code_compteur, type_compteur, date_installation) VALUES
(1, 'ELEC_001', 'Compteur Électrique', '2018-06-15'),
(2, 'ELEC_002', 'Compteur Électrique', '2015-03-20'),
(3, 'EAU_001', 'Compteur Eau', '2018-06-15'),
(4, 'GAZ_001', 'Compteur Gaz', '2015-03-20');