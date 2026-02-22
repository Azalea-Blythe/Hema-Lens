import '../models/survey_data.dart';

/// One individual factor that contributed to the risk boost.
class RiskFactor {
  final String label;       // Human-readable name
  final String category;    // 'image' or 'survey'
  final double contribution; // Raw boost amount (before normalisation)

  RiskFactor({required this.label, required this.category, required this.contribution});
}

class FusionResult {
  final String riskTier; // 'Low', 'Moderate', or 'High'
  final double confidence;
  final List<double> adjustedProbs;
  final List<double> rawImageProbs;   // Original model output [low, mod, high]
  final List<RiskFactor> factors;     // Per-factor contributions
  final double totalSurveyBoost;      // Sum of all survey boosts

  FusionResult({
    required this.riskTier,
    required this.confidence,
    required this.adjustedProbs,
    required this.rawImageProbs,
    required this.factors,
    required this.totalSurveyBoost,
  });
}

class FusionService {
  // Takes model output [low, mod, high] + survey, returns a FusionResult
  static FusionResult fuse(List<double> imageProbs, SurveyData survey) {
    double low  = imageProbs[0];
    double mod  = imageProbs[1];
    double high = imageProbs[2];

    // Track individual factor contributions
    final List<RiskFactor> factors = [];

    void addFactor(String label, double amount) {
      if (amount > 0) {
        factors.add(RiskFactor(label: label, category: 'survey', contribution: amount));
      }
    }

    // Apply WHO-grounded boosts to the HIGH channel
    double boost = 0.0;

    if (survey.isPregnant)       { const v = 0.15; boost += v; addFactor('Pregnant', v); }
    if (survey.hasHeavyBleeding) { const v = 0.15; boost += v; addFactor('Heavy Menstrual Bleeding', v); }
    if (survey.hasPica)          { const v = 0.12; boost += v; addFactor('Pica', v); }
    if (survey.hasSoreTongue)    { const v = 0.10; boost += v; addFactor('Sore / Smooth Tongue', v); }
    if (survey.hasMalariaHistory){ const v = 0.08; boost += v; addFactor('History of Malaria', v); }
    if (survey.hasFatigue && survey.hasPallor) {
      const v = 0.08; boost += v; addFactor('Fatigue + Pallor', v);
    }
    if (survey.isVegetarian)     { const v = 0.05; boost += v; addFactor('Vegetarian / Vegan Diet', v); }
    if (survey.hasPriorAnaemia)  { const v = 0.05; boost += v; addFactor('Prior Anaemia Diagnosis', v); }

    // Add image analysis as a factor
    factors.insert(0, RiskFactor(
      label: 'Image Analysis (AI model)',
      category: 'image',
      contribution: high, // the raw high-risk probability from the model
    ));

    // Redistribute: take boost from low & mod proportionally, add to high
    if (boost > 0 && (low + mod) > 0) {
      final available = low + mod;
      final effectiveBoost = boost.clamp(0.0, available);
      final ratio = effectiveBoost / available;
      low  -= low * ratio;
      mod  -= mod * ratio;
      high += effectiveBoost;
    }

    // Safety: clamp and renormalize so all three sum to 1.0
    low  = low.clamp(0.0, 1.0);
    mod  = mod.clamp(0.0, 1.0);
    high = high.clamp(0.0, 1.0);
    final total = low + mod + high;
    if (total > 0) { low /= total; mod /= total; high /= total; }

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
      rawImageProbs: List.unmodifiable(imageProbs),
      factors: factors,
      totalSurveyBoost: boost,
    );
  }
}
