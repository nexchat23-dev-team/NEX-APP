import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GamingHubScreen extends StatefulWidget {
  static const routeName = '/gaming-hub';
  const GamingHubScreen({super.key});

  @override
  State<GamingHubScreen> createState() => _GamingHubScreenState();
}

class _GamingHubScreenState extends State<GamingHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0A111F),
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kNeonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNeonGreen.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.sports_esports_rounded, color: kNeonGreen, size: 20),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GAMING_HUB',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                Text('SYSTEM_CORE_V3',
                    style: TextStyle(color: kNeonGreen, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kNeonGreen, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildAppBarAction(Icons.emoji_events_outlined, kNeonPurple, _showLeaderboard),
          _buildAppBarAction(Icons.more_vert_rounded, Colors.white38, null),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: kNeonGreen,
          unselectedLabelColor: Colors.white24,
          indicatorColor: kNeonGreen,
          indicatorWeight: 3,
          dividerColor: Colors.white10,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
          tabs: const [
            Tab(text: 'ARENA'),
            Tab(text: 'GAMERS'),
            Tab(text: 'CLANS'),
            Tab(text: 'SQUADS'),
            Tab(text: 'LIVE'),
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
          _buildSessionsTab(),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, Color color, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(icon: Icon(icon, color: color, size: 20), onPressed: onTap),
    );
  }

  Widget _buildGamesTab() {
    final List<Map<String, dynamic>> games = [
      {'name': 'AVIATOR', 'icon': Icons.airplanemode_active_rounded, 'color': kNeonBlue, 'players': '12.5K', 'trending': true, 'rating': 4.8, 'category': 'FLIGHT'},
      {'name': 'MINES', 'icon': Icons.brightness_high_rounded, 'color': Colors.orangeAccent, 'players': '8.2K', 'trending': true, 'rating': 4.5, 'category': 'STRATEGY'},
      {'name': 'SPIN DASH', 'icon': Icons.refresh_rounded, 'color': kNeonPurple, 'players': '6.8K', 'trending': false, 'rating': 4.3, 'category': 'RACING'},
      {'name': 'SKY PATROL', 'icon': Icons.rocket_launch_rounded, 'color': kNeonGreen, 'players': '4.7K', 'trending': true, 'rating': 4.7, 'category': 'ADVENTURE'},
    ];

    final Map<String, dynamic> activeTournament = {
      'title': 'ELITE_TOURNAMENTS',
      'participants': '128',
      'ends': '24H',
      'prize': '25K',
      'status': 'LIVE',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('ACTIVE_TOURNAY', Icons.bolt_rounded),
          const SizedBox(height: 16),
          _buildTournamentCard(activeTournament),
          const SizedBox(height: 32),
          _buildSectionHeader('POPULAR_ARENAS', Icons.grid_view_rounded),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: games.length,
            itemBuilder: (context, index) => _buildGameArenaCard(games[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kNeonGreen, size: 16),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildGameArenaCard(Map<String, dynamic> game) {
    final bool isTrending = game['trending'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTrending ? kNeonPurple.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleGameTap(game['name'] as String),
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (isTrending)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                    ),
                    child: const Text('LIVE', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(game['icon'] as IconData, size: 38, color: game['color'] as Color),
                    const SizedBox(height: 12),
                    Text(
                      (game['name'] as String).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 14),
                        const SizedBox(width: 4),
                        Text('${game['rating']}', style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${game['players']} ACTIVE_USERS',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kNeonPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (game['category'] as String).toUpperCase(),
                        style: const TextStyle(color: kNeonPurple, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kNeonGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kNeonGreen.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.military_tech_rounded, color: kNeonGreen, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (tournament['title'] as String).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${tournament['participants']} NODES • ', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text((tournament['ends'] as String).toUpperCase(), style: const TextStyle(color: kNeonGreen, fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tournament['prize']}'.toUpperCase(),
                style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.w900, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kNeonGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (tournament['status'] as String).toUpperCase(),
                  style: const TextStyle(color: kNeonGreen, fontSize: 8, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGamersTab() {
    final List<Map<String, dynamic>> gamers = [
      {'name': 'NexGamer99', 'rank': 'Diamond', 'score': '15,420', 'avatar': 'N'},
      {'name': 'ProPlayer_X', 'rank': 'Platinum', 'score': '12,890', 'avatar': 'P'},
      {'name': 'GameMaster', 'rank': 'Gold', 'score': '10,250', 'avatar': 'G'},
      {'name': 'EliteSniper', 'rank': 'Gold', 'score': '9,870', 'avatar': 'E'},
      {'name': 'CasualKing', 'rank': 'Silver', 'score': '7,540', 'avatar': 'C'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: gamers.length,
      itemBuilder: (context, index) {
        final gamer = gamers[index];
        final Color rankColor = _getRankColor(gamer['rank'] as String);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E36).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: _buildGamerAvatar(gamer['avatar'] as String, rankColor),
            title: Text(
              (gamer['name'] as String).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  _buildRankBadge(gamer['rank'] as String, rankColor),
                  const SizedBox(width: 10),
                  Text(
                    'XP: ${gamer['score']}',
                    style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                color: kNeonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded, color: kNeonGreen, size: 20),
                onPressed: () => _sendSquadInvite(gamer['name'] as String),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(String rank, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        rank.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildClansTab() {
    final List<Map<String, dynamic>> clans = [
      {'name': 'NEX_WARRIORS', 'members': 45, 'rank': 'S', 'wins': 128},
      {'name': 'SHADOW_LEGION', 'members': 38, 'rank': 'A', 'wins': 95},
      {'name': 'ELITE_FORCE', 'members': 32, 'rank': 'A', 'wins': 87},
      {'name': 'PHOENIX_RISING', 'members': 28, 'rank': 'B', 'wins': 64},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: clans.length,
      itemBuilder: (context, index) {
        final clan = clans[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kNeonGreen.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: kNeonGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kNeonGreen.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  clan['rank'] as String,
                  style: const TextStyle(color: kNeonGreen, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            title: Text(
              (clan['name'] as String).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${clan['members']} MEMBERS • ${clan['wins']} COMBAT_WINS',
                style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _handleClanJoin(clan['name'] as String),
              child: const Text('JOIN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSquadsTab() {
    final List<Map<String, dynamic>> squads = [
      {'name': 'NIGHT_OPERATORS', 'game': 'AVIATOR', 'members': '3/4', 'time': 'ACTIVE'},
      {'name': 'CASUAL_COOP', 'game': 'MINES', 'members': '2/4', 'time': '30M'},
      {'name': 'ELITE_STRIKE', 'game': 'SPIN_HUB', 'members': '4/4', 'time': 'STABLE'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: squads.length,
      itemBuilder: (context, index) {
        final squad = squads[index];
        final bool isFull = squad['members'] == '4/4';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kNeonBlue.withValues(alpha: 0.15)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kNeonBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.hub_rounded, color: kNeonBlue, size: 24),
            ),
            title: Text(
              (squad['name'] as String).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  _buildSquadTag(squad['game'] as String, kNeonBlue),
                  const SizedBox(width: 8),
                  _buildSquadTag(squad['members'] as String, isFull ? Colors.redAccent : kNeonGreen),
                ],
              ),
            ),
            trailing: isFull
                ? const Icon(Icons.lock_rounded, color: Colors.white12)
                : IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: kNeonBlue, size: 18),
                    onPressed: () => _handleSquadJoin(squad['name'] as String),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildSquadTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSessionsTab() {
    final List<Map<String, dynamic>> sessions = [
      {'title': 'AVIATOR_NIGHT_RUN', 'game': 'AVIATOR', 'players': '8/10', 'status': 'LIVE', 'code': 'A1B2C3'},
      {'title': 'MINES_STRAT_DATA', 'game': 'MINES', 'players': '5/8', 'status': 'OPEN', 'code': 'MINE99'},
      {'title': 'SPIN_DASH_SQUAD', 'game': 'SPIN DASH', 'players': '4/6', 'status': 'READY', 'code': 'SPND42'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final bool isLive = session['status'] == 'LIVE';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isLive ? kNeonGreen.withValues(alpha: 0.3) : kNeonPurple.withValues(alpha: 0.2), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: (isLive ? kNeonGreen : kNeonPurple).withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isLive ? kNeonGreen : kNeonPurple).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isLive ? Icons.sensors_rounded : Icons.lock_open_rounded,
                          color: isLive ? kNeonGreen : kNeonPurple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (session['title'] as String).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'MODULE: ${session['game']}'.toUpperCase(),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusIndicator(session['status'] as String, isLive),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildSessionStat(Icons.people_alt_rounded, session['players'] as String),
                      const SizedBox(width: 20),
                      _buildSessionStat(Icons.vpn_key_rounded, 'CODE: ${session['code']}'),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _handleJoinSession(session['title'] as String),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLive ? kNeonGreen : kNeonPurple,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('JOIN_NODE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(String status, bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isLive ? kNeonGreen : kNeonPurple).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isLive ? kNeonGreen : kNeonPurple).withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: isLive ? kNeonGreen : kNeonPurple, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSessionStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white24),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Diamond':
        return const Color(0xFF00E5FF);
      case 'Platinum':
        return const Color(0xFFE5E4E2);
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Silver':
        return const Color(0xFFB0BEC5);
      default:
        return Colors.white54;
    }
  }

  void _showLeaderboard() {
    _showSystemSnackBar(context, 'FETCHING_GLOBAL_RANKINGS: MODULE_OFFLINE');
  }

  void _handleGameTap(String gameName) {
    _showSystemSnackBar(context, 'LAUNCHING_NODE: ${gameName.toUpperCase()}');
  }

  void _handleJoinSession(String title) {
    _showSystemSnackBar(context, 'JOINING_SESSION: ${title.toUpperCase()}');
  }

  void _sendSquadInvite(String gamerName) {
    _showSystemSnackBar(context, 'INVITE_SENT: ${gamerName.toUpperCase()}');
  }

  void _handleClanJoin(String clanName) {
    _showSystemSnackBar(context, 'CLAN_REQUEST: ${clanName.toUpperCase()}');
  }

  void _handleSquadJoin(String squadName) {
    _showSystemSnackBar(context, 'SQUAD_JOIN: ${squadName.toUpperCase()}');
  }

  Widget _buildGamerAvatar(String label, Color rankColor) {
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: rankColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: rankColor.withValues(alpha: 0.1),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ),
    );
  }

  void _showSystemSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
        ),
        backgroundColor: const Color(0xFF0D1E36),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

