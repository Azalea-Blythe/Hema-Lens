import '../services/fusion_service.dart';

// ScanResult holds the final output of one complete scan session.
class ScanResult {
  final int? id; // Auto-assigned by the database
  final String riskTier; // 'Low', 'Moderate', 'High'
  final double confidence;
  final Map<String, dynamic> surveyAnswers;
  final DateTime timestamp;
  final bool syncedToBackend;
  // [low, moderate, high] probabilities after fusion — for visualisation only
  final List<double>? adjustedProbs;
  // Per-factor risk breakdown (image + survey contributions)
  final List<RiskFactor>? factors;
  final List<double>? rawImageProbs;
  final double? totalSurveyBoost;

  ScanResult({
    this.id,
    required this.riskTier,
    required this.confidence,
    required this.surveyAnswers,
    required this.timestamp,
    this.syncedToBackend = false,
    this.adjustedProbs,
    this.factors,
    this.rawImageProbs,
    this.totalSurveyBoost,
  });

  Map<String, dynamic> toMap() {
    return {
      'risk_tier': riskTier, 'confidence': confidence,
      'survey_json': surveyAnswers.toString(),
      'timestamp': timestamp.toIso8601String(),
      'synced': syncedToBackend ? 1 : 0,
    };
  }
}
