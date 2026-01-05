# Phase d'Extraction JSON vers Staging

## Fichier: `01_Extract_JSON_to_Staging.ktr`

### Objectif:
Extraire les données de consommation énergétique (électricité, eau, gaz) à partir des fichiers JSON et les stocker dans la zone de staging au format CSV avec métadonnées de traçabilité.

### Architecture du flux ETL:
[Flux Électricité] → [Traitement] → [Métadonnées] ──┐
                                                    │ → [Fusion] → [Sortie CSV]
[Flux Eau/Gaz] → [Traitement] → [Métadonnées] ──────┘

### Étapes du processus ETL:

#### 1. **JSON_Input_Electricite** 
   - **Rôle**: Lecture des fichiers JSON d'électricité
   - **Fichiers**: `Elec_consumption_*.json` (2 fichiers)
   - **Configuration**:
     - Accepte les noms de fichiers depuis l'étape précédente
     - Ajoute automatiquement `source_filename` (nom du fichier source)
   - **Champs extraits**:
     - Données: `id_region`, `id_batiment`, `type_energie`, `unite`, `date_generation`
     - Mesures: `compteur_id`, `date_mesure`, `consommation_kWh`, `consommation_KWh`
     - Métadonnées: `source_filename`

#### 2. **Calculator_Unifier_KWh** 
   - **Rôle**: Unification des champs de consommation électrique
   - **Fonction**: `NVL(consommation_kWh, consommation_KWh)`
   - **Résultat**: Création du champ `consommation_unified`
   - **Problème résolu**: Incohérence de casse (`kWh` vs `KWh`)

#### 3. **Select_Standardiser_Elec** 
   - **Rôle**: Standardisation du schéma électrique
   - **Actions**:
     - Renommage: `consommation_unified` → `consommation_value`
     - Suppression: `consommation_kWh`, `consommation_KWh`
   - **Schéma final**: 8 champs standardisés

#### 4. **Select_Standardiser_Elec_2** 
   - **Rôle**: Réorganisation des champs
   - **Action**: Sélection des champs dans un ordre spécifique
   - **But**: Préparer la fusion avec le flux eau/gaz

#### 5. **Formula_Add_Metadata** 
   - **Rôle**: Ajout des métadonnées d'extraction (flux électricité)
   - **Champs ajoutés**:
     - `source_type` = `'JSON'`
     - `extraction_timestamp` = horodatage courant
     - `batch_id` = `'EXTRACT_' + date_format(now(), 'yyyyMMdd')`

#### 6. **JSON_Input_Eau_Gaz** 
   - **Rôle**: Lecture des fichiers JSON d'eau et gaz
   - **Fichiers**: `Eau_*.json`, `Gaz_*.json` (4 fichiers)
   - **Configuration**: Similaire au flux électricité
   - **Champs extraits**: Même structure mais avec `consommation_m3`

#### 7. **Select_Standardiser_EauGaz** 
   - **Rôle**: Standardisation du schéma eau/gaz
   - **Action**: Renommage `consommation_m3` → `consommation_value`
   - **Résultat**: 8 champs identiques au flux électrique

#### 8. **Formula_Add_Metadata_2** 
   - **Rôle**: Ajout des métadonnées d'extraction (flux eau/gaz)
   - **Champs ajoutés**: Identiques au flux électricité

#### 9. **Fusionner_Flux** 
   - **Rôle**: Consolidation des trois types d'énergie
   - **Type**: Append Streams (union verticale)
   - **Entrées**: 
     - Head: `Formula_Add_Metadata` (flux électricité)
     - Tail: `Formula_Add_Metadata_2` (flux eau/gaz)
   - **Volume**: 56 enregistrements au total

#### 10. **Output_Staging_CSV** 
   - **Rôle**: Écriture dans la zone de staging
   - **Fichier**: `05_Staging_area/raw/staging_consommation_raw.csv`
   - **Format**: CSV avec en-têtes, encodage UTF-8, séparateur virgule

### Problèmes de qualité résolus:
1. **Incohérence de nomenclature**: `consommation_kWh` vs `consommation_KWh`
2. **Différence de schéma**: `consommation_kWh` (élec) vs `consommation_m3` (eau/gaz)
3. **Unification**: Création d'un champ unique `consommation_value`

### Stratégie de traçabilité:
- **`source_filename`**: Nom du fichier JSON source (ajouté automatiquement)
- **`source_type`**: Type de source (`'JSON'`)
- **`extraction_timestamp`**: Date/heure d'extraction
- **`batch_id`**: Identifiant unique du lot d'extraction

### Résultat:
- **Fichier généré**: `staging_consommation_raw.csv`
- **Nombre d'enregistrements**: 56
- **Champs**: 11 champs (8 données + 3 métadonnées)
- **Types d'énergie**: Électricité (32 enregistrements), Eau (11), Gaz (13)
- **État**: Données brutes unifiées - prêtes pour Transformation

### Préparation pour la phase suivante:
Les données sont maintenant structurées de manière cohérente pour:
1. **Nettoyage** (dates, formats, valeurs manquantes)
2. **Validation** (plages de valeurs, contraintes métier)
3. **Enrichissement** (calculs, agrégations)







## Fichier: `02_Extract_CSV_to_Staging.ktr`

### Objectif:
Extraire les données environnementales (émissions CO2, taux de recyclage) à partir des fichiers CSV et les stocker dans la zone de staging.

### Étapes du processus ETL:

#### 1. **Text_File_Input_Env**
   - **Rôle**: Lecture des fichiers CSV environnementaux
   - **Fichiers**: `env_reports_01_2025.csv`, `env_reports_02_2025.csv`, `env_reports_03_2025.csv`
   - **Configuration**:
     - Chemin: `03_Source_Files/csv/`
     - Wildcard: `env_reports_.*\.csv` (expression régulière)
     - Séparateur: `,` (virgule)
     - En-tête: Oui
     - **Champs supplémentaires**: `source_filename` (nom court du fichier source)
   - **Champs extraits** (tous en String):
     - `id_region`, `id_batiment`, `date_rapport`
     - `emission_CO2_kg`, `taux_recyclage`
     - `source_filename` (ajouté automatiquement)

#### 2. **Formula_Add_Metadata**
   - **Rôle**: Ajout des métadonnées d'extraction
   - **Champs ajoutés**:
     - `source_type` = `'CSV'` (type de source)
     - `extraction_timestamp` = timestamp courant

#### 3. **Text_File_Output_Env**
   - **Rôle**: Écriture dans la zone de staging
   - **Fichier**: `05_Staging_area/raw/staging_environnement_raw.csv`
   - **Format**: CSV avec en-têtes, encodage UTF-8
   - **Séparateur**: Virgule

### Décisions techniques:
1. **Typage des champs**: Tous les champs extraits en `String`
   - **Raison**: Présence de valeurs non-numériques (`N/A`, `Non mesuré`)
   - **Traitement ultérieur**: Conversion dans la phase de Transformation

2. **Traçabilité**:
   - `source_filename` : Nom du fichier CSV source
   - `source_type` : Type de source (CSV)
   - `extraction_timestamp` : Date/heure d'extraction
   - `batch_id` : Identifiant du lot d'extraction

3. **Filtrage des fichiers**: 
   - Inclusion: `env_reports_*.csv` (tous les fichiers de rapports)

### Problèmes de qualité détectés (à traiter en Transformation):
1. **Valeurs manquantes**: `id_region`, `id_batiment` vides
2. **Formats de date incohérents**: `2025-03-31` vs `31/03/2025`
3. **Valeurs numériques invalides**: 
   - `N/A` dans `emission_CO2_kg`
   - `Non mesuré` dans `taux_recyclage`
   - Valeurs hors plage: `99999`, `1.5` (taux > 1)
4. **Espaces superflus**: `  REG99  `
5. **Doublons**: `REG02,BAT003` en double

### Résultat:
- **Fichier généré**: `staging_environnement_raw.csv`
- **Nombre d'enregistrements**: 53
- **Champs**: 8 champs (5 données + 3 métadonnées)
- **État**: Données brutes avec défauts - prêtes pour nettoyage en Transformation
- **Traçabilité**: Chaque enregistrement peut être retracé à son fichier source original













```markdown
## Fichier: `03_Extract_MySQL_to_Staging.ktr`

### Objectif:
Extraire les données relationnelles de la base de données opérationnelle MySQL, organisées par thématique Data Mart, et les stocker dans la zone de staging.

### Architecture du flux ETL:

[3 Flux Parallèles Indépendants]
├── Flux Consommation → staging_consommation_mysql.csv
├── Flux Rentabilité → staging_rentabilite_mysql.csv  
└── Flux Environnement → staging_environnement_mysql.csv


### Sources de données:
- **Base de données**: `greencity_operational` (MySQL:3306)
- **Schéma SQL**: `GreenCity_Operational_Database.sql`
- **Connexion**: Configuration unique réutilisée par les 3 flux

### Flux détaillés:

#### 1. **Flux Consommation (Data Mart: Consommation énergétique)**
##### Étape: Table Input - Consommation SQL
- **Tables jointes**: `Meter_Readings`, `Meters`, `Buildings`, `Regions`
- **Jointures**: 
  - Relevés horaires → Compteurs → Bâtiments → Régions
- **Champs extraits** (13 champs):
  - Relevés: `reading_id`, `reading_date`, `consumption_value`, `temperature`
  - Compteurs: `meter_code`, `meter_type`, `meter_unit`
  - Bâtiments: `building_code`, `building_name`
  - Régions: `region_code`, `region_name`
  - Métadonnées DB: `created_at`, `updated_at`
- **Volume**: Données horaires de consommation

##### Étape: Formula_Add_Metadata_1
- **Champs ajoutés** (3 métadonnées):
  - `source_type` = `'MySQL'`
  - `source_filename` = `'GreenCity_Operational_Database.sql'`
  - `extraction_timestamp` = horodatage courant

##### Étape: Output CSV
- **Fichier**: `staging_consommation_mysql.csv`
- **Champs totaux**: 16 (13 données + 3 métadonnées)

#### 2. **Flux Rentabilité (Data Mart: Rentabilité économique)**
##### Étape: Table Input - Rentabilité SQL
- **Tables jointes**: `Invoices`, `Payments`, `Clients`, `Buildings`, `Regions`
- **Jointures**:
  - Factures → Clients + Bâtiments → Régions
  - LEFT JOIN Paiements (certaines factures non payées)
- **Champs extraits** (20 champs):
  - Factures: `invoice_id`, `invoice_number`, `invoice_date`, `due_date`
  - Montants: `total_ht`, `tva_amount`, `total_ttc`, `energy_cost`, `status`
  - Clients: `client_code`, `client_name`, `sector`
  - Bâtiments: `building_code`, `building_name`
  - Régions: `region_code`
  - Paiements: `payment_date`, `payment_amount`, `payment_method`
  - Métadonnées DB: `created_at`, `updated_at`

##### Étape: Formula_Add_Metadata_2
- **Métadonnées**: Identiques au flux Consommation

##### Étape: Output CSV
- **Fichier**: `staging_rentabilite_mysql.csv`
- **Champs totaux**: 23 (20 données + 3 métadonnées)

#### 3. **Flux Environnement (Data Mart: Impact environnemental)**
##### Étape: Table Input - Environnement SQL
- **Tables jointes**: `Environmental_Reports`, `Regions`, `Buildings`
- **Jointures**: LEFT JOIN (certains rapports sans région/bâtiment)
- **Champs extraits** (7 champs):
  - Rapports: `report_id`, `report_date`, `emission_co2_kg`, `recycling_rate`
  - Contexte: `region_code`, `building_code`
  - Métadonnées DB: `created_at`

##### Étape: Formula_Add_Metadata_3
- **Métadonnées**: Identiques aux autres flux

##### Étape: Output CSV
- **Fichier**: `staging_environnement_mysql.csv`
- **Champs totaux**: 10 (7 données + 3 métadonnées)

### Requêtes SQL détaillées:

#### Flux Consommation:
```sql
SELECT mr.reading_id, mr.reading_date, mr.consumption_value, mr.temperature,
       m.meter_code, m.meter_type, m.meter_unit,
       b.building_code, b.building_name,
       r.region_code, r.region_name,
       mr.created_at, mr.updated_at
FROM Meter_Readings mr
JOIN Meters m ON mr.meter_id = m.meter_id
JOIN Buildings b ON m.building_id = b.building_id
JOIN Regions r ON b.region_id = r.region_id
```

#### Flux Rentabilité:
```sql
SELECT i.invoice_id, i.invoice_number, i.invoice_date, i.due_date,
       i.total_ht, i.tva_amount, i.total_ttc, i.energy_cost, i.status,
       c.client_code, c.client_name, c.sector,
       b.building_code, b.building_name,
       r.region_code, p.payment_date, p.amount as payment_amount,
       p.payment_method, i.created_at, i.updated_at
FROM Invoices i
JOIN Clients c ON i.client_id = c.client_id
JOIN Buildings b ON i.building_id = b.building_id
JOIN Regions r ON b.region_id = r.region_id
LEFT JOIN Payments p ON i.invoice_id = p.invoice_id
```

#### Flux Environnement:
```sql
SELECT er.report_id, er.report_date, er.emission_co2_kg, er.recycling_rate,
       r.region_code, b.building_code, er.created_at
FROM Environmental_Reports er
LEFT JOIN Regions r ON er.region_id = r.region_id
LEFT JOIN Buildings b ON er.building_id = b.building_id
```

### Stratégie de traçabilité:
- **`source_type`**: Type de source (`'MySQL'` - constante)
- **`source_filename`**: Fichier source (`'GreenCity_Operational_Database.sql'` - constante)
- **`extraction_timestamp`**: Date/heure d'extraction (horodatage dynamique)
- **Contexte DB**: Les champs `created_at`/`updated_at` sont préservés de la base source

### Résultats:

#### 1. **staging_consommation_mysql.csv**
- **Destination**: Data Mart Consommation
- **Enregistrements**: Relevés horaires de compteurs
- **Champs**: 16 (13 données métier + 3 métadonnées)
- **Usage**: Analyse consommation vs température, tendances horaires

#### 2. **staging_rentabilite_mysql.csv**
- **Destination**: Data Mart Rentabilité
- **Enregistrements**: Factures avec paiements
- **Champs**: 23 (20 données métier + 3 métadonnées)
- **Usage**: Calcul CA, marge, taux de recouvrement, rentabilité

#### 3. **staging_environnement_mysql.csv**
- **Destination**: Data Mart Environnement
- **Enregistrements**: Rapports environnementaux
- **Champs**: 10 (7 données métier + 3 métadonnées)
- **Usage**: Analyse CO2, taux recyclage, impact par région/bâtiment

### Décisions techniques:
1. **Extraction thématique**: Données organisées par Data Mart cible
2. **Pré-jointures**: Jointures effectuées en extraction pour simplifier Transformation
3. **Métadonnées cohérentes**: Même structure que les extractions JSON/CSV
4. **LEFT JOINs**: Préservation des données même sans contexte complet

### Intégration avec autres sources:
Ces fichiers seront fusionnés en Transformation avec:
- `staging_consommation_raw.csv` (JSON) → Data Mart Consommation
- `staging_environnement_raw.csv` (CSV) → Data Mart Environnement
- `staging_rentabilite_mysql.csv` (MySQL seul) → Data Mart Rentabilité

### État: 
- **Prêt pour Transformation**: Données structurées, traçables, alignées avec les Data Marts
- **Qualité**: Données relationnelles propres (contrairement aux sources JSON/CSV)
- **Volume**: Données transactionnelles et de référence pour analyse BI















┌─────────────────────────────────────────────────────────────────────────┐
│                  04_Transform_Consommation FLOW                         │
└─────────────────────────────────────────────────────────────────────────┘

DEUX SOURCES PARALLÈLES :
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ CSV file input (json stream)         │    │ CSV file input (sql stream)          │
│ - Lit : staging_consommation_raw.csv │    │ - Lit : staging_consommation_mysql.csv│
│ - 10 champs :                        │    │ - 15 champs :                         │
│   • id_region, id_batiment           │    │   • reading_id, reading_date          │
│   • type_energie, unite              │    │   • consumption_value, temperature    │
│   • date_generation, compteur_id     │    │   • meter_code, meter_type            │
│   • date_mesure, consommation_value  │    │   • meter_unit, building_code         │
│   • source_filename                  │    │   • building_name, region_code        │
│   • extraction_timestamp             │    │   • region_name, created_at           │
│   • source_type                      │    │   • updated_at, extraction_timestamp  │
│                                      │    │   • source_type, source_filename      │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ Add fields                           │    │ remove field                         │
│ - Étape Constante                    │    │ - Étape Sélection de valeurs         │
│ - Ajoute 5 champs manquants :        │    │ - Supprime reading_id                │
│   • temperature (BigNumber)          │    │ - Garde 14 autres champs             │
│   • building_name (String)           │    │                                      │
│   • region_name (String)             │    │                                      │
│   • created_at (String)              │    │                                      │
│   • updated_at (String)              │    │                                      │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ rename                               │    │ add field                            │
│ - Étape Sélection de valeurs         │    │ - Étape Constante                    │
│ - Renomme champs français→anglais :  │    │ - Ajoute date_generation             │
│   • id_region → region_code          │    │                                      │
│   • id_batiment → building_code      │    │                                      │
│   • type_energie → meter_type        │    │                                      │
│   • unite → meter_unit               │    │                                      │
│   • compteur_id → meter_code         │    │                                      │
│   • date_mesure → reading_date       │    │                                      │
│   • consommation_value → consumption_value│                                      │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ REORDER                              │    │ REORDER2                             │
│ - Étape Sélection de valeurs         │    │ - Étape Sélection de valeurs         │
│ - Réordonne 16 champs :              │    │ - Réordonne 16 champs :              │
│   1. region_code                     │    │   1. region_code                     │
│   2. building_code                   │    │   2. building_code                   │
│   3. meter_type                      │    │   3. meter_type                      │
│   4. meter_code                      │    │   4. meter_code                      │
│   5. meter_unit                      │    │   5. meter_unit                      │
│   6. reading_date                    │    │   6. reading_date                    │
│   7. consumption_value               │    │   7. consumption_value               │
│   8. temperature                     │    │   8. temperature                     │
│   9. building_name                   │    │   9. building_name                   │
│   10. region_name                    │    │   10. region_name                    │
│   11. source_type                    │    │   11. source_type                    │
│   12. source_filename                │    │   12. source_filename                │
│   13. extraction_timestamp           │    │   13. extraction_timestamp           │
│   14. date_generation                │    │   14. date_generation                │
│   15. created_at                     │    │   15. created_at                     │
│   16. updated_at                     │    │   16. updated_at                     │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
                ┌─────────────────────────────────────────────┐
                │          Append streams                     │
                │ - Étape APPEND                              │
                │ - Head : REORDER (json stream)              │
                │ - Tail : REORDER2 (sql stream)              │
                │ - Fusionne les deux sources                 │
                └────────────────────────────────┬────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    TRAITEMENT COMMUN                                │
└─────────────────────────────────────────────────────────────────────┘

                Append streams
                    │
                    ▼
┌──────────────────────────────────────┐
│ Filter rows                          │
│ - Étape Filtre                       │
│ - Vérifie champs obligatoires :      │
│   • consumption_value IS NOT NULL    │
│   • reading_date IS NOT NULL         │
│   • building_code IS NOT NULL        │
│ - true → trim                        │
│ - false → rejet                      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ trim                                 │
│ - Étape Opérations sur chaînes       │
│ - Trim (both) sur 13 champs texte :  │
│   • region_code, building_code       │
│   • meter_type, meter_code           │
│   • meter_unit, reading_date         │
│   • building_name, region_name       │
│   • source_type, source_filename     │
│   • extraction_timestamp             │
│   • date_generation                  │
│   • created_at, updated_at           │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Replace in string                    │
│ - Étape Remplacement                 │
│ - Normalise valeurs :                │
│   • electricity → electricite        │
│   • gas → gaz                        │
│   • water → eau                      │
│   • KWh → kWh (standardisation)      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ fixing date                          │
│ - Étape Remplacement                 │
│ - Remplace "T" par espace dans       │
│   reading_date (format ISO)          │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values                        │
│ - Étape Sélection de valeurs         │
│ - Convertit formats dates :          │
│   • extraction_timestamp → yyyy/MM/dd HH:mm:ss.SSS│
│   • date_generation → yyyy-MM-dd     │
│   • created_at → yyyy/MM/dd HH:mm:ss │
│   • updated_at → yyyy/MM/dd HH:mm:ss │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 7                      │
│ - Étape Sélection de valeurs         │
│ - Convertit formats dates :          │
│   • extraction_timestamp → yyyy-MM-dd HH:mm:ss│
│   • created_at → yyyy-MM-dd HH:mm:ss │
│   • updated_at → yyyy-MM-dd HH:mm:ss │
└───────────────┬──────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                 ROUTAGE DES FORMATS DE DATE                         │
└─────────────────────────────────────────────────────────────────────┘

                Select values 7
                    │
                    ▼
┌──────────────────────────────────────┐
│ yyyy-MM-dd HH:mm:ss                 │
│ - Étape Filtre avec REGEXP           │
│ - Vérifie format : ^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$│
│ - true → Select values 2 (format OK) │
│ - false → dd/MM/yyyy HH:mm          │
└───────────────┬──────────────────────┘
      ┌─────────┴──────────┐
      │                    │
      ▼                    ▼
┌──────────────────────┐  ┌──────────────────────────────────────┐
│ Select values 2      │  │ dd/MM/yyyy HH:mm                    │
│ - Convertit :        │  │ - Étape Filtre avec REGEXP           │
│   • reading_date →   │  │ - Vérifie format : ^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$│
│     yyyy-MM-dd       │  │ - true → Replace in string 2         │
│                      │  │ - false → Format yyyy/MM/dd HH:mm:ss │
└───────────────┬──────┘  └───────────────┬──────────────────────┘
      │                    ┌───────────────┴──────────┐
      │                    │                          │
      ▼                    ▼                          ▼
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────────────────────┐
│ Append streams 2     │  │ Replace in string 2  │  │ Format yyyy/MM/dd HH:mm:ss          │
│ - Head :             │  │ - Extrait date       │  │ - Vérifie format : ^[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}│
│   Select values 2    │  │   (sans heure)       │  │ - true → Select values 4             │
│ - Tail :             │  │ - Regex :            │  │ - false → rejet                     │
│   Select values 5    │  │   ^(\d{2}/\d{2}/\d{4}).*$ → $1 │
└───────────────┬──────┘  └───────────────┬──────┘  └───────────────┬──────────────────────┘
      │                    │                                       │
      │                    ▼                                       ▼
      │          ┌──────────────────────┐              ┌──────────────────────────────────────┐
      │          │ Select values 3      │              │ Select values 4                      │
      │          │ - Convertit :        │              │ - Convertit :                        │
      │          │   • reading_date →   │              │   • reading_date →                   │
      │          │     dd/MM/yyyy       │              │     yyyy/MM/dd                       │
      │          └───────────────┬──────┘              └───────────────┬──────────────────────┘
      │                    │                                       │
      │                    ▼                                       ▼
      │          ┌──────────────────────┐              ┌──────────────────────────────────────┐
      │          │ Select values 5      │              │ Select values 6                      │
      │          │ - Convertit :        │              │ - Convertit :                        │
      │          │   • reading_date →   │              │   • reading_date →                   │
      │          │     yyyy-MM-dd       │              │     yyyy-MM-dd                       │
      └──────────┴───────────────┬──────┘              └───────────────┬──────────────────────┘
                                  │                                     │
                                  ▼                                     ▼
                                  ┌─────────────────────────────────────────┐
                                  │          Append streams 3               │
                                  │ - Head : Append streams 2               │
                                  │ - Tail : Select values 6                │
                                  │ - Fusionne tous les formats de date     │
                                  └────────────────────────────────┬────────┘
                                                                   │
                                                                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          SORTIE FINALE                              │
└─────────────────────────────────────────────────────────────────────┘

                Append streams 3
                    │
                    ▼
┌──────────────────────────────────────┐
│ Text file output                     │
│ - Écrit vers :                       │
│   transformed_consommation.csv       │
│ - Format : CSV avec entête           │
│ - Encodage : UTF-8                   │
│ - Séparateur : virgule               │
│ - Guillemets : double quotes         │
│ - 16 champs formatés                 │
└──────────────────────────────────────┘

FLUX DE TRAITEMENT :
• Deux sources parallèles (JSON stream + SQL stream)
• Harmonisation des noms de champs (français→anglais)
• Ajout de champs manquants dans chaque flux
• Réorganisation des champs pour alignement
• Fusion des deux sources
• Validation des champs obligatoires
• Nettoyage des chaînes (trim)
• Standardisation des valeurs (électricité→electricite, etc.)
• Correction du format ISO (remplacement "T")
• Conversion des dates metadata
• Routage complexe pour 3 formats de date :
  1. yyyy-MM-dd HH:mm:ss → yyyy-MM-dd
  2. dd/MM/yyyy HH:mm → yyyy-MM-dd
  3. yyyy/MM/dd HH:mm:ss → yyyy-MM-dd
• Fusion finale des flux de dates
• Sortie CSV unique

CHAMPS FINAUX (16) :
1. region_code          9. building_name
2. building_code       10. region_name
3. meter_type          11. source_type
4. meter_code          12. source_filename
5. meter_unit          13. extraction_timestamp
6. reading_date        14. date_generation
7. consumption_value   15. created_at
8. temperature         16. updated_at

FORMATS DE DATE ACCEPTÉS :
1. yyyy-MM-dd HH:mm:ss      (ex: 2024-01-15 14:30:00)
2. dd/MM/yyyy HH:mm         (ex: 15/01/2024 14:30)
3. yyyy/MM/dd HH:mm:ss      (ex: 2024/01/15 14:30:00)
4. yyyy-MM-dd'T'HH:mm:ss    (ex: 2024-01-15T14:30:00)

STANDARDISATION :
• Types énergie : electricity→electricite, gas→gaz, water→eau
• Unité : KWh→kWh (miniscule)
• Noms régions/bâtiments : trim des espaces
• Toutes les dates → format final yyyy-MM-dd







































┌─────────────────────────────────────────────────────────────────────────┐
│                  05_Transform_Rentabilite FLOW                          │
└─────────────────────────────────────────────────────────────────────────┘

SOURCE UNIQUE (Facturation MySQL) :
┌──────────────────────────────────────┐
│ CSV file input                       │
│ - Lit : staging_rentabilite_mysql.csv│
│ - 23 champs de facturation :         │
│   1. invoice_id (Integer)            │
│   2. invoice_number (String)         │
│   3. invoice_date (String)           │
│   4. due_date (String)               │
│   5. total_ht (BigNumber)            │
│   6. tva_amount (BigNumber)          │
│   7. total_ttc (BigNumber)           │
│   8. energy_cost (BigNumber)         │
│   9. status (String)                 │
│   10. client_code (String)           │
│   11. client_name (String)           │
│   12. sector (String)                │
│   13. building_code (String)         │
│   14. building_name (String)         │
│   15. region_code (String)           │
│   16. payment_date (String)          │
│   17. payment_amount (BigNumber)     │
│   18. payment_method (String)        │
│   19. created_at (String)            │
│   20. updated_at (String)            │
│   21. extraction_timestamp (String)  │
│   22. source_type (String)           │
│   23. source_filename (String)       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 2 2                    │
│ - Étape Sélection de valeurs         │
│ - Sélectionne tous les 23 champs     │
│ - Les champs sont déjà en anglais    │
│ - Pas de transformation              │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Replace in string                    │
│ - Étape Remplacement                 │
│ - Traduit payment_method :           │
│   • check → Chèque                   │
│   • card → Carte Bancaire            │
│   • bank_transfer → Virement Bancaire│
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ If field value is null               │
│ - Étape Si valeur nulle              │
│ - Si payment_method est null →       │
│   Remplacer par "Non Payé"           │
│ - Gère les paiements manquants       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ trim                                 │
│ - Étape Opérations sur chaînes       │
│ - Trim (both) sur 11 champs texte :  │
│   • invoice_number, status           │
│   • client_code, client_name, sector │
│   • building_code, building_name     │
│   • region_code, payment_method      │
│   • source_type, source_filename     │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Filter rows 3                        │
│ - Étape Filtre avec REGEXP           │
│ - Vérifie 3 codes simultanément :    │
│   • region_code = ^REG[0-9]{2}$      │
│   • building_code = ^BAT[0-9]{3}$    │
│   • client_code = ^CLI[0-9]{3}$      │
│ - true → Append streams 2            │
│   (tous les codes sont valides)      │
│ - false → Modified JavaScript value 2 │
│   (au moins un code invalide)        │
└───────────────┬──────────────────────┘
      ┌─────────┼─────────┐
      │         │         │
      ▼         ▼         │
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ Append streams 2                     │    │ Modified JavaScript value 2          │
│ - Étape APPEND                       │    │ - Étape JavaScript Modifié           │
│ - Head : Filter rows 3 (codes OK)    │    │ - Pour données avec codes invalides :│
│ - Tail : Select values 3 (corrigées) │    │   • Si region_code invalide OU       │
│                                      │    │     région > 12 OU région = 0 →      │
│                                      │    │     "NON_RENSEIGNE"                  │
│                                      │    │   • Si building_code invalide OU     │
│                                      │    │     bâtiment > 500 →                 │
│                                      │    │     "NON_RENSEIGNE"                  │
│                                      │    │   • Si client_code invalide OU       │
│                                      │    │     client > 999 OU client = 0 →     │
│                                      │    │     "NON_RENSEIGNE"                  │
│                                      │    │ - Crée champs clean :               │
│                                      │    │   • region_clean                     │
│                                      │    │   • building_clean                   │
│                                      │    │   • client_clean                     │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ Fix Date Format with REGEXP          │    │ Calculator_Unifier                   │
│ - Étape Remplacement (Regex)         │    │ - Étape Calculatrice                 │
│ - Transforme dd/MM/yyyy → yyyy-MM-dd │    │ - Unifie avec NVL :                  │
│   pour 6 champs dates :              │    │   • region_code1 = NVL(region_code,  │
│   • invoice_date                     │    │      region_clean)                   │
│   • due_date                         │    │   • building_code1 = NVL(building_code,│
│   • payment_date                     │    │      building_clean)                 │
│   • created_at                       │    │   • client_code1 = NVL(client_code,  │
│   • updated_at                       │    │      client_clean)                   │
│   • extraction_timestamp             │    │ - Garde les deux versions           │
│ - Regex : ^(\d{1,2})/(\d{1,2})/(\d{4})$│  └───────────────┬──────────────────────┘
│   → $3-$1-$2                         │                    │
└───────────────┬──────────────────────┘                    ▼
                │                              ┌──────────────────────────────────────┐
                ▼                              │ Select values                        │
┌──────────────────────────────────────┐      │ - Étape Sélection de valeurs         │
│ Replace in string 2                  │      │ - Supprime anciens champs :          │
│ - Étape Remplacement (Regex)         │      │   • region_code                      │
│ - Extrait partie date                │      │   • building_code                    │
│   (supprime partie heure)            │      │   • region_clean                     │
│   pour 6 champs dates :              │      │   • building_clean                   │
│   • invoice_date                     │      │   • client_code                      │
│   • due_date                         │      │   • client_clean                     │
│   • payment_date                     │      │ - Garde champs unifiés :            │
│   • created_at                       │      │   • region_code1                     │
│   • updated_at                       │      │   • building_code1                   │
│   • extraction_timestamp             │      │   • client_code1                     │
│ - Regex : ^(\d{4}/\d{2}/\d{2}).*$    │      └───────────────┬──────────────────────┘
│   → $1                               │                      │
└───────────────┬──────────────────────┘                      ▼
                │                              ┌──────────────────────────────────────┐
                ▼                              │ Select values 3                      │
┌──────────────────────────────────────┐      │ - Étape Sélection de valeurs         │
│ Select values 2                      │      │ - Renomme champs unifiés :           │
│ - Étape Conversion de type           │      │   • region_code1 → region_code       │
│ - Convertit 6 champs String → Date   │      │   • building_code1 → building_code   │
│   avec format yyyy/MM/dd :           │      │   • client_code1 → client_code       │
│   • invoice_date                     │      │ - Garde les autres champs inchangés  │
│   • due_date                         │      │ - Préparé pour Append streams 2      │
│   • payment_date                     │      └──────────────────────────────────────┘
│   • created_at                       │
│   • updated_at                       │
│   • extraction_timestamp             │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 4                      │
│ - Étape Conversion de type           │
│ - Convertit 6 champs Date → Date     │
│   avec format yyyy-MM-dd :           │
│   • invoice_date                     │
│   • due_date                         │
│   • payment_date                     │
│   • created_at                       │
│   • updated_at                       │
│   • extraction_timestamp             │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ String operations                    │
│ - Étape Opérations sur chaînes       │
│ - Trim (both) sur 11 champs texte :  │
│   • invoice_number, status           │
│   • client_code, client_name, sector │
│   • building_code, building_name     │
│   • region_code, payment_method      │
│   • source_type, source_filename     │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 5                      │
│ - Étape Conversion finale            │
│ - Convertit 6 champs Date → String   │
│   avec format yyyy-MM-dd :           │
│   • invoice_date                     │
│   • due_date                         │
│   • payment_date                     │
│   • created_at                       │
│   • updated_at                       │
│   • extraction_timestamp             │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Text file output                     │
│ - Écrit vers :                       │
│   transformed_rentabilite.csv        │
│ - Format : CSV avec entête           │
│ - Encodage : UTF-8                   │
│ - Séparateur : virgule               │
│ - Guillemets : double quotes         │
│ - 23 champs formatés                 │
└──────────────────────────────────────┘

FLUX DE TRAITEMENT :
• Source unique MySQL (pas de fusion JSON/SQL)
• Traduction des méthodes de paiement (anglais→français)
• Gestion des paiements manquants → "Non Payé"
• Nettoyage des chaînes (trim)
• Validation des 3 codes : région, bâtiment, client
• Deux chemins :
  1. Données valides → directement en sortie
  2. Données non conformes → correction → unification → sortie
• Traitement des dates en 3 étapes :
  1. Format dd/MM/yyyy → yyyy-MM-dd
  2. Extraction date (suppression heure)
  3. Conversion String → Date → String format final
• Sortie CSV final unifié

CHAMPS FINAUX (23) :
1. invoice_id            12. sector
2. invoice_number        13. building_code
3. invoice_date          14. building_name
4. due_date              15. region_code
5. total_ht              16. payment_date
6. tva_amount            17. payment_amount
7. total_ttc             18. payment_method
8. energy_cost           19. created_at
9. status                20. updated_at
10. client_code          21. extraction_timestamp
11. client_name          22. source_type
                         23. source_filename

VALIDATIONS DES CODES :
• REG[0-9]{2} pour région (ex: REG01)
   - Numéro entre 01 et 12
   - Non nul (≠ 00)
• BAT[0-9]{3} pour bâtiment (ex: BAT001)
   - Numéro ≤ 500
• CLI[0-9]{3} pour client (ex: CLI001)
   - Numéro entre 001 et 999
   - Non nul (≠ 000)

VALEURS PAR DÉFAUT :
• payment_method null → "Non Payé"
• Codes invalides → "NON_RENSEIGNE"

FORMATS DE DATE TRAITÉS :
• Entrée : dd/MM/yyyy (ex: 15/01/2024)
• Sortie : yyyy-MM-dd (ex: 2024-01-15)

MÉTHODES DE PAIEMENT TRADUITES :
• check → Chèque
• card → Carte Bancaire
• bank_transfer → Virement Bancaire
















┌─────────────────────────────────────────────────────────────────────────┐
│                  06_Transform_Environnement FLOW                        │
└─────────────────────────────────────────────────────────────────────────┘

DEUX SOURCES PARALLÈLES (Environnement) :
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ CSV file input (Raw)                 │    │ CSV file input 2 (MySQL)             │
│ - Lit : staging_environnement_raw.csv│    │ - Lit : staging_environnement_mysql.csv│
│ - 8 champs :                         │    │ - 10 champs :                         │
│   • id_region (String)               │    │   • report_id (Integer)              │
│   • id_batiment (String)             │    │   • report_date (String)             │
│   • date_rapport (String)            │    │   • emission_co2_kg (String)         │
│   • emission_CO2_kg (String)         │    │   • recycling_rate (String)          │
│   • taux_recyclage (String)          │    │   • region_code (String)             │
│   • source_filename (String)         │    │   • building_code (String)           │
│   • extraction_timestamp (String)    │    │   • created_at (String)              │
│   • source_type (String)             │    │   • extraction_timestamp (String)    │
│                                      │    │   • source_type (String)             │
│                                      │    │   • source_filename (String)         │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ Add constants                        │    │ Add constants 2                      │
│ - Étape Constante                    │    │ - Étape Constante                    │
│ - Ajoute 2 champs manquants :        │    │ - Ajoute 1 champ manquant :          │
│   • created_at (String)              │    │   • updated_at (String)              │
│   • updated_at (String)              │    │                                      │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ Select values 5                      │    │ Select values 4                      │
│ - Étape Sélection de valeurs         │    │ - Étape Sélection de valeurs         │
│ - Renomme champs français→anglais :  │    │ - Supprime report_id                 │
│   • id_region → region_code          │    │ - Garde 9 autres champs              │
│   • id_batiment → building_code      │    │                                      │
│   • date_rapport → report_date       │    │                                      │
│   • emission_CO2_kg → emission_co2_kg│    │                                      │
│   • taux_recyclage → recycling_rate  │    │                                      │
│                                      │    │                                      │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ reorder                              │    │ reorder2                             │
│ - Étape Sélection de valeurs         │    │ - Étape Sélection de valeurs         │
│ - Réordonne 10 champs :              │    │ - Réordonne 10 champs :              │
│   1. region_code                     │    │   1. region_code                     │
│   2. report_date                     │    │   2. report_date                     │
│   3. building_code                   │    │   3. building_code                   │
│   4. emission_co2_kg                 │    │   4. emission_co2_kg                 │
│   5. recycling_rate                  │    │   5. recycling_rate                  │
│   6. extraction_timestamp            │    │   6. extraction_timestamp            │
│   7. source_filename                 │    │   7. source_filename                 │
│   8. source_type                     │    │   8. source_type                     │
│   9. created_at                      │    │   9. created_at                      │
│   10. updated_at                     │    │   10. updated_at                     │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
                ┌─────────────────────────────────────────────┐
                │          Append streams                     │
                │ - Étape APPEND                              │
                │ - Head : reorder (raw stream)               │
                │ - Tail : reorder2 (mysql stream)            │
                │ - Fusionne les deux sources                 │
                └────────────────────────────────┬────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    TRAITEMENT COMMUN                                │
└─────────────────────────────────────────────────────────────────────┘

                Append streams
                    │
                    ▼
┌──────────────────────────────────────┐
│ trim                                 │
│ - Étape Opérations sur chaînes       │
│ - Trim (both) sur 10 champs texte :  │
│   • region_code, report_date         │
│   • building_code, emission_co2_kg   │
│   • recycling_rate                   │
│   • extraction_timestamp             │
│   • source_filename, source_type     │
│   • created_at, updated_at           │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Filter rows 3                        │
│ - Étape Filtre avec REGEXP           │
│ - Vérifie 2 codes simultanément :    │
│   • region_code = ^REG(0[1-9]|1[0-2])$│
│     (région 01-12 uniquement)        │
│   • building_code = ^BAT[0-9]{3}$    │
│ - true → Append streams 2            │
│   (tous les codes sont valides)      │
│ - false → Modified JavaScript value 2 │
│   (au moins un code invalide)        │
└───────────────┬──────────────────────┘
      ┌─────────┼─────────┐
      │         │         │
      ▼         ▼         │
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ Append streams 2                     │    │ Modified JavaScript value 2          │
│ - Étape APPEND                       │    │ - Étape JavaScript Modifié           │
│ - Head : Filter rows 3 (codes OK)    │    │ - Pour données avec codes invalides :│
│ - Tail : Select values 2 (corrigées) │    │   • Si region_code invalide OU       │
│ - Fusionne données valides et        │    │     région > 12 OU région = 0 →      │
│   corrigées                          │    │     "NON_RENSEIGNE"                  │
│                                      │    │   • Si building_code invalide OU     │
│                                      │    │     bâtiment > 500 →                 │
│                                      │    │     "NON_RENSEIGNE"                  │
│                                      │    │ - Crée champs clean :               │
│                                      │    │   • region_clean                     │
│                                      │    │   • building_clean                   │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ Select values 7                      │    │ Select values                        │
│ - Étape Conversion de type           │    │ - Étape Sélection de valeurs         │
│ - Convertit 3 champs String → Date   │    │ - Supprime anciens champs :          │
│   avec format yyyy-MM-dd :           │    │   • region_code                      │
│   • extraction_timestamp             │    │   • building_code                    │
│   • created_at                       │    │   • region_clean, building_clean     │
│   • updated_at                       │    │ - Garde autres champs               │
└───────────────┬──────────────────────┘    └───────────────┬──────────────────────┘
                │                                          │
                ▼                                          ▼
┌──────────────────────────────────────┐    ┌──────────────────────────────────────┐
│ Append streams 2                     │    │ Select values 2                      │
│ - Étape APPEND                       │    │ - Étape Sélection de valeurs         │
│ - Head : Filter rows 3 (codes OK)    │    │ - Renomme champs clean :            │
│ - Tail : Select values 2 (corrigées) │    │   • region_clean → region_code      │
│ - Fusionne données valides et        │    │   • building_clean → building_code  │
│   corrigées                          │    │ - Garde autres champs               │
└───────────────┬──────────────────────┘    └──────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Filter rows                          │
│ - Étape Filtre avec REGEXP           │
│ - Vérifie formats numériques :       │
│   • emission_co2_kg = ^[0-9]+(\.[0-9]+)?$│
│   • recycling_rate = ^[0-9]+(\.[0-9]+)?$│
│ - true → Select values 3 (formats OK)│
│ - false → Dummy (données rejetées)   │
└───────────────┬──────────────────────┘
      ┌─────────┴──────────┐
      │                    │
      ▼                    ▼
┌──────────────────────┐  ┌──────────────────────────────────────┐
│ Select values 3      │  │ Dummy                               │
│ - Convertit types :  │  │ - Étape Dummy (données rejetées)    │
│   • emission_co2_kg →│  │                                      │
│     BigNumber(#.##)  │  │                                      │
│   • recycling_rate → │  │                                      │
│     BigNumber(#.###) │  │                                      │
└───────────────┬──────┘  └──────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Add constants 3 2                    │
│ - Étape Constante                    │
│ - Ajoute constante = 100             │
│   (pour conversion pourcentage)      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Calculator 2                         │
│ - Étape Calculatrice                 │
│ - Calcule :                          │
│   • recycling_rate_percent =         │
│     recycling_rate * 100             │
│   (convertit décimal → pourcentage)  │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Filter rows 2                        │
│ - Étape Filtre de plage              │
│ - Vérifie plages valides :           │
│   • emission_co2_kg ≥ 0 et ≤ 10000   │
│   • recycling_rate ≥ 0 et ≤ 1        │
│ - true → Replace in string           │
│ - false → rejet                      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Replace in string                    │
│ - Étape Remplacement (Regex)         │
│ - Extrait partie date                │
│   (supprime partie heure)            │
│   pour 3 champs dates :              │
│   • extraction_timestamp             │
│   • created_at                       │
│   • updated_at                       │
│ - Regex : ^(\d{4}/\d{2}/\d{2}).*$    │
│   → $1                               │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 6                      │
│ - Étape Conversion de type           │
│ - Convertit 3 champs String → Date   │
│   avec format yyyy/MM/dd :           │
│   • extraction_timestamp             │
│   • created_at                       │
│   • updated_at                       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 7                      │
│ - Étape Conversion de type           │
│ - Convertit 3 champs Date → Date     │
│   avec format yyyy-MM-dd :           │
│   • extraction_timestamp             │
│   • created_at                       │
│   • updated_at                       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Filter rows 4                        │
│ - Étape Filtre avec REGEXP           │
│ - Vérifie format report_date :       │
│   • yyyy-MM-dd                       │
│ - true → Select values 12            │
│   (format direct yyyy-MM-dd)         │
│ - false → Filter rows 5              │
│   (autre format)                     │
└───────────────┬──────────────────────┘
      ┌─────────┴──────────┐
      │                    │
      ▼                    ▼
┌──────────────────────┐  ┌──────────────────────────────────────┐
│ Select values 12     │  │ Filter rows 5                       │
│ - Convertit :        │  │ - Vérifie format report_date :      │
│   • report_date →    │  │   • yyyy/MM/dd                      │
│     Date(yyyy-MM-dd) │  │ - true → Select values 8            │
└───────────────┬──────┘  └───────────────┬──────────────────────┘
                │                         │
                │                         ▼
                │               ┌──────────────────────────────────────┐
                │               │ Select values 8                      │
                │               │ - Convertit :                        │
                │               │   • report_date →                    │
                │               │     Date(yyyy/MM/dd)                 │
                │               └───────────────┬──────────────────────┘
                │                               │
                │                               ▼
                │                     ┌──────────────────────────────────────┐
                │                     │ Select values 10                     │
                │                     │ - Convertit :                        │
                │                     │   • report_date →                    │
                │                     │     Date(yyyy-MM-dd)                 │
                │                     └───────────────┬──────────────────────┘
                │                         ┌───────────┴──────────┐
                │                         │                     │
                │                         ▼                     ▼
                │               ┌──────────────────────────────────────┐
                │               │ Append streams 3                     │
                │               │ - Head : Select values 12            │
                │               │ - Tail : Select values 10            │
                │               │ - Fusionne 2 formats de date        │
                │               └───────────────┬──────────────────────┘
                │                               │
                ▼                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                 TRAITEMENT ALTERNATIF DES DATES                     │
└─────────────────────────────────────────────────────────────────────┘

                Filter rows 5
                    │
                    ▼
┌──────────────────────────────────────┐
│ Filter rows 6                        │
│ - Vérifie format report_date :       │
│   • yyyy/MM/dd HH:mm:ss.SSS         │
│   (avec millisecondes)               │
│ - true → Replace in string 2         │
│ - false → rejet                      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Replace in string 2                  │
│ - Extrait partie date                │
│   (supprime heure/millisecondes)     │
│   pour report_date :                 │
│ - Regex : ^(\d{4}/\d{2}/\d{2}).*$    │
│   → $1                               │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 9                      │
│ - Convertit :                        │
│   • report_date →                    │
│     Date(yyyy/MM/dd)                 │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 11                     │
│ - Convertit :                        │
│   • report_date →                    │
│     Date(yyyy-MM-dd)                 │
└───────────────┬──────────────────────┘
                │
                ▼
                ┌─────────────────────────────────────────────┐
                │          Append streams 4                   │
                │ - Head : Append streams 3                   │
                │ - Tail : Select values 11                   │
                │ - Fusionne tous les formats de date        │
                └────────────────────────────────┬────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  CALCUL FINAL ET SORTIE                             │
└─────────────────────────────────────────────────────────────────────┘

                Append streams 4
                    │
                    ▼
┌──────────────────────────────────────┐
│ Add constants 4                      │
│ - Étape Constante                    │
│ - Ajoute constante = 100             │
│   (pour conversion pourcentage)      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Calculator 3                         │
│ - Étape Calculatrice                 │
│ - Calcule :                          │
│   • recycling_rate_percent =         │
│     recycling_rate * 100             │
│   (pour toutes les données fusionnées)│
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 13                     │
│ - Étape Sélection finale             │
│ - Réordonne 11 champs pour sortie :  │
│   1. region_code                     │
│   2. report_date                     │
│   3. building_code                   │
│   4. emission_co2_kg                 │
│   5. recycling_rate                  │
│   6. recycling_rate_percent          │
│   7. extraction_timestamp            │
│   8. source_filename                 │
│   9. source_type                     │
│   10. created_at                     │
│   11. updated_at                     │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Text file output                     │
│ - Écrit vers :                       │
│   transformed_environnement.csv      │
│ - Format : CSV avec entête           │
│ - Encodage : UTF-8                   │
│ - Séparateur : virgule               │
│ - Guillemets : double quotes         │
│ - 11 champs formatés                 │
└──────────────────────────────────────┘

FLUX DE TRAITEMENT :
• Deux sources parallèles (Raw + MySQL)
• Ajout de champs manquants dans chaque flux
• Renommage français→anglais pour le flux Raw
• Réorganisation des champs pour alignement
• Fusion des deux sources
• Nettoyage des chaînes (trim)
• Validation des 2 codes : région (01-12), bâtiment (001-500)
• Deux chemins :
  1. Données valides → directement en traitement
  2. Données non conformes → correction → unification
• Validation des formats numériques (regex)
• Conversion des types (String → BigNumber)
• Calcul du pourcentage de recyclage (×100)
• Validation des plages :
  - CO2 : 0 à 10000 kg
  - Taux recyclage : 0 à 1 (0-100%)
• Traitement des dates metadata
• Routage complexe pour 3 formats de report_date :
  1. yyyy-MM-dd → conversion directe
  2. yyyy/MM/dd → conversion intermédiaire
  3. yyyy/MM/dd HH:mm:ss.SSS → extraction date → conversion
• Calcul final du pourcentage pour toutes données
• Sortie CSV avec 11 champs

CHAMPS FINAUX (11) :
1. region_code                7. extraction_timestamp
2. report_date                8. source_filename
3. building_code              9. source_type
4. emission_co2_kg           10. created_at
5. recycling_rate            11. updated_at
6. recycling_rate_percent

VALIDATIONS DES CODES :
• REG(0[1-9]|1[0-2]) pour région (ex: REG01 à REG12)
   - Numéro entre 01 et 12 uniquement
• BAT[0-9]{3} pour bâtiment (ex: BAT001)
   - Numéro ≤ 500

VALIDATIONS DES VALEURS :
• emission_co2_kg :
  - Format numérique : ^[0-9]+(\.[0-9]+)?$
  - Plage : 0 à 10000 kg
• recycling_rate :
  - Format numérique : ^[0-9]+(\.[0-9]+)?$
  - Plage : 0 à 1 (0-100%)
  - Calcul : recycling_rate_percent = recycling_rate × 100

FORMATS DE DATE ACCEPTÉS (report_date) :
1. yyyy-MM-dd                 (ex: 2024-01-15)
2. yyyy/MM/dd                 (ex: 2024/01/15)
3. yyyy/MM/dd HH:mm:ss.SSS    (ex: 2024/01/15 14:30:00.123)

FORMATS DE DATE FINAUX :
• report_date → yyyy-MM-dd
• extraction_timestamp → yyyy-MM-dd
• created_at → yyyy-MM-dd
• updated_at → yyyy-MM-dd

TRANSFORMATIONS :
• Raw → MySQL : id_region → region_code, id_batiment → building_code, etc.
• Taux recyclage décimal → pourcentage (×100)
• Valeurs non conformes → "NON_RENSEIGNE"
• Trim de tous les champs texte














┌─────────────────────────────────────────────────────────────────────────┐
│                  07_Load_DM_Consommation FLOW                          │
└─────────────────────────────────────────────────────────────────────────┘

CONNEXION BASE DE DONNÉES :
┌──────────────────────────────────────┐
│ Connexion MySQL : greencity_dw       │
│ - Serveur : localhost                │
│ - Port : 3306                        │
│ - Base : greencity_dw                │
│ - Utilisateur : root                 │
│ - Mot de passe : ******              │
└──────────────────────────────────────┘

SOURCE DE DONNÉES TRANSFORMÉES :
┌──────────────────────────────────────┐
│ Input_Consommation                   │
│ - Type : CSV File Input              │
│ - Fichier : transformed_consommation.csv│
│ - 16 champs transformés :            │
│   1. region_code (String)            │
│   2. building_code (String)          │
│   3. meter_type (String)             │
│   4. meter_code (String)             │
│   5. meter_unit (String)             │
│   6. reading_date (Date:yyyy-MM-dd)  │
│   7. consumption_value (BigNumber)   │
│   8. temperature (BigNumber)         │
│   9. building_name (String)          │
│   10. region_name (String)           │
│   11. source_type (String)           │
│   12. source_filename (String)       │
│   13. extraction_timestamp (Date)    │
│   14. date_generation (Date)         │
│   15. created_at (Date)              │
│   16. updated_at (Date)              │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_TEMPS          │
│ - Type : Database Lookup             │
│ - Table : dim_temps                  │
│ - Clé : reading_date → date_complete │
│ - Retourne : id_temps (Integer)      │
│ - Cherche la dimension temps         │
│   correspondant à la date de lecture │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_REGION         │
│ - Type : Database Lookup             │
│ - Table : dim_region                 │
│ - Clé : region_code → code_region    │
│ - Retourne : id_region (Integer)     │
│ - Cherche la dimension région        │
│   correspondant au code région       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_BATIMENT       │
│ - Type : Database Lookup             │
│ - Table : dim_batiment               │
│ - Clé : building_code → code_batiment│
│ - Retourne : id_batiment (Integer)   │
│ - Cherche la dimension bâtiment      │
│   correspondant au code bâtiment     │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ String operations                    │
│ - Type : String Operations           │
│ - Trim (both) sur 2 champs :         │
│   • meter_type                       │
│   • meter_code                       │
│ - Nettoie avant lookup suivant       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_ENERGIE        │
│ - Type : Database Lookup             │
│ - Table : dim_energie                │
│ - Clé : meter_type → type_energie    │
│ - Retourne :                         │
│   • id_energie (Integer)             │
│   • tarif_unitaire (Number)          │
│ - Cherche la dimension énergie       │
│   + récupère le tarif unitaire       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Calculator                           │
│ - Type : Calculator                  │
│ - Calcule :                          │
│   • cout_energie_calcule =           │
│     consumption_value × tarif_unitaire│
│ - Calcule le coût énergétique        │
│   basé sur la consommation et le     │
│   tarif unitaire                     │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_COMPTEUR       │
│ - Type : Database Lookup             │
│ - Table : dim_compteur               │
│ - Clé : meter_code → code_compteur   │
│ - Retourne : id_compteur (Integer)   │
│ - Cherche la dimension compteur      │
│   correspondant au code compteur     │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values                        │
│ - Type : Select Values               │
│ - Sélectionne 12 champs pour la      │
│   table de fait :                    │
│   1. consumption_value               │
│   2. temperature                     │
│   3. source_filename                 │
│   4. extraction_timestamp            │
│   5. created_at                      │
│   6. updated_at                      │
│   7. id_temps                        │
│   8. id_region                       │
│   9. id_batiment                     │
│   10. id_energie                     │
│   11. cout_energie_calcule           │
│   12. id_compteur                    │
│ - Prépare les champs pour l'insertion│
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Add constants                        │
│ - Type : Constant                    │
│ - Ajoute : id_client = ???           │
│   (valeur constante non spécifiée)   │
│ - Complète avec champ client manquant│
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Upsert_FAIT_CONSOMMATION             │
│ - Type : Insert Update               │
│ - Table : fait_consommation          │
│ - Stratégie : Insert/Update          │
│   (UPSERT sur clés composites)       │
│ - Clés de lookup (4) :               │
│   1. id_temps                        │
│   2. id_batiment                     │
│   3. id_compteur                     │
│   4. id_energie                      │
│ - Champs insérés/mis à jour (11) :   │
│   1. id_temps                        │
│   2. id_batiment                     │
│   3. id_region                       │
│   4. id_client                       │
│   5. id_energie                      │
│   6. id_compteur                     │
│   7. consommation_valeur             │
│   8. temperature                     │
│   9. cout_energie                    │
│   10. source_id                      │
│   11. date_extraction                │
│ - Commit toutes les 100 lignes       │
└──────────────────────────────────────┘

FLUX DE CHARGEMENT DIMENSIONNEL :
• Lecture des données transformées (CSV)
• Séquence de 5 lookups dimensionnels :
  1. DIM_TEMPS : Date de lecture → ID temps
  2. DIM_REGION : Code région → ID région
  3. DIM_BATIMENT : Code bâtiment → ID bâtiment
  4. DIM_ENERGIE : Type énergie → ID énergie + tarif
  5. DIM_COMPTEUR : Code compteur → ID compteur
• Calcul du coût énergétique (consommation × tarif)
• Préparation des champs de fait
• Ajout du client (valeur constante)
• Insertion/Update dans la table de fait

MAPPING DES TABLES DIMENSIONNELLES :
┌─────────────────────────────────────────────────────────────────────┐
│ Source → Table Dimension → Champ Clé → Champ Retour                │
├─────────────────────────────────────────────────────────────────────┤
│ reading_date → dim_temps → date_complete → id_temps               │
│ region_code → dim_region → code_region → id_region                │
│ building_code → dim_batiment → code_batiment → id_batiment        │
│ meter_type → dim_energie → type_energie → id_energie + tarif_unitaire│
│ meter_code → dim_compteur → code_compteur → id_compteur           │
└─────────────────────────────────────────────────────────────────────┘

MAPPING TABLE DE FAIT :
┌─────────────────────────────────────────────────────────────────────┐
│ Champ Source → Champ Table Fait → Type                             │
├─────────────────────────────────────────────────────────────────────┤
│ consumption_value → consommation_valeur → Mesure                   │
│ temperature → temperature → Mesure                                 │
│ cout_energie_calcule → cout_energie → Mesure (calculée)           │
│ source_filename → source_id → Métadata                             │
│ extraction_timestamp → date_extraction → Métadata                  │
│ id_temps → id_temps → Clé étrangère                               │
│ id_region → id_region → Clé étrangère                             │
│ id_batiment → id_batiment → Clé étrangère                         │
│ id_energie → id_energie → Clé étrangère                           │
│ id_compteur → id_compteur → Clé étrangère                         │
│ (constant) → id_client → Clé étrangère (constante)                │
└─────────────────────────────────────────────────────────────────────┘

STRATÉGIE D'INSERTION :
• Type : Insert Update (UPSERT)
• Clés composites : (id_temps, id_batiment, id_compteur, id_energie)
• Si existe : Mise à jour des mesures
• Si n'existe pas : Insertion nouvelle ligne
• Commit batch : 100 lignes

TRANSFORMATIONS APPLIQUÉES :
1. Nettoyage des chaînes avant lookup (trim)
2. Calcul coût énergétique : consommation × tarif unitaire
3. Conversion codes → IDs via lookups dimensionnels
4. Ajout champ client constant

CHAMPS IGNORÉS DANS LE FAIT :
• building_name, region_name (déjà dans dimensions)
• source_type, date_generation, created_at, updated_at
• meter_unit (non utilisé dans le fait)

VALIDATIONS IMPLICITES :
• Tous les lookups doivent réussir (pas de valeur par défaut)
• Les dimensions doivent être pré-chargées
• Format des dates doit correspondre aux dimensions






















┌─────────────────────────────────────────────────────────────────────────┐
│                  08_Load_DM_Rentabilite FLOW                           │
└─────────────────────────────────────────────────────────────────────────┘

CONNEXION BASE DE DONNÉES :
┌──────────────────────────────────────┐
│ Connexion MySQL : greencity_dw       │
│ - Serveur : localhost                │
│ - Port : 3306                        │
│ - Base : greencity_dw                │
│ - Utilisateur : root                 │
│ - Optimisations :                    │
│   • Streaming activé                 │
│   • Fetch size : 500                 │
│   • Cursor fetch activé              │
└──────────────────────────────────────┘

SOURCE DE DONNÉES TRANSFORMÉES :
┌──────────────────────────────────────┐
│ CSV file input                       │
│ - Type : CSV File Input              │
│ - Fichier : transformed_rentabilite.csv│
│ - 23 champs transformés :            │
│   1. invoice_id (Integer)            │
│   2. invoice_number (String)         │
│   3. invoice_date (String:yyyy-MM-dd)│
│   4. due_date (String:yyyy-MM-dd)    │
│   5. total_ht (BigNumber)            │
│   6. tva_amount (BigNumber)          │
│   7. total_ttc (BigNumber)           │
│   8. energy_cost (BigNumber)         │
│   9. status (String)                 │
│   10. client_code (String)           │
│   11. client_name (String)           │
│   12. sector (String)                │
│   13. building_code (String)         │
│   14. building_name (String)         │
│   15. region_code (String)           │
│   16. payment_date (String:yyyy-MM-dd)│
│   17. payment_amount (BigNumber)     │
│   18. payment_method (String)        │
│   19. created_at (String:yyyy-MM-dd) │
│   20. updated_at (String:yyyy-MM-dd) │
│   21. extraction_timestamp (String:yyyy-MM-dd)│
│   22. source_type (String)           │
│   23. source_filename (String)       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values 2                      │
│ - Type : Select Values               │
│ - Convertit 6 champs String → Date   │
│   avec format yyyy-MM-dd :           │
│   • invoice_date                     │
│   • due_date                         │
│   • payment_date                     │
│   • created_at                       │
│   • updated_at                       │
│   • extraction_timestamp             │
│ - Prépare pour lookups dimensionnels │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ String operations                    │
│ - Type : String Operations           │
│ - Trim (both) sur 11 champs texte :  │
│   • invoice_number, status           │
│   • client_code, client_name, sector │
│   • building_code, building_name     │
│   • region_code, payment_method      │
│   • source_type, source_filename     │
│ - Nettoie avant lookups              │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_TEMPS          │
│ - Type : Database Lookup             │
│ - Table : dim_temps                  │
│ - Clé : invoice_date → date_complete │
│ - Retourne : id_temps (Integer)      │
│ - Cherche la dimension temps         │
│   basée sur la date de facturation   │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_REGION         │
│ - Type : Database Lookup             │
│ - Table : dim_region                 │
│ - Clé : region_code → code_region    │
│ - Retourne : id_region (Integer)     │
│ - Cherche la dimension région        │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_BATIMENT       │
│ - Type : Database Lookup             │
│ - Table : dim_batiment               │
│ - Clé : building_code → code_batiment│
│ - Retourne : id_batiment (Integer)   │
│ - Cherche la dimension bâtiment      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_CLIENT         │
│ - Type : Database Lookup             │
│ - Table : dim_client                 │
│ - Clé : client_code → code_client    │
│ - Retourne : id_client (Integer)     │
│ - Cherche la dimension client        │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_FACTURE        │
│ - Type : Database Lookup             │
│ - Table : dim_facture                │
│ - Clé : invoice_number → numero_facture│
│ - Retourne : id_facture (Integer)    │
│ - Cherche la dimension facture       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_PAIEMENT       │
│ - Type : Database Lookup             │
│ - Table : dim_paiement               │
│ - Clé : payment_method → methode_paiement│
│ - Retourne : id_paiement (Integer)   │
│ - Cherche la dimension paiement      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Calculator                           │
│ - Type : Calculator                  │
│ - Calcule 4 indicateurs :            │
│   1. marge = total_ttc - energy_cost │
│      (Bénéfice brut)                 │
│   2. taux_marge = marge / total_ttc  │
│      (Pourcentage de marge)          │
│   3. delai_paiement = payment_date - due_date│
│      (Jours de retard/avance)        │
│   4. taux_recouvrement = payment_amount / total_ttc│
│      (Pourcentage recouvré)          │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values                        │
│ - Type : Select Values               │
│ - Sélectionne 18 champs pour la      │
│   table de fait :                    │
│   1. id_temps                        │
│   2. id_batiment                     │
│   3. id_region                       │
│   4. id_client                       │
│   5. id_facture                      │
│   6. id_paiement                     │
│   7. total_ht                        │
│   8. tva_amount                      │
│   9. total_ttc                       │
│   10. energy_cost                    │
│   11. payment_amount                 │
│   12. marge                          │
│   13. taux_marge                     │
│   14. delai_paiement                 │
│   15. taux_recouvrement              │
│   16. source_filename                │
│   17. extraction_timestamp           │
│ - Prépare les champs pour l'insertion│
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Insert / update                      │
│ - Type : Insert Update               │
│ - Table : fait_rentabilite           │
│ - Stratégie : Insert/Update          │
│   (UPSERT sur 6 clés composites)     │
│ - Clés de lookup (6) :               │
│   1. id_temps                        │
│   2. id_batiment                     │
│   3. id_region                       │
│   4. id_client                       │
│   5. id_facture                      │
│   6. id_paiement                     │
│ - Champs insérés/mis à jour (18) :   │
│   1. id_temps                        │
│   2. id_batiment                     │
│   3. id_region                       │
│   4. id_client                       │
│   5. id_facture                      │
│   6. id_paiement                     │
│   7. montant_ht                      │
│   8. montant_tva                     │
│   9. montant_ttc                     │
│   10. cout_energie                   │
│   11. montant_paye                   │
│   12. marge                          │
│   13. taux_marge                     │
│   14. delai_paiement                 │
│   15. taux_recouvrement              │
│   16. source_id                      │
│   17. date_extraction                │
│ - Commit toutes les 100 lignes       │
│ - Tous les champs mis à jour (update=Y)│
└──────────────────────────────────────┘

FLUX DE CHARGEMENT DIMENSIONNEL :
• Lecture des données transformées (CSV)
• Conversion des dates String → Date
• Nettoyage des chaînes (trim)
• Séquence de 6 lookups dimensionnels :
  1. DIM_TEMPS : Date facture → ID temps
  2. DIM_REGION : Code région → ID région
  3. DIM_BATIMENT : Code bâtiment → ID bâtiment
  4. DIM_CLIENT : Code client → ID client
  5. DIM_FACTURE : Numéro facture → ID facture
  6. DIM_PAIEMENT : Méthode paiement → ID paiement
• Calcul de 4 indicateurs financiers
• Préparation des champs de fait
• Insertion/Update dans la table de fait

MAPPING DES TABLES DIMENSIONNELLES :
┌─────────────────────────────────────────────────────────────────────┐
│ Source → Table Dimension → Champ Clé → Champ Retour                │
├─────────────────────────────────────────────────────────────────────┤
│ invoice_date → dim_temps → date_complete → id_temps               │
│ region_code → dim_region → code_region → id_region                │
│ building_code → dim_batiment → code_batiment → id_batiment        │
│ client_code → dim_client → code_client → id_client                │
│ invoice_number → dim_facture → numero_facture → id_facture        │
│ payment_method → dim_paiement → methode_paiement → id_paiement    │
└─────────────────────────────────────────────────────────────────────┘

CALCULS FINANCIERS :
1. **Marge** = total_ttc - energy_cost
   - Bénéfice brut après coût énergétique
2. **Taux marge** = marge / total_ttc
   - Pourcentage de marge sur chiffre d'affaires
3. **Délai paiement** = payment_date - due_date
   - Nombre de jours entre paiement et échéance
   - Positif = retard, Négatif = avance
4. **Taux recouvrement** = payment_amount / total_ttc
   - Pourcentage de la facture effectivement payé
   - ≤ 1 (100%)

MAPPING TABLE DE FAIT :
┌─────────────────────────────────────────────────────────────────────┐
│ Champ Source → Champ Table Fait → Type                             │
├─────────────────────────────────────────────────────────────────────┤
│ total_ht → montant_ht → Mesure                                    │
│ tva_amount → montant_tva → Mesure                                 │
│ total_ttc → montant_ttc → Mesure                                  │
│ energy_cost → cout_energie → Mesure                               │
│ payment_amount → montant_paye → Mesure                            │
│ marge → marge → Mesure (calculée)                                 │
│ taux_marge → taux_marge → Mesure (calculée)                       │
│ delai_paiement → delai_paiement → Mesure (calculée)               │
│ taux_recouvrement → taux_recouvrement → Mesure (calculée)         │
│ source_filename → source_id → Métadata                            │
│ extraction_timestamp → date_extraction → Métadata                 │
│ id_temps → id_temps → Clé étrangère                               │
│ id_region → id_region → Clé étrangère                             │
│ id_batiment → id_batiment → Clé étrangère                         │
│ id_client → id_client → Clé étrangère                             │
│ id_facture → id_facture → Clé étrangère                           │
│ id_paiement → id_paiement → Clé étrangère                         │
└─────────────────────────────────────────────────────────────────────┘

STRATÉGIE D'INSERTION :
• Type : Insert Update (UPSERT)
• Clés composites : 6 dimensions
   (Temps, Bâtiment, Région, Client, Facture, Paiement)
• Si existe : Mise à jour de TOUS les champs (update=Y)
• Si n'existe pas : Insertion nouvelle ligne
• Commit batch : 100 lignes

CHAMPS IGNORÉS DANS LE FAIT :
• invoice_id (redondant avec numéro facture)
• status, client_name, building_name (dans dimensions)
• sector, source_type, created_at, updated_at
• due_date, payment_date (utilisées dans calculs seulement)

VALIDATIONS IMPLICITES :
• Tous les lookups doivent réussir
• Les dimensions doivent être pré-chargées
• Les calculs nécessitent des valeurs numériques valides
• Format des dates doit correspondre aux dimensions

INDICATEURS DE PERFORMANCE :
• Marge : Profitabilité après coût énergétique
• Taux marge : Efficacité commerciale
• Délai paiement : Gestion de trésorerie
• Taux recouvrement : Efficacité recouvrement
























┌─────────────────────────────────────────────────────────────────────────┐
│                  09_Load_DM_Environnement FLOW                         │
└─────────────────────────────────────────────────────────────────────────┘

CONNEXION BASE DE DONNÉES :
┌──────────────────────────────────────┐
│ Connexion MySQL : greencity_dw       │
│ - Serveur : localhost                │
│ - Port : 3306                        │
│ - Base : greencity_dw                │
│ - Utilisateur : root                 │
└──────────────────────────────────────┘

SOURCE DE DONNÉES TRANSFORMÉES :
┌──────────────────────────────────────┐
│ CSV file input                       │
│ - Type : CSV File Input              │
│ - Fichier : transformed_environnement.csv│
│ - 11 champs transformés :            │
│   1. region_code (String)            │
│   2. report_date (String)            │
│   3. building_code (String)          │
│   4. emission_co2_kg (BigNumber)     │
│   5. recycling_rate (BigNumber)      │
│   6. recycling_rate_percent (BigNumber)│
│   7. extraction_timestamp (String)   │
│   8. source_filename (String)        │
│   9. source_type (String)            │
│   10. created_at (String)            │
│   11. updated_at (String)            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values                        │
│ - Type : Select Values               │
│ - Convertit 4 champs String → Date   │
│   avec format yyyy-MM-dd :           │
│   • report_date                      │
│   • extraction_timestamp             │
│   • created_at                       │
│   • updated_at                       │
│ - Prépare pour lookups dimensionnels │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ String operations                    │
│ - Type : String Operations           │
│ - Trim (both) sur 4 champs texte :   │
│   • region_code                      │
│   • building_code                    │
│   • source_filename                  │
│   • source_type                      │
│ - Nettoie avant lookups              │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_TEMPS          │
│ - Type : Database Lookup             │
│ - Table : dim_temps                  │
│ - Clé : report_date → date_complete  │
│ - Retourne : id_temps (Integer)      │
│ - Cherche la dimension temps         │
│   basée sur la date de rapport       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_REGION         │
│ - Type : Database Lookup             │
│ - Table : dim_region                 │
│ - Clé : region_code → code_region    │
│ - Retourne : id_region (Integer)     │
│ - Cherche la dimension région        │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_BATIMENT       │
│ - Type : Database Lookup             │
│ - Table : dim_batiment               │
│ - Clé : building_code → code_batiment│
│ - Retourne : id_batiment (Integer)   │
│ - Cherche la dimension bâtiment      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Add sequence                         │
│ - Type : Sequence                    │
│ - Ajoute : row_id                    │
│ - Valeur initiale : 1                │
│ - Incrément : 1                      │
│ - Max : 999999999                    │
│ - Crée un identifiant unique par ligne│
│   pour le processus de normalisation │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Row normaliser                       │
│ - Type : Normaliser                  │
│ - Transforme 2 indicateurs en        │
│   structure type-valeur :            │
│   • emission_co2_kg → type "CO2"     │
│   • recycling_rate_percent → type "Recyclage"│
│ - Crée 2 lignes par entrée :         │
│   Ligne 1 : CO2                      │
│   Ligne 2 : Recyclage                │
│ - Champs produits :                  │
│   • typefield (String)               │
│   • valeur_mesuree (Number)          │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_ENVIRONNEMENT  │
│ - Type : Database Lookup             │
│ - Table : dim_environnement          │
│ - Clé : typefield → type_indicateur  │
│ - Retourne :                         │
│   • id_environnement (Integer)       │
│   • seuil_optimal (Number)           │
│   • seuil_alerte (Number)            │
│ - Cherche la dimension environnement │
│   + récupère les seuils de référence │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Calculator 2                         │
│ - Type : Calculator                  │
│ - Calcule :                          │
│   • ecart_reference =                │
│     valeur_mesuree - seuil_optimal   │
│ - Mesure l'écart par rapport au      │
│   seuil optimal de référence         │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Modified JavaScript value            │
│ - Type : JavaScript                  │
│ - Calcule catégorie performance :    │
│   • Si valeur_mesuree ≤ seuil_optimal│
│     → "Excellente"                   │
│   • Si valeur_mesuree ≤ seuil_alerte │
│     → "Moyenne"                      │
│   • Sinon → "À améliorer"            │
│ - Détermine la performance basée sur │
│   les seuils de référence            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Insert / update                      │
│ - Type : Insert Update               │
│ - Table : fait_environnement         │
│ - Stratégie : Insert/Update          │
│   (UPSERT sur 4 clés composites)     │
│ - Clés de lookup (4) :               │
│   1. id_temps                        │
│   2. id_region                       │
│   3. id_batiment                     │
│   4. id_environnement                │
│ - Champs insérés/mis à jour (9) :    │
│   1. id_temps                        │
│   2. id_region                       │
│   3. id_batiment                     │
│   4. id_environnement                │
│   5. valeur_mesuree                  │
│   6. valeur_reference                │
│   7. ecart_reference                 │
│   8. categorie_performance           │
│   9. source_id                       │
│   10. date_extraction                │
│ - Commit toutes les 100 lignes       │
│ - Tous les champs mis à jour (update=Y)│
└──────────────────────────────────────┘

FLUX DE CHARGEMENT DIMENSIONNEL :
• Lecture des données transformées (CSV)
• Conversion des dates String → Date
• Nettoyage des chaînes (trim)
• Séquence de 3 lookups dimensionnels :
  1. DIM_TEMPS : Date rapport → ID temps
  2. DIM_REGION : Code région → ID région
  3. DIM_BATIMENT : Code bâtiment → ID bâtiment
• Ajout d'un identifiant de séquence
• Normalisation des 2 indicateurs en 2 lignes
• Lookup dimension environnement + seuils
• Calcul de l'écart par rapport au seuil optimal
• Catégorisation de la performance
• Insertion/Update dans la table de fait

MAPPING DES TABLES DIMENSIONNELLES :
┌─────────────────────────────────────────────────────────────────────┐
│ Source → Table Dimension → Champ Clé → Champ Retour                │
├─────────────────────────────────────────────────────────────────────┤
│ report_date → dim_temps → date_complete → id_temps               │
│ region_code → dim_region → code_region → id_region                │
│ building_code → dim_batiment → code_batiment → id_batiment        │
│ typefield → dim_environnement → type_indicateur → id_environnement + seuils│
└─────────────────────────────────────────────────────────────────────┘

NORMALISATION DES INDICATEURS :
┌─────────────────────────────────────────────────────────────────────┐
│ Champ Source → Type → Valeur Normalisée                            │
├─────────────────────────────────────────────────────────────────────┤
│ emission_co2_kg → "CO2" → valeur_mesuree                           │
│ recycling_rate_percent → "Recyclage" → valeur_mesuree              │
└─────────────────────────────────────────────────────────────────────┘

TRANSFORMATION 1 → 2 LIGNES :
• Entrée : 1 ligne avec 2 indicateurs
• Sortie : 2 lignes avec 1 indicateur chacune
• Permet le stockage normalisé dans le fait

SEUILS DE RÉFÉRENCE :
• **seuil_optimal** : Valeur cible idéale
• **seuil_alerte** : Valeur limite acceptable
• Stockés dans la dimension environnement

CALCULS DE PERFORMANCE :
1. **Écart référence** = valeur_mesuree - seuil_optimal
   - Différence par rapport à la cible
   - Positif = au-dessus, Négatif = en-dessous
2. **Catégorie performance** :
   - Excellente : ≤ seuil_optimal
   - Moyenne : ≤ seuil_alerte
   - À améliorer : > seuil_alerte

MAPPING TABLE DE FAIT :
┌─────────────────────────────────────────────────────────────────────┐
│ Champ Source → Champ Table Fait → Type                             │
├─────────────────────────────────────────────────────────────────────┤
│ valeur_mesuree → valeur_mesuree → Mesure                          │
│ seuil_optimal → valeur_reference → Référence                     │
│ ecart_reference → ecart_reference → Mesure (calculée)            │
│ categorie_performance → categorie_performance → Catégorie        │
│ source_filename → source_id → Métadata                           │
│ extraction_timestamp → date_extraction → Métadata                │
│ id_temps → id_temps → Clé étrangère                              │
│ id_region → id_region → Clé étrangère                            │
│ id_batiment → id_batiment → Clé étrangère                        │
│ id_environnement → id_environnement → Clé étrangère              │
└─────────────────────────────────────────────────────────────────────┘

STRATÉGIE D'INSERTION :
• Type : Insert Update (UPSERT)
• Clés composites : 4 dimensions
   (Temps, Région, Bâtiment, Environnement)
• Si existe : Mise à jour de TOUS les champs (update=Y)
• Si n'existe pas : Insertion nouvelle ligne
• Commit batch : 100 lignes
• Structure adaptée pour 2 indicateurs par rapport

CHAMPS IGNORÉS DANS LE FAIT :
• recycling_rate (décimal) → utilisé recycling_rate_percent
• created_at, updated_at
• source_type
• row_id (temporaire pour la normalisation)
• emission_co2_kg et recycling_rate_percent transformés

VALIDATIONS IMPLICITES :
• Tous les lookups doivent réussir
• Les dimensions doivent être pré-chargées
• Les indicateurs doivent avoir des seuils définis
• Format des dates doit correspondre aux dimensions

INDICATEURS ENVIRONNEMENTAUX :
1. **CO2** : Émissions en kg
   - Mesure : kilogrammes
   - Objectif : Minimiser (plus bas = meilleur)
2. **Recyclage** : Taux en pourcentage
   - Mesure : pourcentage (0-100%)
   - Objectif : Maximiser (plus haut = meilleur)

INTERPRÉTATION DES RÉSULTATS :
• **Écart référence** :
  - Négatif pour CO2 = Bon (émissions inférieures à la cible)
  - Positif pour Recyclage = Bon (taux supérieur à la cible)
• **Catégorie performance** :
  - Excellente : Performance optimale
  - Moyenne : Performance acceptable
  - À améliorer : Action corrective nécessaire

















┌─────────────────────────────────────────────────────────────────────────────┐
│                          Main_ETL_Job FLOW                                 │
└─────────────────────────────────────────────────────────────────────────────┘

ENVIRONNEMENT D'EXÉCUTION :
┌──────────────────────────────────────┐
│ Pentaho Data Integration (PDI/Kettle)│
│ - Version : Kettle                     │
│ - Mode : Local                        │
│ - Configuration : Pentaho local      │
│ - Logging : Basic                     │
└──────────────────────────────────────┘

DÉMARRAGE DU JOB :
┌──────────────────────────────────────┐
│ Start                                │
│ - Type : SPECIAL                     │
│ - Point de départ du job            │
│ - Pas de paramètres                 │
│ - Pas de planification active       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Nettoyer Staging Area               │
│ - Type : SHELL                       │
│ - Script Windows Batch :            │
│   del /Q "raw\*.csv"               │
│   del /Q "transformed\*.csv"       │
│ - Supprime tous les fichiers        │
│   temporaires des runs précédents   │
│ - Chemins :                         │
│   • C:\...\05_Staging_area\raw      │
│   • C:\...\05_Staging_area\transformed│
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Extraction JSON                      │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   01_Extract_JSON_to_Staging.ktr    │
│ - Chemin :                          │
│   C:\...\01_extract\                │
│ - Extraction depuis sources JSON    │
│   vers staging area                 │
│ - Attend fin d'exécution            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Extraction CSV                       │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   02_Extract_CSV_to_Staging.ktr     │
│ - Chemin :                          │
│   C:\...\01_extract\                │
│ - Extraction depuis fichiers CSV    │
│   vers staging area                 │
│ - Attend fin d'exécution            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Extraction MySQL                     │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   03_Extract_MySQL_to_Staging.ktr   │
│ - Chemin :                          │
│   C:\...\01_extract\                │
│ - Extraction depuis base MySQL      │
│   vers staging area                 │
│ - Attend fin d'exécution            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Transform Consommation               │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   04_Transform_Consommation.ktr     │
│ - Chemin :                          │
│   C:\...\02_transform\              │
│ - Transformation des données        │
│   de consommation                   │
│ - Attend fin d'exécution            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Transform Rentabilite                │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   05_Transform_Rentabilite.ktr      │
│ - Chemin :                          │
│   C:\...\02_transform\              │
│ - Transformation des données        │
│   de rentabilité                   │
│ - Attend fin d'exécution            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Transform Environnement              │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   06_Transform_Environnement.ktr    │
│ - Chemin :                          │
│   C:\...\02_transform\              │
│ - Transformation des données        │
│   environnementales                 │
│ - Génère transformed_environnement.csv│
│ - Attend fin d'exécution            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Load DM Consommation                 │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   07_Load_DM_Consommation.ktr       │
│ - Chemin :                          │
│   C:\...\03_load\                   │
│ - Chargement Data Mart Consommation │
│ - Attend fin d'exécution            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Load DM Rentabilite                  │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   08_Load_DM_Rentabilite.ktr        │
│ - Chemin :                          │
│   C:\...\03_load\                   │
│ - Chargement Data Mart Rentabilité  │
│ - Attend fin d'exécution            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Load DM Environnement                │
│ - Type : TRANSFORMATION             │
│ - Fichier :                         │
│   09_Load_DM_Environnement.ktr      │
│ - Chemin :                          │
│   C:\...\03_load\                   │
│ - Chargement Data Mart Environnement│
│ - Détail du flow :                  │
│   ↓ Voir schéma détaillé ci-dessous ↓│
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Success                              │
│ - Type : SUCCESS                     │
│ - Point de terminaison du job       │
│ - Job terminé avec succès           │
└──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                  09_Load_DM_Environnement FLOW (DÉTAIL)               │
└─────────────────────────────────────────────────────────────────────────┘

CONNEXION BASE DE DONNÉES :
┌──────────────────────────────────────┐
│ Connexion MySQL : greencity_dw       │
│ - Serveur : localhost                │
│ - Port : 3306                        │
│ - Base : greencity_dw                │
│ - Utilisateur : root                 │
└──────────────────────────────────────┘

SOURCE DE DONNÉES TRANSFORMÉES :
┌──────────────────────────────────────┐
│ CSV file input                       │
│ - Type : CSV File Input              │
│ - Fichier : transformed_environnement.csv│
│ - 11 champs transformés :            │
│   1. region_code (String)            │
│   2. report_date (String)            │
│   3. building_code (String)          │
│   4. emission_co2_kg (BigNumber)     │
│   5. recycling_rate (BigNumber)      │
│   6. recycling_rate_percent (BigNumber)│
│   7. extraction_timestamp (String)   │
│   8. source_filename (String)        │
│   9. source_type (String)            │
│   10. created_at (String)            │
│   11. updated_at (String)            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Select values                        │
│ - Type : Select Values               │
│ - Convertit 4 champs String → Date   │
│   avec format yyyy-MM-dd :           │
│   • report_date                      │
│   • extraction_timestamp             │
│   • created_at                       │
│   • updated_at                       │
│ - Prépare pour lookups dimensionnels │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ String operations                    │
│ - Type : String Operations           │
│ - Trim (both) sur 4 champs texte :   │
│   • region_code                      │
│   • building_code                    │
│   • source_filename                  │
│   • source_type                      │
│ - Nettoie avant lookups              │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_TEMPS          │
│ - Type : Database Lookup             │
│ - Table : dim_temps                  │
│ - Clé : report_date → date_complete  │
│ - Retourne : id_temps (Integer)      │
│ - Cherche la dimension temps         │
│   basée sur la date de rapport       │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_REGION         │
│ - Type : Database Lookup             │
│ - Table : dim_region                 │
│ - Clé : region_code → code_region    │
│ - Retourne : id_region (Integer)     │
│ - Cherche la dimension région        │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_BATIMENT       │
│ - Type : Database Lookup             │
│ - Table : dim_batiment               │
│ - Clé : building_code → code_batiment│
│ - Retourne : id_batiment (Integer)   │
│ - Cherche la dimension bâtiment      │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Add sequence                         │
│ - Type : Sequence                    │
│ - Ajoute : row_id                    │
│ - Valeur initiale : 1                │
│ - Incrément : 1                      │
│ - Max : 999999999                    │
│ - Crée un identifiant unique par ligne│
│   pour le processus de normalisation │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Row normaliser                       │
│ - Type : Normaliser                  │
│ - Transforme 2 indicateurs en        │
│   structure type-valeur :            │
│   • emission_co2_kg → type "CO2"     │
│   • recycling_rate_percent → type "Recyclage"│
│ - Crée 2 lignes par entrée :         │
│   Ligne 1 : CO2                      │
│   Ligne 2 : Recyclage                │
│ - Champs produits :                  │
│   • typefield (String)               │
│   • valeur_mesuree (Number)          │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Database lookup - DIM_ENVIRONNEMENT  │
│ - Type : Database Lookup             │
│ - Table : dim_environnement          │
│ - Clé : typefield → type_indicateur  │
│ - Retourne :                         │
│   • id_environnement (Integer)       │
│   • seuil_optimal (Number)           │
│   • seuil_alerte (Number)            │
│ - Cherche la dimension environnement │
│   + récupère les seuils de référence │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Calculator 2                         │
│ - Type : Calculator                  │
│ - Calcule :                          │
│   • ecart_reference =                │
│     valeur_mesuree - seuil_optimal   │
│ - Mesure l'écart par rapport au      │
│   seuil optimal de référence         │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Modified JavaScript value            │
│ - Type : JavaScript                  │
│ - Calcule catégorie performance :    │
│   • Si valeur_mesuree ≤ seuil_optimal│
│     → "Excellente"                   │
│   • Si valeur_mesuree ≤ seuil_alerte │
│     → "Moyenne"                      │
│   • Sinon → "À améliorer"            │
│ - Détermine la performance basée sur │
│   les seuils de référence            │
└───────────────┬──────────────────────┘
                │
                ▼
┌──────────────────────────────────────┐
│ Insert / update                      │
│ - Type : Insert Update               │
│ - Table : fait_environnement         │
│ - Stratégie : Insert/Update          │
│   (UPSERT sur 4 clés composites)     │
│ - Clés de lookup (4) :               │
│   1. id_temps                        │
│   2. id_region                       │
│   3. id_batiment                     │
│   4. id_environnement                │
│ - Champs insérés/mis à jour (9) :    │
│   1. id_temps                        │
│   2. id_region                       │
│   3. id_batiment                     │
│   4. id_environnement                │
│   5. valeur_mesuree                  │
│   6. valeur_reference                │
│   7. ecart_reference                 │
│   8. categorie_performance           │
│   9. source_id                       │
│   10. date_extraction                │
│ - Commit toutes les 100 lignes       │
│ - Tous les champs mis à jour (update=Y)│
└──────────────────────────────────────┘
























 Configuration de l'Automatisation avec Task Scheduler
Étape 1 : Préparer les fichiers batch
1.1 run_etl.bat (racine du projet) :

batch
@echo off
cd /d "C:\Users\hp\Desktop\pdi-ce-10.2.0.0-222\data-integration"
call Kitchen.bat /file:"C:\Users\hp\Desktop\mini projet - greencity\04_ETL_Pentaho\jobs\Main_ETL_Job.kjb" /level:Basic
pause
1.2 run_scheduled.bat (racine du projet) :

batch
@echo off
cd /d "C:\Users\hp\Desktop\mini projet - greencity"
call run_etl.bat
Étape 2 : Configurer Task Scheduler
Ouvrir Task Scheduler (Windows + R → taskschd.msc)

Créer une tâche → "Créer une tâche de base"

Nom : GreenCity_ETL_Daily

Description : Exécution quotidienne du processus ETL à 02:00

Déclencheur : Quotidien, Début : 05/01/2026, Heure : 02:00

Action : Démarrer un programme

Programme : C:\Users\hp\Desktop\mini projet - greencity\run_scheduled.bat

Terminer