import 'dart:convert';

import 'package:dwaya/services/openai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('returns the assistant content from the OpenAI response', () async {
    final service = OpenAIService(
      apiKey: 'test-key',
      post: (
        Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': 'Réponse sécurisée du chatbot.',
                },
              },
            ],
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      },
    );

    final reply = await service.getReply(userMessage: 'Bonjour');

    expect(reply, 'Réponse sécurisée du chatbot.');
  });
}
