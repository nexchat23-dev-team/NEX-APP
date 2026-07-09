import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../screens/video_post_screen.dart';
import '../services/ai_service.dart';

class VideoFeedScreen extends StatefulWidget {
  static const routeName = '/video-feed';
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  late final List<Map<String, dynamic>> _videos = [
    {
      'id': '1',
      'username': 'alex_creates',
      'avatar': 'A',
      'title': 'Studio Drop',
      'description': 'Fresh beats and a clean new look for the weekend.',
      'hashtags': '#beats #nexreels',
      'likes': 2540,
      'comments': 324,
      'shares': 156,
      'duration': '0:45',
      'liked': false,
      'saved': false,
      'followed': false,
      'accent': const Color(0xFF8B5CF6),
      'mediaLabel': 'Music mix',
    },
    {
      'id': '2',
      'username': 'dev_life',
      'avatar': 'D',
      'title': 'Build in public',
      'description': 'Shipping the new chat experience and the polished reel feed.',
      'hashtags': '#flutter #buildinpublic',
      'likes': 5120,
      'comments': 687,
      'shares': 423,
      'duration': '2:15',
      'liked': false,
      'saved': false,
      'followed': false,
      'accent': const Color(0xFF22C55E),
      'mediaLabel': 'Behind the scenes',
    },
    {
      'id': '3',
      'username': 'gaming_pro',
      'avatar': 'G',
      'title': 'Best plays',
      'description': 'Quick highlights from a late-night session.',
      'hashtags': '#gaming #reels',
      'likes': 8934,
      'comments': 1203,
      'shares': 567,
      'duration': '1:32',
      'liked': false,
      'saved': false,
      'followed': false,
      'accent': const Color(0xFF60A5FA),
      'mediaLabel': 'Gameplay clip',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openCreateReel() async {
    final result = await Navigator.pushNamed(context, VideoPostScreen.routeName);
    if (!mounted || result == null) return;

    final reel = Map<String, dynamic>.from(result as Map);
    setState(() {
      _videos.insert(0, {
        ...reel,
        'likes': 0,
        'comments': 0,
        'shares': 0,
        'liked': false,
        'saved': false,
        'followed': false,
        'accent': reel['accent'] ?? const Color(0xFFB23BFF),
      });
    });
    _pageController.jumpToPage(0);
  }

  void _toggleLike(int index) {
    setState(() {
      final liked = _videos[index]['liked'] as bool;
      _videos[index]['liked'] = !liked;
      if (!liked) {
        _videos[index]['likes'] = (_videos[index]['likes'] as int) + 1;
      } else {
        _videos[index]['likes'] = (_videos[index]['likes'] as int) - 1;
      }
    });
  }

  void _toggleSave(int index) {
    setState(() {
      _videos[index]['saved'] = !(_videos[index]['saved'] as bool);
    });
  }

  void _toggleFollow(int index) {
    setState(() {
      _videos[index]['followed'] = !(_videos[index]['followed'] as bool);
    });
  }

  void _showCommentSheet(int index) {
    final controller = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave a comment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Say something nice...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isNotEmpty) {
                    setState(() => _videos[index]['comments'] = (_videos[index]['comments'] as int) + 1);
                  }
                  Navigator.pop(sheetContext);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Comment posted.')),
                  );
                },
                child: const Text('Post comment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareReel(int index) {
    final reel = _videos[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shared ${reel['title']} to your circle.')),
    );
    setState(() => _videos[index]['shares'] = (_videos[index]['shares'] as int) + 1);
  }

  void _showAIHelperSheet(BuildContext context) async {
    final navigator = Navigator.of(context);
    final status = await AIService.instance.getIntegrationStatus();
    if (!mounted) return;
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                width: 40,
                height: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'NEX AI Reels Helper',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(status, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final response = await AIService.instance.explainReelStyle('Explain how to make NEX-Reels more engaging.');
                if (!mounted || !context.mounted) return;
                if (navigator.canPop()) {
                  navigator.pop();
                }
                _showInfoDialog(context, 'Reels Tips', response);
              },
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('AI Reels Tips'),
              style: ElevatedButton.styleFrom(backgroundColor: kNeonBlue),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final caption = await AIService.instance.generateCaption('Create a remix caption for NEX Reels.');
                if (!mounted || !context.mounted) return;
                if (navigator.canPop()) {
                  navigator.pop();
                }
                _showInfoDialog(context, 'AI Caption', caption);
              },
              icon: const Icon(Icons.message),
              label: const Text('Generate Caption'),
              style: ElevatedButton.styleFrom(backgroundColor: kNeonGreen, foregroundColor: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: kNeonGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NEX-Reels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (_) => _showAIHelperSheet(context),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 12),
                    Text('Search'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'ai',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 12),
                    Text('AI Helper'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateReel,
        backgroundColor: kNeonPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: const Text('Create Reel', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.video_camera_back),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: (index) => setState(() => _videos[index]['playing'] = true),
        itemBuilder: (context, index) {
          return _buildVideoCard(_videos[index], index);
        },
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    final accent = video['accent'] as Color;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF070B14),
                accent.withValues(alpha: 0.25),
                kDarkBackground,
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 90, 16, 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.28),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)]),
                          ),
                          child: Center(
                            child: Text(
                              video['avatar'],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(video['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('${video['duration']} • ${video['mediaLabel']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _toggleFollow(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: video['followed'] ? Colors.white.withValues(alpha: 0.16) : kNeonPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              video['followed'] ? 'Following' : 'Follow',
                              style: TextStyle(color: video['followed'] ? Colors.white : kNeonPurple, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(video['title'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            video['description'],
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Text(video['hashtags'], style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.movie_filter, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text('Watch Reels', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('${index + 1}/${_videos.length}', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Positioned(
          right: 18,
          top: 140,
          child: Column(
            children: [
              _buildReelSideButton(icon: video['liked'] ? Icons.favorite : Icons.favorite_border, label: _formatCount(video['likes']), color: video['liked'] ? Colors.redAccent : Colors.white, onTap: () => _toggleLike(index)),
              const SizedBox(height: 16),
              _buildReelSideButton(icon: Icons.comment, label: _formatCount(video['comments']), color: Colors.white, onTap: () => _showCommentSheet(index)),
              const SizedBox(height: 16),
              _buildReelSideButton(icon: Icons.share, label: _formatCount(video['shares']), color: Colors.white, onTap: () => _shareReel(index)),
              const SizedBox(height: 16),
              _buildReelSideButton(icon: video['saved'] ? Icons.bookmark : Icons.bookmark_border, label: 'Save', color: video['saved'] ? kNeonGreen : Colors.white, onTap: () => _toggleSave(index)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReelSideButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
