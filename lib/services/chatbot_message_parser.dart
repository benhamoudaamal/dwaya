List<Map<String, String>> parseChatbotMessages(dynamic rawMessages) {
  if (rawMessages is! List) {
    return <Map<String, String>>[];
  }

  return rawMessages
      .whereType<Map>()
      .map((entry) {
        final user = entry['user'];
        final bot = entry['bot'];

        if (user is String && user.isNotEmpty) {
          return <String, String>{'user': user};
        }

        if (bot is String && bot.isNotEmpty) {
          return <String, String>{'bot': bot};
        }

        return <String, String>{};
      })
      .where((message) => message.isNotEmpty)
      .toList();
}
