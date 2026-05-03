import 'package:flutter/material.dart';
import '../main.dart';

class GamingHubScreen extends StatefulWidget {
  static const routeName = '/gaming-hub';
  const GamingHubScreen({super.key});

  @override
  State<GamingHubScreen> createState() => _GamingHubScreenState();
}

class _GamingHubScreenState extends State<GamingHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1410),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1410),
        title: const Row(
          children: [
            Text('🎮', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Gaming Hub', style: TextStyle(color: Colors.white)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kNeonGreen,
          unselectedLabelColor: Colors.white54,
          indicatorColor: kNeonGreen,
          tabs: const [
            Tab(text: 'Games'),
            Tab(text: 'Gamers'),
            Tab(text: 'Clans'),
            Tab(text: 'Squads'),
            Tab(text: 'Clips'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGamesTab(),
          _buildGamersTab(),
          _buildClansTab(),
          _buildSquadsTab(),
          _buildClipsTab(),
        ],
      ),
    );
  }

  Widget _buildGamesTab() {
    final List<Map<String, dynamic>> games = [
      {'name': 'Aviator', 'icon': '✈️', 'players': '12.5K', 'category': 'Casino'},
      {'name': 'Mines', 'icon': '💣', 'players': '8.2K', 'category': 'Strategy'},
      {'name': 'Spin Wheel', 'icon': '🎡', 'players': '6.8K', 'category': 'Casino'},
      {'name': 'Lucky Slots', 'icon': '🎰', 'players': '5.1K', 'category': 'Casino'},
      {'name': 'Card Battle', 'icon': '🃏', 'players': '3.4K', 'category': 'Card'},
      {'name': 'Racing', 'icon': '🏎️', 'players': '2.9K', 'category': 'Racing'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                kNeonPurple.withValues(alpha: 0.2),
                kNeonBlue.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kNeonPurple.withValues(alpha: 0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, '/bet'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game['icon'] as String,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${game['players']} players',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kNeonGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        game['category'] as String,
                        style: const TextStyle(color: kNeonGreen, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGamersTab() {
    final List<Map<String, dynamic>> gamers = [
      {'name': 'NexGamer99', 'rank': 'Diamond', 'score': '15,420', 'avatar': 'N'},
      {'name': 'ProPlayer_X', 'rank': 'Platinum', 'score': '12,890', 'avatar': 'P'},
      {'name': 'GameMaster', 'rank': 'Gold', 'score': '10,250', 'avatar': 'G'},
      {'name': 'EliteSniper', 'rank': 'Gold', 'score': '9,870', 'avatar': 'E'},
      {'name': 'CasualKing', 'rank': 'Silver', 'score': '7,540', 'avatar': 'C'},
      {'name': 'NightOwl', 'rank': 'Silver', 'score': '6,320', 'avatar': 'N'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: gamers.length,
      itemBuilder: (context, index) {
        final gamer = gamers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: kNeonPurple.withValues(alpha: 0.2),
                child: Text(
                  gamer['avatar'] as String,
                  style: const TextStyle(
                    color: kNeonPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gamer['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getRankColor(gamer['rank'] as String).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            gamer['rank'] as String,
                            style: TextStyle(
                              color: _getRankColor(gamer['rank'] as String),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Score: ${gamer['score']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_add, color: kNeonGreen),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClansTab() {
    final List<Map<String, dynamic>> clans = [
      {'name': 'Nex Warriors', 'members': 45, 'rank': 'S', 'wins': 128},
      {'name': 'Shadow Legion', 'members': 38, 'rank': 'A', 'wins': 95},
      {'name': 'Elite Force', 'members': 32, 'rank': 'A', 'wins': 87},
      {'name': 'Phoenix Rising', 'members': 28, 'rank': 'B', 'wins': 64},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clans.length,
      itemBuilder: (context, index) {
        final clan = clans[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                kNeonGreen.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kNeonGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: kNeonGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    clan['rank'] as String,
                    style: const TextStyle(
                      color: kNeonGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clan['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${clan['members']} members • ${clan['wins']} wins',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNeonGreen,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {},
                child: const Text('Join'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSquadsTab() {
    final List<Map<String, dynamic>> squads = [
      {'name': 'Late Night Gamers', 'game': 'Aviator', 'members': '3/4', 'time': 'Now'},
      {'name': 'Casual Crew', 'game': 'Mines', 'members': '2/4', 'time': '30m'},
      {'name': 'Pro Squad', 'game': 'Spin Wheel', 'members': '4/4', 'time': '1h'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: squads.length,
      itemBuilder: (context, index) {
        final squad = squads[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kNeonBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kNeonBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group, color: kNeonBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      squad['name'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.videogame_asset, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          squad['game'] as String,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.people, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          squad['members'] as String,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kNeonGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      squad['time'] as String,
                      style: const TextStyle(color: kNeonGreen, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNeonBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () {},
                    child: const Text('Join'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClipsTab() {
    final List<Map<String, dynamic>> clips = [
      {'title': 'Insane Aviator Win!', 'author': 'NexGamer99', 'views': '12.5K', 'duration': '0:45'},
      {'title': 'Mines Strategy Guide', 'author': 'ProPlayer_X', 'views': '8.2K', 'duration': '3:20'},
      {'title': 'Biggest Win of 2024', 'author': 'GameMaster', 'views': '25K', 'duration': '1:15'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clips.length,
      itemBuilder: (context, index) {
        final clip = clips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail placeholder
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kNeonPurple.withValues(alpha: 0.3),
                      kNeonBlue.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clip['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: kNeonPurple.withValues(alpha: 0.2),
                          child: Text(
                            (clip['author'] as String)[0],
                            style: const TextStyle(color: kNeonPurple, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          clip['author'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          clip['views'] as String,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          clip['duration'] as String,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
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
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Diamond':
        return const Color(0xFFB9F2FF);
      case 'Platinum':
        return const Color(0xFFE5E4E2);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Silver':
        return const Color(0xFFC0C0C0);
      default:
        return Colors.white;
    }
  }
}
