// ScanResult holds the final output of one complete scan session.
class ScanResult {
  final int? id; // Auto-assigned by the database
  final String riskTier; // 'Low', 'Moderate', 'High'
  final double confidence;
  final Map<String, dynamic> surveyAnswers;
  final DateTime timestamp;
  final bool syncedToBackend;

  ScanResult({
    this.id,
    required this.riskTier,
    required this.confidence,
    required this.surveyAnswers,
    required this.timestamp,
    this.syncedToBackend = false,
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
