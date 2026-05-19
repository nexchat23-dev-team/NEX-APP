import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'permission_screen.dart';
import '../services/auth_service.dart';

class SplashScreenConstants {
  static const Duration splashDelay = Duration(seconds: 3);

  // Colors - Rebranded to NEX Pro League Palette
  static const Color kDeepNavy = Color(0xFF070B14);
  static const Color kSystemBlue = Color(0xFF3B82F6);
  static const Color kNeonPurple = Color(0xFF8B5CF6);
  static const Color kNeonGreen = Color(0xFF10B981);

  // Strings
  static const String appTitle = 'NEXCHAT';
  static const String appSubtitle = 'QUANTUM_ENCRYPTED_OS';
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    try {
      await Future.delayed(SplashScreenConstants.splashDelay);
      if (!mounted) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool(PermissionScreen.firstTimeKey) ?? true;

      String routeName;
      if (authService.isLoggedIn) {
        routeName = isFirstTime ? PermissionScreen.routeName : HomeScreen.routeName;
      } else {
        routeName = LoginScreen.routeName;
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, routeName);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SplashScreenConstants.kDeepNavy,
      body: Stack(
        children: [
          // Background Atmosphere
          Positioned(
            top: -100,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    SplashScreenConstants.kNeonPurple.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Center(child: _AnimatedSplashContent()),
        ],
      ),
    );
  }
}

class _AnimatedSplashContent extends StatefulWidget {
  const _AnimatedSplashContent();

  @override
  State<_AnimatedSplashContent> createState() => _AnimatedSplashContentState();
}

class _AnimatedSplashContentState extends State<_AnimatedSplashContent> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Logo Container
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SplashScreenConstants.kNeonPurple.withValues(alpha: 0.2 * _pulse.value),
                  width: 2,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SplashScreenConstants.kNeonPurple.withValues(alpha: 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: SplashScreenConstants.kNeonPurple.withValues(alpha: 0.1 * _pulse.value),
                      blurRadius: 30 * _pulse.value,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Technical Title
            const Text(
              SplashScreenConstants.appTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 8, // Ultra-wide spacing for Pro look
              ),
            ),
            const SizedBox(height: 12),
            Text(
              SplashScreenConstants.appSubtitle,
              style: const TextStyle(
                color: SplashScreenConstants.kNeonGreen,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 60),
            // Sleek Progress Bar
            SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                color: SplashScreenConstants.kNeonPurple,
                minHeight: 2,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'INITIALIZING_HANDSHAKE...',
              style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        );
      },
    );
  }
}
