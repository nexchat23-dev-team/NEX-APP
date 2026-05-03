import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  static const routeName = '/reset-password';
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false;
  String errorMessage = '';
  String successMessage = '';

  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      successMessage = '';
    });

    final email = emailController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email address';
        isLoading = false;
      });
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.resetPassword(email);
      setState(() {
        successMessage = 'Password reset link sent! Check your email.';
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                    const Text('Forgot Password?', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Reset Your Password', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 16),
                    const Text('Enter your email and we\'ll send you a link to reset your password.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 32),
                    
                    // Email field
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
                    
                    if (successMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(successMessage, style: const TextStyle(color: Colors.green)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    ElevatedButton(
                      onPressed: isLoading ? null : resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Remember your password? Sign in',
                        style: TextStyle(color: Color(0xFF00B8F4), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
