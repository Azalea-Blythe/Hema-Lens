import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../models/scan_result.dart';
import 'capture_screen.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ScanProvider>();
    _ageController.text = provider.age.toString();
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Health Survey',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Consumer<ScanProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Progress bar
              LinearProgressIndicator(
                value: 0.25,
                backgroundColor: const Color(0xFF1A2A3A),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF00D4AA)),
                minHeight: 3,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Step 1 of 4',
                        style: TextStyle(
                          color: Color(0xFF00D4AA),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'About You',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'This information adjusts the AI risk model to your profile.',
                        style: TextStyle(
                          color: Color(0xFF6A7F8E),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── IDENTITY ───────────────────────────────────────────
                      _sectionHeader('Identity'),
                      const SizedBox(height: 12),

                      // Gender selector
                      _label('Biological Sex'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _GenderChip(
                            label: 'Male',
                            icon: Icons.male_rounded,
                            selected: provider.gender == 'Male',
                            onTap: () {
                              provider.updateSurvey(gen: 'Male');
                              // Reset female-specific flags
                              provider.updateSurvey(preg: false, hmb: false);
                            },
                          ),
                          const SizedBox(width: 10),
                          _GenderChip(
                            label: 'Female',
                            icon: Icons.female_rounded,
                            selected: provider.gender == 'Female',
                            onTap: () => provider.updateSurvey(gen: 'Female'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Age
                      _label('Age'),
                      const SizedBox(height: 8),
                      _TextField(
                        controller: _ageController,
                        hint: 'Enter your age',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0 && parsed < 120) {
                            provider.updateSurvey(ag: parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 18),

                      // Ethnicity
                      _label('Ethnicity'),
                      const SizedBox(height: 8),
                      _DropdownCard(
                        value: provider.ethnicity,
                        items: SurveyData.allEthnicities,
                        onChanged: (v) => provider.updateSurvey(eth: v),
                      ),
                      if (!provider.surveyData.isEthnicitySupported) ...[
                        const SizedBox(height: 8),
                        _WarningBanner(
                          text:
                              '⚠ Our AI model is not yet validated for this ethnicity. Proceeding may give inaccurate results.',
                        ),
                      ],
                      const SizedBox(height: 18),

                      // Camera quality
                      _label('Camera Quality'),
                      const SizedBox(height: 8),
                      _DropdownCard(
                        value: provider.cameraQuality,
                        items: const [
                          'High / Flagship',
                          'Medium',
                          'Low / Budget',
                        ],
                        onChanged: (v) => provider.updateSurvey(camQ: v),
                      ),
                      if (!provider.surveyData.isCameraQualityOk) ...[
                        const SizedBox(height: 8),
                        _WarningBanner(
                          text:
                              '⚠ Low-quality cameras may give inaccurate colour readings.',
                        ),
                      ],
                      const SizedBox(height: 30),

                      // ── RISK FACTORS ────────────────────────────────────────
                      _sectionHeader('Risk Factors'),
                      const SizedBox(height: 12),

                      // Menopause toggle (females 45+)
                      if (provider.surveyData.showMenopauseToggle) ...[
                        _CheckTile(
                          label: 'Menopausal / Post-menopausal',
                          sublabel: 'Hides pregnancy & menstruation fields',
                          icon: Icons.elderly_woman_rounded,
                          value: provider.menopausal,
                          color: const Color(0xFFB0A0FF),
                          onChanged: (v) => provider.updateSurvey(meno: v),
                        ),
                      ],

                      // Pregnancy (female, age 12–55, not menopausal)
                      if (provider.surveyData.showPregnancy) ...[
                        _CheckTile(
                          label: 'Currently pregnant',
                          sublabel: '+15% high-risk weight',
                          icon: Icons.pregnant_woman_rounded,
                          value: provider.pregnant,
                          color: const Color(0xFF9C6FFF),
                          onChanged: (v) => provider.updateSurvey(preg: v),
                        ),
                      ],

                      // HMB (female, age >= 12, not pregnant)
                      if (provider.surveyData.showMenstrualBleeding) ...[
                        _CheckTile(
                          label: 'Heavy menstrual bleeding',
                          sublabel: '+15% high-risk weight',
                          icon: Icons.water_drop_rounded,
                          value: provider.heavyMenstrualBleeding,
                          color: const Color(0xFFFF6B9D),
                          onChanged: (v) => provider.updateSurvey(hmb: v),
                        ),
                      ],

                      _CheckTile(
                        label: 'Pica',
                        sublabel:
                            'Craving non-food items (dirt, clay, ice) — +12%',
                        icon: Icons.restaurant_menu_rounded,
                        value: provider.picaPresent,
                        color: const Color(0xFFFFB347),
                        onChanged: (v) => provider.updateSurvey(pica: v),
                      ),
                      _CheckTile(
                        label: 'History of malaria',
                        sublabel: '+8% high-risk weight',
                        icon: Icons.bug_report_rounded,
                        value: provider.malariaHistory,
                        color: const Color(0xFFFF6B6B),
                        onChanged: (v) => provider.updateSurvey(malaria: v),
                      ),
                      _CheckTile(
                        label: 'Vegetarian / vegan diet',
                        sublabel: 'Low iron/B12 intake — +5%',
                        icon: Icons.eco_rounded,
                        value: provider.vegetarianDiet,
                        color: const Color(0xFF4CAF50),
                        onChanged: (v) => provider.updateSurvey(veg: v),
                      ),
                      _CheckTile(
                        label: 'Previously diagnosed with anaemia',
                        sublabel: '+5% high-risk weight',
                        icon: Icons.medical_services_rounded,
                        value: provider.priorAnaemiaDiagnosis,
                        color: const Color(0xFF0099FF),
                        onChanged: (v) => provider.updateSurvey(prior: v),
                      ),
                      const SizedBox(height: 30),

                      // ── SYMPTOMS ────────────────────────────────────────────
                      _sectionHeader('Current Symptoms'),
                      const SizedBox(height: 12),
                      _CheckTile(
                        label: 'Chronic fatigue',
                        sublabel: 'Combined with pallor: +8%',
                        icon: Icons.battery_2_bar_rounded,
                        value: provider.chronicFatigue,
                        color: const Color(0xFFFFA500),
                        onChanged: (v) => provider.updateSurvey(fatigue: v),
                      ),
                      _CheckTile(
                        label: 'Pallor',
                        sublabel: 'Pale skin, lips, or gums',
                        icon: Icons.face_rounded,
                        value: provider.pallor,
                        color: const Color(0xFFC8A8FF),
                        onChanged: (v) => provider.updateSurvey(pal: v),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
              // ── STICKY FOOTER ───────────────────────────────────────────────
              Container(
                color: const Color(0xFF0A1628),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _onContinue(context, provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continue to Scan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF00D4AA),
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFFCCDDEE),
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  void _onContinue(BuildContext context, ScanProvider provider) {
    // Validate age
    final parsedAge = int.tryParse(_ageController.text);
    if (parsedAge == null || parsedAge < 1 || parsedAge >= 120) {
      _showDialog(
        context,
        'Invalid Age',
        'Please enter a valid age between 1 and 119.',
      );
      return;
    }

    final survey = provider.surveyData;

    if (!survey.isEthnicitySupported) {
      _showBlockingDialog(
        context,
        'Ethnicity Not Validated',
        'Our AI model is currently only validated for Indian Subcontinent, Black/African, and White/Caucasian populations. Results for other groups may be unreliable.\n\nProceed with caution or seek traditional clinical screening.',
        proceedLabel: 'Proceed Anyway',
        onProceed: () {
          Navigator.pop(context);
          _goToScan(context, provider);
        },
      );
      return;
    }

    if (!survey.isCameraQualityOk) {
      _showBlockingDialog(
        context,
        'Low Camera Quality',
        'A low-quality camera may produce inaccurate colour readings, leading to dangerous misdiagnosis. Please use a higher-quality device or seek clinical screening.',
      );
      return;
    }

    _goToScan(context, provider);
  }

  void _goToScan(BuildContext context, ScanProvider provider) {
    provider.beginScanning();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
  }

  void _showDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => _AlertBox(title: title, message: message),
    );
  }

  void _showBlockingDialog(
    BuildContext context,
    String title,
    String message, {
    String? proceedLabel,
    VoidCallback? onProceed,
  }) {
    showDialog(
      context: context,
      builder: (_) => _AlertBox(
        title: title,
        message: message,
        proceedLabel: proceedLabel,
        onProceed: onProceed,
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _GenderChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF00D4AA).withAlpha(26)
                : const Color(0xFF1A2A3A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF00D4AA)
                  : const Color(0xFF2A3A4A),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFF556677),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF8899AA),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;
  final ValueChanged<String> onChanged;
  const _TextField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.inputFormatters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF445566)),
        filled: true,
        fillColor: const Color(0xFF1A2A3A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3A4A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A3A4A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownCard extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropdownCard({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3A4A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1A2A3A),
          iconEnabledColor: const Color(0xFF00D4AA),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;
  const _CheckTile({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: value ? color.withAlpha(20) : const Color(0xFF1A2A3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? color.withAlpha(100) : const Color(0xFF2A3A4A),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: value ? color.withAlpha(30) : const Color(0xFF0F1F2E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: value ? color : const Color(0xFF445566),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: value ? Colors.white : const Color(0xFFAABBCC),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      color: Color(0xFF556677),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? color : const Color(0xFF334455),
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.black,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String text;
  const _WarningBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB347).withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFB347).withAlpha(80)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFFFB347),
          fontSize: 12,
          height: 1.4,
        ),
      ),
    );
  }
}

class _AlertBox extends StatelessWidget {
  final String title;
  final String message;
  final String? proceedLabel;
  final VoidCallback? onProceed;
  const _AlertBox({
    required this.title,
    required this.message,
    this.proceedLabel,
    this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A2A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFFFB347),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(color: Color(0xFF8899AA), height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF8899AA)),
          ),
        ),
        if (proceedLabel != null)
          TextButton(
            onPressed: onProceed,
            child: Text(
              proceedLabel!,
              style: const TextStyle(color: Color(0xFF00D4AA)),
            ),
          ),
        if (proceedLabel == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00D4AA))),
          ),
      ],
    );
  }
}
