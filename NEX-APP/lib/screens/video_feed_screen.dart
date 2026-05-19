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
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 20),
                    SizedBox(width: 12),
                    Text('Search'),
                  ],
                ),
                onTap: () {},
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20),
                    SizedBox(width: 12),
                    Text('AI Helper'),
                  ],
                ),
                onTap: () => _showAIHelperSheet(context),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, VideoPostScreen.routeName),
        backgroundColor: kNeonPurple,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        label: const Text('Create Reels', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.video_camera_back),
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
        // Video placeholder with professional gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                kNeonPurple.withValues(alpha: 0.1),
                kDarkBackground,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [kNeonPurple.withValues(alpha: 0.4), kNeonDarkPurple.withValues(alpha: 0.4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: kNeonPurple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.videocam, size: 60, color: kNeonPurple.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Video ${index + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kNeonPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kNeonPurple.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    video['duration'],
                    style: const TextStyle(color: kNeonPurple, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
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
                  Colors.black.withValues(alpha: 0.8),
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
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [kNeonPurple, kNeonDarkPurple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: kNeonPurple.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          video['avatar'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video['username'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: kNeonPurple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Follow',
                              style: TextStyle(color: kNeonPurple, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Three dots menu
                    PopupMenuButton(
                      color: kSurfaceColor,
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          child: const Text('Report', style: TextStyle(color: Colors.white)),
                          onTap: () {},
                        ),
                        PopupMenuItem(
                          child: const Text('Share', style: TextStyle(color: Colors.white)),
                          onTap: () {},
                        ),
                        PopupMenuItem(
                          child: const Text('Save', style: TextStyle(color: Colors.white)),
                          onTap: () {},
                        ),
                      ],
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description
                Text(
                  video['description'],
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    _buildActionButton(
                      icon: video['liked'] ? Icons.favorite : Icons.favorite_border,
                      label: _formatCount(video['likes']),
                      color: video['liked'] ? Colors.red : Colors.white,
                      onTap: () => _toggleLike(index),
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.comment,
                      label: _formatCount(video['comments']),
                      color: Colors.white,
                      onTap: () {},
                    ),
                    const SizedBox(width: 20),
                    _buildActionButton(
                      icon: Icons.share,
                      label: _formatCount(video['shares']),
                      color: Colors.white,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.3),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
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

