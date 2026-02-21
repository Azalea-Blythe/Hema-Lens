import os
import shutil
import pandas as pd
from pathlib import Path
import math

def get_risk_tier(hb_level):
    if pd.isna(hb_level):
        return None
    if hb_level >= 11.0:
        return 'low'
    elif hb_level >= 8.0:
        return 'moderate'
    else:
        return 'high'

BASE_DIR = Path(r"d:\Projects\HemLens")
DATASETS_DIR = BASE_DIR / "Datasets"
OUT_DIR = BASE_DIR / "ml" / "data"

for modality in ['conjunctiva', 'fingernail', 'palm']:
    for tier in ['low', 'moderate', 'high']:
        (OUT_DIR / modality / tier).mkdir(parents=True, exist_ok=True)

# 1. CP-AnemiC Dataset (Conjunctiva)
cpanemic_dir = DATASETS_DIR / "CP-AnemiC dataset"
cpanemic_excel = cpanemic_dir / "Anemia_Data_Collection_Sheet.xlsx"
if cpanemic_excel.exists():
    df = pd.read_excel(cpanemic_excel)
    cols = [c for c in df.columns if 'IMAGE_ID' in str(c).upper() or 'ID' in str(c).upper() or 'IMAGE' in str(c).upper()]
    hb_cols = [c for c in df.columns if 'HB' in str(c).upper() or 'HEMO' in str(c).upper()]
    if cols and hb_cols:
        id_col = cols[0]
        hb_col = hb_cols[0]
        for _, row in df.iterrows():
            try:
                raw_id = row[id_col]
                # Try to extract the integer from IMAGE_ID if it has text, or just cast it
                if isinstance(raw_id, str):
                    import re
                    digits = re.findall(r'\d+', raw_id)
                    if digits:
                        num = int(digits[0])
                    else:
                        continue
                else:
                    num = int(raw_id)
                    
                hb = row[hb_col]
                tier = get_risk_tier(hb)
                if tier:
                    img_name = f"Image_{num:03d}.png"
                    for sub in ["Anemic", "Non-anemic"]:
                        img_path = cpanemic_dir / sub / img_name
                        if img_path.exists():
                            shutil.copy(img_path, OUT_DIR / 'conjunctiva' / tier / f"cp_{num:03d}.png")
                            break
            except Exception as e:
                pass

# 2. dataset anemia / India & Italy (Conjunctiva)
anemia_dir = DATASETS_DIR / "dataset anemia"
for country in ['India', 'Italy']:
    country_dir = anemia_dir / country
    excel_path = country_dir / f"{country}.xlsx"
    if excel_path.exists():
        df = pd.read_excel(excel_path)
        for _, row in df.iterrows():
            hb_val = None
            for c in df.columns:
                if 'HB' in str(c).upper() or 'HGB' in str(c).upper():
                    hb_val = row[c]
                    break
            
            id_val = None
            for c in df.columns:
                if 'NUM' in str(c).upper() or 'ID' in str(c).upper():
                    id_val = row[c]
                    break
            
            if hb_val is not None and not pd.isna(hb_val) and id_val is not None:
                try:
                    tier = get_risk_tier(float(hb_val))
                except:
                    tier = None
                if tier:
                    try:
                        folder_name = str(int(id_val))
                    except:
                        folder_name = str(id_val)
                        
                    patient_dir = country_dir / folder_name
                    if patient_dir.exists() and patient_dir.is_dir():
                        for f in os.listdir(patient_dir):
                            if f.lower().endswith(('.png', '.jpg', '.jpeg')):
                                src = patient_dir / f
                                shutil.copy(src, OUT_DIR / 'conjunctiva' / tier / f"{country}_{folder_name}_{f}")

# 3. data (Fingernails with info)
fingernail_csv = DATASETS_DIR / 'data' / 'metadata.csv'
if fingernail_csv.exists():
    df = pd.read_csv(fingernail_csv)
    for _, row in df.iterrows():
        pat_id = row.get('PATIENT_ID')
        hb = row.get('HB_LEVEL_GperL')
        if pat_id is not None and not pd.isna(pat_id) and hb is not None and not pd.isna(hb):
            try:
                hb_dl = float(hb) / 10.0
                tier = get_risk_tier(hb_dl)
                if tier:
                    img_path = DATASETS_DIR / 'data' / 'photo' / f"{int(pat_id)}.jpg"
                    if img_path.exists():
                        shutil.copy(img_path, OUT_DIR / 'fingernail' / tier / f"data_{int(pat_id)}.jpg")
            except:
                pass

# 4. Fingernails (Binary)
fingernails_bin_dir = DATASETS_DIR / 'Fingernails'
if fingernails_bin_dir.exists():
    for f in os.listdir(fingernails_bin_dir):
        l_f = f.lower()
        if l_f.endswith(('.png', '.jpg', '.jpeg')):
            src = fingernails_bin_dir / f
            if 'non' in l_f:
                shutil.copy(src, OUT_DIR / 'fingernail' / 'low' / f"bin_{f}")
            elif 'anemic' in l_f or 'anrmic' in l_f:
                shutil.copy(src, OUT_DIR / 'fingernail' / 'high' / f"bin_{f}")

# 5. Palm (Binary)
palm_bin_dir = DATASETS_DIR / 'Palm'
if palm_bin_dir.exists():
    for f in os.listdir(palm_bin_dir):
        l_f = f.lower()
        if l_f.endswith(('.png', '.jpg', '.jpeg')):
            src = palm_bin_dir / f
            if 'non' in l_f:
                shutil.copy(src, OUT_DIR / 'palm' / 'low' / f"bin_{f}")
            elif 'anemic' in l_f or 'anrmic' in l_f:
                shutil.copy(src, OUT_DIR / 'palm' / 'high' / f"bin_{f}")

print("Data preparation complete.")

counts = {'conjunctiva': {'low': 0, 'moderate': 0, 'high': 0},
          'fingernail': {'low': 0, 'moderate': 0, 'high': 0},
          'palm': {'low': 0, 'moderate': 0, 'high': 0}}

for modality in counts:
    for tier in counts[modality]:
        d = OUT_DIR / modality / tier
        if d.exists():
            counts[modality][tier] = len(os.listdir(d))

print("Counts:")
for modality in counts:
    print(f"[{modality}] Low: {counts[modality]['low']}, Mod: {counts[modality]['moderate']}, High: {counts[modality]['high']}")
