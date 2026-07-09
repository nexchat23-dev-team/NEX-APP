import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/token_provider.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../widgets/cyber_background.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String errorMessage = '';
  bool _isSupabaseReady = true;

  @override
  void initState() {
    super.initState();
    _restoreBiometricPreference();
  }

  Future<void> _restoreBiometricPreference() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final available = await _localAuth.canCheckBiometrics ||
        await _localAuth.isDeviceSupported();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometricLogin') ?? false;
    final saved = enabled ? await authService.getSavedCredentials() : null;

    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = available && enabled && saved != null;
    });

    if (enabled && saved == null) {
      await prefs.setBool('biometricLogin', false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock NEXCHAT with biometrics',
        options:
            const AuthenticationOptions(biometricOnly: true, stickyAuth: false),
      );

      if (!authenticated) {
        scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Biometric authentication failed.')));
        return;
      }

      final success = await authService.signInWithSavedCredentials();
      if (!mounted) return;
      if (success) {
        Navigator.pushReplacementNamed(context, HomeScreen.routeName);
      } else {
        await authService.clearSavedCredentials();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometricLogin', false);
        setState(() => _biometricEnabled = false);
        scaffoldMessenger.showSnackBar(const SnackBar(
            content:
                Text('No saved credentials found. Please sign in normally.')));
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Biometric login failed. Please try again.')));
    }
  }

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Email and password are required.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final tokenProvider = Provider.of<TokenProvider>(context, listen: false);

    try {
      await authService.signIn(email, password);
      if (!mounted) return;

      await authService.syncPendingReferralRewards(tokenProvider);
      if (!tokenProvider.hasTokens) {
        tokenProvider.setBalance(1000000);
      }

      if (_biometricAvailable && !_biometricEnabled) {
        await _confirmEnableBiometrics(email, password);
      }

      if (!mounted) return;
      setState(() => _isSupabaseReady = true);
      Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSupabaseReady = false;
        errorMessage = _friendlyAuthError(error);
        isLoading = false;
      });
    }
  }

  Future<void> _confirmEnableBiometrics(String email, String password) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enable quick unlock?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'Use biometrics to log in faster on this device. Your credentials are stored securely.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );

    if (result != true) return;

    await authService.saveCredentials(email, password);
    final saved = await authService.getSavedCredentials();
    if (saved == null) {
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Could not enable biometric login.')));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricLogin', true);
    if (!mounted) return;
    setState(() => _biometricEnabled = true);
    scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Biometric login enabled.')));
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('wrong-password') ||
        message.contains('invalid password') ||
        message.contains('user-not-found') ||
        message.contains('password') ||
        message.contains('email')) {
      return 'Wrong email or password. Please try again.';
    }
    if (message.contains('network_error') ||
        message.contains('network error') ||
        message.contains('network') ||
        message.contains('timeout')) {
      return 'A network issue occurred. Please try again later.';
    }
    if (message.contains('google sign in was cancelled')) {
      return 'Google sign in was cancelled.';
    }
    return 'Unable to sign in. Please try again.';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CyberBackground(
              backgroundColors: [
                Color(0xFF010308),
                Color(0xFF050816),
                Color(0xFF081122),
                Color(0xFF02040D),
              ],
              leftAuroraColors: [
                Color(0xFF0A84FF),
                Color(0xFF5A50FF),
                Color(0x00000000),
              ],
              rightAuroraColors: [
                Color(0xFF6A3DFF),
                Color(0xFF00C2FF),
                Color(0x00000000),
              ],
              fogColor: Color(0x1AFFFFFF),
              leftAuroraCenter: Alignment(-0.26, -0.28),
              rightAuroraCenter: Alignment(0.82, -0.16),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 28),
              if (!_isSupabaseReady)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
                  ),
                  child: const Text(
                    'Auth is currently unavailable. Please check your Supabase configuration.',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 13),
                  ),
                ),
              _buildCredentialFields(),
              const SizedBox(height: 20),
              if (errorMessage.isNotEmpty) _buildErrorCard(),
              _buildSignInButton(),
              const SizedBox(height: 14),
              _buildSocialLoginButton(),
              if (_biometricAvailable && _biometricEnabled) ...[
                const SizedBox(height: 18),
                _buildBiometricPrompt(),
              ],
              const SizedBox(height: 28),
              _buildRegisterLink(context),
            ],
          ),
        ),
      ),
      ],
    ),
  );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kNeonPurple.withValues(alpha: 0.1),
            kNeonBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: kNeonPurple.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [kNeonPurple, kNeonBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          const Text(
            'Welcome Back',
            style: TextStyle(
              color: kNeonGreen,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Secure Access',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign in to access your encrypted network and services.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Email',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
              hintText: 'you@example.com',
              icon: Icons.email,
              iconColor: kNeonBlue),
        ),
        const SizedBox(height: 18),
        const Text('Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration(
            hintText: 'Enter your password',
            icon: Icons.lock,
            iconColor: kNeonGreen,
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushNamed(context, '/reset-password'),
            child: const Text('Forgot Password?',
                style:
                    TextStyle(color: kNeonBlue, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    required Color iconColor,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white30),
      prefixIcon: Icon(icon, color: iconColor),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: kSurfaceColor,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: iconColor, width: 2)),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.26)),
      ),
      child: Text(errorMessage,
          style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
    );
  }

  Widget _buildSignInButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : _signIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: kNeonPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Text('Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSocialLoginButton() {
    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () async {
              setState(() {
                isLoading = true;
                errorMessage = '';
              });

              try {
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                final tokenProvider =
                    Provider.of<TokenProvider>(context, listen: false);
                await authService.signInWithGoogle();
                if (!mounted) return;
                await authService.syncPendingReferralRewards(tokenProvider);
                if (!tokenProvider.hasTokens) tokenProvider.setBalance(1000000);
                Navigator.pushReplacementNamed(context, HomeScreen.routeName);
              } catch (error) {
                if (!mounted) return;
                setState(() {
                  errorMessage = _friendlyAuthError(error);
                  isLoading = false;
                });
              }
            },
      icon: const Icon(Icons.login, color: Colors.white),
      label: const Text('Sign in with Google',
          style: TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kNeonBlue, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildBiometricPrompt() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kNeonPurple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kNeonPurple.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, color: kNeonPurple),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Tap to unlock with biometrics',
                    style: TextStyle(color: Colors.white70)),
              ),
              IconButton(
                onPressed: _handleBiometricLogin,
                icon: const Icon(Icons.arrow_forward_ios, color: kNeonGreen),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Don\'t have an account?',
            style: TextStyle(color: Colors.white70)),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          child: const Text('Create Account',
              style: TextStyle(color: kNeonGreen, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
