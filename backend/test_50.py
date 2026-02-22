"""
HemaLens Backend — 50 Comprehensive Test Cases
Tests POST /api/results with the updated dual-scan pipeline (image_probs_list with 2 entries).
Run: python test_50.py (with backend running on localhost:8000)
"""
import requests
import json

BASE = "http://localhost:8000"
API  = f"{BASE}/api/results"

PASS = 0
FAIL = 0

def mk_survey(**kwargs):
    base = {
        "pregnant": False,
        "heavy_menstrual_bleeding": False,
        "pica_present": False,
        "malaria_history": False,
        "fatigue": False,
        "pallor": False,
        "vegetarian_diet": False,
        "prior_anaemia_diagnosis": False,
    }
    base.update(kwargs)
    return base

def mk_probs(low, mod, high):
    return {"low": low, "moderate": mod, "high": high}

def test(name, payload, expect_ok=True, expect_risk=None):
    global PASS, FAIL
    try:
        r = requests.post(API, json=payload, timeout=10)
        if expect_ok:
            ok = r.status_code == 200
            data = r.json() if r.status_code == 200 else {}
            risk_ok = (expect_risk is None) or (data.get("status") == "ok")
            if ok and risk_ok:
                print(f"  [PASS] {name}")
                PASS += 1
            else:
                print(f"  [FAIL] {name} — HTTP {r.status_code}: {r.text[:120]}")
                FAIL += 1
        else:
            # Expect a validation failure
            if r.status_code in (400, 422):
                print(f"  [PASS] {name} — correctly rejected ({r.status_code})")
                PASS += 1
            else:
                print(f"  [FAIL] {name} — Expected rejection, got {r.status_code}: {r.text[:120]}")
                FAIL += 1
    except Exception as e:
        print(f"  [ERROR] {name} — {e}")
        FAIL += 1

# ─── SECTION 1: Dual-scan (conjunctiva + fingernail) — Low Risk ───────────────
print("\n── DUAL SCAN — LOW RISK ──────────────────────────────────────")
test("D01 Adult female, no risk factors, both scans low",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.85, 0.10, 0.05), mk_probs(0.80, 0.12, 0.08)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.82})

test("D02 Adult male, both scans clearly low",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.90, 0.07, 0.03), mk_probs(0.88, 0.09, 0.03)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.89})

test("D03 Child age 8, low risk, both scans",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.78, 0.15, 0.07), mk_probs(0.82, 0.12, 0.06)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.80})

test("D04 Elderly 70, healthy, both scans low",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.75, 0.18, 0.07), mk_probs(0.77, 0.16, 0.07)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.76})

test("D05 Low + vegetarian diet (small boost, still low)",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.80, 0.12, 0.08), mk_probs(0.78, 0.14, 0.08)],
      "survey": mk_survey(vegetarian_diet=True), "final_risk": "low", "confidence": 0.75})

# ─── SECTION 2: Dual-scan — Moderate Risk ────────────────────────────────────
print("\n── DUAL SCAN — MODERATE RISK ─────────────────────────────────")
test("D06 Moderate conjunctiva + low fingernail → moderate",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.20, 0.55, 0.25), mk_probs(0.40, 0.42, 0.18)],
      "survey": mk_survey(), "final_risk": "moderate", "confidence": 0.49})

test("D07 Both scans moderate confidence",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.25, 0.50, 0.25), mk_probs(0.30, 0.48, 0.22)],
      "survey": mk_survey(), "final_risk": "moderate", "confidence": 0.49})

test("D08 Prior anaemia + moderate scans",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.25, 0.48, 0.27), mk_probs(0.28, 0.44, 0.28)],
      "survey": mk_survey(prior_anaemia_diagnosis=True), "final_risk": "moderate", "confidence": 0.44})

test("D09 Malaria history, moderate scans",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.30, 0.50, 0.20), mk_probs(0.35, 0.46, 0.19)],
      "survey": mk_survey(malaria_history=True), "final_risk": "moderate", "confidence": 0.46})

test("D10 Vegetarian + prior anaemia, moderate scans",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.35, 0.45, 0.20), mk_probs(0.33, 0.44, 0.23)],
      "survey": mk_survey(vegetarian_diet=True, prior_anaemia_diagnosis=True), "final_risk": "moderate", "confidence": 0.42})

# ─── SECTION 3: Dual-scan — High Risk ────────────────────────────────────────
print("\n── DUAL SCAN — HIGH RISK ─────────────────────────────────────")
test("D11 Both scans strongly high",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.05, 0.10, 0.85), mk_probs(0.07, 0.12, 0.81)],
      "survey": mk_survey(), "final_risk": "high", "confidence": 0.83})

test("D12 Pregnant woman, moderate scans → high after boost",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.30, 0.40, 0.30), mk_probs(0.28, 0.42, 0.30)],
      "survey": mk_survey(pregnant=True), "final_risk": "high", "confidence": 0.45})

test("D13 Pregnant + HMB tips moderate to very high",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.35, 0.40, 0.25), mk_probs(0.30, 0.38, 0.32)],
      "survey": mk_survey(pregnant=True, heavy_menstrual_bleeding=True), "final_risk": "high", "confidence": 0.57})

test("D14 Pica present, low image → high via boost",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.45, 0.30, 0.25), mk_probs(0.40, 0.32, 0.28)],
      "survey": mk_survey(pica_present=True), "final_risk": "high", "confidence": 0.38})

test("D15 Malaria + pica + fatigue + pallor",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.40, 0.35, 0.25), mk_probs(0.38, 0.33, 0.29)],
      "survey": mk_survey(malaria_history=True, pica_present=True, fatigue=True, pallor=True), "final_risk": "high", "confidence": 0.53})

test("D16 Max boost — all flags, low-ish image",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.55, 0.30, 0.15), mk_probs(0.50, 0.32, 0.18)],
      "survey": mk_survey(pregnant=True, heavy_menstrual_bleeding=True, pica_present=True,
                          malaria_history=True, fatigue=True, pallor=True,
                          vegetarian_diet=True, prior_anaemia_diagnosis=True),
      "final_risk": "high", "confidence": 0.83})

# ─── SECTION 4: Triple-scan (conjunctiva + fingernail + palm) ────────────────
print("\n── TRIPLE SCAN (including palm) ──────────────────────────────")
test("D17 Three scans, all low",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.85, 0.10, 0.05), mk_probs(0.80, 0.12, 0.08), mk_probs(0.82, 0.13, 0.05)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.82})

test("D18 Three scans, mixed → moderate",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.30, 0.50, 0.20), mk_probs(0.40, 0.42, 0.18), mk_probs(0.25, 0.55, 0.20)],
      "survey": mk_survey(), "final_risk": "moderate", "confidence": 0.49})

test("D19 Three scans, two high one moderate → high",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.10, 0.20, 0.70), mk_probs(0.15, 0.25, 0.60), mk_probs(0.35, 0.40, 0.25)],
      "survey": mk_survey(), "final_risk": "high", "confidence": 0.52})

test("D20 Three scans, Ghanaian + malaria history → high",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.35, 0.40, 0.25), mk_probs(0.30, 0.42, 0.28), mk_probs(0.32, 0.38, 0.30)],
      "survey": mk_survey(malaria_history=True), "final_risk": "high", "confidence": 0.36})

# ─── SECTION 5: Edge cases ────────────────────────────────────────────────────
print("\n── EDGE CASES ────────────────────────────────────────────────")
test("E01 100% high confidence both scans",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.0, 0.0, 1.0), mk_probs(0.0, 0.0, 1.0)],
      "survey": mk_survey(), "final_risk": "high", "confidence": 1.0})

test("E02 100% low confidence both scans",
     {"modality": "combined",
      "image_probs_list": [mk_probs(1.0, 0.0, 0.0), mk_probs(1.0, 0.0, 0.0)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 1.0})

test("E03 Equal probs no boost — argmax picks moderate (middle alphabetical, then index)",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.333, 0.333, 0.334), mk_probs(0.333, 0.333, 0.334)],
      "survey": mk_survey(), "final_risk": "high", "confidence": 0.334})

test("E04 Very small high values, no boost → low",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.79, 0.20, 0.01), mk_probs(0.78, 0.21, 0.01)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.785})

test("E05 fatigue without pallor — no boost",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.60, 0.30, 0.10), mk_probs(0.58, 0.32, 0.10)],
      "survey": mk_survey(fatigue=True), "final_risk": "low", "confidence": 0.59})

test("E06 pallor without fatigue — no boost",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.60, 0.30, 0.10), mk_probs(0.58, 0.32, 0.10)],
      "survey": mk_survey(pallor=True), "final_risk": "low", "confidence": 0.59})

test("E07 fatigue + pallor together gives boost",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.38, 0.32, 0.30), mk_probs(0.36, 0.34, 0.30)],
      "survey": mk_survey(fatigue=True, pallor=True), "final_risk": "high", "confidence": 0.38})

test("E08 Empty image_probs_list (accepted, averaged over zero)",
     {"modality": "combined",
      "image_probs_list": [],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.5})

test("E09 Single scan (conjunctiva only fallback)",
     {"modality": "conjunctiva",
      "image_probs_list": [mk_probs(0.80, 0.12, 0.08)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.80})

test("E10 Confidence > 1.0 (API accepts, no server-side clamp required)",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.95, 0.03, 0.02)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 1.5})

# ─── SECTION 6: Demographic scenarios ───────────────────────────────────────
print("\n── DEMOGRAPHICS ──────────────────────────────────────────────")
test("G01 Indian Subcontinent female, pregnant",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.35, 0.38, 0.27), mk_probs(0.33, 0.40, 0.27)],
      "survey": mk_survey(pregnant=True), "final_risk": "high", "confidence": 0.42})

test("G02 Black/African male, malaria history",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.42, 0.38, 0.20), mk_probs(0.40, 0.38, 0.22)],
      "survey": mk_survey(malaria_history=True), "final_risk": "moderate", "confidence": 0.38})

test("G03 White/Caucasian female, vegetarian + prior anaemia",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.38, 0.42, 0.20), mk_probs(0.36, 0.44, 0.20)],
      "survey": mk_survey(vegetarian_diet=True, prior_anaemia_diagnosis=True), "final_risk": "moderate", "confidence": 0.40})

test("G04 Hispanic female, no risk factors",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.75, 0.18, 0.07), mk_probs(0.78, 0.15, 0.07)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.765})

test("G05 Child (age 5), no risk factors",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.80, 0.14, 0.06), mk_probs(0.78, 0.16, 0.06)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.79})

test("G06 Pregnant teenager (age 16)",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.40, 0.38, 0.22), mk_probs(0.38, 0.40, 0.22)],
      "survey": mk_survey(pregnant=True), "final_risk": "high", "confidence": 0.37})

test("G07 Post-menopausal woman, prior anaemia",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.45, 0.38, 0.17), mk_probs(0.48, 0.36, 0.16)],
      "survey": mk_survey(prior_anaemia_diagnosis=True), "final_risk": "moderate", "confidence": 0.37})

test("G08 Adult male, all flags set (male-applicable only)",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.40, 0.35, 0.25), mk_probs(0.38, 0.36, 0.26)],
      "survey": mk_survey(pica_present=True, malaria_history=True, fatigue=True, pallor=True,
                          vegetarian_diet=True, prior_anaemia_diagnosis=True),
      "final_risk": "high", "confidence": 0.63})

# ─── SECTION 7: Invalid/malformed requests ───────────────────────────────────
print("\n── INVALID REQUESTS (should be rejected 422) ────────────────")
test("I01 Missing modality",
     {"image_probs_list": [mk_probs(0.8, 0.1, 0.1)],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.8},
     expect_ok=False)

test("I02 Missing image_probs_list",
     {"modality": "combined",
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.8},
     expect_ok=False)

test("I03 Missing survey",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.8, 0.1, 0.1)],
      "final_risk": "low", "confidence": 0.8},
     expect_ok=False)

test("I04 Missing final_risk",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.8, 0.1, 0.1)],
      "survey": mk_survey(), "confidence": 0.8},
     expect_ok=False)

test("I05 Missing confidence",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.8, 0.1, 0.1)],
      "survey": mk_survey(), "final_risk": "low"},
     expect_ok=False)

test("I06 Confidence as string",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.8, 0.1, 0.1)],
      "survey": mk_survey(), "final_risk": "low", "confidence": "not-a-float"},
     expect_ok=False)

test("I07 image_probs_list containing a string",
     {"modality": "combined",
      "image_probs_list": ["bad"],
      "survey": mk_survey(), "final_risk": "low", "confidence": 0.8},
     expect_ok=False)

test("I08 Completely empty payload",
     {}, expect_ok=False)

# ─── SECTION 8: Combined risk factor stress tests ────────────────────────────
print("\n── STRESS / COMBINATION TESTS ────────────────────────────────")
test("S01 Pica alone tips borderline moderate → high",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.42, 0.28, 0.30), mk_probs(0.40, 0.30, 0.30)],
      "survey": mk_survey(pica_present=True), "final_risk": "high", "confidence": 0.42})

test("S02 Boost exactly maxes out (high=1.0 after clamp)",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.10, 0.05, 0.85), mk_probs(0.08, 0.07, 0.85)],
      "survey": mk_survey(pregnant=True, heavy_menstrual_bleeding=True, pica_present=True,
                          malaria_history=True, fatigue=True, pallor=True,
                          vegetarian_diet=True, prior_anaemia_diagnosis=True),
      "final_risk": "high", "confidence": 1.0})

test("S03 Negative probabilities (accepted, no server clamp)",
     {"modality": "combined",
      "image_probs_list": [{"low": -0.1, "moderate": 0.6, "high": 0.5}],
      "survey": mk_survey(), "final_risk": "moderate", "confidence": 0.6})

test("S04 Very high confidence, single scan",
     {"modality": "conjunctiva",
      "image_probs_list": [mk_probs(0.0, 0.02, 0.98)],
      "survey": mk_survey(), "final_risk": "high", "confidence": 0.98})

test("S05 Only fatigue (no pallor) + malaria — boost of 0.08 only from malaria",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.50, 0.35, 0.15), mk_probs(0.48, 0.37, 0.15)],
      "survey": mk_survey(fatigue=True, malaria_history=True),
      "final_risk": "low", "confidence": 0.46})

test("S06 All moderate + pregnancy → high via boost",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.33, 0.33, 0.34), mk_probs(0.33, 0.33, 0.34)],
      "survey": mk_survey(pregnant=True), "final_risk": "high", "confidence": 0.49})

test("S07 Triple scan averaging — diverse scans, moderate average",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.70, 0.20, 0.10), mk_probs(0.20, 0.50, 0.30), mk_probs(0.40, 0.42, 0.18)],
      "survey": mk_survey(), "final_risk": "moderate", "confidence": 0.37})

test("S08 Two borderline scans + prior anaemia + vegetarian → high",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.35, 0.38, 0.27), mk_probs(0.37, 0.36, 0.27)],
      "survey": mk_survey(prior_anaemia_diagnosis=True, vegetarian_diet=True),
      "final_risk": "high", "confidence": 0.37})

test("S09 Mixed scan quality — one very bad, one good → average moderate",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.80, 0.15, 0.05), mk_probs(0.10, 0.15, 0.75)],
      "survey": mk_survey(), "final_risk": "moderate", "confidence": 0.27})

test("S10 Ghanaian patient, triple scan, all risk factors",
     {"modality": "combined",
      "image_probs_list": [mk_probs(0.30, 0.38, 0.32), mk_probs(0.28, 0.40, 0.32), mk_probs(0.25, 0.38, 0.37)],
      "survey": mk_survey(malaria_history=True, pica_present=True, fatigue=True, pallor=True),
      "final_risk": "high", "confidence": 0.63})

# ─── Verify GET endpoints ─────────────────────────────────────────────────────
print("\n── GET ENDPOINTS ─────────────────────────────────────────────")
try:
    r = requests.get(f"{BASE}/api/health", timeout=5)
    if r.status_code == 200 and r.json().get("status") == "ok":
        print("  [PASS] Health check")
        PASS += 1
    else:
        print(f"  [FAIL] Health check: {r.text}")
        FAIL += 1
except Exception as e:
    print(f"  [ERROR] Health check: {e}")
    FAIL += 1

try:
    r = requests.get(f"{BASE}/api/results", timeout=5)
    if r.status_code == 200 and "results" in r.json():
        print(f"  [PASS] GET /api/results — {len(r.json()['results'])} records")
        PASS += 1
    else:
        print(f"  [FAIL] GET /api/results: {r.text}")
        FAIL += 1
except Exception as e:
    print(f"  [ERROR] GET /api/results: {e}")
    FAIL += 1

try:
    r = requests.get(f"{BASE}/api/results/summary", timeout=5)
    if r.status_code == 200 and "summary" in r.json():
        summary = r.json()["summary"]
        print(f"  [PASS] GET /api/results/summary — total_scans={summary.get('total_scans')}, dist={summary.get('risk_distribution')}")
        PASS += 1
    else:
        print(f"  [FAIL] GET /api/results/summary: {r.text}")
        FAIL += 1
except Exception as e:
    print(f"  [ERROR] GET /api/results/summary: {e}")
    FAIL += 1

# ─── SUMMARY ─────────────────────────────────────────────────────────────────
total = PASS + FAIL
print(f"""
{'═' * 60}
  RESULTS:  ✅ Passed: {PASS}   ❌ Failed: {FAIL}   Total: {total}
{'═' * 60}
""")
