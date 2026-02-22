// SurveyData holds everything collected from the user in the survey screen.
class SurveyData {
  final int age;
  final String sex; // 'Male' or 'Female'
  final bool isPregnant;
  final bool hasFatigue;
  final bool hasPallor;
  final bool hasPica;
  final bool hasSoreTongue; // Glossitis – WHO clinical sign of iron-deficiency anaemia
  final bool hasMalariaHistory;
  final bool hasHeavyBleeding;
  final bool isVegetarian;
  final bool hasPriorAnaemia;
  final String ethnicity; // e.g., 'Brown/Indian'

  SurveyData({
    required this.age,
    required this.sex,
    required this.isPregnant,
    required this.hasFatigue,
    required this.hasPallor,
    required this.hasPica,
    required this.hasSoreTongue,
    required this.hasMalariaHistory,
    required this.hasHeavyBleeding,
    required this.isVegetarian,
    required this.hasPriorAnaemia,
    required this.ethnicity,
  });

  // Converts to a Map so we can save it to the database
  Map<String, dynamic> toMap() {
    return {
      'age': age, 'sex': sex, 'is_pregnant': isPregnant ? 1 : 0,
      'has_fatigue': hasFatigue ? 1 : 0, 'has_pallor': hasPallor ? 1 : 0,
      'has_pica': hasPica ? 1 : 0, 'has_sore_tongue': hasSoreTongue ? 1 : 0,
      'has_malaria': hasMalariaHistory ? 1 : 0,
      'has_bleeding': hasHeavyBleeding ? 1 : 0, 'is_vegetarian': isVegetarian ? 1 : 0,
      'prior_anaemia': hasPriorAnaemia ? 1 : 0, 'ethnicity': ethnicity,
    };
  }
}
