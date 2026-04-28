import 'package:flutter/material.dart';
import '../main.dart';

class AnnouncementsScreen extends StatelessWidget {
  static const routeName = '/announcements';
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> announcements = [
      {
        'title': 'WELCOME TO NEXCHAT',
        'badge': 'NEX-DEV',
        'content': 'WELCOME TO NEXCHAT THE FUTURE IS INIT. WE ARE BRINGING YOU NEX_REELS SIMILAR TO TIKTOK/SNAPCHAT BUT IT WILL BE ON NEXCHAT BY NOVEMBER 23RD...',
        'admin': 'DEMON ALEX {LINUX-DEVELOPER}',
        'time': 'IMPORTANT Update',
        'pinned': true,
      },
      {
        'title': 'New Features Released',
        'badge': 'UPDATE',
        'content': 'We have added new AI chat features, improved token system, and faster messaging. Check out the settings to explore!',
        'admin': 'NEX Team',
        'time': '2 days ago',
        'pinned': false,
      },
      {
        'title': 'Maintenance Notice',
        'badge': 'SYSTEM',
        'content': 'Scheduled maintenance on Sunday from 2AM - 4AM UTC. Some features may be temporarily unavailable.',
        'admin': 'System Admin',
        'time': '5 days ago',
        'pinned': false,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Dark blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1E36), // Blue-tinted app bar
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kNeonBlue, kNeonBlue.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kNeonBlue.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.campaign, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Announcements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kNeonBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: kNeonBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          final isPinned = announcement['pinned'] as bool;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPinned
                    ? [kNeonBlue.withOpacity(0.15), kNeonBlue.withOpacity(0.05)]
                    : [const Color(0xFF0D1E36), const Color(0xFF0A1628)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPinned ? kNeonBlue.withOpacity(0.5) : Colors.white.withOpacity(0.1),
                width: isPinned ? 2 : 1,
              ),
              boxShadow: isPinned
                  ? [
                      BoxShadow(
                        color: kNeonBlue.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (isPinned)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: const Icon(Icons.push_pin, color: kNeonBlue, size: 18),
                        ),
                      Expanded(
                        child: Text(
                          announcement['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kNeonBlue, kNeonBlue.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kNeonBlue.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          announcement['badge'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    announcement['content'] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                // Footer
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.white54, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            announcement['time'] as String,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: kNeonBlue.withOpacity(0.7), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            announcement['admin'] as String,
                            style: TextStyle(
                              color: kNeonBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}