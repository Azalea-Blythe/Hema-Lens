import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';

class ApiService {
  // Replace with your Railway URL once the backend is deployed
  static const String _baseUrl = 'https://your-railway-url.up.railway.app';

  static Future<bool> postResult(ScanResult result) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'risk_tier': result.riskTier,
          'confidence': result.confidence,
          'survey': result.surveyAnswers,
          'timestamp': result.timestamp.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      // No internet — silently fail, we already saved locally
      return false;
    }
  }
}
