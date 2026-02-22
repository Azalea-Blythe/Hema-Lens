import 'package:flutter/material.dart';
import '../models/survey_data.dart';
import 'home_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});
  @override State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _age = 25;
  String _sex = 'Female';
  bool _pregnant = false, _fatigue = false, _pallor = false;
  bool _pica = false, _soreTongue = false, _malaria = false, _bleeding = false;
  bool _vegetarian = false, _priorAnaemia = false;
  String _ethnicity = 'Brown/Indian';

  // Age thresholds for female-specific questions
  static const int _minAgeForMenstruation = 10;
  static const int _minAgeForPregnancy = 12;
  static const int _maxAgeForMenstruationAndPregnancy = 60;

  // Supported ethnicities (all shown, app blocks unsupported ones)
  static const supportedEthnicities = {'Brown/Indian', 'Black/Ghanian', 'White/Italian'};
  static const ethnicities = ['Brown/Indian', 'Black/Ghanian', 'White/Italian'];

  bool get _canShowPregnancy => _sex == 'Female' && _age >= _minAgeForPregnancy && _age <= _maxAgeForMenstruationAndPregnancy;
  bool get _canShowMenstruation => _sex == 'Female' && _age >= _minAgeForMenstruation && _age <= _maxAgeForMenstruationAndPregnancy;
  // Pregnant women do not menstruate
  bool get _canToggleBleeding => _canShowMenstruation && !_pregnant;
  // Pregnancy can only be selected if not already menstruating heavily
  bool get _canTogglePregnancy => _canShowPregnancy && !_bleeding;

  void _onAgeChanged(double v) {
    setState(() {
      _age = v.toInt();
      // Reset age-gated options if user is outside the valid age window
      if (_age < _minAgeForPregnancy || _age > _maxAgeForMenstruationAndPregnancy) _pregnant = false;
      if (_age < _minAgeForMenstruation || _age > _maxAgeForMenstruationAndPregnancy) _bleeding = false;
    });
  }

  void _onSexChanged(String sex) {
    setState(() {
      _sex = sex;
      if (_sex == 'Male') {
        _pregnant = false;
        _bleeding = false;
      }
    });
  }

  void _proceed() {
    final isBlocked = !supportedEthnicities.contains(_ethnicity);
    if (isBlocked) {
      showDialog(context: context, builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 12),
          Text('Scan Not Available'),
        ]),
        content: const Text(
          'Our AI is not yet calibrated for your ethnicity. '
          'We cannot safely proceed. Please seek traditional screening.',
          style: TextStyle(height: 1.5)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ));
      return;
    }
    final survey = SurveyData(
      age: _age, sex: _sex, isPregnant: _pregnant, hasFatigue: _fatigue,
      hasPallor: _pallor, hasPica: _pica, hasSoreTongue: _soreTongue,
      hasMalariaHistory: _malaria,
      hasHeavyBleeding: _bleeding, isVegetarian: _vegetarian,
      hasPriorAnaemia: _priorAnaemia, ethnicity: _ethnicity,
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => HomeScreen(survey: survey)));
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Health Survey')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text(
            'Please complete this brief survey. Your answers help calibrate the AI risk assessment.',
            style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5)),
          const SizedBox(height: 24),

          // ── DEMOGRAPHICS ─────────────────────────────────────────────────
          _buildCard(
            title: 'Demographics',
            icon: Icons.person_outline,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('Age'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$_age years', style: TextStyle(fontWeight: FontWeight.bold, color: primary)),
                  ),
                ],
              ),
              Slider(
                value: _age.toDouble(), min: 1, max: 100, divisions: 99,
                activeColor: primary,
                onChanged: _onAgeChanged,
              ),
              const SizedBox(height: 16),
              _label('Biological Sex'),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Female', label: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Female'))),
                    ButtonSegment(value: 'Male', label: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Male')))
                  ],
                  selected: {_sex},
                  onSelectionChanged: (s) => _onSexChanged(s.first),
                ),
              ),

              // ── Pregnancy (females aged ≥12 only) ────────────────────────
              if (_canShowPregnancy) ...[
                const SizedBox(height: 4),
                _check(
                  'Currently Pregnant',
                  _pregnant,
                  _canTogglePregnancy ? (v) => setState(() {
                    _pregnant = v!;
                    if (_pregnant) _bleeding = false; // mutually exclusive
                  }) : null,
                  lockedReason: _bleeding ? 'Disable "Heavy Menstrual Bleeding" first' : null,
                ),
              ],
            ]),
          ),

          // ── SYMPTOMS ─────────────────────────────────────────────────────
          _buildCard(
            title: 'Symptoms',
            icon: Icons.personal_injury_outlined,
            child: Column(children: [
              _check('Chronic Fatigue', _fatigue, (v) => setState(() => _fatigue = v!)),
              _check('Pallor (Paleness)', _pallor, (v) => setState(() => _pallor = v!)),
              _check('Pica (craving non-food items)', _pica, (v) => setState(() => _pica = v!)),
              _check(
                'Sore / Smooth Tongue',
                _soreTongue,
                (v) => setState(() => _soreTongue = v!),
                subtitle: 'Glossitis – WHO clinical sign of iron-deficiency anaemia',
              ),
            ]),
          ),

          // ── RISK FACTORS ─────────────────────────────────────────────────
          _buildCard(
            title: 'Risk Factors',
            icon: Icons.warning_amber_rounded,
            child: Column(children: [
              // Heavy menstrual bleeding (females ≥10 only, disabled if pregnant)
              if (_canShowMenstruation)
                _check(
                  'Heavy Menstrual Bleeding',
                  _bleeding,
                  _canToggleBleeding ? (v) => setState(() {
                    _bleeding = v!;
                    if (_bleeding) _pregnant = false; // mutually exclusive
                  }) : null,
                  lockedReason: _pregnant ? 'Pregnancy and menstruation are mutually exclusive' : null,
                ),
              _check('History of Malaria', _malaria, (v) => setState(() => _malaria = v!)),
              _check('Vegetarian / Vegan Diet', _vegetarian, (v) => setState(() => _vegetarian = v!)),
              _check('Prior Anaemia Diagnosis', _priorAnaemia, (v) => setState(() => _priorAnaemia = v!)),
            ]),
          ),

          // ── DEVICE & CALIBRATION ─────────────────────────────────────────
          _buildCard(
            title: 'Calibration',
            icon: Icons.settings_cell_outlined,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Ethnicity'),
              DropdownButtonFormField<String>(
                initialValue: _ethnicity,
                items: ethnicities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _ethnicity = v!),
              ),
              const SizedBox(height: 8),
              _infoChip('Only ethnicities present in our training data are shown.'),
            ]),
          ),

          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onPressed: _proceed,
            child: const Text('Continue to Scan Hub', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            ]),
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
            child,
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)));

  Widget _infoChip(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue.shade100),
    ),
    child: Row(children: [
      Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
      const SizedBox(width: 8),
      Expanded(child: Text(t, style: TextStyle(fontSize: 12, color: Colors.blue.shade700))),
    ]));

  Widget _check(String t, bool v, Function(bool?)? cb, {String? lockedReason, String? subtitle}) {
    final isLocked = cb == null;
    return Opacity(
      opacity: isLocked ? 0.45 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Text(t, style: const TextStyle(fontSize: 15)),
            value: v,
            onChanged: isLocked ? null : cb,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 6, top: 0),
              child: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500, fontStyle: FontStyle.italic)),
            ),
          if (isLocked && lockedReason != null)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 4),
              child: Text(lockedReason, style: TextStyle(fontSize: 11, color: Colors.orange.shade700, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}
