class SurveyData {
  final String gender; // 'Male', 'Female'
  final int age;
  final String ethnicity;
  final bool menopausal;
  final bool pregnant;
  final bool heavyMenstrualBleeding;
  final bool picaPresent;
  final bool malariaHistory;
  final bool chronicFatigue;
  final bool pallor;
  final bool vegetarianDiet;
  final bool priorAnaemiaDiagnosis;
  // New symptoms
  final bool glossitis;

  const SurveyData({
    required this.gender,
    required this.age,
    required this.ethnicity,
    this.menopausal = false,
    this.pregnant = false,
    this.heavyMenstrualBleeding = false,
    this.picaPresent = false,
    this.malariaHistory = false,
    this.chronicFatigue = false,
    this.pallor = false,
    this.vegetarianDiet = false,
    this.priorAnaemiaDiagnosis = false,
    this.glossitis = false,
  });

  Map<String, dynamic> toMap() => {
    'pregnant': pregnant,
    'heavy_menstrual_bleeding': heavyMenstrualBleeding,
    'pica_present': picaPresent,
    'malaria_history': malariaHistory,
    'fatigue': chronicFatigue,
    'pallor': pallor,
    'vegetarian_diet': vegetarianDiet,
    'prior_anaemia_diagnosis': priorAnaemiaDiagnosis,
    'glossitis': glossitis,
  };

  // Supported ethnicities — exactly matching training dataset origins
  static const List<String> supportedEthnicities = [
    'Brown / Indian',
    'Black / Ghanaian',
    'Caucasian / Italian',
  ];

  // All ethnicities shown in the app
  static const List<String> allEthnicities = [
    'Brown / Indian',
    'Black / Ghanaian',
    'Caucasian / Italian',
    'Hispanic / Latino',
  ];

  bool get isEthnicitySupported => supportedEthnicities.contains(ethnicity);

  /// Palm scan only for Ghanaian patients (training data origin)
  bool get requiresPalmScan => ethnicity == 'Black / Ghanaian';

  /// Menopause toggle shown for females aged >= 45
  bool get showMenopauseToggle => gender == 'Female' && age >= 45;

  /// Pregnancy: non-menopausal females aged 12–55
  bool get showPregnancy =>
      gender == 'Female' && age >= 12 && age <= 55 && !menopausal;

  /// Menstrual bleeding: non-menopausal, non-pregnant females aged 12–55
  bool get showMenstrualBleeding =>
      gender == 'Female' && age >= 12 && age <= 55 && !menopausal && !pregnant;
}

class ImageProbs {
  final double low;
  final double moderate;
  final double high;
  final String modality;

  const ImageProbs({
    required this.low,
    required this.moderate,
    required this.high,
    required this.modality,
  });

  Map<String, double> toMap() => {
    'low': low,
    'moderate': moderate,
    'high': high,
  };
}

enum RiskLevel { low, moderate, high }

extension RiskLevelExt on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.moderate:
        return 'Moderate Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }

  String get emoji {
    switch (this) {
      case RiskLevel.low:
        return '🟢';
      case RiskLevel.moderate:
        return '🟡';
      case RiskLevel.high:
        return '🔴';
    }
  }
}

class ScanResult {
  final String modality;
  final List<ImageProbs> imageProbsList;
  final SurveyData survey;
  final RiskLevel finalRisk;
  final double confidence;
  final Map<String, double> adjustedProbs;

  const ScanResult({
    required this.modality,
    required this.imageProbsList,
    required this.survey,
    required this.finalRisk,
    required this.confidence,
    required this.adjustedProbs,
  });

  Map<String, dynamic> toApiPayload() => {
    'modality': modality,
    'image_probs_list': imageProbsList.map((p) => p.toMap()).toList(),
    'survey': survey.toMap(),
    'final_risk': finalRisk.name,
    'confidence': confidence,
  };
}
