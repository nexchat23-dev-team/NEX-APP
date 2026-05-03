import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../main.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  bool isLoading = false;
  bool _cardVisible = false;
  String errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> signUp() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Validation
      if (usernameController.text.trim().isEmpty) {
        throw Exception('Username cannot be empty.');
      }
      if (emailController.text.trim().isEmpty) {
        throw Exception('Email cannot be empty.');
      }
      if (passwordController.text.isEmpty) {
        throw Exception('Password cannot be empty.');
      }
      if (passwordController.text != confirmPasswordController.text) {
        throw Exception('Passwords do not match.');
      }
      if (passwordController.text.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      
      await authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
        usernameController.text.trim(),
      );

      if (mounted) {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _cardVisible = true;
      });
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A4F35), Color(0xFF072F20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  left: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [kNeonBlue.withValues(alpha: 0.28), Colors.transparent]),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 140,
                  right: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [kNeonPurple.withValues(alpha: 0.3), Colors.transparent]),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: AnimatedScale(
                    scale: _cardVisible ? 1.0 : 0.96,
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _cardVisible ? 1 : 0,
                      duration: const Duration(milliseconds: 700),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0C331E).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: Colors.white12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 12)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Join NEXCHAT', style: TextStyle(color: Colors.white70, fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            const Text('Sign up to access chat, tokens, games, and rewards.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 32),
                            TextField(
                              controller: usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: const TextStyle(color: Colors.white70),
                                hintText: 'Choose a username',
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF0B4B71),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: const TextStyle(color: Colors.white70),
                                hintText: 'you@example.com',
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF0B4B71),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                hintText: 'Create a password',
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF0B4B71),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                hintText: 'Confirm your password',
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF0B4B71),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (errorMessage.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Text(errorMessage, style: const TextStyle(color: Colors.redAccent)),
                              ),
                              const SizedBox(height: 16),
                            ],
                            ElevatedButton(
                              onPressed: isLoading ? null : signUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Already have an account? Sign in',
                                style: TextStyle(color: Color(0xFF00B8F4), fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

