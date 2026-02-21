import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final ScanResult result;
  const ResultScreen({super.key, required this.result});
  @override State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    _saveAndSync();
  }

  Future<void> _saveAndSync() async {
    await DatabaseService.insertResult(widget.result);
    // Ignore API errors gracefully in the background
    try {
      await ApiService.postResult(widget.result);
    } catch (_) {}
  }

  Color get _themeColor {
    switch (widget.result.riskTier) {
      case 'High': return const Color(0xFFD32F2F);   // Red
      case 'Moderate': return const Color(0xFFF57C00); // Orange
      default: return const Color(0xFF388E3C);       // Green
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false, // Force user to use the "New Scan" button
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Risk Tier Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: _themeColor.withOpacity(0.2), width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _themeColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_riskIcon, size: 80, color: _themeColor),
                  ),
                  const SizedBox(height: 24),
                  Text('${widget.result.riskTier} Risk', 
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: _themeColor, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Text('Confidence: ${(widget.result.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Description Text
            Text(_description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade800, height: 1.5, fontWeight: FontWeight.w500)),
              
            const SizedBox(height: 48),

            // Disclaimer Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_outlined, color: Colors.grey.shade600),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'HemaLens is a screening tool. It is NOT a diagnostic device and does NOT replace '
                      'laboratory haemoglobin testing. Always refer to a doctor for formal evaluation.',
                      style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
            
            // Primary Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.refresh, size: 24),
                label: const Text('Start New Scan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
