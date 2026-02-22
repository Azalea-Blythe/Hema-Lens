import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/scan_result.dart';

class ApiService {
  // Production Railway URL
  static const String _baseUrl = 'https://hema-lens-production.up.railway.app';

  static Future<bool> postResult(ScanResult result) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/results'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(result.toApiPayload()),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (_) {
      // Backend is optional — fail silently so the app still works offline
      return false;
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
