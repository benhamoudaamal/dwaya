import 'package:dwaya/services/chatbot_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses stored Firestore messages safely from dynamic maps', () {
    final parsed = parseChatbotMessages([
      {'user': 'Bonjour'},
      {'bot': 'Bonjour 😊'},
      {'user': 123},
      {'bot': null},
    ]);

    expect(parsed, [
      {'user': 'Bonjour'},
      {'bot': 'Bonjour 😊'},
    ]);
  });
}
