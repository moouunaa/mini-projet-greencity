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































# Phase de Transformation - Impact Environnemental   COMPLÉTÉ

## Fichier: `06_Transform_Environnement.ktr`

### Objectif:
Consolider, valider et nettoyer les données d'impact environnemental (émissions CO2, taux de recyclage) provenant des sources CSV et MySQL avec gestion avancée de la qualité des données.

### État:   TRANSFORMATION COMPLÈTE AVEC GESTION D'ERREURS

#### Innovation clé: **Pipeline à deux voies**
- **Voie principale**: Données conformes → Traitement standard
- **Voie de correction**: Données non conformes → Nettoyage → Réintégration
- **Voie de rejet**: Données irrécupérables → Log pour audit

---

## Architecture du Pipeline de Qualité:


[Fusion sources] → [Nettoyage basique] → [Validation format] → [DIVERGENCE]
       │                                         │
       ├─► Données conformes ────────────────────┤
       │    [Validation numérique] → [Validation plages] → [Normalisation] → [Sortie]
       │
       └─► Données non conformes ────────────────┘
            [Correction] → [Réintégration] ──────┘


---

## Processus Détailé:

### Étape 1: Unification des Sources
#### Flux CSV (53 enregistrements):

Original (8 champs) → Ajout created_at/updated_at → Traduction → Réorganisation
id_region → region_code
id_batiment → building_code
date_rapport → report_date
emission_CO2_kg → emission_co2_kg
taux_recyclage → recycling_rate


#### Flux MySQL:

Original (10 champs) → Suppression report_id → Ajout updated_at → Réorganisation
→ Alignement parfait (10 champs identiques)


### Étape 2: Nettoyage Initial
- **Trim**: Tous les champs texte nettoyés
- **Standardisation**: Nomenclature uniforme

### Étape 3: **Validation des Formats (Filter rows 3)**
#### Vérification par expressions régulières:
- `region_code`: Doit correspondre à `REG[0-9]{2}` (ex: REG01, REG99)
- `building_code`: Doit correspondre à `BAT[0-9]{3}` (ex: BAT001, BAT999)

#### Résultats:
- **Conforme**: Poursuit dans la voie principale
- **Non conforme**: Redirigé vers voie de correction

### Étape 4: **Correction des Données Non Conformes (Voie de correction)**
#### Modified JavaScript value 2:
```javascript
Traitement intelligent:
- region_code invalide → "NON_RENSEIGNE"
- building_code invalide → "NON_RENSEIGNE"
- Création de champs nettoyés: region_clean, building_clean
```

#### Calculator_Unifier:
- Utilisation de `NVL()` pour prioriser les valeurs originales
- Fallback sur les valeurs corrigées si original NULL/invalide

#### Réintégration:
- Données corrigées rejoignent le flux principal via "Append streams 2"
- **Philosophie**: Mieux vaut une valeur corrigée qu'une suppression

### Étape 5: **Validation Numérique (Filter rows)**
#### Vérification des types:
- `emission_co2_kg`: Doit être numérique (regex validation)
- `recycling_rate`: Doit être numérique (regex validation)

#### Résultats:
- **Numérique**: Poursuit le traitement
- **Non numérique**: Rejeté vers "Dummy" (audit)

### Étape 6: **Validation des Plages (Filter rows 2)**
#### Contrôles métier:
- `emission_co2_kg`: Entre 0 et 10000 kg (plage réaliste)
- `recycling_rate`: Entre 0 et 1 (0% à 100%)

#### Rationale:
- CO2 négatif impossible
- Taux recyclage > 100% impossible
- Valeurs extrêmes probablement erronées

### Étape 7: **Normalisation Avancée**
#### Select values 3:
- Typage précis: `BigNumber(7,2)` pour CO2 (ex: 512.50)
- Typage précis: `BigNumber(5,3)` pour taux (ex: 0.715)

#### Modified JavaScript value:
```javascript
Normalisation des dates report_date:
- "2025/03/31" → "2025-03-31"
- "31/03/2025" → "2025-03-31"  
- "2025-03-31" → inchangé
```

#### Select values 6:
- Formatage standard des timestamps: `yyyy/MM/dd HH:mm:ss.SSS`
- Cohérence temporelle pour analyse

### Étape 8: **Sortie Finale**
- **Fichier**: `transformed_environnement.csv`
- **Encodage**: UTF8
- **Format**: CSV standard avec en-têtes
- **Champs**: 10 champs normalisés

---

## Problèmes de Qualité Traités:

### 1.   Formats de Codes Invalides
**Exemples traités**:
- `"  REG99  "` → Trim → Validation échoue → `"NON_RENSEIGNE"`
- `"BAT999"` → Validation réussie (BAT[0-9]{3})
- Codes malformés → Correction plutôt que suppression

### 2.   Valeurs Non Numériques
**Gestion intelligente**:
- `"N/A"` dans `emission_co2_kg` → Rejeté (audit nécessaire)
- `"Non mesuré"` dans `recycling_rate` → Rejeté (audit nécessaire)
- **Philosophie**: Mieux vaut rejeter que convertir arbitrairement

### 3.   Plages Invalides
**Contrôles métier**:
- `99999` (CO2) → Rejeté (hors plage 0-10000)
- `1.5` (recyclage) → Rejeté (> 100%)
- Valeurs manifestement erronées isolées

### 4.   Formats de Date Incohérents
**Normalisation**:
- Trois formats supportés → Un format standard
- Garantie de cohérence pour l'analyse temporelle

### 5.   Données Manquantes
**Stratégie**:
- NULLs préservés 
- `"NON_RENSEIGNE"` pour codes invalides
- Distinction claire: NULL (original) vs "NON_RENSEIGNE" (corrigé)

---

## Métriques de Qualité:

| Étape Validation | Critère | Action | Résultat |
|------------------|---------|--------|----------|
| Format codes | REGXX, BATXXX | Correction/Réintégration |   Données récupérées |
| Type numérique | CO2, taux | Rejet si non numérique |   Pureté numérique |
| Plages métier | CO2: 0-10000, Taux: 0-1 | Rejet si hors plage |   Données réalistes |
| Cohérence | 3 formats date → 1 | Normalisation |   Analyse temporelle |

---

## Fichier de Sortie: `transformed_environnement.csv`

### Structure (10 champs):
```csv
region_code,report_date,building_code,emission_co2_kg,recycling_rate,
extraction_timestamp,source_filename,source_type,created_at,updated_at
```

### Caractéristiques:
- **Typage**: Numéros précis (décimales contrôlées)
- **Dates**: Format `yyyy-MM-dd` standard
- **Qualité**: Validée sur 4 niveaux (format, type, plage, cohérence)

### Données Incluses:
-   Rapports CSV originaux (nettoyés)
-   Rapports MySQL (déjà propres)
-   Données corrigées ("NON_RENSEIGNE")
-   Données irrécupérables (rejetées avec audit)

---

## Innovations du Pipeline:

### 1. **Correction vs Suppression**
- Traditionnel: Supprimer les données invalides
- Notre approche: **Corriger quand possible**, supprimer quand nécessaire
- Exemple: `"  REG  "` → Trim → Invalide → `"NON_RENSEIGNE"` (meilleur que NULL)

### 2. **Validation Multi-niveaux**
- Niveau 1: Format (regex)
- Niveau 2: Type (numérique)
- Niveau 3: Plage (réaliste)
- Niveau 4: Cohérence (dates)

### 3. **Traçabilité Complète**
- Source originale préservée (`source_filename`, `source_type`)
- Horodatages standardisés
- Distinction NULL original vs valeur corrigée


---

## Leçons Apprises:



### 2. **Validation Progressive**
- Mieux vaut 4 validations simples qu'1 validation complexe
- Chaque niveau élimine un type de problème différent

### 3. **Correction Intelligente**
- `"NON_RENSEIGNE"` > NULL pour l'analyse
- Permet de quantifier "X% des régions non renseignées"
- Mieux que "X% des données supprimées"



---

## Préparation pour Phase Suivante:

### Données prêtes pour:
1. **Chargement Data Mart Environnement**
2. **Calcul KPI**: Émissions totales, tendances CO2
3. **Analyse écarts**: Régions/bâtiments "NON_RENSEIGNE"
4. **Tableau de bord**: Impact environnemental visualisable

### Intégration avec:
- **Consommation**:   Complété (énergie utilisée)
- **Rentabilité**:  À venir (coûts environnementaux)
- **Environnement**:   Complété (impact écologique)

---

**État**:   PRÊT POUR CHARGEMENT DATA MART ENVIRONNEMENT**


















# Phase de Transformation - Rentabilité Économique   COMPLÉTÉ

## Fichier: `05_Transform_Rentabilite.ktr`

### Objectif:
Nettoyer, valider et préparer les données financières (factures, paiements, clients) pour le Data Mart de Rentabilité avec une approche intelligente de correction des données.

### État:   TRANSFORMATION COMPLÈTE AVEC CORRECTION INTELLIGENTE

#### Particularité: **Source unique MySQL**
- Pas de fusion nécessaire (contrairement aux autres transformations)
- Focus sur **validation métier** et **correction intelligente**
- Approche: "Valider → Corriger → Unifier" plutôt que "Supprimer"

---

## Architecture du Pipeline:

```
[Source unique] → [Normalisation dates] → [Nettoyage texte] → [Validation triple]
        │                                         │                │
        └─► Données valides (3 codes OK) ────────┼────────────────┘
        │                                         │
        └─► Données à corriger (1+ code invalide)┤
             [Correction codes] → [Unification] ──┘
```

---

## Processus Détailé:

### Étape 1: Chargement Source
- **Source**: `staging_rentabilite_mysql.csv`
- **Champs**: 23 champs de facturation complets
- **Particularité**: Données déjà en anglais, structure cohérente

### Étape 2: Normalisation des Dates (Modified JavaScript value)

Normalisation complète des 6 champs date:
- invoice_date, due_date, payment_date
- created_at, updated_at, extraction_timestamp

Actions:
1. Suppression de la partie heure (focus sur date seule)
2. Conversion vers format standard yyyy-MM-dd
3. Support de 3 formats d'entrée:
   - yyyy-MM-dd (déjà bon)
   - yyyy/MM/dd (format SQL alternatif)
   - dd/MM/yyyy (format français)

Rationale:
- Pour analyse rentabilité: la date suffit (pas besoin heure)
- Uniformité pour regroupements temporels (mensuel, trimestriel)


### Étape 3: Nettoyage Texte (String operations)
- **Trim** sur 10 champs texte critiques
- **Focus**: Codes (invoice_number, client_code, building_code, region_code)
- **Impact**: Élimination d'espaces superflus avant validation

### Étape 4: **Validation Triple Critique (Filter rows 3)**
#### Vérification simultanée par regex:
1. **`region_code`**: `REG[0-9]{2}` (ex: REG01, REG15)
2. **`building_code`**: `BAT[0-9]{3}` (ex: BAT001, BAT999)
3. **`client_code`**: `CLI[0-9]{3}` (ex: CLI001, CLI010)

#### Logique:
- **Tous valides** → Direct vers sortie (voie rapide)
- **Au moins un invalide** → Correction nécessaire (voie de correction)

#### Rationale métier:
- Une facture sans région valide = problème
- Un client sans code valide = problème
- Un bâtiment sans code valide = problème
- **Mais**: Mieux vaut corriger que perdre la facture

### Étape 5: **Correction Intelligente (Voie de correction)**
#### Modified JavaScript value 2:
Correction sélective:
- region_code invalide → "NON_RENSEIGNE_REGION"
- building_code invalide → "NON_RENSEIGNE_BATIMENT"
- client_code invalide → "NON_RENSEIGNE_CLIENT"

Avantages:
1. Distinction du type de problème
2. Maintien de la facture pour analyse financière
3. Identification précise des lacunes


#### Calculator_Unifier:
- Utilisation de `NVL()` pour priorité: original > corrigé
- Création de champs temporaires `*_code1`
- **Philosophie**: Conserver l'information financière même si contexte incomplet

#### Select values + Select values 3:
- Suppression des champs intermédiaires
- Renommage vers noms standard
- Préparation pour réintégration

### Étape 6: **Unification Finale (Append streams 2)**
- Fusion: Données valides + Données corrigées
- **Résultat**: Dataset complet avec indicateurs de qualité

### Étape 7: **Sortie Formatée**
- **Fichier**: `transformed_rentabilite.csv`
- **Encodage**: UTF-8 (standard international)
- **Format**: CSV avec en-têtes, guillemets doubles
- **Champs**: 23 champs normalisés

---

## Problèmes de Qualité Traités:

### 1.   Formats de Date Incohérents
**Approche**: Normalisation vers `yyyy-MM-dd` sans heure
**Impact**: Regroupements temporels précis (CA mensuel, retard paiements)

### 2.   Codes Métier Invalides
**Stratégie triple**:
- Validation stricte par regex
- Correction différenciée ("NON_RENSEIGNE_*")
- Maintien de la donnée financière

### 3.   Espaces Superflus
**Traitement**: Trim avant validation
**Impact**: Évite les faux négatifs de validation

### 4.   Données Manquantes/Invalides
**Philosophie**:
- Code invalide ≠ Facture invalide
- Conserver le montant (`total_ttc`), corriger le contexte
- Permettre analyse: "CA des factures sans région valide"

---


## Métriques de Qualité:

| Validation | Critère | Action | Impact Business |
|------------|---------|--------|-----------------|
| Codes région | REG[0-9]{2} | Correction différenciée | Analyse par région précise |
| Codes bâtiment | BAT[0-9]{3} | Correction différenciée | Rentabilité par bâtiment |
| Codes client | CLI[0-9]{3} | Correction différenciée | Segmentation clientèle |
| Dates | Standard yyyy-MM-dd | Normalisation | Analyse temporelle fiable |

---

## Fichier de Sortie: `transformed_rentabilite.csv`

### Structure (23 champs):
```csv
invoice_id,invoice_number,invoice_date,due_date,total_ht,tva_amount,
total_ttc,energy_cost,status,client_code,client_name,sector,
building_code,building_name,region_code,payment_date,payment_amount,
payment_method,created_at,updated_at,extraction_timestamp,
source_type,source_filename
```

### Caractéristiques Spéciales:
1. **Dates normalisées**: `yyyy-MM-dd` (sans heure)
2. **Codes validés/corrigés**: Distinction claire des problèmes
3. **Texte nettoyé**: Pas d'espaces superflus
4. **Traçabilité**: Source et timestamp préservés

### Préparation pour KPI:
- **CA (Chiffre d'Affaires)**: `total_ttc` nettoyé
- **Marge**: `total_ttc` - `energy_cost` (calculable)
- **Retards**: `due_date` vs `payment_date` (comparables)
- **Rentabilité**: Agrégation par région/bâtiment/client

---



















# **LOAD PHASE - DETAILED TO-DO LIST**

## **OVERVIEW:**
Transform flat CSV data → Dimensional star schema with calculated KPIs in Data Marts

---

## **PHASE 1: PREPARATION (All Data Marts)**

### **1.1 Create Calendar Dimension (DIM_TEMPS)**
- [ ] **Create transformation**: `Create_DIM_TEMPS.ktr`
- [ ] **Generate dates**: 2025-01-01 to 2025-12-31
- [ ] **Calculate attributes**:
  - `annee`, `mois`, `jour`, `trimestre`, `semaine_annee`
  - `jour_semaine` (Lundi, Mardi...)
  - `est_weekend` (TRUE/FALSE)
  - `est_ferie` (basic holidays)
- [ ] **Load into**: All 3 Data Marts (same table in each)

**Estimated time**: 1-2 hours

---

## **PHASE 2: CONSOMMATION DATA MART**

### **2.1 Populate Dimension Tables**
#### **DIM_REGION**
- [ ] **Create transformation**: `Load_DIM_REGION.ktr`
- [ ] **Source**: `transformed_consommation.csv` + `transformed_environnement.csv` + `transformed_rentabilite.csv`
- [ ] **Extract unique**: `region_code`, `region_name`
- [ ] **Add default**: "NON_RENSEIGNE" for NULL/missing
- [ ] **Load into**: DM_consommation.DIM_REGION

#### **DIM_BATIMENT**
- [ ] **Create transformation**: `Load_DIM_BATIMENT.ktr`
- [ ] **Source**: Same 3 CSV files
- [ ] **Extract unique**: `building_code`, `building_name`
- [ ] **Add defaults**: Handle missing names
- [ ] **Load into**: DM_consommation.DIM_BATIMENT

#### **DIM_ENERGIE**
- [ ] **Create transformation**: `Load_DIM_ENERGIE.ktr`
- [ ] **Source**: `transformed_consommation.csv`
- [ ] **Extract unique**: `meter_type`, `meter_unit`
- [ ] **Add tarifs**:
  - `electricite`: 0.18 €/kWh
  - `eau`: 1.20 €/m³  
  - `gaz`: 0.09 €/m³
- [ ] **Load into**: DM_consommation.DIM_ENERGIE

#### **DIM_COMPTEUR**
- [ ] **Create transformation**: `Load_DIM_COMPTEUR.ktr`
- [ ] **Source**: `transformed_consommation.csv`
- [ ] **Extract unique**: `meter_code`, `meter_type`
- [ ] **Add**: `date_installation` (random/fixed dates)
- [ ] **Load into**: DM_consommation.DIM_COMPTEUR

#### **DIM_CLIENT**
- [ ] **Create transformation**: `Load_DIM_CLIENT.ktr`
- [ ] **Source**: `transformed_rentabilite.csv`
- [ ] **Extract unique**: `client_code`, `client_name`, `sector`
- [ ] **Load into**: DM_consommation.DIM_CLIENT

**Estimated time for 2.1**: 3-4 hours

---

### **2.2 Transform and Load FAIT_CONSOMMATION**
- [ ] **Create transformation**: `Load_FAIT_CONSOMMATION.ktr`

#### **Step-by-step:**
1. [ ] **Input**: `transformed_consommation.csv`
2. [ ] **Lookup DIM_TEMPS**: `reading_date` → `id_temps`
3. [ ] **Lookup DIM_REGION**: `region_code` → `id_region`
4. [ ] **Lookup DIM_BATIMENT**: `building_code` → `id_batiment`
5. [ ] **Lookup DIM_CLIENT**: `building_code` → find client → `id_client` (via building-client relationship)
6. [ ] **Lookup DIM_ENERGIE**: `meter_type` → `id_energie`
7. [ ] **Lookup DIM_COMPTEUR**: `meter_code` → `id_compteur`
8. [ ] **Calculate KPIs**:
   - [ ] `consommation_valeur` = `consumption_value`
   - [ ] `temperature` = `temperature` (or NULL)
   - [ ] `cout_energie` = `consumption_value` × `tarif_unitaire` (from DIM_ENERGIE)
   - [ ] `consommation_moyenne_jour` = AVG(consumption) per day (need aggregation)
   - [ ] `consommation_max_jour` = MAX(consumption) per day
   - [ ] `consommation_min_jour` = MIN(consumption) per day
9. [ ] **Add metadata**: `source_id`, `date_extraction`
10. [ ] **Output**: DM_consommation.FAIT_CONSOMMATION

**Estimated time for 2.2**: 4-5 hours

---

## **PHASE 3: ENVIRONNEMENT DATA MART**

### **3.1 Populate DIM_ENVIRONNEMENT**
- [ ] **Create transformation**: `Load_DIM_ENVIRONNEMENT.ktr`
- [ ] **Manual entries**:
  ```sql
  (1, 'CO2', 'kg', 500, 1000)  -- Optimal: 500kg, Alert: 1000kg
  (2, 'Recyclage', 'pourcentage', 0.7, 0.3)  -- Optimal: 70%, Alert: 30%
  ```
- [ ] **Load into**: DM_environnement.DIM_ENVIRONNEMENT

### **3.2 Transform and Load FAIT_ENVIRONNEMENT**
- [ ] **Create transformation**: `Load_FAIT_ENVIRONNEMENT.ktr`

#### **Step-by-step:**
1. [ ] **Input**: `transformed_environnement.csv`
2. [ ] **Lookup DIM_TEMPS**: `report_date` → `id_temps`
3. [ ] **Lookup DIM_REGION**: `region_code` → `id_region`
4. [ ] **Lookup DIM_BATIMENT**: `building_code` → `id_batiment`
5. [ ] **Lookup DIM_CLIENT**: `building_code` → `id_client`
6. [ ] **Lookup DIM_ENVIRONNEMENT**: 
   - `emission_co2_kg` → `id_environnement` = 1 (CO2)
   - `recycling_rate` → `id_environnement` = 2 (Recyclage)
   - **NOTE**: Each row becomes TWO fact rows (CO2 + Recycling)
7. [ ] **Calculate KPIs**:
   - [ ] `valeur_mesuree` = `emission_co2_kg` or `recycling_rate`
   - [ ] `valeur_reference` = `seuil_optimal` from DIM_ENVIRONNEMENT
   - [ ] `ecart_reference` = `valeur_mesuree` - `valeur_reference`
   - [ ] `taux_variation` = NULL (need previous period data)
   - [ ] `ratio_co2_energie` = Need consumption data (join with FAIT_CONSOMMATION)
   - [ ] `categorie_performance`: 
     - IF `valeur_mesuree` > `seuil_alerte` → 'À améliorer'
     - IF `valeur_mesuree` >= `seuil_optimal` → 'Bonne'
     - ELSE → 'Excellente'
8. [ ] **Add metadata**: `source_id`, `date_extraction`
9. [ ] **Output**: DM_environnement.FAIT_ENVIRONNEMENT

**Estimated time for Phase 3**: 3-4 hours

---

## **PHASE 4: RENTABILITE DATA MART**

### **4.1 Populate Dimension Tables**
#### **DIM_FACTURE**
- [ ] **Create transformation**: `Load_DIM_FACTURE.ktr`
- [ ] **Source**: `transformed_rentabilite.csv`
- [ ] **Extract unique**: `invoice_number`, `invoice_date`, `due_date`, `status`
- [ ] **Load into**: DM_rentabilite.DIM_FACTURE

#### **DIM_PAIEMENT**
- [ ] **Create transformation**: `Load_DIM_PAIEMENT.ktr`
- [ ] **Source**: `transformed_rentabilite.csv`
- [ ] **Extract unique**: `payment_method`, `reference` (invoice_number)
- [ ] **Load into**: DM_rentabilite.DIM_PAIEMENT

### **4.2 Transform and Load FAIT_RENTABILITE**
- [ ] **Create transformation**: `Load_FAIT_RENTABILITE.ktr`

#### **Step-by-step:**
1. [ ] **Input**: `transformed_rentabilite.csv`
2. [ ] **Lookup DIM_TEMPS**: `invoice_date` → `id_temps`
3. [ ] **Lookup DIM_REGION**: `region_code` → `id_region`
4. [ ] **Lookup DIM_BATIMENT**: `building_code` → `id_batiment`
5. [ ] **Lookup DIM_CLIENT**: `client_code` → `id_client`
6. [ ] **Lookup DIM_FACTURE**: `invoice_number` → `id_facture`
7. [ ] **Lookup DIM_PAIEMENT**: `payment_method` + `invoice_number` → `id_paiement`
8. [ ] **Calculate KPIs**:
   - [ ] `montant_ht` = `total_ht`
   - [ ] `montant_tva` = `tva_amount`
   - [ ] `montant_ttc` = `total_ttc`
   - [ ] `cout_energie` = `energy_cost`
   - [ ] `montant_paye` = `payment_amount` (or `total_ttc` if status='paid')
   - [ ] `marge` = `total_ttc` - `energy_cost`
   - [ ] `taux_marge` = (`marge` / `total_ttc`) × 100
   - [ ] `delai_paiement` = `payment_date` - `due_date` (in days)
   - [ ] `taux_recouvrement` = (`payment_amount` / `total_ttc`) × 100
   - [ ] `rentabilite_categorie`:
     - IF `taux_marge` > 40% → 'Haute'
     - IF `taux_marge` > 20% → 'Moyenne'
     - ELSE → 'Basse'
9. [ ] **Add metadata**: `source_id`, `date_extraction`
10. [ ] **Output**: DM_rentabilite.FAIT_RENTABILITE

**Estimated time for Phase 4**: 3-4 hours

---

## **PHASE 5: VALIDATION & TESTING**

### **5.1 Data Quality Checks**
- [ ] **Verify referential integrity**: All foreign keys exist in dimensions
- [ ] **Check KPI calculations**: Sample calculations match expected values
- [ ] **Validate business rules**: Recycling rate 0-1, CO2 positive, etc.
- [ ] **Count records**: Compare source CSV rows vs loaded fact rows

### **5.2 Create Test Queries**
- [ ] **KPI queries** for each Data Mart (as per PDF requirements)
- [ ] **Sample reports**: Top 10 buildings by consumption/CO2/profit
- [ ] **Trend analysis**: Monthly evolution charts
- [ ] **Correlation**: Consumption vs Temperature

### **5.3 Documentation**
- [ ] **Update README** with load process details
- [ ] **Document transformation logic** for each KPI
- [ ] **Create data dictionary** for Data Mart tables
- [ ] **Note any assumptions** made during transformations

**Estimated time for Phase 5**: 2-3 hours

---

## **PHASE 6: AUTOMATION (Bonus)**

### **6.1 Create Master Job**
- [ ] **Create job**: `Main_ETL_Job.kjb`
- [ ] **Sequence**: Extract → Transform → Load
- [ ] **Error handling**: Log failures, email alerts
- [ ] **Dependencies**: Ensure dimensions load before facts

### **6.2 Scheduling**
- [ ] **Configure**: Daily run at 02:00
- [ ] **Incremental loading**: Use `updated_at` timestamps
- [ ] **Logging**: Track execution times, row counts

**Estimated time for Phase 6**: 2-3 hours (optional but impressive)

---

## **TOTAL ESTIMATED TIME: 18-25 HOURS**

## **PRIORITY ORDER:**
1. **DIM_TEMPS** (needed by all)
2. **Consommation Data Mart** (most complex)
3. **Rentabilité Data Mart** (business critical)
4. **Environnement Data Mart**
5. **Validation & Documentation**
6. **Automation** (if time permits)

## **PRO TIPS:**
- **Start with ONE complete pipeline** (Consommation) to establish pattern
- **Reuse transformations** where possible (DIM_REGION, DIM_BATIMENT, DIM_CLIENT)
- **Test each step** before moving to next
- **Keep backups** of intermediate CSV files
- **Document challenges** for your project report

**You can do this!** The hard work (extraction + cleaning) is done. Now it's about structuring for analysis, which is the whole point of BI! 🚀




























## Phase de Chargement - Dimension Temps ✅ COMPLÉTÉ

### Fichier: `Create_DIM_TEMPS.ktr`

### Objectif:
Créer et peupler la dimension temps (DIM_TEMPS), dimension partagée par les trois Data Marts, essentielle pour l'analyse temporelle.

### Importance Stratégique:
La dimension temps est **fondamentale** dans tout Data Warehouse car elle permet:
- L'agrégation des données par période (jour, mois, trimestre, année)
- L'analyse des tendances et évolutions temporelles
- Les comparaisons période à période (YoY, MoM)
- Les filtres temporels dans les rapports

### Architecture du Flux:

```
[Génération 365 jours] → [Numérotation] → [Calcul Dates] → [Extraction Composantes] → 
[Calcul Attributs] → [Ajout Clé Primaire] → [Sélection Finale] → [Chargement BD]
```

### Étapes Détailées:

#### 1. Génération de la Plage Temporelle
- **Période**: 1er janvier 2025 au 31 décembre 2025 (365 jours)
- **Rationale**: Les données sources couvrent l'année 2025
- **Méthode**: Génération de 365 lignes vides transformées en dates

#### 2. Calcul de la Date Complète
- **Formule**: `date_complete = 2025-01-01 + (day_number - 1) jours`
- **Résultat**: Séquence continue de dates sans interruption

#### 3. Extraction des Composantes Temporelles
| Composante | Méthode de Calcul | Usage dans l'Analyse |
|------------|-------------------|----------------------|
| `annee` | Extraction année (2025) | Agrégation annuelle |
| `mois` | Extraction mois (1-12) | Analyse mensuelle, saisonnalité |
| `jour` | Extraction jour du mois (1-31) | Analyse journalière |
| `trimestre` | Calcul trimestre (1-4) | Reporting trimestriel |
| `semaine_annee` | Numéro de semaine ISO (1-52) | Analyse hebdomadaire |

#### 4. Calcul des Attributs Définis
- **`jour_semaine`**: Nom français du jour (Lundi à Dimanche)
  - Utilisation: Analyse par jour de semaine, patterns d'utilisation
- **`est_weekend`**: Indicateur booléen (vrai pour Samedi/Dimanche)
  - Utilisation: Comparaison consommation weekdays vs weekends

#### 5. Clé Primaire de Surrogation
- **`id_temps`**: Clé artificielle séquentielle (1 à 365)
- **Avantages sur clé naturelle (date)**:
  - Performance des jointures (entier vs date)
  - Gestion des dates manquantes dans les faits
  - Extensibilité pour années futures

### Structure Finale de DIM_TEMPS:

```sql
CREATE TABLE dim_temps (
    id_temps INT PRIMARY KEY,          -- Clé de surrogation
    date_complete DATE,                -- Date au format yyyy-MM-dd
    annee INT,                         -- 2025
    mois INT,                          -- 1 à 12
    jour INT,                          -- 1 à 31
    trimestre INT,                     -- 1 à 4
    semaine_annee INT,                 -- 1 à 52 (ISO)
    jour_semaine VARCHAR(15),          -- Lundi à Dimanche
    est_weekend BOOLEAN,               -- TRUE pour Samedi/Dimanche
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Exemples de Données Générées:

| id_temps | date_complete | annee | mois | jour | trimestre | semaine_annee | jour_semaine | est_weekend |
|----------|---------------|-------|------|------|-----------|---------------|--------------|-------------|
| 1 | 2025-01-01 | 2025 | 1 | 1 | 1 | 1 | Mercredi | 0 |
| 2 | 2025-01-02 | 2025 | 1 | 2 | 1 | 1 | Jeudi | 0 |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |
| 7 | 2025-01-07 | 2025 | 1 | 7 | 1 | 2 | Mardi | 0 |
| 365 | 2025-12-31 | 2025 | 12 | 31 | 4 | 1 | Mercredi | 0 |

### Décisions de Conception:

#### 1. Dimension Partagée
- **Choix**: Une seule table `dim_temps` utilisée par les 3 Data Marts
- **Avantages**: Cohérence des identifiants, pas de duplication, maintenance unique
- **Implémentation**: Chargée une fois, référencée par toutes les tables de faits

#### 2. Année Fixe 2025
- **Justification**: Les données opérationnelles fournies couvrent uniquement 2025
- **Extensibilité**: Le processus peut être paramétré pour d'autres années

#### 3. Format de Date Standard
- **`yyyy-MM-dd`**: Format ISO recommandé pour les bases de données
- **Avantages**: Tri chronologique correct, indépendant des locales

#### 4. Attributs Calculés
- **`jour_semaine` en français**: Adaptation au contexte métier francophone
- **`est_weekend`**: Simplifié (Samedi/Dimanche) sans jours fériés
  - **Rationale**: Les jours fériés varient géographiquement et n'étaient pas requis

### Validation et Qualité:

#### Tests Effectués:
1. **Complétude**: 365 jours générés (année complète)
2. **Continuité**: Pas de dates manquantes dans la séquence
3. **Cohérence**: `est_weekend` = TRUE seulement pour Samedi/Dimanche
4. **Intégrité**: `id_temps` unique et séquentiel

#### Vérification SQL:
```sql
-- Vérification des données
SELECT 
    COUNT(*) as total_jours,
    MIN(date_complete) as date_min,
    MAX(date_complete) as date_max,
    SUM(est_weekend) as weekends,
    COUNT(DISTINCT mois) as mois_distincts
FROM dim_temps;
```
**Résultat attendu**: 365 jours, 2025-01-01 à 2025-12-31, ~104 weekends, 12 mois

### Intégration avec les Data Marts:

#### Relations Prévisionnelles:
1. **Consommation**: `FAIT_CONSOMMATION.id_temps` → `DIM_TEMPS.id_temps`
   - Analyse: Consommation par mois/trimestre, tendances saisonnières
   
2. **Environnement**: `FAIT_ENVIRONNEMENT.id_temps` → `DIM_TEMPS.id_temps`
   - Analyse: Évolution des émissions CO₂ dans le temps
   
3. **Rentabilité**: `FAIT_RENTABILITE.id_temps` → `DIM_TEMPS.id_temps`
   - Analyse: CA mensuel, retards de paiement par période

### Préparation pour les Requêtes Analytiques:

#### Exemples d'Usage Futur:
```sql
-- Consommation mensuelle
SELECT 
    t.mois,
    t.jour_semaine,
    SUM(f.consommation_valeur) as total_consommation
FROM fait_consommation f
JOIN dim_temps t ON f.id_temps = t.id_temps
GROUP BY t.mois, t.jour_semaine
ORDER BY t.mois;

-- Comparaison weekdays vs weekends
SELECT 
    t.est_weekend,
    AVG(f.temperature) as temperature_moyenne,
    SUM(f.consommation_valeur) as consommation_totale
FROM fait_consommation f
JOIN dim_temps t ON f.id_temps = t.id_temps
GROUP BY t.est_weekend;
```

### Prochaines Étapes:
1. **Dimensions partagées**:
   - `DIM_REGION` (régions)
   - `DIM_BATIMENT` (bâtiments)
   - `DIM_CLIENT` (clients)
   
2. **Dimensions spécifiques**:
   - `DIM_ENERGIE` (consommation)
   - `DIM_ENVIRONNEMENT` (impact écologique)
   - `DIM_FACTURE` (rentabilité)

3. **Tables de faits**:
   - Transformation et chargement des données métier avec jointures aux dimensions

### Leçons Apprises:
1. **Génération de dates**: Approche séquentielle plus fiable que calculs complexes
2. **Clés de surrogation**: Essentielles pour la performance et l'extensibilité
3. **Dimensions partagées**: Réduction de la redondance et garantie de cohérence
4. **Attributs dérivés**: Calcul pendant le chargement pour performance en requête

---

**État**: ✅ DIMENSION TEMPS PRÊTE POUR L'ANALYSE TEMPORELLE

La base temporelle est maintenant établie pour supporter toutes les analyses chronologiques requises par le projet.
```

