import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'permission_screen.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/token_provider.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoClaimDailyBonus = false;
  bool _biometricLoginEnabled = false;
  bool _biometricAvailable = false;
  bool _twoFactorEnabled = false;
  bool _autoLoginEnabled = true;
  bool _lowDataModeEnabled = false;
  bool _useNexRingtone = false;
  int _nexRingtoneIndex = 0;
  String _startupScreen = 'Home';
  late final TextEditingController _recipientController;
  late final TextEditingController _transferAmountController;
  late AnimationController _animController;
  bool _contentVisible = false;

  @override
  void initState() {
    super.initState();
    _initBiometric();
    _loadRingtoneSettings();
    _recipientController = TextEditingController();
    _transferAmountController = TextEditingController();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _contentVisible = true;
      });
      _animController.forward();
    });
  }

  Future<String?> _promptForPasswordToEnableBiometrics() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your account password to enable biometric quick sign-in.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.white30)),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Confirm')),
        ],
      ),
    );
    return result;
  }

  Future<void> _initBiometric() async {
    final localAuth = LocalAuthentication();
    final available = await localAuth.canCheckBiometrics ||
        await localAuth.isDeviceSupported();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometricLogin') ?? false;
    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricLoginEnabled = enabled && available;
      });
    }
  }

  @override
  void dispose() {
    _stopPreview();
    _recipientController.dispose();
    _transferAmountController.dispose();
    _animController.dispose();
    super.dispose();
  }

  static const MethodChannel _ringtoneChannel =
      MethodChannel('nexapp/ringtone');

  Future<void> _loadRingtoneSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final use = prefs.getBool('use_nexapp_ringtone') ?? false;
    final idx = prefs.getInt('nexapp_ringtone_index') ?? 0;
    if (mounted) {
      setState(() {
        _useNexRingtone = use;
        _nexRingtoneIndex = idx;
      });
    }
  }

  Future<void> _setUseNexRingtone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_nexapp_ringtone', value);
    if (mounted) setState(() => _useNexRingtone = value);
  }

  Future<void> _setNexRingtoneIndex(int idx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nexapp_ringtone_index', idx);
    if (mounted) setState(() => _nexRingtoneIndex = idx);
  }

  Future<void> _playPreview(int idx) async {
    try {
      await _ringtoneChannel.invokeMethod('playNexTone', {'index': idx});
    } catch (e) {
      // ignore
    }
  }

  Future<void> _stopPreview() async {
    try {
      await _ringtoneChannel.invokeMethod('stopTone');
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'backup':
                  _backupSettings();
                  break;
                case 'reset':
                  _resetSettings();
                  break;
                case 'export':
                  _exportData();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.backup, color: kNeonBlue),
                    SizedBox(width: 8),
                    Text('Backup Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, color: kNeonGreen),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Reset to Defaults'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kDarkBackground, Color(0xFF0A1929)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: AnimatedOpacity(
          opacity: _contentVisible ? 1 : 0,
          duration: const Duration(milliseconds: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kNeonPurple.withValues(alpha: 0.2),
                      kNeonBlue.withValues(alpha: 0.1)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kNeonPurple.withValues(alpha: 0.3)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customize Your Experience',
                        style: TextStyle(
                            color: kNeonGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Settings & Preferences',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                        'Manage your account, notifications, and app preferences',
                        style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Account Section
              _buildSectionHeader('Account'),
              _buildSectionHeader('Account'),
              _buildSettingsTile(
                icon: Icons.person,
                title: 'Edit Profile',
                subtitle: 'Change name, email, avatar',
                onTap: () => _showEditProfileDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.lock,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => _showChangePasswordDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.security,
                title: 'Privacy',
                subtitle: 'Manage who can see your info',
                onTap: () => _showPrivacyDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.devices,
                title: 'Connected Devices',
                subtitle: 'Review signed-in devices',
                onTap: () => _showConnectedDevicesDialog(context),
              ),

              const SizedBox(height: 24),

              // Security Section
              _buildSectionHeader('Security'),
              _buildSwitchTile(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                subtitle: _biometricLoginEnabled
                    ? 'Enabled for quick sign-in'
                    : (_biometricAvailable
                        ? 'Use fingerprint / face unlock'
                        : 'Biometrics not available'),
                value: _biometricLoginEnabled,
                onChanged: (value) async {
                  final authService =
                      Provider.of<AuthService>(context, listen: false);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  if (value) {
                    if (!_biometricAvailable) {
                      scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text(
                              'Biometric authentication not available on this device.')));
                      return;
                    }
                    if (!authService.isLoggedIn) {
                      scaffoldMessenger.showSnackBar(const SnackBar(
                          content: Text(
                              'Sign in first to enable biometric quick unlock.')));
                      return;
                    }

                    final password =
                        await _promptForPasswordToEnableBiometrics();
                    if (password == null || password.isEmpty) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(const SnackBar(
                            content: Text('Biometric setup cancelled.')));
                      }
                      return;
                    }

                    final email = authService.user?.email;
                    if (email == null) {
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(const SnackBar(
                            content: Text('Unable to detect account email.')));
                      }
                      return;
                    }

                    await authService.saveCredentials(email, password);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('biometricLogin', true);
                    if (!mounted) return;
                    setState(() => _biometricLoginEnabled = true);
                    scaffoldMessenger.showSnackBar(const SnackBar(
                        content: Text('Biometric login enabled.')));
                  } else {
                    await authService.clearSavedCredentials();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('biometricLogin', false);
                    if (!mounted) return;
                    setState(() => _biometricLoginEnabled = false);
                    scaffoldMessenger.showSnackBar(const SnackBar(
                        content: Text('Biometric login disabled.')));
                  }
                },
              ),
              _buildSwitchTile(
                icon: Icons.shield,
                title: 'Two-Factor Authentication',
                subtitle: _twoFactorEnabled
                    ? '2FA is enabled'
                    : 'Add an extra security layer',
                value: _twoFactorEnabled,
                onChanged: (value) => setState(() => _twoFactorEnabled = value),
              ),
              _buildSettingsTile(
                icon: Icons.check_circle,
                title: 'Security Checkup',
                subtitle: 'Review account security settings',
                onTap: () => _showSecurityCheckDialog(context),
              ),

              const SizedBox(height: 24),

              // Notifications Section
              _buildSectionHeader('Notifications'),
              _buildSwitchTile(
                icon: Icons.notifications,
                title: 'Push Notifications',
                subtitle: 'Receive message and call alerts',
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
              ),
              _buildSwitchTile(
                icon: Icons.volume_up,
                title: 'Sound',
                subtitle: 'Notification sounds',
                value: _soundEnabled,
                onChanged: (value) => setState(() => _soundEnabled = value),
              ),
              _buildSwitchTile(
                icon: Icons.vibration,
                title: 'Vibration',
                subtitle: 'Vibrate for notifications',
                value: _vibrationEnabled,
                onChanged: (value) => setState(() => _vibrationEnabled = value),
              ),

              const SizedBox(height: 12),
              _buildSettingsTile(
                icon: Icons.notifications_active,
                title: 'Ringtone',
                subtitle: _useNexRingtone
                    ? 'NexApp tone #${_nexRingtoneIndex + 1}'
                    : 'Use phone ringtone',
                onTap: () => _showRingtoneDialog(context),
              ),

              const SizedBox(height: 24),

              // Appearance Section
              _buildSectionHeader('Appearance'),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _buildSwitchTile(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    subtitle: themeProvider.isDarkMode
                        ? 'Dark theme enabled'
                        : 'Light theme enabled',
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.language,
                title: AppLocalizations.of(context).get('language'),
                subtitle: Provider.of<LocaleProvider>(context).languageName,
                onTap: () => _showLanguageDialog(context),
              ),

              const SizedBox(height: 24),

              // App Experience Section
              _buildSectionHeader('App Experience'),
              _buildSwitchTile(
                icon: Icons.data_saver_on,
                title: 'Low Data Mode',
                subtitle: _lowDataModeEnabled
                    ? 'Reduced data usage'
                    : 'Standard mode',
                value: _lowDataModeEnabled,
                onChanged: (value) {
                  setState(() => _lowDataModeEnabled = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? 'Low Data Mode enabled.'
                          : 'Low Data Mode disabled.'),
                      backgroundColor: kNeonBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildSwitchTile(
                icon: Icons.login,
                title: 'Auto Login',
                subtitle: _autoLoginEnabled
                    ? 'Stay signed in'
                    : 'Require manual sign-in',
                value: _autoLoginEnabled,
                onChanged: (value) => setState(() => _autoLoginEnabled = value),
              ),
              _buildSettingsTile(
                icon: Icons.home_filled,
                title: 'Default Startup Screen',
                subtitle: _startupScreen,
                onTap: () => _showStartupScreenDialog(context),
              ),

              const SizedBox(height: 24),

              // Tokens Section
              _buildSectionHeader('Tokens'),
              Consumer<TokenProvider>(
                builder: (context, tokenProvider, _) {
                  return _buildSettingsTile(
                    icon: Icons.monetization_on,
                    title: 'Token Balance',
                    subtitle: '${tokenProvider.balance} tokens available',
                    onTap: () =>
                        _showTokenBalanceDialog(context, tokenProvider.balance),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.swap_horiz,
                title: 'Token Transfer',
                subtitle: 'Send tokens to another user',
                onTap: () => _showTokenTransferDialog(context),
              ),
              _buildSwitchTile(
                icon: Icons.auto_awesome,
                title: 'Auto Claim Daily Bonus',
                subtitle: _autoClaimDailyBonus ? 'Enabled' : 'Disabled',
                value: _autoClaimDailyBonus,
                onChanged: (value) {
                  setState(() => _autoClaimDailyBonus = value);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(value
                          ? 'Daily bonus auto-claim enabled'
                          : 'Auto claim disabled'),
                      backgroundColor: kNeonBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.card_giftcard,
                title: 'Promo Codes',
                subtitle: 'Redeem promo codes',
                onTap: () => _showPromoDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.group_add,
                title: 'Referral Rewards',
                subtitle: 'Invite friends and earn tokens',
                onTap: () => _showReferralDialog(context),
              ),

              const SizedBox(height: 24),

              // Support Section
              _buildSectionHeader('Support'),
              _buildSettingsTile(
                icon: Icons.help,
                title: 'Help Center',
                subtitle: 'FAQs and support',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.sd_storage,
                title: 'Storage Permissions',
                subtitle: 'Open permission helper to fix storage issues',
                onTap: () =>
                    Navigator.pushNamed(context, PermissionScreen.routeName),
              ),
              _buildSettingsTile(
                icon: Icons.info,
                title: 'About',
                subtitle: 'App version 1.0.0',
                onTap: () => _showAboutDialog(context),
              ),
              _buildSettingsTile(
                icon: Icons.description,
                title: 'Terms of Service',
                subtitle: 'Read terms',
                onTap: () {},
              ),
              _buildSettingsTile(
                icon: Icons.privacy_tip,
                title: 'Privacy Policy',
                subtitle: 'Read privacy policy',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kSurfaceColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: kNeonGreen,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kNeonPurple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kNeonPurple, size: 24),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kNeonBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kNeonBlue, size: 24),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: kNeonGreen,
        activeTrackColor: kNeonGreen.withValues(alpha: 0.3),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person, color: kNeonBlue),
            SizedBox(width: 12),
            Text('Edit Profile',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.person_outline, color: kNeonBlue),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Bio',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.description, color: kNeonGreen),
              ),
              style: TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.save),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: kNeonGreen),
            SizedBox(width: 12),
            Text('Change Password',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.lock_outline, color: kNeonGreen),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.lock, color: kNeonGreen),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                labelStyle: TextStyle(color: Colors.white70),
                prefixIcon: Icon(Icons.check_circle, color: kNeonGreen),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.update),
            label: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.language, color: kNeonBlue),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context).get('selectLanguage'),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleProvider.supportedLocales.map((locale) {
            final label = LocaleProvider.languageNameForCode(locale.languageCode);
            return ListTile(
              title: Text(label, style: const TextStyle(color: Colors.white)),
              trailing: localeProvider.locale.languageCode == locale.languageCode
                  ? const Icon(Icons.check, color: kNeonGreen)
                  : null,
              onTap: () async {
                await localeProvider.setLocale(locale);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }


  void _showRingtoneDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.music_note, color: kNeonBlue),
            SizedBox(width: 12),
            Text('Ringtone',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<bool>(
                  title: const Text('Use phone ringtone',
                      style: TextStyle(color: Colors.white)),
                  value: false,
                  groupValue: _useNexRingtone,
                  onChanged: (v) async {
                    await _setUseNexRingtone(false);
                    setState(() {});
                  },
                ),
                RadioListTile<bool>(
                  title: const Text('Use NexApp ringtone',
                      style: TextStyle(color: Colors.white)),
                  value: true,
                  groupValue: _useNexRingtone,
                  onChanged: (v) async {
                    await _setUseNexRingtone(true);
                    setState(() {});
                  },
                ),
                if (_useNexRingtone)
                  ...List.generate(10, (i) {
                    return ListTile(
                      title: Text('NexApp Tone ${i + 1}',
                          style: const TextStyle(color: Colors.white)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                const Icon(Icons.play_arrow, color: kNeonGreen),
                            onPressed: () => _playPreview(i),
                          ),
                          IconButton(
                            icon: Icon(
                              _nexRingtoneIndex == i
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _nexRingtoneIndex == i
                                  ? kNeonBlue
                                  : Colors.white54,
                            ),
                            onPressed: () async {
                              await _setNexRingtoneIndex(i);
                              if (mounted) setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            );
          },
        ),
        actions: [
          TextButton(
              onPressed: () {
                _stopPreview();
                Navigator.pop(context);
              },
              child:
                  const Text('Close', style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  void _showSecurityCheckDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.shield, color: kNeonGreen),
            SizedBox(width: 12),
            Text('Security Checkup',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('We checked your account settings and found no issues.',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(height: 10),
            Text('• Two-Factor Authentication status',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            Text('• Biometric login readiness',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            Text('• Connected devices review',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showStartupScreenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.home_filled, color: kNeonBlue),
            SizedBox(width: 12),
            Text('Default Startup Screen',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children:
              ['Home', 'Chat', 'Marketplace', 'Gaming Terminal'].map((screen) {
            return ListTile(
              title: Text(screen, style: const TextStyle(color: Colors.white)),
              trailing: _startupScreen == screen
                  ? const Icon(Icons.check, color: kNeonGreen)
                  : null,
              onTap: () {
                setState(() => _startupScreen = screen);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTokenBalanceDialog(BuildContext context, int balance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.monetization_on, color: kNeonGreen),
            SizedBox(width: 12),
            Text('Token Balance',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available balance: $balance tokens',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 14),
            const Text('Use tokens for games, chats, and marketplace rewards.',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTokenTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: kSurfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.swap_horiz, color: kNeonPurple),
              SizedBox(width: 12),
              Text('Transfer Tokens',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient ID or email',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.person_outline, color: kNeonBlue),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _transferAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.attach_money, color: kNeonGreen),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _recipientController.clear();
                _transferAmountController.clear();
                Navigator.pop(context);
              },
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final recipient = _recipientController.text.trim();
                final amount =
                    int.tryParse(_transferAmountController.text.trim()) ?? 0;
                final tokenProvider =
                    Provider.of<TokenProvider>(context, listen: false);

                if (recipient.isEmpty || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please enter a valid recipient and amount.'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (!tokenProvider.transferTokens(amount)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Not enough tokens to complete transfer.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Transferred $amount tokens to $recipient.'),
                    backgroundColor: kNeonGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                _recipientController.clear();
                _transferAmountController.clear();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.send),
              label: const Text('Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPromoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final promoController = TextEditingController();
        return AlertDialog(
          backgroundColor: kSurfaceColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.card_giftcard, color: kNeonGreen),
              SizedBox(width: 12),
              Text('Redeem Promo',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: promoController,
                decoration: const InputDecoration(
                  labelText: 'Promo code',
                  labelStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.local_offer, color: kNeonBlue),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final code = promoController.text.trim();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter a promo code to redeem.'),
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Promo "$code" applied! Tokens added soon.'),
                    backgroundColor: kNeonGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeonBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _showReferralDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.group_add, color: kNeonBlue),
            SizedBox(width: 12),
            Text('Referral Rewards',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Invite friends to NEX-APP and earn bonus tokens when they join.',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(height: 12),
            Text('Share your referral code: NEX-12345',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Controls',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Manage who can see your profile, activity, and token history.',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(height: 10),
            Text('• Visible to friends only',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            Text('• Hide token activity',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            Text('• Block unknown users',
                style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showConnectedDevicesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Connected Devices',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device 1: Windows Desktop — Active',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            SizedBox(height: 10),
            Text('Device 2: Mobile Android — Active',
                style: TextStyle(color: Colors.white, fontSize: 14)),
            SizedBox(height: 10),
            Text('To secure your account, sign out from unused devices.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.apps, color: kNeonGreen, size: 24),
            SizedBox(width: 12),
            Text('NEX-APP',
                style:
                    TextStyle(color: kNeonGreen, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(height: 12),
            Text(
              'NEX-APP is a comprehensive social platform featuring secure messaging, token-based rewards, gaming, betting, and marketplace features.',
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeonBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Log Out',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out? You\'ll need to sign in again to access your account.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              authService.signOut();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _backupSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings backup functionality coming soon.'),
        backgroundColor: kNeonBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset to defaults functionality coming soon.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export functionality coming soon.'),
        backgroundColor: kNeonGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
