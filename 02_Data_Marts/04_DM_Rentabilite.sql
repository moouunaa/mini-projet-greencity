-- ============================================
-- DATA MART: RENTABILITÉ ÉCONOMIQUE
-- ============================================
USE greencity_dw;

-- Data Mart specific dimensions
CREATE TABLE DIM_FACTURE (
    id_facture INT PRIMARY KEY,
    numero_facture VARCHAR(30),
    date_facture DATE,
    date_echeance DATE,
    statut_facture VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE DIM_PAIEMENT (
    id_paiement INT PRIMARY KEY,
    methode_paiement VARCHAR(50),
    reference_paiement VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Fact table
CREATE TABLE FAIT_RENTABILITE (
    id_fait INT PRIMARY KEY AUTO_INCREMENT,
    id_temps INT,
    id_batiment INT,
    id_region INT,
    id_client INT,
    id_facture INT,
    id_paiement INT,
    montant_ht DECIMAL(12,2),
    montant_tva DECIMAL(12,2),
    montant_ttc DECIMAL(12,2),
    cout_energie DECIMAL(12,2),
    montant_paye DECIMAL(12,2),
    marge DECIMAL(12,2),
    taux_marge DECIMAL(5,2),
    delai_paiement INT,
    taux_recouvrement DECIMAL(5,2),
    rentabilite_categorie VARCHAR(20),
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

-- Indexes
CREATE INDEX idx_fait_rent_temps ON FAIT_RENTABILITE(id_temps);
CREATE INDEX idx_fait_rent_client ON FAIT_RENTABILITE(id_client);
CREATE INDEX idx_fait_rent_batiment ON FAIT_RENTABILITE(id_batiment);

-- ============================================
-- POPULATION OF DIMENSIONS FROM CSV DATA
-- ============================================

-- DIM_FACTURE - All invoices from CSV
INSERT IGNORE INTO DIM_FACTURE (id_facture, numero_facture, date_facture, date_echeance, statut_facture) VALUES
(1, 'INV-1-2025-01', '2025-01-31', '2025-02-15', 'en attente'),
(2, 'INV-16-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(3, 'INV-2-2025-01', '2025-01-31', '2025-02-15', 'en attente'),
(4, 'INV-3-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(5, 'INV-15-2025-01', '2025-01-31', '2025-02-15', 'en attente'),
(6, 'INV-4-2025-01', '2025-01-31', '2025-02-15', 'en attente'),
(7, 'INV-5-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(8, 'INV-6-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(9, 'INV-7-2025-01', '2025-01-31', '2025-02-15', 'en attente'),
(10, 'INV-8-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(11, 'INV-9-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(12, 'INV-10-2025-01', '2025-01-31', '2025-02-15', 'en attente'),
(13, 'INV-14-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(14, 'INV-11-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(15, 'INV-13-2025-01', '2025-01-31', '2025-02-15', 'en attente'),
(16, 'INV-12-2025-01', '2025-01-31', '2025-02-15', 'payée'),
(999, 'UNKNOWN', '1900-01-01', '1900-01-01', 'inconnu');

-- DIM_PAIEMENT
INSERT IGNORE INTO DIM_PAIEMENT (id_paiement, methode_paiement, reference_paiement) VALUES
(1, 'Chèque', 'CHEQUE'),
(2, 'Carte Bancaire', 'CARTE'),
(3, 'Virement Bancaire', 'VIREMENT'),
(4, 'Non Payé', 'NON_PAYE'),
(999, 'Inconnu', 'UNKNOWN');

