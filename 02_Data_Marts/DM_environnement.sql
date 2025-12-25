-- DIM_ENVIRONNEMENT
CREATE TABLE DIM_ENVIRONNEMENT (
    id_environnement INT PRIMARY KEY,
    type_indicateur VARCHAR(50), -- 'CO2', 'Recyclage', 'Eau_reutilisee'
    unite_mesure VARCHAR(20), -- 'kg', 'pourcentage', 'm3'
    seuil_optimal DECIMAL(10,2),
    seuil_alerte DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


-- FAIT_ENVIRONNEMENT
CREATE TABLE FAIT_ENVIRONNEMENT (
    id_fait INT PRIMARY KEY AUTO_INCREMENT,
    id_temps INT,
    id_batiment INT,
    id_region INT,
    id_client INT,
    id_environnement INT,
    
    -- Mesures environnementales
    valeur_mesuree DECIMAL(12,2), -- ex: 512 kg de CO2
    valeur_reference DECIMAL(12,2), -- valeur attendue/standard
    
    -- Indicateurs calculés
    ecart_reference DECIMAL(12,2), -- = valeur_mesuree - valeur_reference
    taux_variation DECIMAL(5,2), -- % vs période précédente
    
    -- Ratios importants
    ratio_co2_energie DECIMAL(10,4), -- kg CO2 / kWh
    efficacite_energetique DECIMAL(10,2),
    
    -- Catégorisation
    categorie_performance VARCHAR(20), -- 'Excellente', 'Bonne', 'À améliorer'
    
    -- Pour extraction incrémentale
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

-- Index
CREATE INDEX idx_fait_env_temps ON FAIT_ENVIRONNEMENT(id_temps);
CREATE INDEX idx_fait_env_batiment ON FAIT_ENVIRONNEMENT(id_batiment);
CREATE INDEX idx_fait_env_indicateur ON FAIT_ENVIRONNEMENT(id_environnement);