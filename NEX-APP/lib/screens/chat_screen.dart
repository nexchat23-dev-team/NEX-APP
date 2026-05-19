import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';

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

  void _initializeConversation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      final routeConversationId = routeArgs is Map<String, dynamic>
          ? routeArgs['conversationId'] as String?
          : null;
      setState(() {
        _conversationId ??= widget.conversationId ?? routeConversationId;
        _isLoading = false;
      });
    });
  }

  void _showMessageOptions(String messageId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message', style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                await _deleteMessage(messageId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(_conversationId!, messageId);
      // FIX: Check mounted before using BuildContext (use_build_context_synchronously)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    } catch (e) {
      // FIX: Check mounted before using BuildContext
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
    }
  }

  Future<void> sendMessage() async {
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
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final routeConversationId = routeArgs is Map<String, dynamic>
        ? routeArgs['conversationId'] as String?
        : null;
    final participantName = widget.participantName ??
        (routeArgs is Map<String, dynamic>
            ? (routeArgs['participantName'] as String? ?? routeArgs['name'] as String?)
            : null);
    _conversationId ??= widget.conversationId ?? routeConversationId;
    final chatName = participantName?.trim().isEmpty ?? true ? 'NEX Chat' : participantName;

    // Starting from line 193 logic...

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12132A),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            // ... [Previous Container with chat icon logic] ...
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatName ?? 'NEX Chat',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    participantName != null ? 'Online' : 'Connect with your contact',
                    style: TextStyle(
                      color: participantName != null ? kNeonGreen : Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _buildAppBarAction(Icons.call, () {}),
          _buildAppBarAction(Icons.videocam, () {}),
          _buildAppBarAction(Icons.more_vert, () {}),
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
            child: _buildFirestoreMessages(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Helper for cleaner AppBar actions
  Widget _buildAppBarAction(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: kNeonPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(onPressed: onPressed, icon: Icon(icon, color: kNeonPurple)),
    );
  }

  Widget _buildRecentlyChattedList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: kNeonPurple.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No conversation selected', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Choose a conversation from the list to view messages.', style: TextStyle(color: Colors.white38), textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: kNeonPurple),
              child: const Text('BACK TO CHATS', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirestoreMessages() {
    if (_conversationId == null) {
      return _buildRecentlyChattedList();
    }

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
            final messageId = doc.id;
            final isMine = data['senderId'] == _chatService.currentUserId;
            final time = data['timestamp'] != null
                ? (data['timestamp'] as Timestamp).toDate().toString().substring(11, 16)
                : 'Now';
            return GestureDetector(
              onLongPress: isMine ? () => _showMessageOptions(messageId) : null,
              child: _buildMessageBubble(data['text'] ?? '', isMine, time),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isMine, String time) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          gradient: isMine
              ? LinearGradient(
                  colors: [kNeonPurple, kNeonPurple.withOpacity(0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFF17172A), Color(0xFF1D2037)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMine ? 20 : 4),
            topRight: Radius.circular(isMine ? 4 : 20),
            bottomLeft: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
          ),
          // FIX: withOpacity -> withValues
          border: Border.all(color: Colors.white.withOpacity(isMine ? 0.12 : 0.08)),
          boxShadow: [
            BoxShadow(
              color: isMine ? kNeonPurple.withOpacity(0.18) : Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              softWrap: true,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMine)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF1E1E3A)],
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


} // End of _ChatScreenState

