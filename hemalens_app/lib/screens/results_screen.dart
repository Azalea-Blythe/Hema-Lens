import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import '../models/scan_result.dart';
import 'home_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScanProvider>();
    final result = provider.result;

    if (result == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A1628),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
        ),
      );
    }

    final risk = result.finalRisk;
    final color = _riskColor(risk);
    final confidence = (result.confidence * 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Scan Result',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            // Risk card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withAlpha(51), color.withAlpha(13)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: color.withAlpha(128), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(risk.emoji, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    risk.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Confidence: $confidence%',
                    style: const TextStyle(
                      color: Color(0xFF8899AA),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Confidence bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: result.confidence,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF1A2A3A),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Probability breakdown
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A3A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A3A4A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PROBABILITY BREAKDOWN',
                    style: TextStyle(
                      color: Color(0xFF00D4AA),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProbBar(
                    label: 'Low Risk',
                    value: result.adjustedProbs['low'] ?? 0,
                    color: const Color(0xFF00D4AA),
                  ),
                  const SizedBox(height: 10),
                  _ProbBar(
                    label: 'Moderate Risk',
                    value: result.adjustedProbs['moderate'] ?? 0,
                    color: const Color(0xFFFFB347),
                  ),
                  const SizedBox(height: 10),
                  _ProbBar(
                    label: 'High Risk',
                    value: result.adjustedProbs['high'] ?? 0,
                    color: const Color(0xFFFF6B6B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Modality + sync badge
            Row(
              children: [
                _InfoBadge(
                  label: 'Scans Analysed',
                  value:
                      '${result.imageProbsList.length} image${result.imageProbsList.length > 1 ? "s" : ""}',
                  icon: Icons.biotech_rounded,
                ),
                const SizedBox(width: 12),
                _InfoBadge(
                  label: 'Synced',
                  value: provider.isSynced ? 'Yes' : 'Offline',
                  icon: provider.isSynced
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  valueColor: provider.isSynced
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFF8899AA),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Referral CTA if high risk
            if (risk == RiskLevel.high) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withAlpha(26),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF6B6B).withAlpha(128),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      color: Color(0xFFFF6B6B),
                      size: 28,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'High risk detected. Please visit a healthcare provider for a blood test (CBC) as soon as possible.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Disclaimer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3A4A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF8899AA), size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This result is for screening purposes only and is not a medical diagnosis. Consult a qualified healthcare professional before making any health decisions.',
                      style: TextStyle(
                        color: Color(0xFF8899AA),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Scan again button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  provider.reset();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'New Scan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _riskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:
        return const Color(0xFF00D4AA);
      case RiskLevel.moderate:
        return const Color(0xFFFFB347);
      case RiskLevel.high:
        return const Color(0xFFFF6B6B);
    }
  }
}

class _ProbBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProbBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toStringAsFixed(1);
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF8899AA), fontSize: 13),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFF0A1628),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$pct%',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoBadge({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A3A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A3A4A)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF556677), size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF556677),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
