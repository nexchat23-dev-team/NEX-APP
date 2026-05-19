import 'package:flutter/material.dart';
import '../utils/constants.dart';
// Note: To make this "Real Time Smart", you'll eventually want to
// import 'package:google_generative_ai/google_generative_ai.dart';

class AIChatScreen extends StatefulWidget {
  static const routeName = '/ai-chat';
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content': 'Welcome to the NEX Intelligence Hub. I am NEX AI, your advanced system assistant. How may I assist your operations today?',
      'time': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Expanded Logic: Simulated Intelligence + Real-Time Prep
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
    _scrollToBottom();

    // Simulation of AI processing (Replace this block with Gemini API call later)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    String aiResponse = _getSmartAIResponse(message);

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': aiResponse,
        'time': DateTime.now().toIso8601String(),
      });
      _isLoading = false;
    });
    _scrollToBottom();
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

  // Expanded "Knowledge Base" for a smarter feel
  String _getSmartAIResponse(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('hello') || msg.contains('hi')) {
      return 'Greetings. My neural systems are fully operational. I can help you manage your marketplace ads, optimize your betting strategy, or explain NEX-APP features. What\'s on your mind?';
    }
    if (msg.contains('token') || msg.contains('money') || msg.contains('balance')) {
      return 'Current Protocol: Tokens are the lifeblood of the NEX ecosystem. You can acquire them via the Marketplace or earn them through referrals. Would you like me to navigate you to the Token Management screen?';
    }
    if (msg.contains('bet') || msg.contains('aviator') || msg.contains('mines')) {
      return 'NEX Gaming Core: I detected interest in our high-stakes games. \n\n• Aviator: Watch the multiplier and cash out before the crash.\n• Mines: A game of precision—avoid the hidden explosives.\n• Spin: Pure algorithmic luck.\n\nStrategy tip: Always set a daily token limit!';
    }
    if (msg.contains('group') || msg.contains('invite')) {
      return 'Social Protocols: You can expand your network by creating Groups or using the Invite Friends feature in the Advertisement screen. Each successful referral grants 200 tokens.';
    }

    // "Smart" fallback that mimics deep understanding
    return 'Analysis Complete: Regarding "$message", I can provide deeper insights if you specify which NEX-APP module you are interested in (Gaming, Social, or Marketplace). How should I proceed?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFF070B14), // Deeper, more "AI" black
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A111F),
          elevation: 0,
          centerTitle: false,
          leadingWidth: 50,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: kNeonBlue, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kNeonBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.psychology_outlined, color: kNeonBlue, size: 22),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: kNeonGreen, shape: BoxShape.circle),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEX INTELLIGENCE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Text('SYSTEM ONLINE', style: TextStyle(color: kNeonGreen.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController, // Use the controller we added in part 1
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['role'] == 'user';

                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.8,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFF1A2135) : const Color(0xFF0D1E36),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 20),
                          ),
                          border: Border.all(
                            color: isUser
                                ? kNeonGreen.withValues(alpha: 0.3)
                                : kNeonBlue.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isUser ? kNeonGreen : kNeonBlue).withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
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
                                  isUser ? Icons.account_circle : Icons.terminal_rounded,
                                  size: 14,
                                  color: isUser ? kNeonGreen : kNeonBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isUser ? 'AUTHORIZED USER' : 'NEX CORE AI',
                                  style: TextStyle(
                                    color: isUser ? kNeonGreen : kNeonBlue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              message['content'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
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
                _buildAILoadingIndicator(),
              _buildMessageComposer(),
            ],
          ),
        );
    }

  Widget _buildAILoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kNeonBlue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: kNeonBlue.withValues(alpha: 0.1)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: kNeonBlue),
            ),
            SizedBox(width: 12),
            Text(
              'PROCESSING NEURAL DATA...',
              style: TextStyle(color: kNeonBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      decoration: BoxDecoration(
        color: const Color(0xFF0A111F),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF131C2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kNeonBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_none_rounded, color: Colors.white38),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Command NEX AI...',
                        hintStyle: TextStyle(color: Colors.white24),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kNeonBlue, Color(0xFF3B82F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kNeonBlue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 22),
            ),
          ),
        ],
      ),
    );
  }
} // End of State

