import 'package:flutter/material.dart';
import '../main.dart';
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


  // Mock video data - in production, fetch from Firebase
  final List<Map<String, dynamic>> videos = [
    {
      'id': '1',
      'username': 'alex_creates',
      'avatar': 'A',
      'description': 'Check out my new beat production! 🎵',
      'likes': 2540,
      'comments': 324,
      'shares': 156,
      'duration': '0:45',
      'liked': false,
    },
    {
      'id': '2',
      'username': 'dev_life',
      'avatar': 'D',
      'description': 'Building NEX-APP in real-time 💻 #Flutter #Development',
      'likes': 5120,
      'comments': 687,
      'shares': 423,
      'duration': '2:15',
      'liked': false,
    },
    {
      'id': '3',
      'username': 'gaming_pro',
      'avatar': 'G',
      'description': 'Insane gaming moments 🎮 New game incoming!',
      'likes': 8934,
      'comments': 1203,
      'shares': 567,
      'duration': '1:32',
      'liked': false,
    },
    {
      'id': '4',
      'username': 'lifestyle_hub',
      'avatar': 'L',
      'description': 'Morning routine that changed my life ✨',
      'likes': 12450,
      'comments': 2103,
      'shares': 934,
      'duration': '3:45',
      'liked': false,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleLike(int index) {
    setState(() {
      videos[index]['liked'] = !videos[index]['liked'];
      if (videos[index]['liked']) {
        videos[index]['likes']++;
      } else {
        videos[index]['likes']--;
      }
    });
  }

  void _showAIHelperSheet(BuildContext context) async {
    final status = await AIService.instance.getIntegrationStatus();
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
                if (mounted) {
                  Navigator.pop(context);
                  _showInfoDialog(context, 'Reels Tips', response);
                }
              },
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('AI Reels Tips'),
              style: ElevatedButton.styleFrom(backgroundColor: kNeonBlue),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final caption = await AIService.instance.generateCaption('Create a remix caption for NEX Reels.');
                if (mounted) {
                  Navigator.pop(context);
                  _showInfoDialog(context, 'AI Caption', caption);
                }
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
    return Scaffold(
      backgroundColor: kDarkBackground,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('NEX-Reels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            tooltip: 'AI Reels Helper',
            onPressed: () => _showAIHelperSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, VideoPostScreen.routeName),
        backgroundColor: kNeonGreen,
        label: const Text('Post Reels', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.video_camera_back, color: Colors.black),
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: (index) {
          // page changed to index
        },
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return _buildVideoCard(videos[index], index);
        },
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video, int index) {
    return Stack(
      children: [
        // Video placeholder
        Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: kNeonPurple.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.videocam, size: 60, color: kNeonGreen),
                ),
                const SizedBox(height: 16),
                Text(
                  'Video ${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  video['duration'],
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        // Video info and controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.9),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: kNeonPurple,
                      child: Text(
                        video['avatar'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video['username'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kNeonGreen,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Follow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  video['description'],
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Engagement buttons (right side)
        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              _buildActionButton(
                icon: video['liked'] ? Icons.favorite : Icons.favorite_border,
                label: '${video['likes']}',
                color: video['liked'] ? Colors.red : Colors.white,
                onTap: () => _toggleLike(index),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.comment_outlined,
                label: '${video['comments']}',
                color: Colors.white,
                onTap: () => _showCommentSheet(context, video),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: '${video['shares']}',
                color: Colors.white,
                onTap: () {},
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.more_vert,
                label: '',
                color: Colors.white,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  void _showCommentSheet(BuildContext context, Map<String, dynamic> video) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Comments (${video['comments']})',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildCommentTile('user_1', 'This is amazing! 🔥', '2h ago'),
                  _buildCommentTile('user_2', 'Love this content!', '1h ago'),
                  _buildCommentTile('user_3', 'Can\'t stop watching', '30m ago'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D2F49),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: kNeonPurple,
                    child: Text('Y', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add comment...',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: kNeonGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.send, color: Colors.black, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentTile(String username, String comment, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: kNeonPurple.withValues(alpha: 0.5),
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
