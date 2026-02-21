import 'package:flutter/material.dart';
import 'screens/disclaimer_screen.dart';

void main() {
  runApp(const HemaLensApp());
}

class HemaLensApp extends StatelessWidget {
  const HemaLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HemaLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Deep Indigo
          primary: const Color(0xFF283593),
          secondary: const Color(0xFFFF5252), // Vibrant accent
          surface: Colors.grey.shade50,
          background: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Inter', // Using Inter if available, fallback is system sans-serif
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A237E),
          iconTheme: IconThemeData(color: Color(0xFF1A237E)),
          titleTextStyle: TextStyle(color: Color(0xFF1A237E), fontSize: 20, fontWeight: FontWeight.w700),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF283593), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      home: const DisclaimerScreen(),
    );
  }
}
