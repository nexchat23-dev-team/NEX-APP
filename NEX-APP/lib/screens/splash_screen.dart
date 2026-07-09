import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreenConstants {
  static const Duration statusDelay = Duration(milliseconds: 1200);
  static const Duration transitionDelay = Duration(milliseconds: 1000);

  static const Color kDeepNavy = Color(0xFF050814);
  static const Color kStarBlue = Color(0xFF5D7CFF);
  static const Color kNeonPurple = Color(0xFFB23BFF);
  static const Color kNeonGreen = Color(0xFF22D47C);
  static const Color kElectricCyan = Color(0xFF34D1F8);

  static const String appTitle = 'NEXCHAT';
  static const String appSubtitle = 'SECURELY CONNECTED';
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final List<String> _statusMessages = [
    'NEXCHAT ENGINE INITIATED',
    'NEXCHAT ENGINE IS COMPUTING YOUR SERVER PLS HOLD',
    'YOUR SERVER HAS BEEN INITIALIZE',
  ];
  int _statusIndex = 0;
  String _statusMessage = 'NEXCHAT ENGINE INITIATED';
  Timer? _statusTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startInitializationSequence();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startInitializationSequence() {
    _showStatusMessage();
  }

  void _showStatusMessage() {
    if (!mounted) return;
    setState(() {
      _statusMessage = _statusMessages[_statusIndex];
    });

    if (_statusIndex < _statusMessages.length - 1) {
      _statusTimer?.cancel();
      _statusTimer = Timer(SplashScreenConstants.transitionDelay, () {
        if (!mounted) return;
        setState(() => _statusIndex += 1);
        _showStatusMessage();
      });
    } else {
      _statusTimer?.cancel();
      _statusTimer = Timer(SplashScreenConstants.statusDelay, () {
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      });
    }
  }

  Widget _buildStar(double left, double top, double size, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF050814),
                  Color(0xFF0A0E27),
                  Color(0xFF0B1030),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _SpaceTechPainter(),
            ),
          ),
          Positioned.fill(
            child: Stack(
              children: [
                _buildStar(40, 88, 2.5, SplashScreenConstants.kStarBlue),
                _buildStar(110, 160, 1.8, SplashScreenConstants.kElectricCyan),
                _buildStar(212, 82, 2, SplashScreenConstants.kNeonPurple),
                _buildStar(306, 130, 2.2, SplashScreenConstants.kStarBlue),
                _buildStar(128, 278, 1.6, SplashScreenConstants.kElectricCyan),
                _buildStar(292, 244, 2.4, SplashScreenConstants.kNeonPurple),
              ],
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: SplashScreenConstants.kNeonPurple.withValues(alpha: 0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        size: 60,
                        color: SplashScreenConstants.kNeonPurple,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'NEXCHAT',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'QUANTUM ENCRYPTED',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: SplashScreenConstants.kElectricCyan,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        SplashScreenConstants.kNeonPurple.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: SplashScreenConstants.kElectricCyan,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Initializing secure network...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white38,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceTechPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final skyPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 1.25,
        colors: [Color(0xFF153A72), Color(0xFF050814)],
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.75, 0.1),
        radius: 0.7,
        colors: [Color(0xFF7A4DFF), Color(0x00000000)],
      ).createShader(rect);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.12),
      size.width * 0.25,
      glowPaint,
    );

    final nebulaPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.1, 0.9),
        radius: 0.8,
        colors: [Color(0xFF0F4E6A), Color(0x00000000)],
      ).createShader(rect);
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.84),
      size.width * 0.3,
      nebulaPaint,
    );

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (final point in [
      const Offset(38, 82),
      const Offset(98, 154),
      const Offset(216, 78),
      const Offset(304, 132),
      const Offset(120, 266),
      const Offset(280, 240),
      const Offset(56, 420),
      const Offset(332, 392),
    ]) {
      canvas.drawCircle(point, 1.5, starPaint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white12
      ..strokeWidth = 1.1;

    final center = Offset(size.width * 0.5, size.height * 0.2);
    canvas.drawCircle(center, 120, ringPaint);
    canvas.drawCircle(center, 200, ringPaint);
    canvas.drawCircle(center, 270, ringPaint);

    ringPaint.color = Colors.white24;
    ringPaint.strokeWidth = 1.3;
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.35, size.height * 0.08),
      ringPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, size.height * 0.18),
      Offset(size.width * 0.68, size.height * 0.04),
      ringPaint,
    );

    final glowPaint2 = Paint()..color = const Color(0xFF34D1F8).withValues(alpha: 0.14);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      70,
      glowPaint2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.72),
      50,
      glowPaint2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
