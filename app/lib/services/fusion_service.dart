import '../models/survey_data.dart';

class FusionResult {
  final String riskTier; // 'Low', 'Moderate', or 'High'
  final double confidence;
  final List<double> adjustedProbs;

  FusionResult({required this.riskTier, required this.confidence, required this.adjustedProbs});
}

class FusionService {
  // Takes model output [low, mod, high] + survey, returns a FusionResult
  static FusionResult fuse(List<double> imageProbs, SurveyData survey) {
    double low = imageProbs[0];
    double mod = imageProbs[1];
    double high = imageProbs[2];

    // Apply WHO-grounded boosts to the HIGH channel
    double boost = 0.0;
    if (survey.isPregnant) { boost += 0.15; }
    if (survey.hasHeavyBleeding) { boost += 0.15; }
    if (survey.hasPica) { boost += 0.12; }
    if (survey.hasMalariaHistory) { boost += 0.08; }
    if (survey.hasFatigue && survey.hasPallor) { boost += 0.08; }
    if (survey.isVegetarian) { boost += 0.05; }
    if (survey.hasPriorAnaemia) { boost += 0.05; }

    // Apply the boost and clamp to [0,1]
    high = (high + boost).clamp(0.0, 1.0);

    // Renormalize all three so they sum to 1.0
    final total = low + mod + high;
    low /= total; mod /= total; high /= total;

    // Pick the tier with the highest probability
    final maxProb = [low, mod, high].reduce((a, b) => a > b ? a : b);
    String tier;
    if (high == maxProb) {
      tier = 'High';
    } else if (mod == maxProb) {
      tier = 'Moderate';
    } else {
      tier = 'Low';
    }

    return FusionResult(
      riskTier: tier,
      confidence: maxProb,
      adjustedProbs: [low, mod, high],
    );
  }
}
