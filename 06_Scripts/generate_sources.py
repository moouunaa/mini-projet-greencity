import json
import random
from datetime import datetime, timedelta

# =====================================================
# FONCTIONS DE GÉNÉRATION AVEC ERREURS
# =====================================================

def generate_json_with_errors(energy_type, filename, unit, field_name, month=1):
    """
    Génère un fichier JSON (avec erreurs volontaires) pour le mois donné (1 ou 2)
    """
    
    # Structure de base
    data = {
        "id_region": "REG01",
        "BATG01": {
            "id_batiment": "BATG01",
            "type_energie": energy_type,
            "unite": unit,
            "date_generation": f"2025-{month:02d}-14",
            "mesures": []
        },
        "BAT101": {
            "id_batiment": "BAT101",
            "type_energie": energy_type,
            "unite": unit,
            "date_generation": f"2025-{month:02d}-14",
            "mesures": []
        }
    }
    
    # Dates de base (14th of the requested month)
    base_date = datetime(2025, month, 14) 
    
    # Générer des mesures pour chaque compteur
    if energy_type == "electricite":
        counters = ["ELEC_G01", "ELEC_G02", "ELEC_101", "ELEC_102"]
        base_consumption = 100.0
    elif energy_type == "eau":
        counters = ["EAU_001", "EAU_002"]
        base_consumption = 2.0
    else:  # gaz
        counters = ["GAZ_001", "GAZ_002"]
        base_consumption = 4.0
    
    # Pour chaque compteur, générer 4 mesures (2 bâtiments × 2 heures)
    for building_code, building_data in data.items():
        if building_code == "id_region":
            continue
            
        for counter in counters[:2] if building_code == "BATG01" else counters[2:]:
            for hour in [8, 9, 10, 11]:  # De 8h à 11h
                measure_date = base_date.replace(hour=hour, minute=0, second=0)
                
                # CONSOMMATION AVEC VARIATION ALÉATOIRE
                consumption = base_consumption + random.uniform(-20, 30)
                if consumption < 0:
                    consumption = 0.0
                
                mesure = {
                    "compteur_id": counter,
                    "date_mesure": measure_date.isoformat(),
                    field_name: round(consumption, 1)
                }
                
                #  INTRODUIRE DES ERREURS VOLONTAIRES (30% de chance)
                if random.random() < 0.3:
                    error_type = random.choice([
                        "missing_value", "duplicate", "date_format", 
                        "unit_case", "negative", "extra_space"
                    ])
                    
                    if error_type == "missing_value":
                        # Valeur manquante
                        mesure[field_name] = None
                    
                    elif error_type == "duplicate":
                        # Pas de modification - la duplication sera faite après
                        pass
                    
                    elif error_type == "date_format":
                        # Format de date incorrect
                        mesure["date_mesure"] = measure_date.strftime("%d/%m/%Y %H:%M")
                    
                    elif error_type == "unit_case" and energy_type == "electricite":
                        # Unité mal écrite (seulement pour électricité)
                        if "consommation_kWh" in mesure:
                            mesure["consommation_KWh"] = mesure.pop("consommation_kWh")
                        elif "consommation_KWh" in mesure:
                            mesure["consommation_kwh"] = mesure.pop("consommation_KWh")
                    
                    elif error_type == "negative":
                        # Valeur négative
                        mesure[field_name] = round(-abs(consumption), 1)
                    
                    elif error_type == "extra_space":
                        # Espaces inutiles
                        mesure["compteur_id"] = f" {counter}  "
                
                building_data["mesures"].append(mesure)
                
                #  AJOUTER UN DOUBLON (10% de chance)
                if random.random() < 0.1:
                    duplicate = mesure.copy()
                    building_data["mesures"].append(duplicate)
    
    #  AJOUTER DES MESURES INCOMPLÈTES (5%)
    for building_code, building_data in data.items():
        if building_code == "id_region":
            continue
        
        if random.random() < 0.05:
            incomplete_measure = {
                "compteur_id": "FAKE_001",
                "date_mesure": "2025-01-14T12:00:00"
                # Pas de consommation_value !
            }
            building_data["mesures"].append(incomplete_measure)
    
    # Écrire le fichier JSON
    json_filename = f"C:/Users/hp/Desktop/mini projet - greencity/03_Source_Files/json/{filename}"
    with open(json_filename, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
        print(f" {json_filename} généré avec {sum(len(b['mesures']) for k, b in data.items() if k != 'id_region')} mesures (dont erreurs)")
        
# =====================================================
# GÉNÉRATION DES 3 FICHIERS JSON
# =====================================================

def generate_all_json_files():
    print("=" * 50)
    print("GÉNÉRATION DES FICHIERS JSON AVEC ERREURS (MOIS 01 & 02)")
    print("=" * 50)
    
    for month in (1, 2):
        suffix = f"{month:02d}_2025"

        # Électricité
        generate_json_with_errors(
            energy_type="electricite",
            filename=f"Elec_consumption_{suffix}.json",
            unit="KWh",
            field_name="consommation_kWh",
            month=month
        )

        # Eau
        generate_json_with_errors(
            energy_type="eau",
            filename=f"Eau_consumption_{suffix}.json",
            unit="m3",
            field_name="consommation_m3",
            month=month
        )

        # Gaz
        generate_json_with_errors(
            energy_type="gaz",
            filename=f"Gaz_consumption_{suffix}.json",
            unit="m3",
            field_name="consommation_m3",
            month=month
        )
    
    print("\n" + "=" * 50)
    print("TYPES D'ERREURS INCLUS DANS LES FICHIERS :")
    print("=" * 50)
    print("1. Valeurs manquantes (NULL)")
    print("2. Doublons de mesures")
    print("3. Formats de date incorrects (JJ/MM/AAAA)")
    print("4. Variations de casse (KWh, kwh, kWh)")
    print("5. Valeurs négatives")
    print("6. Espaces inutiles")
    print("7. Mesures incomplètes")
    print("\nCes erreurs devront être traitées dans la phase Transformation !")

# =====================================================
# GÉNÉRATION FICHIER CSV ENVIRONNEMENTAL
# =====================================================

def generate_env_csv_with_errors(month=1):
    """Génère le fichier CSV environnemental avec erreurs pour le mois demandé (1..3)"""
    
    print("\n" + "=" * 50)
    print(f"GÉNÉRATION DU FICHIER CSV ENVIRONNEMENTAL (MOIS {month:02d})")
    print("=" * 50)
    
    # Données de base (dates will be set according to the requested month)
    base_data = [
        {"id_region": "REG01", "id_batiment": "BAT001", "date_rapport": "2025-01-31", "emission_CO2_kg": 512, "taux_recyclage": 0.67},
        {"id_region": "REG01", "id_batiment": "BAT002", "date_rapport": "2025-01-31", "emission_CO2_kg": 430, "taux_recyclage": 0.71},
        {"id_region": "REG02", "id_batiment": "BAT003", "date_rapport": "2025-01-31", "emission_CO2_kg": 380, "taux_recyclage": 0.65},
        {"id_region": "REG03", "id_batiment": "BAT006", "date_rapport": "2025-01-31", "emission_CO2_kg": 620, "taux_recyclage": 0.58},
        {"id_region": "REG04", "id_batiment": "BAT013", "date_rapport": "2025-01-31", "emission_CO2_kg": 490, "taux_recyclage": 0.73},
        {"id_region": "REG05", "id_batiment": "BAT014", "date_rapport": "2025-01-31", "emission_CO2_kg": 410, "taux_recyclage": 0.69},
    ]

    # Map month to a reasonable last-day date string for the report
    month_days = {1: "2025-01-31", 2: "2025-02-28", 3: "2025-03-31"}
    date_report = month_days.get(month, f"2025-{month:02d}-28")

    # Update the date_rapport for all base rows
    for r in base_data:
        r["date_rapport"] = date_report
    
    # Ajouter des erreurs
    data_with_errors = []
    
    for row in base_data:
        data_with_errors.append(row)
        
        #  AJOUTER DES ERREURS (40% de chance par ligne)
        if random.random() < 0.4:
            error_row = row.copy()
            error_type = random.choice([
                "missing", "date_bad", "space", "duplicate", 
                "negative", "out_of_range", "wrong_type"
            ])
            
            if error_type == "missing":
                # Valeur manquante
                if random.random() < 0.5:
                    error_row["emission_CO2_kg"] = ""
                else:
                    error_row["taux_recyclage"] = ""
            
            elif error_type == "date_bad":
                # Date mal formatée
                error_row["date_rapport"] = date_report.replace("-", "/")
            
            elif error_type == "space":
                # Espaces inutiles
                error_row["id_region"] = f" {error_row['id_region']}  "
                error_row["id_batiment"] = f"{error_row['id_batiment']} "
            
            elif error_type == "negative":
                # Valeur négative
                error_row["emission_CO2_kg"] = -abs(error_row["emission_CO2_kg"])
            
            elif error_type == "out_of_range":
                # Valeur hors limites
                error_row["taux_recyclage"] = 1.5  # > 1.0
            
            elif error_type == "wrong_type":
                # Mauvais type de données
                error_row["emission_CO2_kg"] = "N/A"
            
            data_with_errors.append(error_row)
    
    #  AJOUTER DES LIGNES PROBLÉMATIQUES SUPPLÉMENTAIRES
    problematic_rows = [
        {"id_region": "REG01", "id_batiment": "BAT999", "date_rapport": date_report, "emission_CO2_kg": 300, "taux_recyclage": 0.60},  # Bâtiment inexistant
        {"id_region": "REG99", "id_batiment": "BAT001", "date_rapport": date_report, "emission_CO2_kg": 250, "taux_recyclage": 0.55},  # Région inexistante
        {"id_region": "", "id_batiment": "BAT002", "date_rapport": date_report, "emission_CO2_kg": 480, "taux_recyclage": 0.70},  # Région vide
        {"id_region": "REG01", "id_batiment": "", "date_rapport": date_report, "emission_CO2_kg": 520, "taux_recyclage": 0.68},  # Bâtiment vide
    ]
    
    data_with_errors.extend(problematic_rows)
    
    # Écrire le fichier CSV
    import csv
    out_path = f'C:/Users/hp/Desktop/mini projet - greencity/03_Source_Files/csv/env_reports_{month:02d}_2025.csv'
    with open(out_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=base_data[0].keys())
        writer.writeheader()
        writer.writerows(data_with_errors)
    
    print(f" {out_path} généré avec {len(data_with_errors)} lignes (dont erreurs)")
    print("\nTypes d'erreurs inclus :")
    print("- Valeurs manquantes (champs vides)")
    print("- Dates mal formatées (JJ/MM/AAAA)")
    print("- Espaces inutiles")
    print("- Doublons")
    print("- Valeurs négatives")
    print("- Valeurs hors limites (taux > 1.0)")
    print("- Mauvais types de données")
    print("- Références à des régions/bâtiments inexistants")

# Perfect example generator removed — script now generates only dirty data (requested JSON & CSV files).

# =====================================================
# EXÉCUTION PRINCIPALE
# =====================================================

if __name__ == "__main__":
    print(" DÉBUT DE LA GÉNÉRATION DES FICHIERS SOURCES")
    print("=" * 60)
    print("NOTE : Ces fichiers contiennent des erreurs VOLONTAIRES")
    print("       pour tester la phase de Transformation ETL.")
    print("=" * 60)
    
    # 1. Générer les fichiers JSON IoT (mois 01 & 02)
    generate_all_json_files()
    
    # 2. Générer les fichiers CSV environnementaux (mois 01-03)
    for m in (1, 2, 3):
        generate_env_csv_with_errors(month=m)
    
    print("\n" + "=" * 60)
    print(" FICHIERS GÉNÉRÉS AVEC SUCCÈS (DIRTY DATA ONLY)")
    print("=" * 60)
    print("JSON:")
    print(" - Elec_consumption_01_2025.json")
    print(" - Elec_consumption_02_2025.json")
    print(" - Eau_consumption_01_2025.json")
    print(" - Eau_consumption_02_2025.json")
    print(" - Gaz_consumption_01_2025.json")
    print(" - Gaz_consumption_02_2025.json")
    print("CSV:")
    print(" - env_reports_01_2025.csv")
    print(" - env_reports_02_2025.csv")
    print(" - env_reports_03_2025.csv")
    print("\n  Les fichiers ci-dessus contiennent des erreurs à corriger en ETL")