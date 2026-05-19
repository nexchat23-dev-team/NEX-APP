import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../services/status_service.dart';

class StatusViewerScreen extends StatefulWidget {
  final String statusId;
  final Map<String, dynamic> statusData;

  const StatusViewerScreen({
    super.key,
    required this.statusId,
    required this.statusData,
  });

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> with SingleTickerProviderStateMixin {
  final StatusService _statusService = StatusService();
  final TextEditingController _reactionController = TextEditingController();
  bool _isReacting = false;
  late AnimationController _animController;
  bool _cardVisible = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _cardVisible = true;
      });
      _animController.forward();
    });
    // Mark status as viewed
    _statusService.viewStatus(widget.statusId);
  }

  @override
  void dispose() {
    _reactionController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.statusData['userId'] as String?;
    final text = widget.statusData['text'] as String?;
    final mediaType = widget.statusData['mediaType'] as String? ?? 'text';
    final createdAt = widget.statusData['createdAt'] as Timestamp?;
    final views = widget.statusData['views'] as int? ?? 0;

    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        backgroundColor: kPrimaryBlue,
        title: const Text('📱 Status Viewer', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'react':
                  _showReactionDialog();
                  break;
                case 'share':
                  _shareStatus();
                  break;
                case 'report':
                  _reportStatus();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'react',
                child: Row(
                  children: [
                    Icon(Icons.add_reaction, color: kNeonGreen),
                    SizedBox(width: 8),
                    Text('Add Reaction'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: kNeonBlue),
                    SizedBox(width: 8),
                    Text('Share Status'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Report'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kDarkBackground, Color(0xFF0A1929)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Content Card
              AnimatedScale(
                scale: _cardVisible ? 1.0 : 0.96,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  opacity: _cardVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 700),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [kNeonPurple.withValues(alpha: 0.15), kNeonBlue.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: kNeonPurple.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: kNeonPurple.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // User Info Section
                        FutureBuilder<Map<String, String>>(
                          future: _getUserInfo(userId),
                          builder: (context, snapshot) {
                            final userName = snapshot.data?['name'] ?? 'User';
                            final avatarLabel = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

                            return Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [kNeonPurple, kNeonDarkPurple],
                                    ),
                                    border: Border.all(color: kNeonPurple, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: kNeonPurple.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      avatarLabel,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        createdAt != null ? _formatTime(createdAt.toDate()) : 'Just now',
                                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: kNeonPurple.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: kNeonPurple.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        mediaType == 'image' ? Icons.image :
                                        mediaType == 'video' ? Icons.videocam : Icons.text_fields,
                                        size: 18,
                                        color: kNeonPurple,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        mediaType.toUpperCase(),
                                        style: const TextStyle(color: kNeonPurple, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Status Text
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: kSurfaceColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            text ?? 'Status update',
                            style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Stats Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kNeonBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.visibility, size: 16, color: kNeonBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$views views',
                                    style: const TextStyle(color: kNeonBlue, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            StreamBuilder<QuerySnapshot>(
                              stream: _statusService.getStatusReactions(widget.statusId),
                              builder: (context, snapshot) {
                                final reactions = snapshot.data?.docs ?? [];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: kNeonGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: kNeonGreen.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.favorite, size: 16, color: kNeonGreen),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${reactions.length} reactions',
                                        style: const TextStyle(color: kNeonGreen, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Reactions Section Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kSurfaceColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_emotions, color: kNeonGreen, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Reactions',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kNeonGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _statusService.getStatusReactions(widget.statusId),
                        builder: (context, snapshot) {
                          final count = snapshot.data?.docs.length ?? 0;
                          return Text(
                            '$count',
                            style: const TextStyle(color: kNeonGreen, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reactions List
              StreamBuilder<QuerySnapshot>(
                stream: _statusService.getStatusReactions(widget.statusId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: kNeonPurple));
                  }

                  final reactions = snapshot.data?.docs ?? [];

                  if (reactions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kSurfaceColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.emoji_emotions_outlined, color: Colors.white30, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'No reactions yet',
                            style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Be the first to react to this status!',
                            style: TextStyle(color: Colors.white30, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final reactionDoc = reactions[index];
                      final reactionData = reactionDoc.data() as Map<String, dynamic>;
                      final reactionUserId = reactionData['userId'] as String?;
                      final reactionText = reactionData['reaction'] as String?;
                      final reactionCreatedAt = reactionData['createdAt'] as Timestamp?;

                      return FutureBuilder<Map<String, String>>(
                        future: _getUserInfo(reactionUserId),
                        builder: (context, userSnapshot) {
                          final reactionUserName = userSnapshot.data?['name'] ?? 'User';
                          final avatarLabel = reactionUserName.isNotEmpty ? reactionUserName[0].toUpperCase() : 'U';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white12, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [kNeonGreen.withValues(alpha: 0.6), kNeonGreen.withValues(alpha: 0.3)],
                                    ),
                                    border: Border.all(color: kNeonGreen.withValues(alpha: 0.5), width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      avatarLabel,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reactionUserName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: kSurfaceColor.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          reactionText ?? '',
                                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  reactionCreatedAt != null ? _formatTime(reactionCreatedAt.toDate()) : '',
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_reaction, color: kNeonGreen),
            SizedBox(width: 12),
            Text('Add Reaction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: _reactionController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'What do you think about this status?',
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: kDarkBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kNeonGreen, width: 2),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: _addReaction,
            icon: _isReacting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
            label: Text(_isReacting ? 'Adding...' : 'Add Reaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _addReaction() async {
    if (_reactionController.text.trim().isEmpty) return;

    setState(() => _isReacting = true);

    try {
      await _statusService.reactToStatus(
        widget.statusId,
        _reactionController.text.trim(),
      );

      _reactionController.clear();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Reaction added successfully!'),
          backgroundColor: kNeonGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isReacting = false);
    }
  }

  void _shareStatus() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Share functionality coming soon!'),
        backgroundColor: kNeonBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _reportStatus() {
    // TODO: Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚨 Report functionality coming soon!'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<Map<String, String>> _getUserInfo(String? userId) async {
    if (userId == null) return {'name': 'User'};

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'name': data['username'] ?? data['name'] ?? 'User',
          'email': data['email'] ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
    }
    return {'name': 'User'};
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}
