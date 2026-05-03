import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'calls_screen.dart';
import 'announcements_screen.dart';
import 'terminal_screen.dart';
import 'video_feed_screen.dart';
import 'gaming_hub_screen.dart';
import 'advertisement_screen.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1410),
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF25D366),
                ),
                child: const Icon(Icons.chat, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('NEXCHAT'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => _showSearchDialog(context),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, AnnouncementsScreen.routeName),
              icon: const Icon(Icons.campaign),
              tooltip: 'Announcements',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.smart_toy),
              tooltip: 'AI Chat',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, TerminalScreen.routeName),
              icon: const Icon(Icons.terminal),
              tooltip: 'Terminal',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, VideoFeedScreen.routeName),
              icon: const Icon(Icons.video_collection),
              tooltip: 'NEX-Reels',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, GamingHubScreen.routeName),
              icon: const Icon(Icons.sports_esports),
              tooltip: 'Gaming Hub',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, AdvertisementScreen.routeName),
              icon: const Icon(Icons.ads_click),
              tooltip: 'Advertisements',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/settings'),
              icon: const Icon(Icons.settings),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Status'),
              Tab(text: 'Calls'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildChats(context),
            _buildStatus(context),
            _buildCalls(context),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF25D366),
          child: const Icon(Icons.chat, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, ChatScreen.routeName),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _UserSearchDialog(),
    );
  }

  Widget _buildChats(BuildContext context) {
    final chatService = ChatService();
    final currentUserId = chatService.currentUserId;

    if (currentUserId == null) {
      return const Center(
        child: Text('Sign in to view your recent chats.', style: TextStyle(color: Colors.white70)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNeonGreen));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load chats right now.', style: TextStyle(color: Colors.white70)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyChats(context);
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 8),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 0, indent: 76, color: Colors.white12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isGroup = (data['isGroup'] ?? false) as bool;
            final lastMessage = (data['lastMessage'] ?? 'No messages yet').toString();
            final timeText = _formatTime(data['lastMessageTime']);

            return FutureBuilder<String>(
              future: _resolveConversationTitle(data, currentUserId),
              builder: (context, titleSnapshot) {
                final title = titleSnapshot.data ?? (isGroup ? (data['groupName'] ?? 'NEX Group') : 'NEX Chat');
                final avatarLabel = title.isNotEmpty ? title[0].toUpperCase() : 'N';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: isGroup ? kNeonPurple.withValues(alpha: 0.20) : kNeonGreen.withValues(alpha: 0.20),
                    child: Text(avatarLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(lastMessage, style: const TextStyle(color: Colors.white70, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(timeText, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  onTap: () {
                    final conversationId = docs[index].id;
                    if (isGroup) {
                      Navigator.pushNamed(context, GroupChatScreen.routeName);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: conversationId,
                            participantName: title,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyChats(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 96, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'No recent chats yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start a new conversation and your recent chat partners will appear here automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, ChatScreen.routeName),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('Start a chat', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _resolveConversationTitle(Map<String, dynamic> data, String currentUserId) async {
    try {
      final isGroup = (data['isGroup'] ?? false) as bool;
      if (isGroup) {
        return data['groupName']?.toString() ?? 'NEX Group';
      }

      final participants = List<String>.from(data['participants'] ?? []);
      final otherIds = participants.where((id) => id != currentUserId).toList();
      if (otherIds.isEmpty) return 'NEX Chat';
      final otherId = otherIds.first;
      final doc = await FirebaseFirestore.instance.collection('users').doc(otherId).get();
      if (!doc.exists) return 'NEX Chat';
      final userData = doc.data() as Map<String, dynamic>;
      return (userData['username'] ?? userData['name'] ?? otherId).toString();
    } catch (e) {
      debugPrint('Error resolving title: $e');
      return 'NEX Chat';
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      }
      if (diff.inDays == 1) {
        return 'Yesterday';
      }
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }

  Widget _buildStatus(BuildContext context) {
    final List<Map<String, dynamic>> statuses = [
      {'name': 'My status', 'subtitle': 'Tap to add status update', 'time': 'Today, 09:00'},
      {'name': 'NEX Community', 'subtitle': '3 new updates', 'time': 'Yesterday'},
      {'name': 'Anna', 'subtitle': '2 new updates', 'time': 'Today, 10:24'},
    ];
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: statuses.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 76, color: Colors.white12),
      itemBuilder: (context, index) {
        final status = statuses[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.22),
            child: Text(status['name']![0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          title: Text(status['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(status['subtitle'] as String, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          trailing: Text(status['time'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          onTap: () {},
        );
      },
    );
  }

  Widget _buildCalls(BuildContext context) {
    // Use the dedicated CallsScreen
    return const CallsScreen();
  }
}

class _UserSearchDialog extends StatefulWidget {
  const _UserSearchDialog();

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final queryLower = query.toLowerCase();
      final usersRef = FirebaseFirestore.instance.collection('users');
      final snapshot = await usersRef.get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        return name.contains(queryLower) || email.contains(queryLower);
      }).map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown User',
          'email': data['email'] ?? '',
          'photoUrl': data['photoUrl'],
        };
      }).toList();

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search users. Please try again.';
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search Users',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => _searchUsers(value),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: kNeonBlue),
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
            else if (_searchController.text.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Enter a name or email to search',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else if (_searchResults.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No users found',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kNeonBlue.withValues(alpha: 0.2),
                        child: Text(
                          (user['name'] as String)[0].toUpperCase(),
                          style: const TextStyle(color: kNeonBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        user['name'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        user['email'] as String,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          ChatScreen.routeName,
                          arguments: user,
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
