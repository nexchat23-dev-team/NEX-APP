import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';
import 'group_invite_screen.dart';
import 'group_settings_screen.dart';

class GroupChatScreen extends StatefulWidget {
  static const routeName = '/group-chat';
  final String? conversationId;

  const GroupChatScreen({super.key, this.conversationId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();
  Timer? _shootingStarTimer;
  bool _showShootingStar = false;
  double _shootingStartX = 0;
  double _shootingStartY = 0;
  double _shootingEndX = 0;
  double _shootingEndY = 0;
  Color _shootingStarColor = Colors.white;
  Color _shootingFromColor = Colors.white;
  Color _shootingToColor = Colors.white;
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _groupNameController = TextEditingController();

  String? _conversationId;
  String _groupName = 'New Group';
  List<String> _members = [];
  List<String> _admins = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _initializeGroup();
    _scheduleShootingStar();
  }

  Future<void> _initializeGroup() async {
    if (widget.conversationId != null) {
      _conversationId = widget.conversationId;
      await _loadGroupDetails();
    } else {
      // Show create group dialog
      _showCreateGroupDialog();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadGroupDetails() async {
    if (_conversationId == null) return;

    try {
      final data = await _chatService.getConversation(_conversationId!);
      setState(() {
        _groupName = data['groupName'] ?? 'Group';
        _members = List<String>.from(data['participants'] ?? []);
        _admins = List<String>.from(data['admins'] ?? []);
      });
    } catch (e) {
      debugPrint('Error loading group: $e');
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kNeonPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.group_add, color: kNeonPurple),
            ),
            const SizedBox(width: 12),
            const Text('Create Group', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121224),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNeonPurple.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _groupNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  labelStyle: TextStyle(color: kNeonPurple),
                  hintText: 'Enter group name',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kNeonPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: kNeonPurple, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('You can add members after creating the group.',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [kNeonPurple, kNeonPurple.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => _createGroup(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child:
                  const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createGroup(BuildContext dialogContext) async {
    final name = _groupNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final currentUserId = _chatService.currentUserId;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to create a group')),
        );
        setState(() => _isCreating = false);
        return;
      }
      _conversationId = await _chatService.createConversation(
        participantIds: [currentUserId],
        groupName: name,
        isGroup: true,
      );

      setState(() {
        _groupName = name;
        _members = [currentUserId];
        _admins = [currentUserId];
      });

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating group: $e')),
        );
      }
    } finally {
      setState(() => _isCreating = false);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting message: $e')),
      );
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

  void _showAddMemberDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Add Member', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'User ID',
            labelStyle: TextStyle(color: Colors.white70),
            hintText: 'Enter user ID to add',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = controller.text.trim();
              if (userId.isNotEmpty && _conversationId != null) {
                await _chatService.addMember(_conversationId!, userId);
                setState(() => _members.add(userId));
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    Navigator.pop(context); // Close the group info dialog first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupSettingsScreen(
          conversationId: _conversationId!,
          groupName: _groupName,
        ),
      ),
    );
  }

  void _showGroupInvite() {
    if (_conversationId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupInviteScreen(
          conversationId: _conversationId!,
          groupName: _groupName,
        ),
      ),
    );
  }

  void _showGroupInfoDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kNeonPurple.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kNeonPurple, kNeonPurple.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kNeonPurple.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_groupName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.people,
                              color: kNeonPurple.withValues(alpha: 0.7),
                              size: 14),
                          const SizedBox(width: 4),
                          Text('${_members.length} members',
                              style: const TextStyle(
                                  color: kNeonPurple, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: kNeonPurple.withValues(alpha: 0.3))),
              ),
              child: const Text('Members',
                  style: TextStyle(
                      color: kNeonPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            const SizedBox(height: 12),
            ...List.generate(
                _members.length,
                (index) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121224),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: kNeonPurple.withValues(alpha: 0.2),
                            child: Text(_members[index][0].toUpperCase(),
                                style: const TextStyle(
                                    color: kNeonPurple,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_members[index],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500)),
                                Text(
                                  _admins.contains(_members[index])
                                      ? 'Admin'
                                      : 'Member',
                                  style: TextStyle(
                                    color: _admins.contains(_members[index])
                                        ? kNeonPurple
                                        : Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_admins.contains(_chatService.currentUserId) &&
                              _members[index] != _chatService.currentUserId)
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.redAccent),
                              onPressed: () async {
                                await _chatService.removeMember(
                                    _conversationId!, _members[index]);
                                setState(() => _members.removeAt(index));
                              },
                            ),
                        ],
                      ),
                    )),
            const SizedBox(height: 16),
            if (_admins.contains(_chatService.currentUserId))
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          kNeonPurple,
                          kNeonPurple.withValues(alpha: 0.8)
                        ]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: kNeonPurple.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _showAddMemberDialog,
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text('Add Member',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          kNeonGreen,
                          kNeonGreen.withValues(alpha: 0.8)
                        ]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: kNeonGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _showSettings,
                        icon: const Icon(Icons.settings, color: Colors.white),
                        label: const Text('Settings',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _shootingStarTimer?.cancel();
    messageController.dispose();
    _groupNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleShootingStar() {
    _shootingStarTimer?.cancel();
    _shootingStarTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      _launchShootingStar();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _launchShootingStar();
    });
  }

  void _launchShootingStar() {
    final size = MediaQuery.of(context).size;
    final startX = Random().nextDouble() * size.width * 0.7;
    final startY = Random().nextDouble() * size.height * 0.16;
    final endX = startX + size.width * 0.45;
    final endY = startY + size.height * 0.12;
    final palette = [Colors.white, const Color(0xFF7DDCFF), const Color(0xFFB23BFF), const Color(0xFFFFD166)];

    setState(() {
      _shootingStartX = startX;
      _shootingStartY = startY;
      _shootingEndX = endX;
      _shootingEndY = endY;
      _shootingFromColor = palette[Random().nextInt(palette.length)];
      _shootingToColor = palette[Random().nextInt(palette.length)];
      _shootingStarColor = _shootingFromColor;
      _showShootingStar = true;
    });
  }

  Widget _buildShootingStarOverlay() {
    if (!_showShootingStar) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final x = _shootingStartX + (_shootingEndX - _shootingStartX) * value;
        final y = _shootingStartY + (_shootingEndY - _shootingStartY) * value;
        final opacity = (1 - value).clamp(0.0, 1.0).toDouble();

        final currentColor = Color.lerp(_shootingFromColor, _shootingToColor, value) ?? _shootingStarColor;

        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 140,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      currentColor.withValues(alpha: 0.95),
                      _shootingToColor.withValues(alpha: 0.6),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      onEnd: () => setState(() => _showShootingStar = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151528),
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
                gradient: LinearGradient(
                  colors: [kNeonPurple, kNeonPurple.withValues(alpha: 0.65)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kNeonPurple.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.group, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_groupName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people,
                          color: kNeonPurple.withValues(alpha: 0.8), size: 14),
                      const SizedBox(width: 6),
                      Text('${_members.length} members',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          _buildGroupAction(Icons.link, _showGroupInvite, 'Invite'),
          _buildGroupAction(Icons.call, () {}, 'Call'),
          _buildGroupAction(Icons.videocam, () {}, 'Video'),
          _buildGroupAction(Icons.info_outline, _showGroupInfoDialog, 'Info'),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF060810), Color(0xFF0C1223)],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _SpaceGlowPainter(),
            ),
          ),
          _isLoading || _isCreating
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
                    Expanded(child: _buildMessages()),
                    _buildMessageInput(),
                  ],
                ),
          _buildShootingStarOverlay(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_conversationId == null) {
      return const Center(
        child: Text('Create a group to start chatting',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getMessages(_conversationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kNeonPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(color: kNeonPurple),
            ),
          );
        }

        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return const Center(
            child: Text('No messages yet. Start the conversation!',
                style: TextStyle(color: Colors.white54)),
          );
        }

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
              child: _buildMessageBubble(data['text']?.toString() ?? '', isMine, time),
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

  Widget _buildMessageBubble(String text, bool isMine, String time) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        decoration: BoxDecoration(
          color: isMine ? null : const Color(0xFF181A2F),
          gradient: isMine
              ? LinearGradient(
                  colors: [kNeonPurple, kNeonPurple.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isMine ? 18 : 4),
            topRight: Radius.circular(isMine ? 4 : 18),
            bottomLeft: const Radius.circular(18),
            bottomRight: const Radius.circular(18),
          ),
          border: Border.all(
            color: isMine
                ? kNeonPurple.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
            width: isMine ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isMine
                  ? kNeonPurple.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: isMine ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMine)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child:
                        Icon(Icons.done_all, size: 14, color: Colors.white70),
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

  Widget _buildGroupAction(
      IconData icon, VoidCallback onPressed, String tooltip) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: kNeonPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: kNeonPurple),
          tooltip: tooltip),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF121224),
        border: Border(
          top: BorderSide(color: kNeonPurple.withValues(alpha: 0.3), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: kNeonPurple.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: kNeonPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kNeonPurple),
              onPressed: _showAddMemberDialog,
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
    );
  }
}

class _SpaceGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.2, -0.3),
        radius: 1.2,
        colors: [Color(0xFF120F2A), Color(0xFF060810)],
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.8, 0.1),
        radius: 0.8,
        colors: [Color(0xFF7B61FF), Color(0x00000000)],
      ).createShader(rect);
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.16),
      size.width * 0.24,
      glowPaint,
    );

    final pulsePaint = Paint()
      ..color = const Color(0xFF34D1F8).withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.78),
      size.width * 0.18,
      pulsePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
