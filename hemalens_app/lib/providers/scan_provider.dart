import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../services/ml_service.dart';
import '../services/fusion_service.dart';
import '../services/api_service.dart';

// Which scan step the user is on
enum ScanStep {
  survey,
  scanConjunctiva,
  scanFingernail,
  scanPalm,
  processing,
  result,
}

class ScanProvider extends ChangeNotifier {
  // ── Survey State ───────────────────────────────────────────────────────────
  String gender = 'Female';
  int age = 25;
  String ethnicity = 'Brown / Indian';
  String cameraQuality = 'High / Flagship';
  bool menopausal = false;
  bool pregnant = false;
  bool heavyMenstrualBleeding = false;
  bool picaPresent = false;
  bool malariaHistory = false;
  bool chronicFatigue = false;
  bool pallor = false;
  bool vegetarianDiet = false;
  bool priorAnaemiaDiagnosis = false;

  // New symptoms
  bool glossitis = false;

  // ── Scan State ─────────────────────────────────────────────────────────────
  ScanStep step = ScanStep.survey;
  List<ImageProbs> imageProbsList = [];
  ScanResult? result;
  String? errorMessage;
  bool isSynced = false;

  SurveyData get surveyData => SurveyData(
    gender: gender,
    age: age,
    ethnicity: ethnicity,
    menopausal: menopausal,
    pregnant: pregnant,
    heavyMenstrualBleeding: heavyMenstrualBleeding,
    picaPresent: picaPresent,
    malariaHistory: malariaHistory,
    chronicFatigue: chronicFatigue,
    pallor: pallor,
    vegetarianDiet: vegetarianDiet,
    priorAnaemiaDiagnosis: priorAnaemiaDiagnosis,
    glossitis: glossitis,
  );

  // Returns the modality string for the current scan step
  String get currentModality {
    switch (step) {
      case ScanStep.scanConjunctiva:
        return 'conjunctiva';
      case ScanStep.scanFingernail:
        return 'fingernail';
      case ScanStep.scanPalm:
        return 'palm';
      default:
        return 'conjunctiva';
    }
  }

  // Whether current patient requires palm scan
  bool get requiresPalmScan => surveyData.requiresPalmScan;

  // Total scans required (2 or 3)
  int get totalScans => requiresPalmScan ? 3 : 2;

  // Current scan number (1-indexed)
  int get currentScanNumber {
    switch (step) {
      case ScanStep.scanConjunctiva:
        return 1;
      case ScanStep.scanFingernail:
        return 2;
      case ScanStep.scanPalm:
        return 3;
      default:
        return 1;
    }
  }

  void updateSurvey({
    String? gen,
    int? ag,
    String? eth,
    bool? meno,
    bool? preg,
    bool? hmb,
    bool? pica,
    bool? malaria,
    bool? fatigue,
    bool? pal,
    bool? veg,
    bool? prior,
    bool? gloss,
  }) {
    if (gen != null) gender = gen;
    if (ag != null) age = ag;
    if (eth != null) ethnicity = eth;
    if (meno != null) {
      menopausal = meno;
      // Menopause clears reproductive flags
      if (meno) {
        pregnant = false;
        heavyMenstrualBleeding = false;
      }
    }
    if (preg != null) {
      pregnant = preg;
      // Pregnant women cannot menstruate
      if (preg) heavyMenstrualBleeding = false;
    }
    if (hmb != null) heavyMenstrualBleeding = hmb;
    if (pica != null) picaPresent = pica;
    if (malaria != null) malariaHistory = malaria;
    if (fatigue != null) chronicFatigue = fatigue;
    if (pal != null) pallor = pal;
    if (veg != null) vegetarianDiet = veg;
    if (prior != null) priorAnaemiaDiagnosis = prior;
    if (gloss != null) glossitis = gloss;
    notifyListeners();
  }

  void beginScanning() {
    step = ScanStep.scanConjunctiva;
    imageProbsList = [];
    errorMessage = null;
    notifyListeners();
  }

  Future<void> processImage(File imageFile) async {
    final modality = currentModality;
    step = ScanStep.processing;
    errorMessage = null;
    notifyListeners();

    try {
      final probs = await MlService.runInference(imageFile, modality);
      imageProbsList.add(probs);

      // Advance to next step
      _advanceStep();
    } catch (e) {
      errorMessage = e.toString();
      // Return to current camera step
      _revertToCurrentCamera();
    }
    notifyListeners();
  }

  void _advanceStep() {
    switch (step) {
      case ScanStep.processing:
        // Figure out which step we just completed based on imageProbsList length
        final count = imageProbsList.length;
        if (count == 1) {
          // Done conjunctiva → go to fingernail
          step = ScanStep.scanFingernail;
        } else if (count == 2) {
          if (requiresPalmScan) {
            step = ScanStep.scanPalm;
          } else {
            _finalizeResult();
          }
        } else if (count >= 3) {
          _finalizeResult();
        }
        break;
      default:
        break;
    }
  }

  void _revertToCurrentCamera() {
    final count = imageProbsList.length;
    if (count == 0)
      step = ScanStep.scanConjunctiva;
    else if (count == 1)
      step = ScanStep.scanFingernail;
    else
      step = ScanStep.scanPalm;
  }

  void _finalizeResult() {
    final fusion = FusionService.fuseRisk(imageProbsList, surveyData);
    result = ScanResult(
      modality: 'combined',
      imageProbsList: imageProbsList,
      survey: surveyData,
      finalRisk: fusion['finalRisk'] as RiskLevel,
      confidence: fusion['confidence'] as double,
      adjustedProbs: (fusion['adjustedProbs'] as Map).cast<String, double>(),
    );
    step = ScanStep.result;

    // Fire-and-forget backend sync
    ApiService.postResult(result!).then((ok) {
      isSynced = ok;
      notifyListeners();
    });
  }

  void reset() {
    step = ScanStep.survey;
    imageProbsList = [];
    result = null;
    errorMessage = null;
    isSynced = false;
    menopausal = false;
    pregnant = false;
    heavyMenstrualBleeding = false;
    picaPresent = false;
    malariaHistory = false;
    chronicFatigue = false;
    pallor = false;
    vegetarianDiet = false;
    priorAnaemiaDiagnosis = false;
    glossitis = false;
    notifyListeners();
  }
}
