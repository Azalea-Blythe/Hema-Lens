import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart';
import 'survey_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo + Brand
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D4AA), Color(0xFF0099FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HemaLens',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Anaemia Screening',
                        style: TextStyle(
                          color: Color(0xFF00D4AA),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 56),
              // Hero text
              const Text(
                'AI-Powered\nAnaemia Detection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Non-invasive screening using conjunctiva and fingernail analysis combined with WHO clinical guidelines.',
                style: TextStyle(
                  color: Color(0xFF6A7F8E),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 48),
              // How it works
              _StepBadge(n: 1, text: 'Complete a brief health survey'),
              const SizedBox(height: 14),
              _StepBadge(n: 2, text: 'Scan your conjunctiva (inner eyelid)'),
              const SizedBox(height: 14),
              _StepBadge(n: 3, text: 'Scan your fingernails'),
              const SizedBox(height: 14),
              _StepBadge(n: 4, text: 'Receive your risk assessment'),
              const Spacer(),
              // CTA
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<ScanProvider>().reset();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SurveyScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start Scan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Disclaimer
              const Text(
                'For screening only. Not a substitute for clinical diagnosis.',
                style: TextStyle(
                  color: Color(0xFF445566),
                  fontSize: 11,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int n;
  final String text;
  const _StepBadge({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF00D4AA).withAlpha(26),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00D4AA).withAlpha(77)),
          ),
          child: Center(
            child: Text(
              '$n',
              style: const TextStyle(
                color: Color(0xFF00D4AA),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(color: Color(0xFFCCDDEE), fontSize: 14),
        ),
      ],
    );
  }
}
