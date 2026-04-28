import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../main.dart';

class GroupChatScreen extends StatefulWidget {
  static const routeName = '/group-chat';
  final String? conversationId;
  
  const GroupChatScreen({super.key, this.conversationId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController messageController = TextEditingController();
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
      final doc = await _chatService.getConversation(_conversationId!);
      final data = doc.data() as Map<String, dynamic>;
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
                color: kNeonPurple.withOpacity(0.2),
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
                border: Border.all(color: kNeonPurple.withOpacity(0.3)),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kNeonPurple.withOpacity(0.1),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kNeonPurple, kNeonPurple.withOpacity(0.8)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => _createGroup(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
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
      final currentUserId = _chatService.currentUserId ?? 'demo-user';
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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
                  color: kNeonPurple.withOpacity(0.5),
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
                      colors: [kNeonPurple, kNeonPurple.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kNeonPurple.withOpacity(0.3),
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
                      Text(_groupName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Icon(Icons.people, color: kNeonPurple.withOpacity(0.7), size: 14),
                          const SizedBox(width: 4),
                          Text('${_members.length} members', style: const TextStyle(color: kNeonPurple, fontSize: 12)),
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
                border: Border(bottom: BorderSide(color: kNeonPurple.withOpacity(0.3))),
              ),
              child: const Text('Members', style: TextStyle(color: kNeonPurple, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            ...List.generate(_members.length, (index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF121224),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: kNeonPurple.withOpacity(0.2),
                    child: Text(_members[index][0].toUpperCase(), style: const TextStyle(color: kNeonPurple, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_members[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        Text(
                          _admins.contains(_members[index]) ? 'Admin' : 'Member',
                          style: TextStyle(
                            color: _admins.contains(_members[index]) ? kNeonPurple : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_admins.contains(_chatService.currentUserId) && _members[index] != _chatService.currentUserId)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                      onPressed: () async {
                        await _chatService.removeMember(_conversationId!, _members[index]);
                        setState(() => _members.removeAt(index));
                      },
                    ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            if (_admins.contains(_chatService.currentUserId))
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [kNeonPurple, kNeonPurple.withOpacity(0.8)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: kNeonPurple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _showAddMemberDialog,
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text('Add Member', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    _groupNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A), // Dark purple-black
      appBar: AppBar(
        backgroundColor: const Color(0xFF151528), // Purple-tinted
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
              child: const Icon(Icons.group, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_groupName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Row(
                  children: [
                    Icon(Icons.people, color: kNeonPurple.withOpacity(0.7), size: 14),
                    const SizedBox(width: 4),
                    Text('${_members.length} members', style: const TextStyle(color: kNeonPurple, fontSize: 12, fontWeight: FontWeight.w500)),
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
            child: IconButton(onPressed: _showGroupInfoDialog, icon: const Icon(Icons.info_outline, color: kNeonPurple)),
          ),
        ],
      ),
      body: _isLoading || _isCreating
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
                Expanded(child: _buildMessages()),
                _buildMessageInput(),
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

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(_conversationId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kNeonPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const CircularProgressIndicator(color: kNeonPurple),
            ),
          );
        }

        final messages = snapshot.data?.docs ?? [];
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
          // NEON PURPLE gradient for user messages
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
              style: const TextStyle(
                color: Colors.white,
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