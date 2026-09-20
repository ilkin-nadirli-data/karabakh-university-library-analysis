"""
Karabakh University Library Analytics - Data Cleaning Pipeline
Author: İlkin Nadirli
Description: Automated data consolidation, standardizing schema across multi-sheet 
             Excel files, date correction, duration calculations, and JSON export 
             for Google BigQuery ingestion.
"""

import os
import pandas as pd

# ====================================================================
# 1. CONSOLIDATION OF MULTI-SHEET EXCEL FILES (CIRCULATION DATA)
# ====================================================================

folder_path = r"./data/raw_circulation"  # Update or use relative path

STANDART_COLUMNS = [
    "No", "Soyad", "Ad", "Ata", "Edebiyyat", "Rol_ve_ya_Ixtisas",
    "Elaqe", "Verilme_Tarixi", "Qaytarilma_Tarixi", "Oxucu_Tipi",
    "Fayl_Adi", "Sehife_Adi"
]

all_rows = []

# Walk through directories and extract relevant circulation files
for root, dirs, files in os.walk(folder_path):
    for file in files:
        if file.endswith(".xlsx") and not file.startswith("~$") and "Müzakirə" not in file and "Notebook" not in file:
            file_path = os.path.join(root, file)
            file_name = os.path.basename(file_path)

            try:
                sheets = pd.read_excel(file_path, sheet_name=None)
                for sheet_name, df in sheets.items():
                    if df.empty:
                        continue

                    # Strip column whitespaces
                    df.columns = [str(col).strip() for col in df.columns]

                    # Standardize reader role/department
                    if "İxtisas" in df.columns:
                        df = df.rename(columns={"İxtisas": "Rol_ve_ya_Ixtisas"})
                        df["Oxucu_Tipi"] = "Tələbə"
                    elif "Vəzifə" in df.columns:
                        df = df.rename(columns={"Vəzifə": "Rol_ve_ya_Ixtisas"})
                        df["Oxucu_Tipi"] = "Müəllim"
                    else:
                        df["Oxucu_Tipi"] = "Müəllim" if "müəllim" in file_name.lower() else "Tələbə"
                        df["Rol_ve_ya_Ixtisas"] = None

                    # Standardize general headers
                    rename_map = {
                        "№": "No",
                        "Ədəbiyyat": "Edebiyyat",
                        "Əlaqə": "Elaqe",
                        "Verilmə tarixi": "Verilme_Tarixi",
                        "Qaytarılma tarixi": "Qaytarilma_Tarixi",
                    }
                    df = df.rename(columns=rename_map)
                    df["Fayl_Adi"] = file_name
                    df["Sehife_Adi"] = str(sheet_name)

                    # Ensure uniform column layout
                    for col in STANDART_COLUMNS:
                        if col not in df.columns:
                            df[col] = None

                    all_rows.append(df[STANDART_COLUMNS])
            except Exception as e:
                print(f"Error processing {file_name}: {e}")

df_circulation = pd.concat(all_rows, ignore_index=True)
df_circulation = df_circulation.drop_duplicates()


# ====================================================================
# 2. DATE PARSING, WHITESPACE STRIPPING & ANOMALY CORRECTION
# ====================================================================

# Strip hidden whitespaces preventing proper datetime parsing
df_circulation["Verilme_Tarixi"] = df_circulation["Verilme_Tarixi"].astype(str).str.strip()
df_circulation["Qaytarilma_Tarixi"] = df_circulation["Qaytarilma_Tarixi"].astype(str).str.strip()
df_circulation["Verilme_Tarixi"] = df_circulation["Verilme_Tarixi"].replace(["nan", "None", ""], pd.NA)
df_circulation["Qaytarilma_Tarixi"] = df_circulation["Qaytarilma_Tarixi"].replace(["nan", "None", ""], pd.NA)

df_circulation["Verilme_Tarixi"] = pd.to_datetime(df_circulation["Verilme_Tarixi"], dayfirst=True, errors="coerce")
df_circulation["Qaytarilma_Tarixi"] = pd.to_datetime(df_circulation["Qaytarilma_Tarixi"], dayfirst=True, errors="coerce")

# Calculate initial borrowing duration (in days)
df_circulation["Saxlama_Muddeti_Gun"] = (df_circulation["Qaytarilma_Tarixi"] - df_circulation["Verilme_Tarixi"]).dt.days

# Fix swapped dates (where return date and check-out date were accidentally inverted)
mask_swap = (df_circulation["Saxlama_Muddeti_Gun"] < 0) & (df_circulation["Saxlama_Muddeti_Gun"] >= -60)
df_circulation.loc[mask_swap, ["Verilme_Tarixi", "Qaytarilma_Tarixi"]] = (
    df_circulation.loc[mask_swap, ["Qaytarilma_Tarixi", "Verilme_Tarixi"]].values
)

# Fix year-shift entry mistakes in specific batch sheets
mask_june = (df_circulation["Saxlama_Muddeti_Gun"] < 0) & (df_circulation["Sehife_Adi"] == "İyun25")
df_circulation.loc[mask_june, "Verilme_Tarixi"] -= pd.DateOffset(years=1)

mask_dec = (df_circulation["Saxlama_Muddeti_Gun"] < 0) & (df_circulation["Sehife_Adi"] == "Dekabr25")
df_circulation.loc[mask_dec, "Qaytarilma_Tarixi"] += pd.DateOffset(years=1)

# Recalculate duration and extract year/month features
df_circulation["Saxlama_Muddeti_Gun"] = (df_circulation["Qaytarilma_Tarixi"] - df_circulation["Verilme_Tarixi"]).dt.days
df_circulation["Verilme_Ili"] = df_circulation["Verilme_Tarixi"].dt.year
df_circulation["Verilme_Ayi"] = df_circulation["Verilme_Tarixi"].dt.month

# Export cleaned circulation dataset
df_circulation.to_csv("kitabxana_dovriyye_temiz.csv", index=False, encoding="utf-8-sig")


# ====================================================================
# 3. STUDY ROOMS & COMPUTER RESERVATIONS EXPORT FOR BIGQUERY
# ====================================================================

# Discussion rooms conversion
df_rooms = pd.read_excel("muzakire_otaqlari_temiz.xlsx")
df_rooms["Tarix"] = df_rooms["Tarix"].astype(str)
df_rooms["Baslama"] = df_rooms["Baslama"].astype(str)
df_rooms["Bitme"] = df_rooms["Bitme"].astype(str)
df_rooms.to_json("muzakire_otaqlari.json", orient="records", lines=True, force_ascii=False)

# Computer reservations conversion
df_laptops = pd.read_excel("notebook_rezerv_temiz.xlsx")
df_laptops["Verilme_Tarixi"] = df_laptops["Verilme_Tarixi"].astype(str)
df_laptops["Qaytarilma_Tarixi"] = df_laptops["Qaytarilma_Tarixi"].astype(str)
df_laptops["Saat_vq"] = df_laptops["Saat_vq"].astype(str)
df_laptops.to_json("notebook_rezerv.json", orient="records", lines=True, force_ascii=False)

print("Data processing pipeline completed successfully.")
