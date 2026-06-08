import 'dart:convert';
import 'env.dart';
import 'package:http/http.dart' as http;

class GeminiServiceException implements Exception {
  GeminiServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GeminiService {
  final String _apiKey = Env.geminiKey;
static const String _endpoint =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> getReply({required String userMessage}) async {
    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Tu es un assistant medical Dwaya. Reponds en francais ou arabe, concis, sans diagnostic ni prescription. Message: $userMessage'
                }
              ]
            }
          ]
        }),
      );

      print("📡 STATUS = ${response.statusCode}");
      print("📦 BODY = ${response.body}");

      if (response.statusCode != 200) {
        throw GeminiServiceException(
            'Gemini erreur ${response.statusCode}: ${response.body}');
      }

      final decoded = jsonDecode(response.body);
      return decoded['candidates'][0]['content']['parts'][0]['text'].trim();
    } catch (e) {
      print("❌ GEMINI ERROR: $e");
      if (e is GeminiServiceException) rethrow;
      throw GeminiServiceException('Erreur réseau: $e');
    }
  }
}