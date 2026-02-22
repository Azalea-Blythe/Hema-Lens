import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../services/fusion_service.dart';

// ─── Shared Theme Palette (matches capture_screen.dart) ──────────────────────
const Color _kBgDark      = Color(0xFF0D1117);
const Color _kSurface     = Color(0xFF161B22);
const Color _kTeal        = Color(0xFF2DD4BF);
const Color _kAmber       = Color(0xFFFBBF24);
const Color _kRed         = Color(0xFFF87171); // Brighter red for dark mode
const Color _kSuccess     = Color(0xFF34D399); // Minty green
const Color _kTextPrimary = Color(0xFFF0F6FC);
const Color _kTextMuted   = Color(0xFF8B949E);

class ResultScreen extends StatefulWidget {
  final ScanResult result;
  const ResultScreen({super.key, required this.result});
  @override State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showBreakdown = false;

  @override
  void initState() {
    super.initState();
    _saveAndSync();
  }

  Future<void> _saveAndSync() async {
    await DatabaseService.insertResult(widget.result);
    try {
      await ApiService.postResult(widget.result);
    } catch (_) {}
  }

  Color get _themeColor {
    switch (widget.result.riskTier) {
      case 'High': return _kRed;
      case 'Moderate': return _kAmber;
      default: return _kSuccess;
    }
  }

  IconData get _riskIcon {
    switch (widget.result.riskTier) {
      case 'High': return Icons.warning_rounded;
      case 'Moderate': return Icons.info_outline_rounded;
      default: return Icons.check_circle_outline_rounded;
    }
  }

  String get _description {
    switch (widget.result.riskTier) {
      case 'High': return 'High probability of anaemia detected. Please consult a healthcare professional immediately.';
      case 'Moderate': return 'Moderate risk detected. Consider scheduling a routine checkup and blood test.';
      default: return 'Low risk detected. Maintain a healthy diet and monitor for symptoms.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final probs = widget.result.adjustedProbs;
    return Scaffold(
      backgroundColor: _kBgDark,
      appBar: AppBar(
        title: const Text('Analysis Result', style: TextStyle(fontWeight: FontWeight.bold, color: _kTextPrimary)),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // ── Risk Tier Hero Card ───────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _themeColor.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: _themeColor.withValues(alpha: 0.05), blurRadius: 40, spreadRadius: 8),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _themeColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_riskIcon, size: 70, color: _themeColor),
                  ),
                  const SizedBox(height: 24),
                  Text('${widget.result.riskTier} Risk',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: _themeColor, letterSpacing: -0.5)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _kBgDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_user_rounded, color: _kTeal, size: 16),
                        const SizedBox(width: 8),
                        Text('Confidence: ${(widget.result.confidence * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kTextPrimary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Probability Breakdown Card ────────────────────────────────────
            if (probs != null && probs.length == 3) ...[
              Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.bar_chart_rounded, color: _kTeal, size: 22),
                      SizedBox(width: 10),
                      Text('Probability Breakdown',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kTextPrimary)),
                    ]),
                    const SizedBox(height: 6),
                    const Text('Values reflect combined image and clinical data.',
                      style: TextStyle(fontSize: 13, color: _kTextMuted)),
                    const SizedBox(height: 24),
                    _ProbabilityBar(label: 'Low Risk',       value: probs[0], color: _kSuccess),
                    const SizedBox(height: 18),
                    _ProbabilityBar(label: 'Moderate Risk',  value: probs[1], color: _kAmber),
                    const SizedBox(height: 18),
                    _ProbabilityBar(label: 'High Risk',      value: probs[2], color: _kRed),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── "More Info" — Per-factor contribution breakdown ──────────────
            if (widget.result.factors != null && widget.result.factors!.isNotEmpty) ...[
              _buildFactorBreakdownCard(context),
              const SizedBox(height: 24),
            ],

            // ── Description Text ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: _kTextPrimary, height: 1.6, fontWeight: FontWeight.w500)),
            ),

            const SizedBox(height: 32),

            // ── Disclaimer Box ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_outlined, color: _kTextMuted),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'HemaLens is a screening tool. It is NOT a diagnostic device and does NOT replace '
                      'laboratory haemoglobin testing. Always refer to a doctor for formal evaluation.',
                      style: TextStyle(color: _kTextMuted, height: 1.5, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Primary Action Button ─────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kTeal,
                  foregroundColor: _kBgDark,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 6,
                  shadowColor: _kTeal.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 24),
                label: const Text('Start New Scan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  FACTOR BREAKDOWN CARD — expandable "More Info" section
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFactorBreakdownCard(BuildContext context) {
    final factors = widget.result.factors!;
    final rawProbs = widget.result.rawImageProbs;
    final surveyBoost = widget.result.totalSurveyBoost ?? 0.0;

    final imageContrib = (rawProbs != null && rawProbs.length == 3) ? rawProbs[2] : 0.0;
    final totalSignal = imageContrib + surveyBoost;

    // A subtle accent color for this specific card
    const Color accentColor = Color(0xFF818CF8); // Soft indigo

    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Tap to expand header ─────────────────────────────────
          InkWell(
            onTap: () => setState(() => _showBreakdown = !_showBreakdown),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.analytics_outlined, color: accentColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Risk Factor Breakdown',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _kTextPrimary)),
                        SizedBox(height: 4),
                        Text('See how each factor contributes',
                          style: TextStyle(fontSize: 13, color: _kTextMuted)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showBreakdown ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: _kTextMuted, size: 28),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable body ──────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 20),

                  // ── Image vs Survey summary chips ─────────────
                  if (totalSignal > 0) ...[
                    Row(children: [
                      _contributionChip(
                        '📷 Image Analysis',
                        imageContrib,
                        totalSignal,
                        const Color(0xFF38BDF8), // Light blue
                      ),
                      const SizedBox(width: 12),
                      _contributionChip(
                        '📋 Survey Factors',
                        surveyBoost,
                        totalSignal,
                        const Color(0xFFA78BFA), // Light purple
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  // ── Raw image probabilities ────────────────────
                  if (rawProbs != null && rawProbs.length == 3) ...[
                    _sectionHeader('Image Analysis (AI Model)'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kBgDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: Column(children: [
                        _miniProbRow('Low Risk',  rawProbs[0], _kSuccess),
                        const SizedBox(height: 12),
                        _miniProbRow('Moderate Risk', rawProbs[1], _kAmber),
                        const SizedBox(height: 12),
                        _miniProbRow('High Risk', rawProbs[2], _kRed),
                      ]),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Individual survey factor bars ───────────────
                  _sectionHeader('Survey Contributions'),
                  const SizedBox(height: 6),
                  Text(
                    surveyBoost == 0
                        ? 'No survey factors triggered a risk boost.'
                        : 'Each factor below adds to the high-risk probability.',
                    style: const TextStyle(fontSize: 13, color: _kTextMuted),
                  ),
                  const SizedBox(height: 16),

                  ...factors
                      .where((f) => f.category == 'survey')
                      .map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _factorRow(f, surveyBoost),
                          )),

                  if (factors.where((f) => f.category == 'survey').isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kSuccess.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(children: [
                        Icon(Icons.check_circle_rounded, color: _kSuccess, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No clinical risk factors identified. Risk is based purely on image analysis.',
                            style: TextStyle(color: _kSuccess, fontSize: 13.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ),
                ],
              ),
            ),
            crossFadeState: _showBreakdown ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _contributionChip(String label, double value, double total, Color color) {
    final pct = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            const SizedBox(height: 8),
            Text('$pct%',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
            const SizedBox(height: 2),
            Text('of total signal',
                style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Text(text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: _kTextPrimary));
  }

  Widget _miniProbRow(String label, double value, Color color) {
    final pct = (value * 100).toStringAsFixed(1);
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextPrimary)),
      const Spacer(),
      Text('$pct%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _factorRow(RiskFactor factor, double totalBoost) {
    final pctOfBoost = totalBoost > 0
        ? (factor.contribution / totalBoost * 100).toStringAsFixed(0)
        : '0';
    final rawPct = (factor.contribution * 100).toStringAsFixed(0);

    const Color c = Color(0xFFA78BFA);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _kBgDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(factor.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kTextPrimary)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('+$rawPct%',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c)),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 44,
          child: Text('$pctOfBoost%',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: _kTextMuted)),
        ),
      ]),
    );
  }
}

// ── Reusable probability bar row ──────────────────────────────────────────────
class _ProbabilityBar extends StatelessWidget {
  final String label;
  final double value; // 0.0 – 1.0
  final Color color;

  const _ProbabilityBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _kTextPrimary)),
            Text('$pct %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 12,
            color: color,
            backgroundColor: _kBgDark, // Dark background for the track
          ),
        ),
      ],
    );
  }
}
