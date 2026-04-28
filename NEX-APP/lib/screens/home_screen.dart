import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'calls_screen.dart';
import 'announcements_screen.dart';
import 'ai_chat_screen.dart';
import 'terminal_screen.dart';
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
              onPressed: () => Navigator.pushNamed(context, AIChatScreen.routeName),
              icon: const Icon(Icons.smart_toy),
              tooltip: 'AI Chat',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, TerminalScreen.routeName),
              icon: const Icon(Icons.terminal),
              tooltip: 'Terminal',
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
    final List<Map<String, dynamic>> chats = [
      {'name': 'Alex', 'message': 'Do you have the new token update?', 'time': '13:45', 'unread': 2, 'type': 'chat'},
      {'name': 'NEX Group', 'message': 'New event launching tomorrow!', 'time': '12:30', 'unread': 5, 'type': 'group'},
      {'name': 'Sam', 'message': 'Check the new marketplace pack.', 'time': '08:15', 'unread': 0, 'type': 'chat'},
      {'name': 'Support', 'message': 'Your token balance was updated.', 'time': 'Yesterday', 'unread': 1, 'type': 'chat'},
    ];
    return ListView.separated(
      padding: const EdgeInsets.only(top: 8),
      itemCount: chats.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 76, color: Colors.white12),
      itemBuilder: (context, index) {
        final chat = chats[index];
        final isGroup = chat['type'] == 'group';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: isGroup ? kNeonPurple.withOpacity(0.20) : kNeonGreen.withOpacity(0.20),
            child: Icon(
              isGroup ? Icons.group : Icons.person,
              color: isGroup ? kNeonPurple : Colors.white,
            ),
          ),
          title: Text(chat['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(chat['message'] as String, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(chat['time'] as String, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              if ((chat['unread'] as int) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: isGroup ? kNeonPurple : kNeonGreen, borderRadius: BorderRadius.all(Radius.circular(12))),
                  child: Text('${chat['unread']}', style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          onTap: () {
            if (isGroup) {
              Navigator.pushNamed(context, GroupChatScreen.routeName);
            } else {
              Navigator.pushNamed(context, ChatScreen.routeName);
            }
          },
        );
      },
    );
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
            backgroundColor: const Color(0xFF25D366).withOpacity(0.22),
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
                        backgroundColor: kNeonBlue.withOpacity(0.2),
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
