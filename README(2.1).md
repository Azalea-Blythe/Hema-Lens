# HemaLens

## AI-Based Anaemia Risk Screening Using Multi-Modal Imaging + WHO Risk Fusion

HemaLens is a mobile-first anaemia risk screening system built for a
24-hour hackathon.\
It combines on-device image classification (Conjunctiva, Fingernail,
Palm) using MobileNetV2 with WHO guideline--based survey risk fusion.

The system is designed for: - Community Health Workers (CHWs) -
Low-resource settings - On-device privacy-first AI screening -
Supervisor-level backend aggregation

------------------------------------------------------------------------

# 🚀 System Overview

The architecture is intentionally split into two major layers:

1.  On-device intelligence (Flutter + TFLite)
2.  Cloud aggregation (FastAPI + SQLite)

All AI inference happens **on-device**. The backend only stores and
aggregates results.

------------------------------------------------------------------------

# 🧠 Complete Inference Flow

User → Survey → Safety Guardrails → Image Capture\
→ Preprocessing → TFLite Model → Image Probabilities\
→ WHO Fusion Layer → Final Risk → Display\
→ Local Storage → Backend Sync

------------------------------------------------------------------------

# 📦 Project Structure

    HemaLens/
    ├── ml/
    │   ├── scripts/
    │   │   ├── prepare_data.py
    │   │   ├── train.py
    │   │   └── fusion.py
    │   ├── models/
    │   │   ├── conjunctiva_model.tflite
    │   │   ├── fingernail_model.tflite
    │   │   └── palm_model.tflite
    │   └── data/ (gitignored)
    │
    ├── backend/
    │   ├── main.py
    │   ├── database.py
    │   ├── requirements.txt
    │   └── railway.toml
    │
    ├── app/
    │   └── lib/services/
    │       └── fusion_service.dart
    │
    └── README.md

------------------------------------------------------------------------

# 🧬 ML Model Details

Architecture:

Input: 224x224x3 (float32, normalized 0--1)\
MobileNetV2 (ImageNet pretrained, frozen base)\
→ GlobalAveragePooling2D\
→ Dense(128, relu)\
→ Dropout(0.3)\
→ Dense(3, softmax)

Output:\
\[low, moderate, high\]

Training: - Optimizer: Adam (lr=1e-3) - Epochs: 20 - Batch size: 32 -
class_weight='balanced' - EarlyStopping enabled

Export: - Converted to TensorFlow Lite - INT8 quantized for mobile
performance

------------------------------------------------------------------------

# 🧮 WHO Risk Fusion Layer

Image model output alone is not sufficient for clinical interpretation.

We apply WHO-grounded risk adjustments based on survey data.

Boost rules applied to HIGH channel:

-   Pregnant → +0.15\
-   Heavy menstrual bleeding → +0.15\
-   Pica present → +0.12\
-   Malaria history → +0.08\
-   Fatigue + pallor → +0.08\
-   Vegetarian diet → +0.05\
-   Prior anaemia diagnosis → +0.05

After boosting: - Renormalize probabilities - Select argmax - Return
final risk tier

This logic is implemented in: - Python: ml/scripts/fusion.py - Dart:
app/lib/services/fusion_service.dart

------------------------------------------------------------------------

# 📱 Flutter App Responsibilities

The frontend is not just UI --- it performs inference.

It must:

1.  Collect survey data
2.  Apply ethnicity & camera guardrails
3.  Capture image
4.  Preprocess to 224x224 float32 tensor
5.  Run TFLite inference
6.  Apply FusionService logic
7.  Display final risk result
8.  Store locally (sqflite)
9.  POST result to backend

Important: The frontend does NOT send images to backend. Inference is
fully on-device.

------------------------------------------------------------------------

# 🛡️ Bias & Safety Guardrails

Training data is primarily from: - India - Ghana - Italy

Skin tone significantly affects conjunctiva and nailbed color
interpretation.

The app blocks scans if: - Ethnicity is unsupported - Camera quality is
Low

Blocked message: "This AI model is currently only trained on specific
regions and cannot safely screen your skin tone yet."

This prevents unsafe predictions.

------------------------------------------------------------------------

# 🌐 Backend API (FastAPI)

The backend does NOT perform ML inference.

It provides:

GET /api/health\
POST /api/results\
GET /api/results\
GET /api/results/summary

Purpose: - Store scan logs - Aggregate statistics - Provide supervisor
dashboard capability

Database: - SQLite (sqlite3) - Table: results

------------------------------------------------------------------------

# 📊 Risk Tiers (WHO Cutoffs)

Low Risk: Hb ≥ 11 g/dL

Moderate Risk: 8.0--10.9 g/dL

High Risk: \< 8.0 g/dL

Minority class (High Risk) handled using: - class_weight='balanced' -
Heavy augmentation

Fallback: If High Risk F1 \< 0.6 → revert to binary classification.

------------------------------------------------------------------------

# 🔌 Deployment Plan

ML: - Trained locally - Exported to .tflite - Bundled as Flutter assets

Backend: - FastAPI - Deployed to Railway (free tier)

Frontend: - Flutter app - On-device inference - Offline capable

------------------------------------------------------------------------

# 👥 Team Workstreams

ML + Backend: - Data prep - Training - TFLite export - FastAPI endpoints

Frontend: - Flutter scaffold - TFLite integration - Fusion logic - API
integration

Documentation & QA: - README - Architecture diagrams - Testing - Demo
prep

------------------------------------------------------------------------

# 🎯 Why This Architecture?

-   Privacy-first (no image upload)
-   Works offline
-   Faster inference
-   Safer bias handling
-   Clean separation of responsibilities
-   Hackathon-friendly and production-scalable

------------------------------------------------------------------------

# ⚠ Disclaimer

HemaLens is a screening tool. It is NOT a diagnostic device. It does NOT
replace laboratory haemoglobin testing. Always refer high-risk
individuals for formal medical evaluation.

------------------------------------------------------------------------

# 📌 Summary

HemaLens combines:

MobileNetV2 multi-modal image classification\
WHO-based risk fusion\
On-device AI inference\
Backend aggregation

Result: A deployable, safety-aware anaemia risk screening system
designed for low-resource healthcare environments.
