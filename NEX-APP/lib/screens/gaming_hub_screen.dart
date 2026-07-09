import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/clan_service.dart';
import '../services/session_service.dart';
import '../services/squad_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class GamingHubScreen extends StatefulWidget {
  static const routeName = '/gaming-hub';
  const GamingHubScreen({super.key});

  @override
  State<GamingHubScreen> createState() => _GamingHubScreenState();
}

class _GamingHubScreenState extends State<GamingHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _animationController;
  final ClanService _clanService = ClanService();
  final SquadService _squadService = SquadService();
  final SessionService _sessionService = SessionService();

  String? get _currentUserId => SupabaseService.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchGamers() async {
    final response = await SupabaseService.client.from('users').select().limit(50).order('updated_at', ascending: false);
    final data = response as List<dynamic>;

    return data.cast<Map<String, dynamic>>().where((user) => user['id'] != _currentUserId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050816),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) => CustomPaint(painter: _HubBackgroundPainter(_animationController.value)),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.sports_esports_rounded, color: kNeonGreen, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('GAMING HUB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.4)),
                          Text('CORE NETWORK', style: TextStyle(color: kNeonGreen, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: kNeonGreen, size: 18),
                    ),
                  ],
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildAppBarAction(Icons.emoji_events_outlined, kNeonPurple, _showLeaderboard),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: kNeonGreen,
                          unselectedLabelColor: Colors.white54,
                          indicatorColor: kNeonGreen,
                          indicatorWeight: 3,
                          dividerColor: Colors.transparent,
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
                    ),
                  ),
                ),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildArenaTab(),
                _buildGamersTab(),
                _buildClansTab(),
                _buildSquadsTab(),
                _buildLiveTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, Color color, VoidCallback? onTap) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(icon: Icon(icon, color: color, size: 20), onPressed: onTap),
        ),
      ),
    );
  }

  Widget _buildArenaTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Arena Command Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(height: 10),
                const Text('Monitor the hottest matches, scout upcoming teams, and dive into tournaments with one tap.', style: TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 16),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _buildInfoBadge('Top Arena', 'Shadow Rift', kNeonGreen),
                  _buildInfoBadge('Open Rooms', '24 Live', kNeonPurple),
                  _buildInfoBadge('Champion', 'Luna Squad', kNeonBlue),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.sports_esports_rounded, size: 72, color: kNeonGreen),
                  SizedBox(height: 22),
                  Text('Live gameplay arenas are activated once creators launch sessions.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamersTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchGamers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNeonPurple));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load gamers', style: TextStyle(color: Colors.redAccent)));
        }

        final gamers = snapshot.data ?? [];
        if (gamers.isEmpty) {
          return const Center(child: Text('No active gamers were found. Invite friends and watch them appear here.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: gamers.length,
          itemBuilder: (context, index) {
            final gamer = gamers[index];
            final name = (gamer['username'] as String?) ?? (gamer['name'] as String?) ?? 'Player';
            final status = (gamer['status'] as String?) ?? 'online';
            final badge = (gamer['level'] != null) ? 'Lv ${gamer['level']}' : 'New';

            return _buildGlassCard(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: kNeonBlue.withValues(alpha: 0.16),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                subtitle: Text('$badge • ${status.toUpperCase()}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: kNeonGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Text('VIEW', style: TextStyle(color: kNeonGreen, fontWeight: FontWeight.w900, fontSize: 11)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClansTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _clanService.getClans(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNeonPurple));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load clans', style: TextStyle(color: Colors.redAccent)));
        }

        final clans = snapshot.data ?? [];
        if (clans.isEmpty) {
          return const Center(child: Text('No clans have been formed yet. Start one to lead your own squad.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: clans.length,
          itemBuilder: (context, index) {
            final clan = clans[index];
            final clanName = (clan['name'] as String?) ?? 'Unnamed Clan';
            final members = List<String>.from(clan['members'] ?? []);
            final level = clan['level']?.toString() ?? 'N/A';
            final wins = clan['experience']?.toString() ?? '0';
            final clanId = clan['id']?.toString() ?? '';
            final isMember = members.contains(_currentUserId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGlassCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: kNeonGreen.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: kNeonGreen.withValues(alpha: 0.3))),
                    child: Center(child: Text(level, style: const TextStyle(color: kNeonGreen, fontSize: 18, fontWeight: FontWeight.w900))),
                  ),
                  title: Text(clanName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: Text('${members.length} members · ${wins} XP', style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold))),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: isMember ? Colors.white12 : kNeonGreen, foregroundColor: isMember ? Colors.white : Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: isMember ? null : () => _handleClanJoin(clanId, clanName),
                    child: Text(isMember ? 'MEMBER' : 'JOIN', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSquadsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _squadService.getSquads(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNeonPurple));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load squads', style: TextStyle(color: Colors.redAccent)));
        }

        final squads = snapshot.data ?? [];
        if (squads.isEmpty) {
          return const Center(child: Text('No squads found yet. Assemble a crew and take the arena by storm.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: squads.length,
          itemBuilder: (context, index) {
            final squad = squads[index];
            final squadName = (squad['name'] as String?) ?? 'Unnamed Squad';
            final game = (squad['game'] as String?) ?? 'Unknown';
            final members = List<String>.from(squad['members'] ?? []);
            final maxMembers = squad['maxMembers'] as int? ?? 4;
            final isFull = members.length >= maxMembers;
            final squadId = squad['id']?.toString() ?? '';
            final isMember = members.contains(_currentUserId);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGlassCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kNeonBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.hub_rounded, color: kNeonBlue, size: 24)),
                  title: Text(squadName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [
                    _buildSquadTag(game.toUpperCase(), kNeonBlue),
                    const SizedBox(width: 8),
                    _buildSquadTag('$members.length/$maxMembers', isFull ? Colors.redAccent : kNeonGreen),
                  ])),
                  trailing: isMember
                      ? Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10)), child: const Text('MEMBER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)))
                      : IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded, color: kNeonBlue, size: 18), onPressed: isFull ? null : () => _handleSquadJoin(squadId, squadName)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLiveTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _sessionService.getSessions(publicOnly: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kNeonPurple));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load live sessions', style: TextStyle(color: Colors.redAccent)));
        }

        final sessions = snapshot.data ?? [];
        if (sessions.isEmpty) {
          return const Center(child: Text('No public sessions are live right now. Start one and see it appear instantly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final title = (session['title'] as String?) ?? 'Live session';
            final game = (session['game'] as String?) ?? 'Unknown';
            final status = (session['status'] as String?) ?? 'scheduled';
            final participants = List<String>.from(session['participants'] ?? []);
            final sessionId = session['id']?.toString() ?? '';
            final startTime = _parseSessionTime(session['startTime']);
            final timeLabel = startTime != null ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}' : 'TBA';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15))),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: status == 'active' ? kNeonGreen.withValues(alpha: 0.18) : kNeonPurple.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)), child: Text(status.toUpperCase(), style: TextStyle(color: status == 'active' ? kNeonGreen : kNeonPurple, fontWeight: FontWeight.w900, fontSize: 11))),
                      ]),
                      const SizedBox(height: 10),
                      Text(game, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(children: [
                        _buildSmallTag(timeLabel, kNeonBlue),
                        const SizedBox(width: 8),
                        _buildSmallTag('${participants.length} players', kNeonGreen),
                      ]),
                      const SizedBox(height: 16),
                      OutlinedButton(onPressed: () => _joinSession(sessionId, title), style: OutlinedButton.styleFrom(foregroundColor: kNeonGreen, side: BorderSide(color: kNeonGreen.withValues(alpha: 0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Join session')),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF10172E).withValues(alpha: 0.74),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInfoBadge(String title, String subtitle, Color color) {
    return Container(width: 110, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 10)), const SizedBox(height: 8), Text(subtitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14))]));
  }

  Widget _buildSmallTag(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)));
  }

  Widget _buildSquadTag(String label, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)), child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)));
  }

  DateTime? _parseSessionTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void _joinSession(String sessionId, String sessionTitle) async {
    try {
      await _sessionService.joinSession(sessionId);
      if (!mounted) return;
      _showSystemSnackBar(context, 'Joined session: $sessionTitle');
    } catch (e) {
      if (!mounted) return;
      _showSystemSnackBar(context, 'Failed to join session: ${e.toString()}');
    }
  }

  void _showLeaderboard() {
    _showSystemSnackBar(context, 'FETCHING_GLOBAL_RANKINGS: MODULE_OFFLINE');
  }

  Future<void> _handleClanJoin(String clanId, String clanName) async {
    try {
      await _clanService.requestJoinClan(clanId);
      if (!mounted) return;
      _showSystemSnackBar(context, 'CLAN_REQUEST_SENT: ${clanName.toUpperCase()}');
    } catch (e) {
      if (!mounted) return;
      _showSystemSnackBar(context, 'CLAN_JOIN_FAILED: ${e.toString()}');
    }
  }

  Future<void> _handleSquadJoin(String squadId, String squadName) async {
    try {
      await _squadService.joinSquad(squadId);
      if (!mounted) return;
      _showSystemSnackBar(context, 'JOINED_SQUAD: ${squadName.toUpperCase()}');
    } catch (e) {
      if (!mounted) return;
      _showSystemSnackBar(context, 'SQUAD_JOIN_FAILED: ${e.toString()}');
    }
  }

  void _showSystemSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        backgroundColor: const Color(0xFF0D1E36),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _HubBackgroundPainter extends CustomPainter {
  const _HubBackgroundPainter(this.animationValue);

  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: const [Color(0xFF050816), Color(0xFF0B1330)]).createShader(rect);
    canvas.drawRect(rect, bg);

    final aurora = Paint()..shader = RadialGradient(center: Alignment(-0.3 + animationValue * 0.05, -0.25 + animationValue * 0.03), radius: 1.15, colors: const [Color(0xFF4C6FFF), Color(0xFF20325F), Color(0x00000000)]).createShader(rect);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.16), size.width * 0.36, aurora);

    final glow = Paint()..shader = RadialGradient(center: Alignment(0.8 - animationValue * 0.04, 0.12 + animationValue * 0.02), radius: 0.8, colors: const [Color(0xFFB14EFF), Color(0x00000000)]).createShader(rect);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.1), size.width * 0.22, glow);

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < 14; i++) {
      final normalized = i / 14;
      final driftX = sin(animationValue * 2 * pi + normalized * 5) * size.width * 0.018;
      final driftY = cos(animationValue * 2 * pi + normalized * 4) * size.height * 0.012;
      final x = size.width * (0.08 + normalized * 0.84) + driftX;
      final y = size.height * (0.08 + ((i % 5) * 0.14)) + driftY;
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * 0.25, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HubBackgroundPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}
