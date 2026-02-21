# HemaLens — 24-Hour Hackathon Plan (3-Person Team)

> [!IMPORTANT]
> **Final approach confirmed**: 3-tier image classification (MobileNetV2 → Low/Moderate/High) + **WHO guideline-based survey risk fusion** for improved accuracy. Survey collects age, sex, BMI, pregnancy, symptoms, ethnic background, and camera details.

> [!CAUTION]
> **Data Bias & Safety Safeguard (Judge Feedback)**: Our training data only covers India, Ghana, and Italy. Skin tone heavily impacts conjunctiva/nailbed colour analysis. To prevent dangerous misdiagnosis, the app must ask for **Ethnicity**. If the user selects an unsupported ethnicity, the app will refuse the image scan and show an alert: *"This AI model is currently only trained on data from specific regions and cannot safely screen your skin tone yet."* We also track **Camera Quality** to evaluate hardware variance.

---

## Complete Dataset Inventory (All Downloaded ✅)

| File | Type | Hb Labels | 3-Tier Distribution |
|------|------|-----------|--------------------|
| [archive.zip](file:///d:/Projects/HemaLens/Datasets/archive.zip) | **Conjunctiva** (palpebral + forniceal) | ✅ Hb in `India.xlsx` g/dL | Low: 55, Mod: 38, High: **2** (~860 images, 95 patients) |
| `CP-AnemiC dataset.rar` | **Conjunctiva** (palpebral) | ✅ Hb + `Severity` column in Excel | Low: ~286, Mod: ~300, High: ~124 (**710 images**) |
| [data.zip](file:///d:/Projects/HemaLens/Datasets/data.zip) | **Fingernails** | ✅ Hb in `metadata.csv` g/L + bounding boxes | Low: 207, Mod: 25, High: **18** (250 images) |
| [Fingernails.rar](file:///d:/Projects/HemaLens/Datasets/Fingernails.rar) | **Fingernails** | ❌ Binary only (no Hb values inside) | ~4,261 images — used for augmenting at-risk class |

> [!NOTE]
> `CP-AnemiC dataset.rar` contains `Anemia_Data_Collection_Sheet.xlsx` with columns: `IMAGE_ID`, `HB_LEVEL` (g/dL), `Severity` (Mild/Moderate/Severe/Non-Anemic), `Age`, `Gender`, `Hospital`. This is the richest source for High Risk label data.

### 3-Tier Label Mapping (WHO Classification)

| Risk Tier | Image label | Adult Hb | Children (<5) Hb | Est. total samples |
|-----------|-------------|----------|------------------|--------------------|
| **Low Risk** | `low` | ≥ 11 g/dL | ≥ 11 g/dL | ~550 |
| **Moderate Risk** | `moderate` | 8.0–10.9 g/dL | 7.0–10.9 g/dL | ~360 |
| **High Risk** | `high` | < 8.0 g/dL | < 7.0 g/dL | ~130 (boost with augmentation) |

> [!WARNING]
> High Risk is minority class. Strategy: **class_weight='balanced'** + heavy augmentation on High Risk images. Fallback to 2-class if F1 on High Risk < 0.6 after training.

---

## Team & Workstreams

| Person | Role | Workstream |
|--------|------|-----------|
| **You** | ML + Backend | Data prep → Training → TFLite export → FastAPI backend |
| **Friend 1** | Frontend | Flutter scaffold → screens → TFLite + API integration |
| **Friend 2** | Docs + QA | README, architecture docs, app testing, demo prep |

---

## Parallel Workstreams

### 🧠 Workstream A — ML & Model (You)

**Hour 0–2: Data Prep**
- [x] GitHub repo + branch strategy + `.gitignore` *(already done by you)*
- [ ] Extract all 4 archives into `ml/data/raw/`
- [ ] Run [prepare_data.py](file:///d:/Projects/HemaLens/ml/scripts/prepare_data.py) → outputs `ml/data/conjunctiva/{low,moderate,high}/` and `ml/data/fingernail/{low,moderate,high}/`
- [ ] Verify counts and class balance per modality

**Hour 2–6: Model Training**
- [ ] Train conjunctiva 3-class classifier (MobileNetV2, frozen base → head)
- [ ] Train fingernail 3-class classifier (same architecture)
- [ ] Evaluate both: accuracy, per-class F1, confusion matrix

**Hour 6–8: Export**
- [ ] Convert both to [.tflite](file:///d:/Projects/HemaLens/ml/models/conjunctiva_model.tflite) with INT8 quantization
- [ ] Test TFLite inference in Python
- [ ] Commit [ml/models/conjunctiva_model.tflite](file:///d:/Projects/HemaLens/ml/models/conjunctiva_model.tflite) + `fingernail_model.tflite`

**Sync point @ Hour 8**: Hand off [.tflite](file:///d:/Projects/HemaLens/ml/models/conjunctiva_model.tflite) files to Friend 1

**Hour 8–10: WHO Risk Fusion Module**
- [ ] Create [ml/scripts/fusion.py](file:///d:/Projects/HemaLens/ml/scripts/fusion.py) — pure Python, no ML needed
- [ ] Inputs: image model probabilities `[low, mod, high]` + survey dict
- [ ] WHO adjustment rules (see table below)
- [ ] Output: adjusted final risk tier + confidence
- [ ] Unit test with 10 edge cases
- [ ] Port same logic to `app/lib/services/fusion_service.dart` for Flutter

**Hour 10–14: Thin FastAPI Backend**
- [ ] Create [backend/main.py](file:///d:/Projects/HemaLens/backend/main.py) with FastAPI
- [ ] `POST /api/results` — save a scan result + survey answers (JSON body)
- [ ] `GET  /api/results` — return all results
- [ ] `GET  /api/results/summary` — aggregate stats (for CHW supervisor)
- [ ] `GET  /api/health` — health check
- [ ] Local SQLite via `sqlite3` (no ORM needed)
- [ ] Deploy to [Railway.app](https://railway.app) free tier

**Sync point @ Hour 14**: Share live API URL with Friend 1

---

### 📱 Workstream B — Flutter App (Friend 1)

**Hour 0–2: Scaffold**
- [ ] `flutter create app` inside `app/`
- [ ] Add dependencies to `pubspec.yaml` (`camera`, `tflite_flutter`, [image](file:///d:/Projects/HemaLens/ml/scripts/prepare_data.py#49-51), `sqflite`, `path_provider`, `google_fonts`)
- [ ] Set up folder structure, theme, and navigation skeleton

**Hour 2–9: Core Screens (with stub model)**
- [ ] Disclaimer + consent screen
- [ ] Home screen: choose scan type (👁️ Conjunctiva / 🖐️ Fingernail)
- [ ] **Survey screen** (before capture):
  - Age, sex, pregnancy status (female only)
  - Symptom checklist: fatigue, dizziness, pallor, shortness of breath, pica
  - Risk factors: heavy menstrual bleeding, vegetarian diet, malaria history, prior anaemia diagnosis
  - **Data Safety Guardrails**:
    - Ethnicity: Dropdown (Asian/Indian, Black/African, White/Caucasian, Hispanic/Latino, Other).
    - Camera Quality: Dropdown (High/Flagship, Medium, Low/Budget).
- [ ] **Safeguard Logic (UI)**: If Ethnicity is NOT one of the supported ones (Asian/Indian, Black/African, White/Caucasian) OR Camera Quality is Low, show a blocking alert and halt the scan: *"Our AI is not yet calibrated for this ethnicity/camera. We cannot safely proceed. Please seek traditional screening."*
- [ ] Guided capture screen: camera + oval overlay + hints
- [ ] Result screen: Low 🟢 / Moderate 🟡 / High 🔴 card + fusion-adjusted score + disclaimer + referral CTA
- [ ] History screen: SQLite-backed scan log (stores survey answers + result)

**Sync point @ Hour 8**: Plug in real [.tflite](file:///d:/Projects/HemaLens/ml/models/conjunctiva_model.tflite) models from Workstream A

**Hour 9–16: TFLite + Fusion + API Integration**
- [ ] Bundle [.tflite](file:///d:/Projects/HemaLens/ml/models/conjunctiva_model.tflite) as asset, wire up `InferenceService`
- [ ] Preprocess captured image in Dart (resize 224×224, normalise)
- [ ] Implement `FusionService` in Dart (ported from [fusion.py](file:///d:/Projects/HemaLens/ml/scripts/fusion.py))
- [ ] Display fusion-adjusted risk result on result screen
- [ ] Wire `ResultRepository` to POST results + survey to FastAPI backend (Hour 14+ once URL is live)

---

### 📝 Workstream C — Documentation (Friend 2)

**Hour 0–2: Docs Setup** *(repo setup already done by you)*
- [ ] Write [README.md](file:///d:/Projects/HemaLens/README.md) skeleton: overview, problem statement, setup guide
- [ ] Document Flutter interface contract for Friend 1 (already drafted — share the PDF)

**Hour 2–10: Core Documentation**
- [ ] Architecture diagram (survey → image → TFLite → WHO fusion → result → FastAPI → DB)
- [ ] Dataset inventory section in README
- [ ] Ethical disclaimers and limitations section
- [ ] App user guide with screenshots / mockups

**Hour 10–18: App QA & Testing** *(freed up since no repo to set up)*
- [ ] Install Flutter app on a test device and do manual walkthroughs
- [ ] Test each scan type end-to-end once models are integrated (Hour 12+)
- [ ] Log bugs in a simple issue list and hand to Friend 1
- [ ] Verify API endpoints are reachable from the Flutter app

**Hour 18–24: Demo Prep**
- [ ] Fill in accuracy metrics once training is done
- [ ] Write demo walkthrough script for judges
- [ ] Prepare slide deck / poster if required by hackathon
- [ ] Record 1-minute demo video

---

## Shared Hour-by-Hour Sync Points

```
Hour  0  : All 3 set up environments, review plan (repo already up ✅)
Hour  2  : A: data ready       | B: scaffold + survey screen  | C: README
Hour  8  : 🔁 SYNC — .tflite handed to B; A builds WHO fusion module
Hour 10  : A: fusion.py done → port to Dart FusionService; A starts FastAPI
Hour 14  : 🔁 SYNC — API live; B wires TFLite + Fusion + API; C starts QA
Hour 18  : B: full E2E test on device (survey → capture → fusion → result)
Hour 20  : 🔁 SYNC — polish, C fills metrics + demo script
Hour 24  : Submit 🚀
```

---

## Repo Structure

```
HemaLens/
├── ml/
│   ├── scripts/
│   │   ├── prepare_data.py       ← extract + label all 4 datasets
│   │   ├── train.py              ← MobileNetV2 fine-tune + TFLite export
│   │   └── fusion.py             ← WHO guideline risk score fusion (Python)
│   ├── models/
│   │   ├── conjunctiva_model.tflite
│   │   └── fingernail_model.tflite
│   └── data/  (gitignored)
├── backend/
│   ├── main.py                   ← FastAPI app (4 endpoints)
│   ├── database.py               ← SQLite connection
│   ├── requirements.txt
│   └── railway.toml              ← Railway deploy config
├── app/
│   └── lib/services/
│       └── fusion_service.dart   ← WHO fusion logic (Dart port of fusion.py)
├── .gitignore
└── README.md
```

---

## System Architecture

### Image Model (both models identical)
```
Input: 224×224×3 (float32, normalized [0,1])
  └─ MobileNetV2 (ImageNet weights, base frozen)
       └─ GlobalAveragePooling2D
            └─ Dense(128, relu) + Dropout(0.3)
                 └─ Dense(3, softmax)
                      └─ [low, moderate, high]  ← raw image probabilities
```
**Training config**: Adam lr=1e-3, class_weight=balanced, 20 epochs, batch 32, EarlyStopping

### WHO Guideline Risk Fusion Layer
```
image_probs  = [low: 0.55, moderate: 0.35, high: 0.10]  ← from TFLite
survey_boost = 0.0

# WHO-grounded adjustments (each adds to 'high' channel weight):
+ pregnant               → +0.15
+ heavy menstrual bleed  → +0.15
+ pica present           → +0.12  (strong iron-deficiency signal)
+ malaria history        → +0.08
+ fatigue + pallor       → +0.08
+ vegetarian diet        → +0.05
+ prior anaemia diagn.   → +0.05

adjusted_high  = min(1.0, image_probs['high'] + survey_boost)
final_risk     = argmax(renormalised adjusted probs)
```
> Source: WHO Guidelines for Haemoglobin Cutoffs and Anaemia Risk Factors (2011)

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| ML Training | Python + TensorFlow/Keras + MobileNetV2 |
| On-device Inference | TensorFlow Lite (INT8 quantized) |
| Risk Fusion | Python [fusion.py](file:///d:/Projects/HemaLens/ml/scripts/fusion.py) (train/test) → Dart `FusionService` (on-device) |
| Mobile App | Flutter (Dart) |
| Camera | `camera` plugin |
| TFLite in Flutter | `tflite_flutter` |
| Local Storage | `sqflite` |
| Fonts | `google_fonts` |
| Backend API | FastAPI (Python) — 4 endpoints |
| Backend DB | SQLite via `sqlite3` |
| Backend Deploy | Railway.app (free tier) |
