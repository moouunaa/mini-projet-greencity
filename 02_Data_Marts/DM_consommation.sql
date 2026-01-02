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

-- DIM_REGION
CREATE TABLE DIM_REGION (
    id_region INT PRIMARY KEY,
    code_region VARCHAR(10),
    nom_region VARCHAR(100),
    pays VARCHAR(50),
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

-- DIM_ENERGIE
CREATE TABLE DIM_ENERGIE (
    id_energie INT PRIMARY KEY,
    type_energie VARCHAR(50), -- 'electricite', 'eau', 'gaz'
    unite_mesure VARCHAR(20), -- 'kWh', 'm3'
    tarif_unitaire DECIMAL(10,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- DIM_COMPTEUR
CREATE TABLE DIM_COMPTEUR (
    id_compteur INT PRIMARY KEY,
    code_compteur VARCHAR(20),
    type_compteur VARCHAR(50),
    date_installation DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);



-- FAIT_CONSOMMATION
CREATE TABLE FAIT_CONSOMMATION (
    id_fait INT PRIMARY KEY AUTO_INCREMENT,
    id_temps INT,
    id_batiment INT,
    id_region INT,
    id_client INT,
    id_energie INT,
    id_compteur INT,
    
    -- Mesures
    consommation_valeur DECIMAL(12,2), -- kWh ou m3
    temperature DECIMAL(5,2), -- °C (pour corrélation)
    cout_energie DECIMAL(12,2), -- coût calculé = consommation × tarif
    
    -- Indicateurs calculés
    consommation_moyenne_jour DECIMAL(10,2),
    consommation_max_jour DECIMAL(10,2),
    consommation_min_jour DECIMAL(10,2),
    
    -- Pour extraction incrémentale
    source_id VARCHAR(50), -- ID de la source originale
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

-- Index pour performances
CREATE INDEX idx_fait_cons_temps ON FAIT_CONSOMMATION(id_temps);
CREATE INDEX idx_fait_cons_batiment ON FAIT_CONSOMMATION(id_batiment);
CREATE INDEX idx_fait_cons_energie ON FAIT_CONSOMMATION(id_energie);