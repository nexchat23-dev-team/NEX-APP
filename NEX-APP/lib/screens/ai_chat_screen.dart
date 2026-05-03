import 'package:flutter/material.dart';
import '../main.dart';

class AIChatScreen extends StatefulWidget {
  static const routeName = '/ai-chat';
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content': 'Hello! I\'m NEX AI, your AI assistant. How can I help you today?',
      'time': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': message,
        'time': DateTime.now().toIso8601String(),
      });
      _isLoading = true;
    });

    _messageController.clear();

    await Future.delayed(const Duration(seconds: 1));
    
    String aiResponse = _getAIResponse(message);
    
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': aiResponse,
        'time': DateTime.now().toIso8601String(),
      });
      _isLoading = false;
    });
  }

  String _getAIResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi')) {
      return 'Hello! I\'m NEX AI, here to help you with any questions or tasks you have. What would you like to know?';
    } else if (lowerMessage.contains('token') || lowerMessage.contains('balance')) {
      return 'You can check your token balance in the home screen or in your profile settings. Tokens can be used for premium features, marketplace purchases, and betting games.';
    } else if (lowerMessage.contains('bet') || lowerMessage.contains('game')) {
      return 'NEX-APP offers several exciting games: Aviator (crash game), Mines (mine avoidance), and Spin Wheel (luck-based). Visit the Bet screen to try them!';
    } else if (lowerMessage.contains('chat') || lowerMessage.contains('message')) {
      return 'You can start a new chat by tapping the chat button on the home screen. You can also create group chats and send messages to your contacts.';
    } else if (lowerMessage.contains('help')) {
      return 'I can help you with:\n• App features and navigation\n• Token and balance questions\n• Chat and messaging\n• Betting and games\n• Account settings\n• And more!\n\nJust ask me anything.';
    } else if (lowerMessage.contains('feature')) {
      return 'NEX-APP includes:\n• Real-time chat messaging\n• Group chats\n• Voice and video calls\n• Betting games (Aviator, Mines, Spin Wheel)\n• Marketplace for token packs\n• User profiles\n• AI assistant\n• And much more!';
    } else {
      return 'I understand you\'re asking about "$message". As NEX AI, I can help you navigate the app, answer questions about features, and assist with various tasks. Is there something specific you\'d like to know?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1E36),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kNeonBlue, kNeonBlue.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kNeonBlue.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('NEX AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kNeonBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: kNeonBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: kNeonBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: kNeonBlue),
              onPressed: () {
                setState(() {
                  _messages.clear();
                  _messages.add({
                    'role': 'assistant',
                    'content': 'Chat cleared! How can I help you?',
                    'time': DateTime.now().toIso8601String(),
                  });
                });
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? LinearGradient(
                              colors: [kNeonBlue.withValues(alpha: 0.2), kNeonBlue.withValues(alpha: 0.1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUser ? null : const Color(0xFF0D1E36),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kNeonBlue.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kNeonBlue.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.smart_toy,
                              size: 16,
                              color: isUser ? kNeonGreen : kNeonBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isUser ? 'You' : 'NEX AI',
                              style: TextStyle(
                                color: isUser ? kNeonGreen : kNeonBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message['content'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: kNeonBlue,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'NEX AI is thinking...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1E36),
              border: Border(
                top: BorderSide(color: kNeonBlue.withValues(alpha: 0.3)),
              ),
              boxShadow: [
                BoxShadow(
                  color: kNeonBlue.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: kNeonBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mic, color: kNeonBlue),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1628),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Ask NEX AI anything...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kNeonBlue, kNeonBlue.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kNeonBlue.withValues(alpha: 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
