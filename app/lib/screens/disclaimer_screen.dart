import 'package:flutter/material.dart';
import 'survey_screen.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // Deep Indigo
              Color(0xFF311B92), // Deep Purple
              Color(0xFF000051), // Very dark blue
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bloodtype, color: Color(0xFFFF5252), size: 80),
                ),
                const SizedBox(height: 32),
                const Text('HemaLens', 
                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Text('AI-Based Anaemia Risk Screening',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  textAlign: TextAlign.center),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
                          const SizedBox(width: 12),
                          Text('DISCLAIMER', style: TextStyle(color: Colors.orange.shade300, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'HemaLens is a screening tool only. '
                        'It is NOT a diagnostic device and does NOT replace '
                        'laboratory haemoglobin testing. Always refer '
                        'high-risk individuals for formal medical evaluation.',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15, height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A237E),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (_) => const SurveyScreen())),
                    child: const Text('I Understand — Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
