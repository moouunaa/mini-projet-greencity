-- DIM_FACTURE
CREATE TABLE DIM_FACTURE (
    id_facture INT PRIMARY KEY,
    numero_facture VARCHAR(30),
    date_facture DATE,
    date_echeance DATE,
    statut_facture VARCHAR(20), -- 'paid', 'pending', 'partial'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- DIM_PAIEMENT
CREATE TABLE DIM_PAIEMENT (
    id_paiement INT PRIMARY KEY,
    methode_paiement VARCHAR(50), -- 'bank_transfer', 'card', 'check'
    reference_paiement VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);


-- FAIT_RENTABILITE
CREATE TABLE FAIT_RENTABILITE (
    id_fait INT PRIMARY KEY AUTO_INCREMENT,
    id_temps INT,
    id_batiment INT,
    id_region INT,
    id_client INT,
    id_facture INT,
    id_paiement INT,
    
    -- Mesures financières
    montant_ht DECIMAL(12,2),
    montant_tva DECIMAL(12,2),
    montant_ttc DECIMAL(12,2),
    cout_energie DECIMAL(12,2),
    montant_paye DECIMAL(12,2),
    
    -- Indicateurs calculés
    marge DECIMAL(12,2), -- = montant_ttc - cout_energie
    taux_marge DECIMAL(5,2), -- = (marge / montant_ttc) × 100
    delai_paiement INT, -- jours entre facture et paiement
    taux_recouvrement DECIMAL(5,2), -- = (montant_paye / montant_ttc) × 100
    
    -- Pour analyse comparative
    rentabilite_categorie VARCHAR(20), -- 'Haute', 'Moyenne', 'Basse'
    
    -- Pour extraction incrémentale
    source_id VARCHAR(50),
    date_extraction DATE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (id_temps) REFERENCES DIM_TEMPS(id_temps),
    FOREIGN KEY (id_batiment) REFERENCES DIM_BATIMENT(id_batiment),
    FOREIGN KEY (id_region) REFERENCES DIM_REGION(id_region),
    FOREIGN KEY (id_client) REFERENCES DIM_CLIENT(id_client),
    FOREIGN KEY (id_facture) REFERENCES DIM_FACTURE(id_facture),
    FOREIGN KEY (id_paiement) REFERENCES DIM_PAIEMENT(id_paiement)
);

-- Index
CREATE INDEX idx_fait_rent_temps ON FAIT_RENTABILITE(id_temps);
CREATE INDEX idx_fait_rent_client ON FAIT_RENTABILITE(id_client);
CREATE INDEX idx_fait_rent_batiment ON FAIT_RENTABILITE(id_batiment);