import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/token_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _cardVisible = false;
  bool _obscurePassword = true;
  String errorMessage = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _cardVisible = true;
      });
      _animController.forward();
    });
  }

  Future<void> signIn() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      if (emailController.text.trim().isEmpty) {
        throw Exception('Email cannot be empty.');
      }
      if (passwordController.text.isEmpty) {
        throw Exception('Password cannot be empty.');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signIn(emailController.text.trim(), passwordController.text.trim());
      
      if (mounted) {
        final tokenProvider = Provider.of<TokenProvider>(context, listen: false);
        if (!tokenProvider.hasTokens) {
          tokenProvider.setBalance(1000000);
        }
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();

      if (mounted) {
        final tokenProvider = Provider.of<TokenProvider>(context, listen: false);
        if (!tokenProvider.hasTokens) {
          tokenProvider.setBalance(1000000);
        }
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kDarkBackground, Color(0xFF0A1929)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kNeonPurple.withValues(alpha: 0.2), kNeonBlue.withValues(alpha: 0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kNeonPurple.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔐 Welcome Back', style: TextStyle(color: kNeonGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Sign in to NEX-APP', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Access chats, games, betting, and more', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Email Field
                const Text('📧 Email Address', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.email, color: kNeonBlue),
                    filled: true,
                    fillColor: kSurfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kNeonBlue, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                const Text('🔑 Password', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: Colors.white30),
                    prefixIcon: const Icon(Icons.lock, color: kNeonGreen),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: kSurfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: kNeonGreen, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/reset-password'),
                    child: const Text('Forgot Password?', style: TextStyle(color: kNeonBlue, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),

                // Error Message
                if (errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text('❌ $errorMessage', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 16),

                // Sign In Button
                ElevatedButton.icon(
                  onPressed: isLoading ? null : signIn,
                  icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                  label: Text(isLoading ? 'Signing in...' : 'Sign In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeonPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR', style: TextStyle(color: Colors.white30, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 16),

                // Google Sign In
                OutlinedButton.icon(
                  onPressed: isLoading ? null : signInWithGoogle,
                  icon: const Text('🔍', style: TextStyle(fontSize: 20)),
                  label: const Text('Sign in with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: kNeonBlue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: const Text('Sign Up', style: TextStyle(color: kNeonGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

