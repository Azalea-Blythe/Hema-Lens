import '../models/scan_result.dart';

/// Dart port of ml/scripts/fusion.py — WHO guideline-based risk fusion.
class FusionService {
  static Map<String, dynamic> fuseRisk(
    List<ImageProbs> imageProbsList,
    SurveyData survey,
  ) {
    // Average probabilities across all scans provided
    final n = imageProbsList.isNotEmpty ? imageProbsList.length : 1;
    double lowProb = imageProbsList.fold(0.0, (sum, p) => sum + p.low) / n;
    double modProb = imageProbsList.fold(0.0, (sum, p) => sum + p.moderate) / n;
    double highProb = imageProbsList.fold(0.0, (sum, p) => sum + p.high) / n;

    // WHO guideline survey boost
    double surveyBoost = 0.0;
    if (survey.pregnant) surveyBoost += 0.15;
    if (survey.heavyMenstrualBleeding) surveyBoost += 0.15;
    if (survey.picaPresent) surveyBoost += 0.12;
    if (survey.glossitis) surveyBoost += 0.10; // Glossitis warning sign
    if (survey.malariaHistory) surveyBoost += 0.08;
    if (survey.chronicFatigue && survey.pallor) surveyBoost += 0.08;
    if (survey.vegetarianDiet) surveyBoost += 0.05;
    if (survey.priorAnaemiaDiagnosis) surveyBoost += 0.05;

    double adjustedHigh = (highProb + surveyBoost).clamp(0.0, 1.0);
    double remainder = 1.0 - adjustedHigh;
    double originalNonHigh = lowProb + modProb;

    double adjustedLow;
    double adjustedMod;

    if (originalNonHigh > 0) {
      adjustedLow = lowProb * (remainder / originalNonHigh);
      adjustedMod = modProb * (remainder / originalNonHigh);
    } else {
      adjustedLow = 0.0;
      adjustedMod = 0.0;
    }

    final adjustedProbs = {
      'low': adjustedLow,
      'moderate': adjustedMod,
      'high': adjustedHigh,
    };

    // argmax
    final finalRiskKey = adjustedProbs.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final confidence = adjustedProbs[finalRiskKey]!;

    RiskLevel finalRisk;
    switch (finalRiskKey) {
      case 'moderate':
        finalRisk = RiskLevel.moderate;
        break;
      case 'high':
        finalRisk = RiskLevel.high;
        break;
      default:
        finalRisk = RiskLevel.low;
    }

    return {
      'finalRisk': finalRisk,
      'confidence': confidence,
      'adjustedProbs': adjustedProbs,
    };
  }
}
