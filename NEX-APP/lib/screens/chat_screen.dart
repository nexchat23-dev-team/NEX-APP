import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';
import '../services/offline_service.dart';
import '../services/audio_service.dart';
import 'call_screen.dart';
import 'package:hive/hive.dart';

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
  final AudioService _audioService = AudioService();
  String? _conversationId;
  bool _isLoading = true;

  // Reply state
  Map<String, dynamic>? _replyToMessage;

  // Audio message state
  bool _isRecording = false;
  String? _audioFilePath;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    _audioService.disposeRecorder();
    _audioService.disposePlayer();
    super.dispose();
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
              title: const Text('Delete Message',
                  style: TextStyle(color: Colors.white)),
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
    final hasAudio = _audioFilePath != null;
    if ((text.isEmpty && !hasAudio) || _conversationId == null) return;
    final convId = _conversationId!;
    final senderId = _chatService.currentUserId;
    if (senderId == null) return;

    try {
      if (hasAudio) {
        // Upload audio file to Firebase Storage and get URL
        final audioUrl =
            await _chatService.uploadAudioMessage(convId, _audioFilePath!);
        await _chatService.sendMessage(
          conversationId: convId,
          text: '',
          type: 'audio',
          audioUrl: audioUrl,
          replyTo: _replyToMessage != null ? _replyToMessage!['id'] : null,
          replyText: _replyToMessage != null ? _replyToMessage!['text'] : null,
          replySender:
              _replyToMessage != null ? _replyToMessage!['senderName'] : null,
        );
        await _chatService.updateLastMessage(convId, '[Audio message]');
        setState(() => _audioFilePath = null);
      } else {
        await _chatService.sendMessage(
          conversationId: convId,
          text: text,
          type: _replyToMessage != null ? 'reply' : 'text',
          replyTo: _replyToMessage != null ? _replyToMessage!['id'] : null,
          replyText: _replyToMessage != null ? _replyToMessage!['text'] : null,
          replySender:
              _replyToMessage != null ? _replyToMessage!['senderName'] : null,
        );
        await _chatService.updateLastMessage(convId, text);
        messageController.clear();
      }
      setState(() => _replyToMessage = null);
    } catch (e) {
      try {
        await OfflineService().saveLocalMessage(
          conversationId: convId,
          senderId: senderId,
          text: hasAudio ? '[Audio message]' : text,
        );
        await OfflineService().retryFailed();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message queued for sync')),
          );
        }
      } catch (queueError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send: $queueError')),
          );
        }
      }
    }
  }

  Future<void> _startOrStopRecording() async {
    if (_isRecording) {
      await _audioService.stopRecording();
      setState(() => _isRecording = false);
    } else {
      final filePath =
          '/storage/emulated/0/Download/nexchat_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _audioService.startRecording(filePath);
      setState(() {
        _isRecording = true;
        _audioFilePath = filePath;
      });
    }
  }

  Future<void> _playOrStopAudio() async {
    if (_isPlayingAudio) {
      await _audioService.stopPlayer();
      setState(() => _isPlayingAudio = false);
    } else if (_audioFilePath != null) {
      await _audioService.play(_audioFilePath!);
      setState(() => _isPlayingAudio = true);
    }
  }

  Future<void> _startCall(bool isVideo) async {
    final receiverId = await _resolveReceiverId();

    if (!mounted) {
      return;
    }

    if (receiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Call is only available for direct chats.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          receiverId: receiverId,
          receiverName: widget.participantName ?? 'NEX Chat',
          isVideo: isVideo,
        ),
      ),
    );
  }

  Future<String?> _resolveReceiverId() async {
    if (_conversationId == null) {
      return null;
    }

    final currentUserId = _chatService.currentUserId;
    if (currentUserId == null) {
      return null;
    }

    final conversationData = await _chatService.getConversation(_conversationId!);

    if (conversationData['isGroup'] == true) {
      return null;
    }

    final participants = List<String>.from(conversationData['participants'] ?? const []);
    for (final participant in participants) {
      if (participant != currentUserId) {
        return participant;
      }
    }

    return null;
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

  // Only one dispose method should exist. The correct one is above with audioService cleanup.

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    final routeConversationId = routeArgs is Map<String, dynamic>
        ? routeArgs['conversationId'] as String?
        : null;
    final participantName = widget.participantName ??
        (routeArgs is Map<String, dynamic>
            ? (routeArgs['participantName'] as String? ??
                routeArgs['name'] as String?)
            : null);
    _conversationId ??= widget.conversationId ?? routeConversationId;
    final chatName =
        participantName?.trim().isEmpty ?? true ? 'NEX Chat' : participantName;
    final themeProvider = context.watch<ThemeProvider>();

    // Starting from line 193 logic...

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12132A),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kNeonPurple.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
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
                    participantName != null
                        ? 'Online now'
                        : 'Secure connection',
                    style: TextStyle(
                      color:
                          participantName != null ? kNeonGreen : Colors.white54,
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
          _buildAppBarAction(Icons.call, () => _startCall(false)),
          _buildAppBarAction(Icons.videocam, () => _startCall(true)),
          _buildAppBarAction(Icons.more_vert, () {}),
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white70,
            ),
            tooltip: themeProvider.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
          ),
          IconButton(
            onPressed: _showPendingMessages,
            icon: const Icon(Icons.sync_problem, color: Colors.white70),
            tooltip: 'Pending messages',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kNeonPurple.withValues(alpha: 0.1),
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

  void _showPendingMessages() {
    if (_conversationId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final boxListen = OfflineService().listenable();
        return ValueListenableBuilder<Box>(
          valueListenable: boxListen,
          builder: (context, box, _) {
            final items = OfflineService().getLocalMessages(_conversationId!);
            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: const Center(
                    child: Text('No pending messages',
                        style: TextStyle(color: Colors.white70))),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final m = items[index];
                final status = m['status'] as String? ?? 'pending';
                return ListTile(
                  title: Text(m['text'] ?? '',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text('Status: $status',
                      style: const TextStyle(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'failed')
                        TextButton(
                          onPressed: () async {
                            await OfflineService()
                                .retryMessageById(m['id'] as String);
                          },
                          child: const Text('Retry'),
                        ),
                      if (status == 'pending' || status == 'uploading')
                        const SizedBox(width: 8),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const Divider(),
              itemCount: items.length,
            );
          },
        );
      },
    );
  }

  // Helper for cleaner AppBar actions
  Widget _buildAppBarAction(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: kNeonPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
          onPressed: onPressed, icon: Icon(icon, color: kNeonPurple)),
    );
  }

  Widget _buildRecentlyChattedList() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 64, color: kNeonPurple.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            const Text('No conversation selected',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Choose a conversation from the list to view messages.',
                style: TextStyle(color: Colors.white38),
                textAlign: TextAlign.center),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: kNeonPurple),
              child: const Text('BACK TO CHATS',
                  style: TextStyle(color: Colors.white)),
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

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getMessages(_conversationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kNeonGreen));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70)),
          );
        }

        final messages = snapshot.data ?? [];
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
            final data = messages[index];
            final messageId = data['id']?.toString() ?? '';
            final isMine = data['senderId'] == _chatService.currentUserId;
            final time = _formatTimestamp(data['timestamp']);
            return GestureDetector(
              onLongPress: isMine ? () => _showMessageOptions(messageId) : null,
              onHorizontalDragEnd: (details) {
                if (!isMine &&
                    details.primaryVelocity != null &&
                    details.primaryVelocity! > 0) {
                  setState(() {
                    _replyToMessage = {
                      'id': messageId,
                      'text': data['text'] ?? '',
                      'senderName': data['senderName'] ?? 'User',
                    };
                  });
                }
              },
              child: _buildMessageBubbleWithReply(data, isMine, time),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Now';
    if (timestamp is DateTime) {
      return timestamp.toLocal().toString().substring(11, 16);
    }
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp).toLocal().toString().substring(11, 16);
      } catch (_) {
        return timestamp;
      }
    }
    return timestamp.toString();
  }

  Widget _buildMessageBubbleWithReply(
      Map<String, dynamic> data, bool isMine, String time) {
    const radius = Radius.circular(22);
    final replyText = data['replyText'] as String?;
    final replySender = data['replySender'] as String?;
    final isAudio = data['type'] == 'audio' && data['audioUrl'] != null;
    return Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isMine ? 40 : 8,
        right: isMine ? 8 : 40,
      ),
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: isMine ? radius : const Radius.circular(6),
                  topRight: isMine ? const Radius.circular(6) : radius,
                  bottomLeft: radius,
                  bottomRight: radius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMine
                        ? kNeonPurple.withValues(alpha: 0.35)
                        : kNeonBlue.withValues(alpha: 0.22),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine)
                CustomPaint(
                  painter: _BubbleTailPainter(
                    color: kNeonBlue.withValues(alpha: 0.7),
                    isMine: false,
                  ),
                  size: const Size(12, 18),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                  decoration: BoxDecoration(
                    color: isMine
                        ? kNeonPurple.withValues(alpha: 0.85)
                        : kNeonBlue.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.only(
                      topLeft: isMine ? radius : const Radius.circular(6),
                      topRight: isMine ? const Radius.circular(6) : radius,
                      bottomLeft: radius,
                      bottomRight: radius,
                    ),
                    border: Border.all(
                      color: isMine
                          ? kNeonPurple.withValues(alpha: 0.5)
                          : kNeonBlue.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (replyText != null && replyText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isMine
                                ? kNeonPurple.withValues(alpha: 0.18)
                                : kNeonBlue.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.reply,
                                  size: 14,
                                  color: isMine ? kNeonPurple : kNeonBlue),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  replySender != null
                                      ? '$replySender: $replyText'
                                      : replyText,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isAudio)
                        _buildAudioMessageBubble(data['audioUrl'], isMine)
                      else
                        Text(
                          data['text'] ?? '',
                          softWrap: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                              child: Icon(Icons.done_all,
                                  size: 15, color: kNeonGreen),
                            ),
                          Text(
                            time,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMine)
                CustomPaint(
                  painter: _BubbleTailPainter(
                    color: kNeonPurple.withValues(alpha: 0.85),
                    isMine: true,
                  ),
                  size: const Size(12, 18),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioMessageBubble(String audioUrl, bool isMine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mic, color: isMine ? kNeonGreen : kNeonBlue, size: 22),
        const SizedBox(width: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isMine
                ? kNeonGreen.withValues(alpha: 0.18)
                : kNeonBlue.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          onPressed: () async {
            await _audioService.play(audioUrl);
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow, size: 18),
              SizedBox(width: 4),
              Text('Play', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121224),
        border: Border(
          top: BorderSide(color: kNeonPurple.withValues(alpha: 0.25), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: kNeonPurple.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyToMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kNeonBlue.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, color: kNeonBlue, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _replyToMessage!['text'] ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.white38, size: 18),
                    onPressed: () => setState(() => _replyToMessage = null),
                    tooltip: 'Cancel reply',
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: kNeonPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined,
                      color: kNeonPurple),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: TextField(
                    controller: messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Audio message button
              if (_audioFilePath == null)
                Container(
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? kNeonGreen.withValues(alpha: 0.2)
                        : kNeonPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: _startOrStopRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                        color: _isRecording ? kNeonGreen : Colors.white),
                  ),
                ),
              if (_audioFilePath != null)
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: kNeonBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        onPressed: _playOrStopAudio,
                        icon: Icon(
                            _isPlayingAudio ? Icons.stop : Icons.play_arrow,
                            color: kNeonBlue),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kNeonPurple,
                            kNeonPurple.withValues(alpha: 0.8)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: kNeonPurple.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: sendMessage,
                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              if (_audioFilePath == null)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kNeonPurple, kNeonPurple.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kNeonPurple.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // End of _ChatScreenState
}

// WhatsApp-style bubble tail painter
class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isMine;
  _BubbleTailPainter({required this.color, required this.isMine});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isMine) {
      path.moveTo(0, size.height);
      path.quadraticBezierTo(
          size.width * 0.7, size.height * 0.7, size.width, 0);
      path.lineTo(0, 0);
      path.close();
    } else {
      path.moveTo(size.width, size.height);
      path.quadraticBezierTo(size.width * 0.3, size.height * 0.7, 0, 0);
      path.lineTo(size.width, 0);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
