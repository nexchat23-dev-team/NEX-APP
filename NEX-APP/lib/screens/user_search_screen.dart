
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';
import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  static const routeName = '/user-search';
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ChatService _chatService = ChatService();
  String _searchText = '';
  String? _errorMessage;

  Stream<List<Map<String, dynamic>>> get _usersStream {
    return SupabaseService.client
        .from('users')
        .stream(primaryKey: ['id']);
  }

  List<_UserSearchResult> _filterUsers(
    List<Map<String, dynamic>> rows,
    String currentUserId,
  ) {
    final query = _searchText.trim().toLowerCase();
    final results = <_UserSearchResult>[];

    for (final data in rows) {
      final uid = data['id']?.toString() ?? '';
      if (uid.isEmpty || uid == currentUserId) continue;

      final rawUsername = (data['username'] as String?)?.trim() ?? '';
      final rawEmail = (data['email'] as String?)?.trim() ?? '';
      final username = rawUsername.isNotEmpty ? rawUsername : rawEmail.split('@').first;
      final email = rawEmail.isNotEmpty ? rawEmail : 'No public email';
      final usernameLower = username.toLowerCase();
      final emailLower = email.toLowerCase();

      final matchesQuery = query.isEmpty ||
          usernameLower.contains(query) ||
          emailLower.contains(query);

      if (matchesQuery) {
        results.add(_UserSearchResult(uid: uid, username: username, email: email));
      }
    }

    results.sort((a, b) => a.username.compareTo(b.username));
    return results;
  }

  Future<void> _openChat(_UserSearchResult user) async {
    try {
      final conversationId = await _chatService.createOrGetDirectConversation(user.uid);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        ChatScreen.routeName,
        arguments: {
          'conversationId': conversationId,
          'participantName': user.username,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open chat: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUserId ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A111F),
        elevation: 0,
        title: const Text(
          'USER SEARCH',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kNeonPurple.withValues(alpha: 0.16), kNeonBlue.withValues(alpha: 0.12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kNeonBlue.withValues(alpha: 0.2)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find people and start a private conversation.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Search by username or email, then open chat instantly.',
                      style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _searchText = value),
                decoration: InputDecoration(
                  hintText: 'Search username or email',
                  hintStyle: const TextStyle(color: Colors.white30),
                  prefixIcon: const Icon(Icons.search_rounded, color: kNeonBlue),
                  filled: true,
                  fillColor: const Color(0xFF0D162F),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _usersStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: kNeonPurple),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Unable to load users right now.',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    final results = _filterUsers(snapshot.data ?? [], currentUserId);
                    if (results.isEmpty) {
                      return Center(
                        child: Text(
                          _searchText.trim().isEmpty
                              ? 'No users available yet. New accounts appear here automatically.'
                              : 'No matches found for your search.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = results[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D162F),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: kNeonPurple.withValues(alpha: 0.24),
                              child: Text(
                                user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              user.email,
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kNeonGreen,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onPressed: () => _openChat(user),
                              child: const Text('CHAT', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserSearchResult {
  final String uid;
  final String username;
  final String email;

  _UserSearchResult({
    required this.uid,
    required this.username,
    required this.email,
  });
}
