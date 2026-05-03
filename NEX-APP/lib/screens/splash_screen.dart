import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'permission_screen.dart';
import '../services/auth_service.dart';

// Constants for better maintainability
class SplashScreenConstants {
  static const Duration animationDuration = Duration(milliseconds: 1200);
  static const Duration splashDelay = Duration(seconds: 2);
  static const double scaleBegin = 1.0;
  static const double scaleEnd = 1.06;
  static const double iconSize = 78.0;
  static const double progressSize = 40.0;
  static const double progressStrokeWidth = 3.0;
  static const double letterSpacing = 1.2;
  static const double titleFontSize = 36.0;
  static const double subtitleFontSize = 16.0;
  static const double padding = 24.0;
  static const double spacing = 12.0;
  static const double largeSpacing = 28.0;
  static const double blurRadius = 18.0;
  static const Offset shadowOffset = Offset(0, 8);

  // Colors
  static const Color primaryGreen = Color(0xFF25D366);
  static const Color accentBlue = Color(0xFF00B8F4);
  static const Color gradientStart = Color(0xFF054A85);
  static const Color gradientEnd = Color(0xFF25D366);
  static const Color backgroundOpacity = Colors.white;
  static const double backgroundOpacityValue = 0.08;
  static const Color shadowColor = Colors.black;
  static const double shadowOpacity = 0.24;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  // Strings
  static const String appTitle = 'NEXCHAT';
  static const String appSubtitle = 'Your WhatsApp-style chat experience';
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
      
      // If logged in and first time, go to permissions
      // If logged in and not first time, go to home
      // If not logged in, go to login
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
      debugPrint('Navigation error: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              SplashScreenConstants.gradientStart,
              SplashScreenConstants.gradientEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: _AnimatedSplashContent(),
        ),
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
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SplashScreenConstants.animationDuration,
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: SplashScreenConstants.scaleBegin,
      end: SplashScreenConstants.scaleEnd,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(SplashScreenConstants.padding),
            decoration: BoxDecoration(
              color: SplashScreenConstants.backgroundOpacity.withValues(alpha: SplashScreenConstants.backgroundOpacityValue),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SplashScreenConstants.shadowColor.withValues(alpha: SplashScreenConstants.shadowOpacity),
                  blurRadius: SplashScreenConstants.blurRadius,
                  offset: SplashScreenConstants.shadowOffset,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: SplashScreenConstants.iconSize,
                height: SplashScreenConstants.iconSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: SplashScreenConstants.padding),
          const Text(
            SplashScreenConstants.appTitle,
            style: TextStyle(
              color: SplashScreenConstants.textPrimary,
              fontSize: SplashScreenConstants.titleFontSize,
              fontWeight: FontWeight.bold,
              letterSpacing: SplashScreenConstants.letterSpacing,
            ),
          ),
          const SizedBox(height: SplashScreenConstants.spacing),
          const Text(
            SplashScreenConstants.appSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SplashScreenConstants.textSecondary,
              fontSize: SplashScreenConstants.subtitleFontSize,
            ),
          ),
          const SizedBox(height: SplashScreenConstants.largeSpacing),
          const SizedBox(
            width: SplashScreenConstants.progressSize,
            height: SplashScreenConstants.progressSize,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(SplashScreenConstants.accentBlue),
              strokeWidth: SplashScreenConstants.progressStrokeWidth,
            ),
          ),
        ],
      ),
    );
  }
}
