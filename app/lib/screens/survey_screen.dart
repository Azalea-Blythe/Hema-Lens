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
  bool _pica = false, _malaria = false, _bleeding = false;
  bool _vegetarian = false, _priorAnaemia = false;
  String _ethnicity = 'Asian/Indian';
  String _cameraQuality = 'High/Flagship';

  static const supportedEthnicities = {'Asian/Indian', 'Black/African', 'White/Caucasian'};
  static const ethnicities = ['Asian/Indian', 'Black/African', 'White/Caucasian', 'Hispanic/Latino', 'Other'];
  static const cameraQualities = ['High/Flagship', 'Medium', 'Low/Budget'];

  void _proceed() {
    // SAFETY GUARDRAIL: Block unsupported users
    final isBlocked = !supportedEthnicities.contains(_ethnicity) || _cameraQuality == 'Low/Budget';
    if (isBlocked) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('⚠️ Scan Not Available'),
        content: const Text(
          'Our AI is not yet calibrated for your ethnicity or camera quality. '
          'We cannot safely proceed. Please seek traditional screening.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ));
      return;
    }
    final survey = SurveyData(
      age: _age, sex: _sex, isPregnant: _pregnant, hasFatigue: _fatigue,
      hasPallor: _pallor, hasPica: _pica, hasMalariaHistory: _malaria,
      hasHeavyBleeding: _bleeding, isVegetarian: _vegetarian,
      hasPriorAnaemia: _priorAnaemia, ethnicity: _ethnicity,
      cameraQuality: _cameraQuality,
    );
    // Push HomeScreen on top of SurveyScreen. When user clicks "Calculate" on Home -> Result.
    // Result's "New Scan" will popUntil(isFirst) right back to this SurveyScreen.
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => HomeScreen(survey: survey)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Survey')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Please complete this brief survey. Your answers help calibrate the AI risk assessment.', 
            style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
          const SizedBox(height: 24),
          
          _buildCard(
            title: 'Demographics',
            icon: Icons.person_outline,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Age: $_age'),
              Slider(
                value: _age.toDouble(), min: 1, max: 100,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (v) => setState(() => _age = v.toInt())
              ),
              const SizedBox(height: 16),
              _label('Sex'),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Female', label: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Female'))),
                    ButtonSegment(value: 'Male', label: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Male')))
                  ],
                  selected: {_sex},
                  onSelectionChanged: (s) => setState(() { _sex = s.first; if (_sex == 'Male') _pregnant = false; }),
                ),
              ),
              if (_sex == 'Female') ...[
                const SizedBox(height: 8),
                _check('Currently Pregnant', _pregnant, (v) => setState(() => _pregnant = v!)),
              ],
            ]),
          ),
          
          _buildCard(
            title: 'Symptoms',
            icon: Icons.personal_injury_outlined,
            child: Column(children: [
              _check('Fatigue / Weakness', _fatigue, (v) => setState(() => _fatigue = v!)),
              _check('Pallor (Paleness)', _pallor, (v) => setState(() => _pallor = v!)),
              _check('Pica (craving dirt/ice)', _pica, (v) => setState(() => _pica = v!)),
            ]),
          ),
          
          _buildCard(
            title: 'Risk Factors',
            icon: Icons.warning_amber_rounded,
            child: Column(children: [
              _check('Heavy Menstrual Bleeding', _bleeding, (v) => setState(() => _bleeding = v!)),
              _check('History of Malaria', _malaria, (v) => setState(() => _malaria = v!)),
              _check('Vegetarian / Vegan Diet', _vegetarian, (v) => setState(() => _vegetarian = v!)),
              _check('Prior Anaemia Diagnosis', _priorAnaemia, (v) => setState(() => _priorAnaemia = v!)),
            ]),
          ),
          
          _buildCard(
            title: 'Device & Calibration',
            icon: Icons.settings_cell_outlined,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Ethnicity'),
              DropdownButtonFormField<String>(
                initialValue: _ethnicity, 
                items: ethnicities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _ethnicity = v!),
              ),
              const SizedBox(height: 20),
              _label('Camera Quality'),
              DropdownButtonFormField<String>(
                initialValue: _cameraQuality, 
                items: cameraQualities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _cameraQuality = v!),
              ),
            ]),
          ),
          
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ]),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)));
    
  Widget _check(String t, bool v, Function(bool?) cb) =>
    CheckboxListTile(
      title: Text(t, style: const TextStyle(fontSize: 15)), 
      value: v, 
      onChanged: cb, 
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -2),
    );
}
