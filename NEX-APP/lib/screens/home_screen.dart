import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/status_service.dart';
import '../services/chat_service.dart';
import '../utils/constants.dart';
import '../widgets/hub_feature_panel.dart';
import 'announcements_screen.dart';
import 'advertisement_screen.dart';
import 'bet_screen.dart';
import 'calls_screen.dart';
import 'chat_screen.dart';
import 'package:nex_app/screens/gaming_hub_screen.dart';
import 'profile_screen.dart';
import 'group_chat_screen.dart';
import 'join_group_screen.dart';
import 'my_statuses_screen.dart';
import 'settings_screen.dart';
import 'status_viewer_screen.dart';
import 'terminal_screen.dart';
import 'video_feed_screen.dart' as video_feed;
import 'offline_chat_screen.dart';
import 'ai_chat_screen.dart'; // Added for your smart AI

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<String> _selectedChats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14), // Modern Deep Navy
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildProAppBar(),
          SliverToBoxAdapter(
            child: HubFeaturePanel(
              onSearch: () => _showSearchDialog(context),
              features: [
                HubFeature(
                  title: 'AI CORE',
                  subtitle: 'Smart assistant',
                  icon: Icons.smart_toy_rounded,
                  color: kNeonBlue,
                  onTap: () => Navigator.pushNamed(context, AIChatScreen.routeName),
                ),
                HubFeature(
                  title: 'TERMINAL',
                  subtitle: 'Secure shell',
                  icon: Icons.terminal_rounded,
                  color: Colors.greenAccent,
                  onTap: () => Navigator.pushNamed(context, TerminalScreen.routeName),
                ),
                HubFeature(
                  title: 'GAMING',
                  subtitle: 'Arena sessions',
                  icon: Icons.sports_esports_rounded,
                  color: kNeonPurple,
                  onTap: () => Navigator.pushNamed(context, GamingHubScreen.routeName),
                ),
                HubFeature(
                  title: 'BETTING',
                  subtitle: 'Stake tokens',
                  icon: Icons.monetization_on_rounded,
                  color: Colors.amberAccent,
                  onTap: () => Navigator.pushNamed(context, BettingScreen.routeName),
                ),
                HubFeature(
                  title: 'REELS',
                  subtitle: 'Video feed',
                  icon: Icons.video_library_rounded,
                  color: Colors.redAccent,
                  onTap: () => Navigator.pushNamed(context, video_feed.VideoFeedScreen.routeName),
                ),
                HubFeature(
                  title: 'NEWS',
                  subtitle: 'Announcements',
                  icon: Icons.campaign_rounded,
                  color: kNeonBlue,
                  onTap: () => Navigator.pushNamed(context, AnnouncementsScreen.routeName),
                ),
                HubFeature(
                  title: 'MARKET',
                  subtitle: 'Ads & offers',
                  icon: Icons.ads_click_rounded,
                  color: kNeonPurple,
                  onTap: () => Navigator.pushNamed(context, AdvertisementScreen.routeName),
                ),
                HubFeature(
                  title: 'PROFILE',
                  subtitle: 'Account center',
                  icon: Icons.account_circle_rounded,
                  color: kNeonGreen,
                  onTap: () => Navigator.pushNamed(context, ProfileScreen.routeName),
                ),
                HubFeature(
                  title: 'OFFLINE CHAT',
                  subtitle: 'Bluetooth transfer',
                  icon: Icons.bluetooth_rounded,
                  color: kNeonBlue,
                  onTap: () => Navigator.pushNamed(context, OfflineChatScreen.routeName),
                ),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            _buildCustomTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildChats(context),
                  _buildStatus(context),
                  _buildCalls(context),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kNeonPurple,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
        onPressed: () => Navigator.pushNamed(context, ChatScreen.routeName),
      ),
    );
  }

  Widget _buildProAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: const Color(0xFF0A111F),
      elevation: 0,
      expandedHeight: 80,
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [kNeonPurple, Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: kNeonPurple.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('NEXCHAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1)),
              Text('QUANTUM ENCRYPTED', style: TextStyle(color: kNeonPurple, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white70),
          onPressed: () => _showSearchDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white70),
          onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildOperationsBar() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildOpItem(Icons.smart_toy_rounded, 'AI Core', kNeonBlue, () => Navigator.pushNamed(context, AIChatScreen.routeName)),
          _buildOpItem(Icons.terminal_rounded, 'Terminal', Colors.greenAccent, () => Navigator.pushNamed(context, TerminalScreen.routeName)),
          _buildOpItem(Icons.sports_esports_rounded, 'Gaming', kNeonPurple, () => Navigator.pushNamed(context, GamingHubScreen.routeName)),
          _buildOpItem(Icons.monetization_on_rounded, 'Betting', Colors.amberAccent, () => Navigator.pushNamed(context, BettingScreen.routeName)),
          _buildOpItem(Icons.video_library_rounded, 'Reels', Colors.redAccent, () => Navigator.pushNamed(context, video_feed.VideoFeedScreen.routeName)),
          _buildOpItem(Icons.campaign_rounded, 'News', kNeonBlue, () => Navigator.pushNamed(context, AnnouncementsScreen.routeName)),
          _buildOpItem(Icons.ads_click_rounded, 'Market', kNeonPurple, () => Navigator.pushNamed(context, AdvertisementScreen.routeName)),
        ],
      ),
    );
  }

  Widget _buildOpItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        width: 70,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: kNeonPurple,
      indicatorWeight: 4,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white30,
      labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
      tabs: const [
        Tab(text: 'MESSAGES'),
        Tab(text: 'STORY'),
        Tab(text: 'SECURE CALLS'),
      ],
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1E36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('SEARCH NEURAL NETWORK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'User identity or encrypted ID...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF070B14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ABORT', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kNeonPurple),
            onPressed: () => Navigator.pop(context),
            child: const Text('SCAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  Widget _buildChats(BuildContext context) {
    final chatService = ChatService();
    final currentUserId = chatService.currentUserId;

    if (currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 80, color: kNeonPurple.withOpacity(0.15)),
            const SizedBox(height: 24),
            const Text(
              'ENCRYPTED ACCESS REQUIRED',
              style: TextStyle(color: kNeonPurple, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please authorize to view active nodes.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: chatService.getConversations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNeonPurple, strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text('DATA SYNC ERROR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyChats(context);

        return Column(
          children: [
            // Selection Mode Header: Professional "Glass" Design
            if (_selectedChats.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kNeonPurple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kNeonPurple.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.checklist_rtl_rounded, color: kNeonPurple, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedChats.length} NODES SELECTED',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearSelection,
                      child: const Text('ABORT', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _createGroupFromSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNeonPurple,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('MERGE GROUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
              ),

            // Chat List: Modern Card-Style Tiles
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final conversationId = docs[index].id;
                  final isGroup = (data['isGroup'] ?? false) as bool;
                  final lastMessage = (data['lastMessage'] ?? 'No activity logged...').toString();
                  final timeText = _formatTime(data['lastMessageTime']);

                  return FutureBuilder<Map<String, String>>(
                    future: _resolveConversationTitle(data, currentUserId),
                    builder: (context, titleSnapshot) {
                      final title = titleSnapshot.data?['name'] ?? 'Authorized User';
                      final avatarLabel = title.isNotEmpty ? title[0].toUpperCase() : 'N';
                      final isSelected = _selectedChats.contains(conversationId);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kNeonPurple.withOpacity(0.15)
                              : const Color(0xFF0D1E36).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? kNeonPurple : Colors.white.withOpacity(0.05),
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          onLongPress: () => _toggleChatSelection(conversationId),
                          onTap: () {
                            if (_selectedChats.isNotEmpty) {
                              _toggleChatSelection(conversationId);
                            } else {
                              _openChat(conversationId, isGroup, title);
                            }
                          },
                          contentPadding: const EdgeInsets.all(12),
                          leading: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_selectedChats.isNotEmpty)
                                Transform.scale(
                                  scale: 0.9,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) => _toggleChatSelection(conversationId),
                                    activeColor: kNeonPurple,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              if (_selectedChats.isEmpty)
                                _buildModernAvatar(avatarLabel, isGroup),
                            ],
                          ),
                          title: Text(
                            title.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              lastMessage,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeText,
                                style: TextStyle(
                                  color: kNeonPurple.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (_selectedChats.isEmpty)
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    color: const Color(0xFF0D1E36),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (value) => _handleChatAction(conversationId, value, data),
                                    itemBuilder: (context) => [
                                      _buildPopupItem('pin', Icons.push_pin_rounded, 'PIN NODE'),
                                      _buildPopupItem('archive', Icons.archive_rounded, 'ARCHIVE'),
                                      _buildPopupItem('mute', Icons.notifications_off_rounded, 'MUTE'),
                                      _buildPopupItem('delete', Icons.delete_sweep_rounded, 'PURGE', isDestructive: true),
                                    ],
                                    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white24, size: 20),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ],
          );
        },
      );
  }

// Pro Helper for Menus to keep the logic clean and professional
PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label, {bool isDestructive = false}) {
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Icon(icon, color: isDestructive ? Colors.redAccent : kNeonPurple, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

void _createGroupFromSelection() async {
if (_selectedChats.isEmpty) return;

final chatService = ChatService();
final currentUserId = chatService.currentUserId;

if (currentUserId == null) {
if (!mounted) return;
_showSystemSnackBar(context, 'AUTH_REQUIRED: SIGN IN TO PROCEED', isError: true);
return;
}

final allParticipants = <String>{currentUserId};

for (final conversationId in _selectedChats) {
try {
final doc = await FirebaseFirestore.instance
.collection('conversations')
.doc(conversationId)
.get();

if (doc.exists) {
final data = doc.data()!;
final participants = List<String>.from(data['participants'] ?? []);
allParticipants.addAll(participants);
}
} catch (e) {
debugPrint('NODE_SYNC_ERROR: $e');
}
}

try {
final groupId = await chatService.createConversation(
participantIds: allParticipants.toList(),
groupName: 'SECURE_GROUP_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
isGroup: true,
);

_clearSelection();
if (!mounted) return;

Navigator.push(
context,
MaterialPageRoute(builder: (_) => GroupChatScreen(conversationId: groupId)),
);

_showSystemSnackBar(context, 'GROUP_ESTABLISHED: ENCRYPTION ACTIVE');
} catch (e) {
if (!mounted) return;
_showSystemSnackBar(context, 'FAILURE: $e', isError: true);
}
}

void _handleChatAction(String conversationId, String action, Map<String, dynamic> chatData) async {
final chatService = ChatService();
try {
switch (action) {
case 'pin':
await chatService.pinConversation(conversationId);
if (!mounted) return;
_showSystemSnackBar(context, 'NODE_PINNED');
break;
case 'archive':
await chatService.archiveConversation(conversationId);
if (!mounted) return;
_showSystemSnackBar(context, 'NODE_ARCHIVED');
break;
case 'mute':
await chatService.muteConversation(conversationId);
if (!mounted) return;
_showSystemSnackBar(context, 'ALERTS_SILENCED');
break;
case 'delete':
final confirmed = await _showProConfirmDialog(
context,
title: 'PURGE CONVERSATION',
content: 'This will permanently remove the data node. Proceed?'
);

if (confirmed == true) {
await chatService.deleteConversation(conversationId);
if (!mounted) return;
_showSystemSnackBar(context, 'DATA_PURGED', isError: true);
}
break;
}
} catch (e) {
if (!mounted) return;
_showSystemSnackBar(context, 'SYSTEM_ERROR: $e', isError: true);
}
}

// --- Pro UI Helpers ---
void _showSystemSnackBar(BuildContext context, String message, {bool isError = false}) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
backgroundColor: isError ? Colors.redAccent : kNeonPurple,
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
duration: const Duration(seconds: 2),
),
);
}

Future<bool?> _showProConfirmDialog(BuildContext context, {required String title, required String content}) {
return showDialog<bool>(
context: context,
builder: (context) => AlertDialog(
backgroundColor: const Color(0xFF0D1E36),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
content: Text(content, style: const TextStyle(color: Colors.white54, fontSize: 13)),
actions: [
TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ABORT', style: TextStyle(color: Colors.white24))),
ElevatedButton(
onPressed: () => Navigator.pop(context, true),
style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
),
],
),
);
}


Widget _buildEmptyChats(BuildContext context) {
return Padding(
padding: const EdgeInsets.symmetric(horizontal: 40),
child: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Stack(
alignment: Alignment.center,
children: [
_buildPulseRing(kNeonPurple, 1.5), // Using our pulse ring helper
Container(
width: 100,
height: 100,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: kNeonPurple.withValues(alpha: 0.1),
border: Border.all(color: kNeonPurple.withValues(alpha: 0.2)),
),
child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: kNeonPurple.withValues(alpha: 0.5)),
),
],
),
const SizedBox(height: 32),
const Text(
'NO ACTIVE NODES',
textAlign: TextAlign.center,
style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2),
),
const SizedBox(height: 12),
const Text(
'Your encrypted communication network is empty. Initiate a new connection to begin.',
textAlign: TextAlign.center,
style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
),
const SizedBox(height: 32),
ElevatedButton(
onPressed: () => Navigator.pushNamed(context, ChatScreen.routeName),
style: ElevatedButton.styleFrom(
backgroundColor: kNeonPurple,
padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
elevation: 10,
shadowColor: kNeonPurple.withValues(alpha: 0.4),
),
child: const Text('INITIATE_CHAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
),
],
),
),
);
}

void _toggleChatSelection(String conversationId) {
  setState(() {
    if (_selectedChats.contains(conversationId)) {
      _selectedChats.remove(conversationId);
    } else {
      _selectedChats.add(conversationId);
    }
  });
}

void _clearSelection() {
  setState(() {
    _selectedChats.clear();
  });
}

void _openChat(String conversationId, bool isGroup, String title) {
  Navigator.pushNamed(
    context,
    ChatScreen.routeName,
    arguments: {
      'conversationId': conversationId,
      'participantName': title,
    },
  );
}

String _formatTime(dynamic timestamp) {
  if (timestamp == null) return 'NOW';
  if (timestamp is Timestamp) {
    timestamp = timestamp.toDate();
  }

  if (timestamp is DateTime) {
    final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  return timestamp.toString();
}

Future<Map<String, String>> _resolveConversationTitle(Map<String, dynamic> data, String currentUserId) async {
  final name = (data['name'] as String?)?.trim();
  if (name != null && name.isNotEmpty) {
    return {'name': name};
  }

  final participants = List<String>.from(data['participants'] ?? <String>[]);
  final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => currentUserId);

  if (otherUserId.isEmpty) {
    return {'name': 'NEX NODE'};
  }

  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
    if (doc.exists) {
      final userData = doc.data() as Map<String, dynamic>;
      return {
        'name': (userData['username'] as String?) ?? (userData['name'] as String?) ?? 'NEX NODE',
      };
    }
  } catch (_) {
    debugPrint('Could not resolve conversation title for $otherUserId');
  }

  return {'name': 'NEX NODE'};
}

Widget _buildModernAvatar(String label, bool isGroup) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: [kNeonPurple.withValues(alpha: 0.3), kNeonBlue.withValues(alpha: 0.3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
    ),
    child: Center(
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
      ),
    ),
  );
}

Widget _buildPopupMenuButton(BuildContext context) {
  return PopupMenuButton<String>(
    padding: EdgeInsets.zero,
    color: const Color(0xFF0D1E36),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    icon: const Icon(Icons.more_horiz_rounded, color: Colors.white24, size: 20),
    onSelected: (value) {
      if (value == 'my_statuses') {
        Navigator.pushNamed(context, MyStatusesScreen.routeName);
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(value: 'my_statuses', child: Text('MY_STATUSES', style: TextStyle(color: Colors.white))),
    ],
  );
}

Widget _buildPulseRing(Color color, double scale) {
  return Container(
    width: 100 * scale,
    height: 100 * scale,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color.withValues(alpha: 0.18), width: 2),
    ),
  );
}

// Optimized Status Header
Widget _buildStatus(BuildContext context) {
final statusService = StatusService();

return StreamBuilder<QuerySnapshot>(
stream: statusService.getStatuses(),
builder: (context, snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(child: CircularProgressIndicator(color: kNeonPurple, strokeWidth: 2));
}

if (snapshot.hasError) {
return const Center(
child: Text('STATUS_LINK_ERROR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
);
}

final statuses = snapshot.data?.docs ?? [];

return SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Padding(
padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
child: Text('MY_BROADCAST', style: TextStyle(color: kNeonPurple, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Container(
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(24),
color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
),
child: ListTile(
contentPadding: const EdgeInsets.all(12),
leading: Container(
width: 54,
height: 54,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(18),
gradient: const LinearGradient(colors: [kNeonPurple, kNeonDarkPurple]),
boxShadow: [
BoxShadow(color: kNeonPurple.withValues(alpha: 0.3), blurRadius: 12),
],
),
child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
),
title: const Text(
'STORY_FEED',
style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
),
subtitle: const Text(
'Broadcast an update to your nodes',
style: TextStyle(color: Colors.white38, fontSize: 12),
),
trailing: _buildPopupMenuButton(context),
onTap: () => _showAddStatusDialog(context),
),
),
),
// ... [Previous logic]
if (statuses.isNotEmpty) ...[
const Padding(
padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
child: Text(
'RECENT_TRANSMISSIONS',
style: TextStyle(
color: kNeonPurple,
fontSize: 10,
fontWeight: FontWeight.w900,
letterSpacing: 2,
),
),
),
// Modern Status List
ListView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
padding: const EdgeInsets.symmetric(horizontal: 16),
itemCount: statuses.length,
itemBuilder: (context, index) {
final statusDoc = statuses[index];
final statusData = statusDoc.data() as Map<String, dynamic>;
final statusId = statusDoc.id;
final userId = statusData['userId'] as String?;
final text = statusData['text'] as String?;
final mediaType = statusData['mediaType'] as String? ?? 'text';
final createdAt = statusData['createdAt'] as Timestamp?;
final views = statusData['views'] as int? ?? 0;

final timeText = createdAt != null ? _formatTime(createdAt.toDate()) : 'Now';

return FutureBuilder<Map<String, String>>(
future: _getUserInfo(userId),
builder: (context, userSnapshot) {
final userName = userSnapshot.data?['name'] ?? 'Authorized User';
final avatarLabel = userName.isNotEmpty ? userName[0].toUpperCase() : 'N';

return Container(
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
color: const Color(0xFF0D1E36).withValues(alpha: 0.3),
borderRadius: BorderRadius.circular(20),
border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
),
child: ListTile(
contentPadding: const EdgeInsets.all(12),
leading: Container(
width: 54,
height: 54,
padding: const EdgeInsets.all(2.5),
decoration: BoxDecoration(
shape: BoxShape.circle,
border: Border.all(color: kNeonPurple, width: 2), // The "Unread" Glow
boxShadow: [
BoxShadow(
color: kNeonPurple.withValues(alpha: 0.2),
blurRadius: 10,
),
],
),
child: Container(
decoration: const BoxDecoration(
shape: BoxShape.circle,
color: Color(0xFF131C2E),
),
child: Center(
child: Text(
avatarLabel,
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
),
),
),
),
title: Row(
children: [
Text(
userName.toUpperCase(),
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
),
const Spacer(),
Text(
timeText.toUpperCase(),
style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold),
),
],
),
subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 4),
Text(
text ?? 'No description available',
style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.3),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
const SizedBox(height: 8),
Row(
children: [
_buildMediaBadge(mediaType),
const SizedBox(width: 8),
Icon(Icons.visibility_outlined, size: 12, color: kNeonPurple.withValues(alpha: 0.6)),
const SizedBox(width: 4),
Text(
'$views VIEWS',
style: TextStyle(color: kNeonPurple.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w900),
),
],
),
],
),
onTap: () => _viewStatus(context, statusId, statusData),
),
);
},
);
},
),
// ... closure logic
] else ...[
// Pro Empty State: High-Tech Broadcast Look
Padding(
padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
width: 90,
height: 90,
decoration: BoxDecoration(
color: kNeonPurple.withValues(alpha: 0.05),
shape: BoxShape.circle,
border: Border.all(color: kNeonPurple.withValues(alpha: 0.1)),
),
child: Icon(Icons.sensors_rounded, size: 40, color: kNeonPurple.withValues(alpha: 0.3)),
),
const SizedBox(height: 32),
const Text(
'NO ACTIVE BROADCASTS',
textAlign: TextAlign.center,
style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5),
),
const SizedBox(height: 12),
const Text(
'Your network is silent. Be the first to transmit a status update to your connected nodes.',
textAlign: TextAlign.center,
style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
),
],
),
),
],
],
),
);
},
);
}

void _showAddStatusDialog(BuildContext context) {
final TextEditingController statusController = TextEditingController();
String selectedMediaType = 'text';

showDialog(
context: context,
builder: (context) => StatefulBuilder(
builder: (context, setState) => AlertDialog(
backgroundColor: const Color(0xFF0D1E36),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: kNeonPurple.withValues(alpha: 0.2))),
title: Row(
children: [
Icon(Icons.add_reaction_rounded, color: kNeonPurple, size: 20),
const SizedBox(width: 12),
const Text('TRANSMIT STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
],
),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
TextField(
controller: statusController,
style: const TextStyle(color: Colors.white, fontSize: 14),
decoration: InputDecoration(
hintText: "What's the latest update?",
hintStyle: const TextStyle(color: Colors.white24),
filled: true,
fillColor: const Color(0xFF070B14),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
contentPadding: const EdgeInsets.all(16),
),
maxLines: 4,
),
const SizedBox(height: 20),
const Text('MEDIA_PROTOCOL', style: TextStyle(color: kNeonPurple, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
const SizedBox(height: 8),
Container(
padding: const EdgeInsets.symmetric(horizontal: 12),
decoration: BoxDecoration(
color: const Color(0xFF070B14),
borderRadius: BorderRadius.circular(12),
),
child: DropdownButtonHideUnderline(
child: DropdownButton<String>(
value: selectedMediaType,
dropdownColor: const Color(0xFF0D1E36),
icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kNeonPurple),
isExpanded: true,
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
items: const [
DropdownMenuItem(value: 'text', child: Text('TEXT_ONLY')),
DropdownMenuItem(value: 'image', child: Text('IMAGE_DATA')),
DropdownMenuItem(value: 'video', child: Text('VIDEO_FEED')),
],
onChanged: (value) => setState(() => selectedMediaType = value!),
),
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('ABORT', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
),
ElevatedButton(
onPressed: () async {
if (statusController.text.trim().isNotEmpty) {
final messenger = ScaffoldMessenger.of(context);
final navigator = Navigator.of(context);

try {
final statusService = StatusService();
await statusService.postStatus(
text: statusController.text.trim(),
mediaType: selectedMediaType,
);

if (!mounted) return; // FIXED: Async gap check
navigator.pop();
_showSystemSnackBar(context, 'STATUS_TRANSMITTED');
} catch (e) {
if (!mounted) return;
_showSystemSnackBar(context, 'TRANSMISSION_FAILED', isError: true);
}
}
},
style: ElevatedButton.styleFrom(
backgroundColor: kNeonPurple,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
),
child: const Text('POST_LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
),
],
),
),
);
}

// Media Badge Helper for the Status Feed
Widget _buildMediaBadge(String type) {
return Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(
color: kNeonPurple.withValues(alpha: 0.1),
borderRadius: BorderRadius.circular(4),
),
child: Text(
type.toUpperCase(),
style: const TextStyle(color: kNeonPurple, fontSize: 8, fontWeight: FontWeight.w900),
),
);
}

void _showMyStatuses(BuildContext context) {
Navigator.pushNamed(context, '/my-statuses');
}

void _viewStatus(BuildContext context, String statusId, Map<String, dynamic> statusData) {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => StatusViewerScreen(
statusId: statusId,
statusData: statusData,
),
),
);
}

Future<Map<String, String>> _getUserInfo(String? userId) async {
if (userId == null) return {'name': 'Unknown Node'};

try {
final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
if (doc.exists) {
final data = doc.data() as Map<String, dynamic>;
return {
'name': data['username'] ?? data['name'] ?? 'Authorized User',
'email': data['email'] ?? '',
};
}
} catch (e) {
debugPrint('NODE_SYNC_ERROR: $e');
}
return {'name': 'Unknown Node'};
}

Widget _buildCalls(BuildContext context) {
return const CallsScreen();
}
} // End of _HomeScreenState

