import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/token_provider.dart';
import '../utils/constants.dart';
import '../widgets/cyber_background.dart';
import 'cosmic_animation_screen.dart';

class RegisterScreen extends StatefulWidget {
  static const routeName = '/register';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController referralController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _animController.forward();
  }

  Future<void> signUp() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Validation logic
      if (usernameController.text.trim().isEmpty) {
        throw Exception('IDENTITY_REQUIRED: Username cannot be empty.');
      }
      if (emailController.text.trim().isEmpty) {
        throw Exception('LINK_REQUIRED: Email cannot be empty.');
      }
      if (passwordController.text.length < 6) {
        throw Exception('SECURITY_BREACH: Password must be 6+ characters.');
      }
      if (passwordController.text != confirmPasswordController.text) {
        throw Exception('SYNC_ERROR: Passwords do not match.');
      }

      final authService = Provider.of<AuthService>(context, listen: false);
      final tokenProvider = Provider.of<TokenProvider>(context, listen: false);
      final referralCode = referralController.text.trim();

      await authService.signUp(
        emailController.text.trim(),
        passwordController.text.trim(),
        usernameController.text.trim(),
        referralCode: referralCode.isNotEmpty ? referralCode : null,
      );

      final startingBalance = 1000000 + (referralCode.isNotEmpty ? 10000 : 0);
      tokenProvider.setBalance(startingBalance);

      if (!mounted) return; // FIX: Essential for stability after await
      Navigator.pushReplacementNamed(context, CosmicLoginAnimationScreen.routeName);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    referralController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CyberBackground(
              backgroundColors: [
                Color(0xFF03050A),
                Color(0xFF080A16),
                Color(0xFF0E1120),
                Color(0xFF04060D),
              ],
              leftAuroraColors: [
                Color(0xFF00F0B6),
                Color(0xFF5A50FF),
                Color(0x00000000),
              ],
              rightAuroraColors: [
                Color(0xFFB14BFF),
                Color(0xFF3B82F6),
                Color(0x00000000),
              ],
              fogColor: Color(0x1EFFFFFF),
              leftAuroraCenter: Alignment(-0.22, -0.24),
              rightAuroraCenter: Alignment(0.8, -0.18),
            ),
          ),
          Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0x660D1E36), Color(0x00070B14)],
                center: Alignment.topCenter,
                radius: 1.5,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    if (errorMessage.isNotEmpty) _buildErrorBanner(),
                    _buildInputLabel('SYSTEM_IDENTITY'),
                    _buildStyledField(
                      controller: usernameController,
                      hint: 'Choose your codename',
                      icon: Icons.person_add_alt_1_rounded,
                      color: kNeonBlue,
                    ),
                    const SizedBox(height: 18),
                    _buildInputLabel('SECURE_COMM_LINK'),
                    _buildStyledField(
                      controller: emailController,
                      hint: 'user@nex-core.com',
                      icon: Icons.alternate_email_rounded,
                      color: kNeonBlue,
                      type: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),
                    _buildInputLabel('ACCESS_PASSPHRASE'),
                    _buildStyledField(
                      controller: passwordController,
                      hint: 'At least 6 characters',
                      icon: Icons.security_rounded,
                      color: kNeonGreen,
                      isPassword: true,
                      obscure: _obscurePassword,
                      toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 18),
                    _buildInputLabel('CONFIRM_PASSPHRASE'),
                    _buildStyledField(
                      controller: confirmPasswordController,
                      hint: 'Re-enter access key',
                      icon: Icons.check_circle_rounded,
                      color: kNeonGreen,
                      isPassword: true,
                      obscure: _obscureConfirmPassword,
                      toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    const SizedBox(height: 18),
                    _buildInputLabel('REFERRAL_CODE (optional)'),
                    _buildStyledField(
                      controller: referralController,
                      hint: 'Enter referral code',
                      icon: Icons.link_rounded,
                      color: kNeonBlue,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isLoading)
                            BoxShadow(
                              color: kNeonGreen.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading ? null : signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kNeonGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'AUTHORIZE_ENTRY',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'RECOGNIZED_USER? ',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: const Text(
                            'LOG_IN',
                            style: TextStyle(
                              color: kNeonBlue,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Pro UI Component Helpers ---

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROTOCOL: REGISTER',
          style: TextStyle(
              color: kNeonGreen,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2),
        ),
        SizedBox(height: 12),
        Text(
          'Establish New Identity',
          style: TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color color,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1E36).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white12),
          prefixIcon: Icon(icon, color: color, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: Colors.white24,
                      size: 18),
                  onPressed: toggleObscure,
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage.toUpperCase(),
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
