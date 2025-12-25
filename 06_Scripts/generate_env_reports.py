import csv
import random
from datetime import datetime, timedelta

# =====================================================
# CONFIGURATION
# =====================================================
MONTHS = [
    ("01", "2025-01-31", "Janvier 2025"),
    ("02", "2025-02-28", "Février 2025"),
    ("03", "2025-03-31", "Mars 2025"),
]

# Bâtiments et régions de référence (de ta base MySQL)
BUILDINGS = [
    {"id_region": "REG01", "id_batiment": "BAT001"},
    {"id_region": "REG01", "id_batiment": "BAT002"},
    {"id_region": "REG02", "id_batiment": "BAT003"},
    {"id_region": "REG02", "id_batiment": "BAT004"},
    {"id_region": "REG02", "id_batiment": "BAT005"},
    {"id_region": "REG03", "id_batiment": "BAT006"},
    {"id_region": "REG03", "id_batiment": "BAT007"},
    {"id_region": "REG03", "id_batiment": "BAT008"},
    {"id_region": "REG04", "id_batiment": "BAT013"},
    {"id_region": "REG05", "id_batiment": "BAT014"},
    {"id_region": "REG05", "id_batiment": "BAT015"},
    {"id_region": "REG04", "id_batiment": "BAT016"},
]

# =====================================================
# FONCTIONS DE GÉNÉRATION D'ERREURS
# =====================================================

def introduce_errors(row, month_num, error_level):
    """
    Introduit des erreurs dans une ligne selon le mois et le niveau d'erreur
    """
    error_row = row.copy()
    
    # Niveau d'erreur : 1=léger, 2=moyen, 3=important
    error_probability = 0.2 + (error_level * 0.15)
    
    if random.random() < error_probability:
        # CHOISIR UN TYPE D'ERREUR SPÉCIFIQUE AU MOIS
        errors_by_month = {
            "01": ["null_co2", "date_format", "duplicate"],
            "02": ["recycling_overflow", "negative_co2", "missing_building"],
            "03": ["all_errors", "inconsistent", "wrong_type"]
        }
        
        available_errors = errors_by_month.get(month_num, [
            "null_co2", "date_format", "recycling_overflow", 
            "negative_co2", "missing_building", "missing_region",
            "extra_space", "wrong_type", "outlier"
        ])
        
        error_type = random.choice(available_errors)
        
        if error_type == "null_co2":
            # CO₂ NULL
            error_row["emission_CO2_kg"] = ""
            error_row["_error_note"] = "CO2_MANQUANT"
        
        elif error_type == "date_format":
            # Format de date incorrect
            error_row["date_rapport"] = error_row["date_rapport"].replace("-", "/")
            error_row["_error_note"] = "DATE_MAL_FORMATEE"
        
        elif error_type == "recycling_overflow":
            # Taux de recyclage > 1
            error_row["taux_recyclage"] = round(random.uniform(1.1, 2.0), 3)
            error_row["_error_note"] = "RECYCLAGE_SUPERIEUR_1"
        
        elif error_type == "negative_co2":
            # CO₂ négatif
            error_row["emission_CO2_kg"] = -abs(error_row["emission_CO2_kg"])
            error_row["_error_note"] = "CO2_NEGATIF"
        
        elif error_type == "missing_building":
            # Bâtiment manquant
            error_row["id_batiment"] = ""
            error_row["_error_note"] = "BATIMENT_MANQUANT"
        
        elif error_type == "missing_region":
            # Région manquante
            error_row["id_region"] = ""
            error_row["_error_note"] = "REGION_MANQUANTE"
        
        elif error_type == "extra_space":
            # Espaces inutiles
            error_row["id_region"] = f"  {error_row['id_region']}  "
            error_row["id_batiment"] = f" {error_row['id_batiment']} "
            error_row["_error_note"] = "ESPACES_INUTILES"
        
        elif error_type == "wrong_type":
            # Mauvais type de données
            if random.random() < 0.5:
                error_row["emission_CO2_kg"] = "N/A"
            else:
                error_row["taux_recyclage"] = "Non mesuré"
            error_row["_error_note"] = "MAUVAIS_TYPE"
        
        elif error_type == "outlier":
            # Valeur aberrante
            error_row["emission_CO2_kg"] = error_row["emission_CO2_kg"] * 10
            error_row["_error_note"] = "VALEUR_ABERRANTE"
        
        elif error_type == "duplicate":
            # Cette ligne sera dupliquée plus tard
            error_row["_error_note"] = "A_DUPLIQUER"
        
        elif error_type == "inconsistent":
            # Données incohérentes
            if float(error_row["emission_CO2_kg"]) > 500 and float(error_row["taux_recyclage"]) > 0.8:
                error_row["taux_recyclage"] = 0.3  # Incohérence délibérée
                error_row["_error_note"] = "INCOHERENCE"
        
        elif error_type == "all_errors":
            # Toutes les erreurs en une !
            error_row["emission_CO2_kg"] = ""
            error_row["taux_recyclage"] = 1.5
            error_row["date_rapport"] = "31/03/2025"
            error_row["id_region"] = "  REG99  "
            error_row["_error_note"] = "TOUTES_ERREURS"
    
    return error_row

# =====================================================
# GÉNÉRATION DES DONNÉES DE BASE
# =====================================================

def generate_base_data(report_date):
    """Génère des données environnementales de base"""
    base_data = []
    
    for building in BUILDINGS:
        # Émissions CO2 réalistes (200-1000 kg)
        co2 = random.randint(200, 1000)
        
        # Taux de recyclage réaliste (30%-85%)
        recycling = round(random.uniform(0.3, 0.85), 3)
        
        row = {
            "id_region": building["id_region"],
            "id_batiment": building["id_batiment"],
            "date_rapport": report_date,
            "emission_CO2_kg": co2,
            "taux_recyclage": recycling
        }
        
        base_data.append(row)
    
    return base_data

# =====================================================
# GÉNÉRATION D'UN FICHIER CSV POUR UN MOIS
# =====================================================

def generate_monthly_csv(month_num, report_date, month_name, error_level):
    """Génère un fichier CSV pour un mois spécifique"""
    filename = f"env_reports_{month_num}_2025.csv"
    
    print(f"\n Génération de {filename} ({month_name})...")
    print(f"   Niveau d'erreur : {error_level}/3")
    
    # 1. Données de base
    all_data = generate_base_data(report_date)
    
    # 2. Appliquer des erreurs
    data_with_errors = []
    for row in all_data:
        # Version avec erreurs
        error_row = introduce_errors(row, month_num, error_level)
        data_with_errors.append(error_row)
        
        # Ajouter un doublon si demandé
        if "_error_note" in error_row and "A_DUPLIQUER" in error_row["_error_note"]:
            duplicate = error_row.copy()
            duplicate["_error_note"] = "DOUBLON"
            data_with_errors.append(duplicate)
    
    # 3. Ajouter des lignes problématiques supplémentaires
    problematic_rows = []
    
    # Lignes avec références inexistantes
    problematic_rows.append({
        "id_region": "REG99",
        "id_batiment": "BAT999",
        "date_rapport": report_date,
        "emission_CO2_kg": 350,
        "taux_recyclage": 0.6,
        "_error_note": "REF_INEXISTANTE"
    })
    
    # Ligne sans région
    problematic_rows.append({
        "id_region": "",
        "id_batiment": "BAT001",
        "date_rapport": report_date,
        "emission_CO2_kg": 420,
        "taux_recyclage": 0.7,
        "_error_note": "REGION_VIDE"
    })
    
    # Ligne sans bâtiment
    problematic_rows.append({
        "id_region": "REG01",
        "id_batiment": "",
        "date_rapport": report_date,
        "emission_CO2_kg": 380,
        "taux_recyclage": 0.65,
        "_error_note": "BATIMENT_VIDE"
    })
    
    # Ligne avec date au mauvais format
    problematic_rows.append({
        "id_region": "REG02",
        "id_batiment": "BAT003",
        "date_rapport": report_date.replace("-", "/"),
        "emission_CO2_kg": 510,
        "taux_recyclage": 0.72,
        "_error_note": "DATE_FORMAT_DDMMYYYY"
    })
    
    # Ligne avec CO2 extrêmement élevé
    problematic_rows.append({
        "id_region": "REG03",
        "id_batiment": "BAT006",
        "date_rapport": report_date,
        "emission_CO2_kg": 99999,
        "taux_recyclage": 0.1,
        "_error_note": "CO2_EXTREME"
    })
    
    data_with_errors.extend(problematic_rows)
    
    # 4. Mélanger les données
    random.shuffle(data_with_errors)
    
    # 5. Écrire le fichier CSV
    fieldnames = [
        "id_region", "id_batiment", "date_rapport", 
        "emission_CO2_kg", "taux_recyclage"
    ]
    
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in data_with_errors:
            # Nettoyer les notes d'erreur (ne pas les écrire dans le CSV)
            clean_row = {k: v for k, v in row.items() if not k.startswith('_')}
            writer.writerow(clean_row)
    
    # 6. Statistiques
    total_rows = len(data_with_errors)
    error_rows = sum(1 for r in data_with_errors if "_error_note" in r)
    
    print(f"   {filename} généré avec {total_rows} lignes")
    print(f"   Dont {error_rows} lignes avec erreurs ({error_rows/total_rows*100:.1f}%)")
    
    # Afficher quelques exemples d'erreurs
    print(f"    Exemples d'erreurs incluses :")
    error_examples = set()
    for row in data_with_errors:
        if "_error_note" in row and len(error_examples) < 3:
            error_examples.add(row["_error_note"])
    
    for err in list(error_examples)[:3]:
        print(f"      • {err}")
    
    return filename

# =====================================================
# GÉNÉRATION DU FICHIER "PROPRE" POUR COMPARAISON
# =====================================================

def generate_clean_csv():
    """Génère un fichier CSV propre sans erreurs"""
    print("\nGénération d'un fichier de référence propre...")
    
    clean_data = []
    for building in BUILDINGS[:5]:  # Seulement 5 bâtiments pour l'exemple
        clean_data.append({
            "id_region": building["id_region"],
            "id_batiment": building["id_batiment"],
            "date_rapport": "2025-01-31",
            "emission_CO2_kg": random.randint(300, 600),
            "taux_recyclage": round(random.uniform(0.5, 0.8), 3)
        })
    
    with open('env_reports_clean.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=clean_data[0].keys())
        writer.writeheader()
        writer.writerows(clean_data)
    
    print(f"    env_reports_clean.csv généré (5 lignes sans erreurs)")

# =====================================================
# GÉNÉRATION DU FICHIER DE MÉTADONNÉES DES ERREURS
# =====================================================

def generate_error_metadata():
    """Génère un fichier expliquant les erreurs incluses"""
    metadata = [
        {"Fichier": "env_reports_01_2025.csv", "Description": "Janvier 2025 - Erreurs légères", "Erreurs principales": "Dates mal formatées, quelques valeurs NULL"},
        {"Fichier": "env_reports_02_2025.csv", "Description": "Février 2025 - Erreurs moyennes", "Erreurs principales": "CO2 négatifs, recyclage > 1, bâtiments manquants"},
        {"Fichier": "env_reports_03_2025.csv", "Description": "Mars 2025 - Erreurs complexes", "Erreurs principales": "Toutes les erreurs combinées, incohérences"},
        {"Fichier": "env_reports_clean.csv", "Description": "Référence propre", "Erreurs principales": "Aucune"}
    ]
    
    with open('metadata_erreurs.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=metadata[0].keys())
        writer.writeheader()
        writer.writerows(metadata)
    
    print("\n metadata_erreurs.csv généré (documentation des erreurs)")

# =====================================================
# EXÉCUTION PRINCIPALE
# =====================================================

def main():
    print("=" * 70)
    print(" GÉNÉRATION DES RAPPORTS ENVIRONNEMENTAUX (CSV)")
    print("=" * 70)
    print("Ce script génère plusieurs fichiers CSV avec des erreurs")
    print("volontaires pour tester la phase Transformation de l'ETL.")
    print("=" * 70)
    
    generated_files = []
    
    # Générer les fichiers pour chaque mois avec un niveau d'erreur croissant
    for i, (month_num, report_date, month_name) in enumerate(MONTHS):
        error_level = i + 1  # Niveau d'erreur croissant
        filename = generate_monthly_csv(month_num, report_date, month_name, error_level)
        generated_files.append(filename)
    
    # Générer un fichier propre pour comparaison
    generate_clean_csv()
    
    # Générer les métadonnées
    generate_error_metadata()
    
    # Résumé
    print("\n" + "=" * 70)
    print("FICHIERS GÉNÉRÉS AVEC SUCCÈS")
    print("=" * 70)
    
    for i, filename in enumerate(generated_files):
        print(f"{i+1}. {filename}")
    
    print("4. env_reports_clean.csv")
    print("5. metadata_erreurs.csv")
    
    print("\n" + "=" * 70)
    print(" ERREURS VOLONTAIRES INCLUSES DANS LES CSV :")
    print("=" * 70)
    print("✅ CO₂ NULL (champ vide)")
    print("✅ Recyclage > 1 (valeurs > 1.0)")
    print("✅ CO₂ négatif")
    print("✅ Format de date incorrect (JJ/MM/AAAA)")
    print("✅ Bâtiment manquant (champ vide)")
    print("✅ Région manquante (champ vide)")
    print("✅ Espaces inutiles")
    print("✅ Doublons de lignes")
    print("✅ Valeurs aberrantes")
    print("✅ Références à des régions/bâtiments inexistants")
    print("✅ Mauvais types de données (texte dans numérique)")
    print("✅ Incohérences (ex: CO2 élevé mais recyclage élevé)")
    

# =====================================================
# LANCEMENT
# =====================================================

if __name__ == "__main__":
    main()