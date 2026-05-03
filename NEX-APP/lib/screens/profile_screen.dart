import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/token_provider.dart';
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final tokenProvider = Provider.of<TokenProvider>(context);
    final user = authService.user;
    final bonusAvailable = !tokenProvider.dailyBonusClaimed;

    return Scaffold(
      backgroundColor: kDarkBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showEditProfileDialog(context, authService),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E1B),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF00B8F4).withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Account Overview', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.person, color: Color(0xFF25D366), size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user?.email ?? 'Guest User', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(user != null ? 'Signed in' : 'Guest access', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        _buildInfoChip('Tokens', '${tokenProvider.balance}'),
                        const SizedBox(width: 12),
                        _buildInfoChip('Status', user != null ? 'Verified' : 'Guest'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: bonusAvailable
                    ? () {
                        tokenProvider.claimDailyBonus(2500);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily reward claimed: +2,500 tokens!'),
                            backgroundColor: Color(0xFF25D366),
                          ),
                        );
                      }
                    : null,
                child: Text(bonusAvailable ? 'Claim Daily Reward' : 'Daily Reward Claimed', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E1B),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFF00B8F4).withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Achievements', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildAchievementChip('Token Collector'),
                        _buildAchievementChip(user != null ? 'Verified Member' : 'Guest'),
                        _buildAchievementChip(tokenProvider.balance >= 20000 ? 'Big Wallet' : 'Rising Trader'),
                        _buildAchievementChip(tokenProvider.balance >= 50000 ? 'Elite Investor' : 'Keep Going'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF00B8F4).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70)),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthService authService) {
    final nameController = TextEditingController(text: authService.user?.email ?? 'Guest');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kSurfaceColor,
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: kNeonGreen.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: kNeonGreen, size: 40),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: kDarkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Bio',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: 'Tell us about yourself',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: kDarkBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated!'),
                  backgroundColor: kNeonGreen,
                ),
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
