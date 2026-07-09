import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'bet_screen.dart';
import 'calls_screen.dart';
import 'chat_screen.dart';
import 'gaming_hub_screen.dart';
import 'marketplace_screen.dart';
import 'my_statuses_screen.dart';
import 'offline_chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'terminal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const List<Color> _shootingStarColors = [
    Color(0xFFFFFFFF),
    Color(0xFF7D8CFF),
    Color(0xFFFF69B4),
    Color(0xFF00D4FF),
  ];

  final List<_HomeAction> _actions = const [
    _HomeAction(
      title: 'Chat',
      subtitle: 'Secure messages',
      icon: Icons.chat_bubble_rounded,
      color: Color(0xFF5D7CFF),
      routeName: ChatScreen.routeName,
    ),
    _HomeAction(
      title: 'Calls',
      subtitle: 'Voice & video',
      icon: Icons.videocam_rounded,
      color: Color(0xFF22D47C),
      routeName: CallsScreen.routeName,
    ),
    _HomeAction(
      title: 'Marketplace',
      subtitle: 'Buy & sell',
      icon: Icons.storefront_rounded,
      color: Color(0xFFFFA726),
      routeName: MarketplaceScreen.routeName,
    ),
    _HomeAction(
      title: 'Betting',
      subtitle: 'Live odds',
      icon: Icons.sports_soccer_rounded,
      color: Color(0xFFFF5D8F),
      routeName: BettingScreen.routeName,
    ),
    _HomeAction(
      title: 'Gaming',
      subtitle: 'Hub & events',
      icon: Icons.gamepad_rounded,
      color: Color(0xFF7C4DFF),
      routeName: GamingHubScreen.routeName,
    ),
    _HomeAction(
      title: 'Terminal',
      subtitle: 'Developer tools',
      icon: Icons.terminal_rounded,
      color: Color(0xFF00B8D4),
      routeName: TerminalScreen.routeName,
    ),
    _HomeAction(
      title: 'Status',
      subtitle: 'Your updates',
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF00E676),
      routeName: MyStatusesScreen.routeName,
    ),
    _HomeAction(
      title: 'Offline',
      subtitle: 'Queue & sync',
      icon: Icons.wifi_off_rounded,
      color: Color(0xFF6C63FF),
      routeName: OfflineChatScreen.routeName,
    ),
  ];

  late final AnimationController _animationController;
  Timer? _shootingStarTimer;
  int _shootingStarColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat(reverse: true);
    _shootingStarTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() {
        _shootingStarColorIndex = (_shootingStarColorIndex + 1) % _shootingStarColors.length;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shootingStarTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundStart = isDark ? const Color(0xFF050816) : const Color(0xFFF7F9FF);

    return Scaffold(
      backgroundColor: backgroundStart,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _HomeBackgroundPainter(
                    isDark: isDark,
                    animationValue: _animationController.value,
                    shootingStarColor: _shootingStarColors[_shootingStarColorIndex],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NEXCHAT',
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.4,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFF5D7CFF).withValues(alpha: isDark ? 0.45 : 0.22),
                                          blurRadius: 16,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Secure social hub',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.72),
                                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.16) : const Color(0xFF5D7CFF).withValues(alpha: 0.22)),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: IconButton(
                                    onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
                                    icon: const Icon(Icons.tune_rounded),
                                    color: isDark ? Colors.white : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF1D2B6F).withValues(alpha: 0.85), const Color(0xFF0C1534).withValues(alpha: 0.95)]
                                      : [const Color(0xFF5D7CFF).withValues(alpha: 0.95), const Color(0xFF2B4BFE).withValues(alpha: 0.98)],
                                ),
                                border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.24)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF5D7CFF).withValues(alpha: 0.28),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Momentum is live',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Everything you need is one tap away.',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.9),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                                    ),
                                    child: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Quick access',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.08,
                    children: _actions.map((action) => _buildActionCard(action, isDark)).toList(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.notifications_active_rounded,
                          title: 'New updates available',
                          subtitle: 'Sync your messages and stay connected.',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          icon: Icons.shield_rounded,
                          title: 'Encrypted by default',
                          subtitle: 'Your chats and media stay private.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: isDark ? const Color(0xFF0A1028).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
            selectedItemColor: const Color(0xFF5D7CFF),
            unselectedItemColor: isDark ? Colors.white54 : const Color(0xFF64748B),
            onTap: (index) {
              switch (index) {
                case 1:
                  Navigator.pushNamed(context, ChatScreen.routeName);
                  break;
                case 2:
                  Navigator.pushNamed(context, MarketplaceScreen.routeName);
                  break;
                case 3:
                  Navigator.pushNamed(context, ProfileScreen.routeName);
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.store_rounded), label: 'Market'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(_HomeAction action, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, action.routeName),
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10172E).withValues(alpha: 0.74) : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: action.color.withValues(alpha: isDark ? 0.3 : 0.2), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: action.color.withValues(alpha: 0.22)),
                  ),
                  child: Icon(action.icon, color: action.color, size: 24),
                ),
                const Spacer(),
                Text(
                  action.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  action.subtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF10172E).withValues(alpha: 0.74) : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D7CFF).withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5D7CFF).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontSize: 13,
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
}

class _HomeBackgroundPainter extends CustomPainter {
  const _HomeBackgroundPainter({required this.isDark, required this.animationValue, required this.shootingStarColor});

  final bool isDark;
  final double animationValue;
  final Color shootingStarColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? const [Color(0xFF050816), Color(0xFF0B1330)]
            : const [Color(0xFFF7F9FF), Color(0xFFE7EDFF)],
      ).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final auroraPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(-0.35 + (animationValue * 0.06), -0.25 + (animationValue * 0.04)),
        radius: 1.25,
        colors: isDark
            ? const [Color(0xFF4D6DFF), Color(0xFF1E2A5E), Color(0x00000000)]
            : const [Color(0xFF8BC9FF), Color(0xFFE7DFFF), Color(0x00000000)],
      ).createShader(rect);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.18), size.width * 0.34, auroraPaint);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment(0.75 - (animationValue * 0.04), 0.12 + (animationValue * 0.03)),
        radius: 0.85,
        colors: isDark
            ? const [Color(0xFFB14EFF), Color(0x00000000)]
            : const [Color(0xFFFFC8E7), Color(0x00000000)],
      ).createShader(rect);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.12), size.width * 0.26, glowPaint);

    final starPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B).withValues(alpha: 0.7);
    for (var i = 0; i < 12; i++) {
      final normalized = i / 12;
      final driftX = sin(animationValue * 2 * pi + normalized * 6) * size.width * 0.018;
      final driftY = cos(animationValue * 2 * pi + normalized * 4) * size.height * 0.016;
      final x = size.width * (0.1 + normalized * 0.8) + driftX;
      final y = size.height * (0.08 + ((i % 5) * 0.14)) + driftY;
      canvas.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.3, starPaint);
    }

    final shootingPaint = Paint()
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..shader = LinearGradient(
        colors: [shootingStarColor, const Color(0xFF5D7CFF)],
      ).createShader(rect);
    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.66)
      ..lineTo(size.width * 0.24, size.height * 0.51)
      ..lineTo(size.width * 0.34, size.height * 0.46);
    canvas.drawPath(path, shootingPaint);

    canvas.drawCircle(
      Offset(size.width * 0.34, size.height * 0.46),
      3.6,
      Paint()..color = shootingStarColor.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant _HomeBackgroundPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.animationValue != animationValue || oldDelegate.shootingStarColor != shootingStarColor;
  }
}

class _HomeAction {
  const _HomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.routeName,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String routeName;
}
