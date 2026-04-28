import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';
  final String? conversationId;
  final String? participantName;
  
  const ChatScreen({super.key, this.conversationId, this.participantName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  String? _conversationId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    if (widget.conversationId != null) {
      _conversationId = widget.conversationId;
      setState(() => _isLoading = false);
    } else {
      // Create or get default conversation
      _conversationId = 'default-chat';
      setState(() => _isLoading = false);
    }
  }

  void sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || _conversationId == null) return;

    try {
      await _chatService.sendMessage(
        conversationId: _conversationId!,
        text: text,
      );
      await _chatService.updateLastMessage(_conversationId!, text);
      messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatName = widget.participantName ?? 'NEX Support';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Dark purple-black background
      appBar: AppBar(
        backgroundColor: const Color(0xFF151528), // Purple-tinted app bar
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kNeonPurple, kNeonPurple.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kNeonPurple.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chatName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: kNeonGreen,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.5), blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('Online', style: TextStyle(color: kNeonGreen, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: kNeonPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.call, color: kNeonPurple)),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: kNeonPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.videocam, color: kNeonPurple)),
          ),
          Container(
            decoration: BoxDecoration(
              color: kNeonPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: kNeonPurple)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kNeonPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const CircularProgressIndicator(color: kNeonPurple),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: _conversationId == 'default-chat'
                      ? _buildDemoMessages()
                      : _buildFirestoreMessages(),
                ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildDemoMessages() {
    // Fallback demo messages when not connected to Firestore
    final messages = [
      {'text': 'Hey, welcome to NEXCHAT!', 'sentByMe': false, 'time': '09:00'},
      {'text': 'Hi! Ready to chat.', 'sentByMe': true, 'time': '09:02'},
      {'text': 'Check out the new marketplace packs.', 'sentByMe': false, 'time': '09:05'},
      {'text': 'Awesome! Just bought the Pro Bundle.', 'sentByMe': true, 'time': '09:10'},
    ];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMine = message['sentByMe'] as bool;
        return _buildMessageBubble(message['text'] as String, isMine, message['time'] as String);
      },
    );
  }

  Widget _buildFirestoreMessages() {
    if (_conversationId == null) return _buildDemoMessages();

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(_conversationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNeonGreen));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)),
          );
        }

        final messages = snapshot.data?.docs ?? [];
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet. Start the conversation!',
                style: TextStyle(color: Colors.white54)),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final doc = messages[index];
            final data = doc.data() as Map<String, dynamic>;
            final isMine = data['senderId'] == _chatService.currentUserId;
            final time = data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate().toString().substring(11, 16)
                : 'Now';
            return _buildMessageBubble(data['text'] as String, isMine, time);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isMine, String time) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        decoration: BoxDecoration(
          // NEON PURPLE for user messages, Dark teal for received
          gradient: isMine
              ? LinearGradient(
                  colors: [kNeonPurple, kNeonPurple.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMine ? null : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 20),
          ),
          border: isMine
              ? Border.all(color: kNeonPurple.withOpacity(0.5), width: 1.5)
              : Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: isMine
              ? [
                  BoxShadow(
                    color: kNeonPurple.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMine)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.done_all, size: 14, color: Colors.white70),
                  ),
                Text(
                  time,
                  style: TextStyle(
                    color: isMine ? Colors.white70 : Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121224),
        border: Border(
          top: BorderSide(color: kNeonPurple.withOpacity(0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: kNeonPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: kNeonPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kNeonPurple),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1A1A2E), const Color(0xFF1E1E3A)],
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: kNeonPurple.withOpacity(0.3)),
              ),
              child: TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                onSubmitted: (_) => sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kNeonPurple, kNeonPurple.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: kNeonPurple.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: sendMessage,
              mini: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
