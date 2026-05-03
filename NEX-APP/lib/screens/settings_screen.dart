import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: kPrimaryBlue,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Section
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
            onTap: () {},
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive message and call alerts',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
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

          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return _buildSwitchTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                subtitle: themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                value: themeProvider.isDarkMode,
                onChanged: (value) => themeProvider.toggleTheme(),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _selectedLanguage,
            onTap: () => _showLanguageDialog(context),
          ),

          const SizedBox(height: 24),

          // Tokens Section
          _buildSectionHeader('Tokens'),
          _buildSettingsTile(
            icon: Icons.monetization_on,
            title: 'Token Balance',
            subtitle: 'View your tokens',
            onTap: () {},
          ),
          _buildSettingsTile(
            icon: Icons.card_giftcard,
            title: 'Promo Codes',
            subtitle: 'Redeem promo codes',
            onTap: () {},
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
          ElevatedButton(
            onPressed: () => _showLogoutDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: kNeonGreen,
          fontSize: 14,
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kNeonPurple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kNeonPurple, size: 24),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
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
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kNeonBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: kNeonBlue, size: 24),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: kNeonGreen,
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Bio',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
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
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Select Language', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'Spanish', 'French', 'German', 'Arabic'].map((lang) {
            return RadioListTile<String>(
              title: Text(lang, style: const TextStyle(color: Colors.white)),
              value: lang,
              groupValue: _selectedLanguage,
              onChanged: (val) {
                setState(() => _selectedLanguage = val!);
                Navigator.pop(context);
              },
              activeColor: kNeonGreen,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('NEXCHAT', style: TextStyle(color: kNeonGreen)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 8),
            Text('NEXCHAT is a secure messaging app with token-based rewards, betting, and marketplace features.', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
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
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final authService = Provider.of<AuthService>(context, listen: false);
              authService.signOut();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
