import sqlite3
import os

# On Railway, use /data for persistence (mounted volume); fallback to local
_DATA_DIR = os.environ.get("RAILWAY_VOLUME_MOUNT_PATH", ".")
DB_PATH = os.path.join(_DATA_DIR, "hemalens.db")

def init_db():
    os.makedirs(_DATA_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            modality TEXT NOT NULL,
            initial_low REAL,
            initial_moderate REAL,
            initial_high REAL,
            survey_pregnant BOOLEAN,
            survey_heavy_menstrual_bleeding BOOLEAN,
            survey_pica_present BOOLEAN,
            survey_malaria_history BOOLEAN,
            survey_fatigue BOOLEAN,
            survey_pallor BOOLEAN,
            survey_vegetarian_diet BOOLEAN,
            survey_prior_anaemia_diagnosis BOOLEAN,
            final_risk TEXT,
            confidence REAL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

def save_result(data: dict):
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    survey = data.get('survey', {})
    probs_list = data.get('image_probs_list', [])
    
    # Average the probabilities across all scans provided
    avg_low = sum(p.get('low', 0.0) for p in probs_list) / max(1, len(probs_list))
    avg_mod = sum(p.get('moderate', 0.0) for p in probs_list) / max(1, len(probs_list))
    avg_high = sum(p.get('high', 0.0) for p in probs_list) / max(1, len(probs_list))
    
    cursor.execute('''
        INSERT INTO results (
            modality,
            initial_low, initial_moderate, initial_high,
            survey_pregnant, survey_heavy_menstrual_bleeding, survey_pica_present,
            survey_malaria_history, survey_fatigue, survey_pallor,
            survey_vegetarian_diet, survey_prior_anaemia_diagnosis,
            final_risk, confidence
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (
        data.get('modality', 'combined'),
        avg_low, avg_mod, avg_high,
        survey.get('pregnant', False),
        survey.get('heavy_menstrual_bleeding', False),
        survey.get('pica_present', False),
        survey.get('malaria_history', False),
        survey.get('fatigue', False),
        survey.get('pallor', False),
        survey.get('vegetarian_diet', False),
        survey.get('prior_anaemia_diagnosis', False),
        data.get('final_risk', 'unknown'),
        data.get('confidence', 0.0)
    ))
    conn.commit()
    result_id = cursor.lastrowid
    conn.close()
    return result_id

def get_all_results():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''SELECT * FROM results ORDER BY timestamp DESC''')
    rows = cursor.fetchall()
    col_names = [description[0] for description in cursor.description]
    results = [dict(zip(col_names, row)) for row in rows]
    conn.close()
    return results

def get_summary_stats():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM results")
    total_scans = cursor.fetchone()[0]
    cursor.execute("SELECT final_risk, COUNT(*) FROM results GROUP BY final_risk")
    risk_distribution = dict(cursor.fetchall())
    conn.close()
    return {
        "total_scans": total_scans,
        "risk_distribution": risk_distribution
    }
