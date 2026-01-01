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



















04_Transform_Consommation.ktr    (clean JSON + MySQL consommation)
05_Transform_Rentabilite.ktr     (clean MySQL rentabilité only)
06_Transform_Environnement.ktr   (clean CSV + MySQL environnement)







# Phase de Transformation - Consommation Énergétique   COMPLÉTÉ

## Fichier: `04_Transform_Consommation.ktr`

### Objectif:
Consolider, nettoyer et normaliser les données de consommation énergétique provenant des sources JSON et MySQL en préparation pour le chargement dans le Data Mart.

### État:   TRANSFORMATION COMPLÈTE

#### Résumé des accomplissements:
1.   **Unification des schémas** - JSON (11 champs) + MySQL (16 champs) → 16 champs standardisés
2.   **Traduction nomenclature** - Français → Anglais → Français (selon norme finale)
3.   **Fusion des flux** - Données consolidées en dataset unique
4.   **Nettoyage qualité données** - 6 étapes de purification implémentées
5.   **Normalisation formats** - Dates, unités, types d'énergie standardisés
6.   **Sortie formatée** - CSV prêt pour chargement Data Mart

---

## Processus de Transformation Détailé:

### Étape 1: Unification des Schémas (Pré-fusion)
#### Flux JSON (56 enregistrements):

Original (11 champs) → Ajout 5 champs NULL → Traduction → Réorganisation
id_region → region_code
id_batiment → building_code
type_energie → meter_type
unite → meter_unit
compteur_id → meter_code
date_mesure → reading_date
consommation_value → consumption_value


#### Flux MySQL:

Original (16 champs) → Suppression reading_id → Ajout date_generation → Réorganisation
→ Alignement parfait avec flux JSON (16 champs identiques)


### Étape 2: Fusion des Données
- **Append streams**: Union verticale des deux flux traités
- **Résultat**: Dataset unifié avec données JSON + MySQL

### Étape 3: Nettoyage en Cascade (6 Étapes)

#### 3.1 Filtrage des Données Incomplètes (Filter rows)

Conditions:
- consumption_value IS NOT NULL
- reading_date IS NOT NULL  
- building_code IS NOT NULL

**Impact**: Élimination des enregistrements non analysables

#### 3.2 Nettoyage des Espaces (trim)
- **Champs traités**: Tous les champs texte
- **Action**: Trim (both) pour éliminer espaces superflus
- **Cible particulière**: `source_filename`, codes région/bâtiment

#### 3.3 Standardisation des Valeurs (Replace in string)
| Valeur Originale | Valeur Standardisée | Rationale       |
|------------------|---------------------|-----------------|
| `"electricity"`  | `"electricite"`     | Norme française |
| `"gas"`          | `"gaz"`             | Norme française |
| `"water"`        | `"eau"`             | Norme française |
| `"KWh"`          | `"kWh"`             | Norme d'unité   |

#### 3.4 Normalisation des Dates - Préparation (fixing date)
- **Problème**: Format ISO avec `T` (`2025-01-14T08:00:00`)
- **Solution**: Remplacement `"T"` → `" "`
- **Résultat**: `2025-01-14 08:00:00` (format SQL standard)

#### 3.5 Formatage des Métadonnées Temporelles (Select values)
- `extraction_timestamp`: `yyyy/MM/dd HH:mm:ss.SSS`
- `date_generation`: `yyyy-MM-dd`
- `created_at`, `updated_at`: `yyyy/MM/dd HH:mm:ss`
- **Objectif**: Cohérence pour analyse temporelle

#### 3.6 Normalisation Avancée des Dates (Modified JavaScript value)

Fonctions implémentées:
1. Suppression du 'T' ISO si présent
2. Conversion dd/MM/yyyy HH:mm → yyyy-MM-dd HH:mm:00
3. Conversion yyyy/MM/dd HH:mm:ss → yyyy-MM-dd HH:mm:ss
4. Ajout 00:00:00 si heure manquante

**Résultat**: Toutes les dates au format `yyyy-MM-dd HH:mm:ss`

### Étape 4: Sortie Formatée
- **Fichier**: `transformed_consommation.csv`
- **Location**: `05_Staging_area/transformed/`
- **Format**: CSV avec en-têtes, UTF-8, guillemets doubles
- **Champs**: 16 champs normalisés

---

## Problèmes de Qualité Résolus:

### 1.   Formats de Date Incohérents
**Avant**:
- `2025-01-14T08:00:00` (ISO)
- `14/01/2025 10:00` (Français)
- `2025/01/01 23:00:00` (Slashes)

**Après**: Tous `yyyy-MM-dd HH:mm:ss`

### 2.   Valeurs Manquantes/Invalides
- Filtrage des `consumption_value` NULL/vides
- Conservation des `temperature` NULL (acceptable - absent JSON)

### 3.   Incohérences de Valeurs
- `meter_type`: `electricity`/`gas`/`water` → `electricite`/`gaz`/`eau`
- `meter_unit`: `KWh` → `kWh` (standard minuscule)

### 4.   Problèmes de Formatage
- Espaces superflus éliminés (trim)
- Structure de données cohérente

### 5.   Schémas Hétérogènes
- Fusion JSON (mesures IoT) + MySQL (données relationnelles)
- Champs manquants complétés avec NULL
- Nomenclature unifiée

---

## Métriques de Qualité Finales:

|          Métrique                | Valeur |
|----------------------------------|--------|
|Champs standardisés               | 100%   |
|Formats date cohérents            | 100%   | 
| Valeurs manquantes (consumption) | 0%     | 
| Unités normalisées               | 100%   | 
| Types énergie standardisés       | 100%   |  

---

## Fichier de Sortie: `transformed_consommation.csv`

### Structure (16 champs):

region_code,building_code,meter_type,meter_code,meter_unit,reading_date,
consumption_value,temperature,building_name,region_name,source_type,
source_filename,extraction_timestamp,date_generation,created_at,updated_at


### Caractéristiques:
- **Encodage**: UTF-8
- **Séparateur**: Virgule
- **En-têtes**: Oui
- **Guillemets**: Doubles quotes pour textes
- **Dates**: Format standard `yyyy-MM-dd HH:mm:ss`
- **Prêt pour**: Chargement Data Mart Consommation

---

## Préparation pour Phase Suivante (LOAD):

### Données prêtes pour:
1. **Chargement incrémental** dans Data Mart Consommation
2. **Agrégations temporelles** (heure → jour → mois)
3. **Analyse corrélation** consommation vs température
4. **Calcul KPI** par région/bâtiment/type énergie

### Intégration avec autres Data Marts:
- **Consommation**: Ce fichier (énergie utilisée)
- **Rentabilité**: À venir (coûts associés)
- **Environnement**: À venir (émissions CO2)

---

## Leçons Apprises:
1. **Importance schéma early** - Définir structure cible avant transformation
2. **Traitement par étapes** - 6 étapes successives > 1 étape complexe
3. **Traçabilité** - Garder `source_filename`, `source_type` pour audit
4. **Normalisation progressive** - Dates → Unités → Types → Nettoyage

---

**État**:   PRÊT POUR CHARGEMENT DATA MART**


