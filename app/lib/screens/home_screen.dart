import 'package:flutter/material.dart';
import '../models/survey_data.dart';
import '../models/scan_result.dart';
import '../services/fusion_service.dart';
import 'capture_screen.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  final SurveyData survey;
  const HomeScreen({super.key, required this.survey});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<double>? _conjunctivaProbs;
  List<double>? _nailbedProbs;
  bool _isCalculating = false;

  Future<void> _startScan(String target) async {
    // Navigate to capture screen and wait for it to pop back with probabilities
    final probs = await Navigator.push<List<double>>(
      context,
      MaterialPageRoute(builder: (_) => CaptureScreen(scanTarget: target)),
    );

    if (probs != null && mounted) {
      setState(() {
        if (target == 'conjunctiva') {
          _conjunctivaProbs = probs;
        } else if (target == 'fingernail') {
          _nailbedProbs = probs;
        }
      });
    }
  }

  void _calculateResult() {
    if (_conjunctivaProbs == null || _nailbedProbs == null) return;
    
    setState(() => _isCalculating = true);
    
    // Average both sets of probs
    final combined = [
      (_conjunctivaProbs![0] + _nailbedProbs![0]) / 2,
      (_conjunctivaProbs![1] + _nailbedProbs![1]) / 2,
      (_conjunctivaProbs![2] + _nailbedProbs![2]) / 2,
    ];

    final fusion = FusionService.fuse(combined, widget.survey);
    final result = ScanResult(
      riskTier: fusion.riskTier,
      confidence: fusion.confidence,
      surveyAnswers: widget.survey.toMap(),
      timestamp: DateTime.now(),
      adjustedProbs: fusion.adjustedProbs,
      factors: fusion.factors,
      rawImageProbs: fusion.rawImageProbs,
      totalSurveyBoost: fusion.totalSurveyBoost,
    );

    setState(() => _isCalculating = false);
    
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ResultScreen(result: result)));
  }

  @override
  Widget build(BuildContext context) {
    final bool bothDone = _conjunctivaProbs != null && _nailbedProbs != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistoryScreen())),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Select an area to scan', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            const SizedBox(height: 12),
            const Text(
              'Both areas must be photographed to accurately calculate your risk level. You can do this in any order.',
              style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 15),
            ),
            const SizedBox(height: 40),
            
            _ScanOptionCard(
              title: 'Conjunctiva',
              subtitle: 'Inner lower eyelid',
              icon: '👁️',
              isCompleted: _conjunctivaProbs != null,
              onTap: () => _startScan('conjunctiva'),
            ),
            
            const SizedBox(height: 20),
            
            _ScanOptionCard(
              title: 'Nailbed',
              subtitle: 'Fingernail pallor',
              icon: '💅',
              isCompleted: _nailbedProbs != null,
              onTap: () => _startScan('fingernail'),
            ),
            
            const Spacer(),
            
            AnimatedOpacity(
              opacity: bothDone ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !bothDone || _isCalculating,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 8,
                      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    onPressed: _calculateResult,
                    child: _isCalculating 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('Calculate Risk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  final String title, subtitle, icon;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ScanOptionCard({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.isCompleted, 
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isCompleted ? 1 : 4,
      color: isCompleted ? Colors.green.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isCompleted ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.shade100 : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(icon, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                )
              else
                Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
