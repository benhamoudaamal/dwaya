import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/chatbot_message_parser.dart';
import '../services/gemini_service.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  List<Map<String, String>> messages = [];
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String getBotReply(String text) {
    text = text.toLowerCase();
    if (text.contains('bonjour')) {
      return 'Bonjour 😊 comment puis-je vous aider ?';
    } else if (text.contains('medicament') || text.contains('médicament')) {
      return '💊 Prenez vos médicaments à l\'heure prescrite. Consultez votre médecin si nécessaire.';
    } else if (text.contains('douleur')) {
      return 'Si vous avez une douleur persistante, consultez un professionnel de santé 👨‍⚕️.';
    } else if (text.contains('merci')) {
      return 'De rien 😊 Je suis là pour vous aider !';
    }
    return 'Je suis votre assistant médical Dwaya 🏥. Posez-moi vos questions sur vos symptômes ou traitements.';
  }

  Future<void> loadMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('chatbot_messages')
        .doc(currentUser.uid)
        .get();

    if (!mounted) return;

    if (doc.exists && doc['messages'] != null) {
      setState(() {
        messages = parseChatbotMessages(doc['messages']);
      });
      _scrollToBottom();
    }
  }

  Future<void> saveMessagesToFirebase() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('chatbot_messages')
        .doc(currentUser.uid)
        .set({'messages': messages});
  }

  Future<void> clearMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    await FirebaseFirestore.instance
        .collection('chatbot_messages')
        .doc(currentUser.uid)
        .delete();

    setState(() => messages.clear());
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() {
      isSending = true;
      messages.add({'user': text});
    });

    controller.clear();
    _scrollToBottom();

    try {
      final botReply = await _geminiService.getReply(userMessage: text);
      if (!mounted) return;
      setState(() => messages.add({'bot': botReply}));
    } catch (_) {
      if (!mounted) return;
      setState(() => messages.add({'bot': getBotReply(text)}));
    } finally {
      if (!mounted) return;
      setState(() => isSending = false);
      _scrollToBottom();
      await saveMessagesToFirebase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FF),
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Text('🤖', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ChatBot Médical',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('En ligne',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Effacer la conversation',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Effacer ?'),
                  content: const Text(
                      'Voulez-vous effacer toute la conversation ?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Non')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Oui',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) await clearMessages();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 💬 Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        const Text(
                          'Bonjour ! Comment puis-je\nvous aider aujourd\'hui ?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        _quickQuestion('💊 Mes médicaments'),
                        _quickQuestion('🩺 Symptômes'),
                        _quickQuestion('📅 Mon traitement'),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length + (isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Typing indicator
                      if (index == messages.length) {
                        return _typingIndicator();
                      }
                      final msg = messages[index];
                      final isUser = msg.containsKey('user');
                      return _messageBubble(
                        text: isUser ? msg['user']! : msg['bot']!,
                        isUser: isUser,
                      );
                    },
                  ),
          ),

          // ✍️ Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3))
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F6FF),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message...',
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: isSending ? null : sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSending ? Colors.grey : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageBubble({required String text, required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.green : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14.5,
          ),
        ),
      ),
    );
  }

  Widget _typingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06), blurRadius: 6)
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(delay: 0),
            SizedBox(width: 4),
            _Dot(delay: 200),
            SizedBox(width: 4),
            _Dot(delay: 400),
          ],
        ),
      ),
    );
  }

  Widget _quickQuestion(String text) {
    return GestureDetector(
      onTap: () {
        controller.text = text;
        sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.green, fontSize: 13)),
      ),
    );
  }
}

// Animated typing dot
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(widget.delay / 600, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            color: Colors.green, shape: BoxShape.circle),
      ),
    );
  }
}