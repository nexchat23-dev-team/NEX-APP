import 'package:flutter/material.dart';
import '../main.dart';

class AdvertisementScreen extends StatefulWidget {
  static const routeName = '/advertisements';
  const AdvertisementScreen({super.key});

  @override
  State<AdvertisementScreen> createState() => _AdvertisementScreenState();
}

class _AdvertisementScreenState extends State<AdvertisementScreen> {
  final List<Map<String, dynamic>> _ads = [
    {
      'id': '1',
      'title': 'Get 500 Free Tokens!',
      'description': 'Sign up today and receive 500 bonus tokens to use on all games.',
      'type': 'promo',
      'cta': 'Claim Now',
      'expires': '2 days left',
    },
    {
      'id': '2',
      'title': 'Premium Membership',
      'description': 'Unlock all features with Premium. No ads, exclusive games, and more!',
      'type': 'subscription',
      'cta': 'Learn More',
      'expires': null,
    },
    {
      'id': '3',
      'title': 'Token Pack Sale',
      'description': 'Buy 1000 tokens get 500 FREE! Limited time offer.',
      'type': 'sale',
      'cta': 'Buy Now',
      'expires': '5 hours left',
    },
    {
      'id': '4',
      'title': 'Invite Friends',
      'description': 'Invite a friend and get 200 tokens for each referral!',
      'type': 'referral',
      'cta': 'Invite',
      'expires': null,
    },
    {
      'id': '5',
      'title': 'Weekly Tournament',
      'description': 'Join the Aviator Championship. Win up to 10,000 tokens!',
      'type': 'event',
      'cta': 'Join',
      'expires': '3 days left',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628), // Dark blue background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1E36), // Blue-tinted app bar
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kNeonBlue, kNeonBlue.withValues(alpha: 0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kNeonBlue.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.ads_click, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Advertisements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kNeonBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: kNeonBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: kNeonBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: kNeonBlue),
              onPressed: () => _showFilterDialog(context),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return _buildAdCard(ad);
        },
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final Color adColor = _getAdTypeColor(ad['type'] as String);
    final IconData adIcon = _getAdTypeIcon(ad['type'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            adColor.withValues(alpha: 0.15),
            adColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: adColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: adColor.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: adColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(adIcon, color: adColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: adColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getAdTypeLabel(ad['type'] as String),
                          style: TextStyle(
                            color: adColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (ad['expires'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.red, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          ad['expires'] as String,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              ad['description'] as String,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          // CTA Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: adColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _handleAdAction(ad),
                child: Text(
                  ad['cta'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAdTypeColor(String type) {
    switch (type) {
      case 'promo':
        return kNeonBlue; // Changed to neon blue
      case 'subscription':
        return kNeonBlue; // Changed to neon blue
      case 'sale':
        return kNeonBlue; // Changed to neon blue
      case 'referral':
        return kNeonBlue;
      case 'event':
        return kNeonBlue; // Changed to neon blue
      default:
        return kNeonBlue;
    }
  }

  IconData _getAdTypeIcon(String type) {
    switch (type) {
      case 'promo':
        return Icons.card_giftcard;
      case 'subscription':
        return Icons.star;
      case 'sale':
        return Icons.local_offer;
      case 'referral':
        return Icons.person_add;
      case 'event':
        return Icons.emoji_events;
      default:
        return Icons.campaign;
    }
  }

  String _getAdTypeLabel(String type) {
    switch (type) {
      case 'promo':
        return 'PROMOTION';
      case 'subscription':
        return 'PREMIUM';
      case 'sale':
        return 'SALE';
      case 'referral':
        return 'REFERRAL';
      case 'event':
        return 'EVENT';
      default:
        return 'AD';
    }
  }

  void _handleAdAction(Map<String, dynamic> ad) {
    switch (ad['type']) {
      case 'promo':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claiming ${ad['title']}...'),
            backgroundColor: kNeonBlue,
          ),
        );
        break;
      case 'subscription':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'sale':
        Navigator.pushNamed(context, '/marketplace');
        break;
      case 'referral':
        _showReferralDialog(context);
        break;
      case 'event':
        Navigator.pushNamed(context, '/bet');
        break;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1E36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kNeonBlue.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kNeonBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.filter_list, color: kNeonBlue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Ads',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildFilterOption('All', true),
            _buildFilterOption('Promotions', false),
            _buildFilterOption('Sales', false),
            _buildFilterOption('Events', false),
            _buildFilterOption('Referrals', false),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? kNeonBlue.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? kNeonBlue : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? kNeonBlue : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: selected
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: kNeonBlue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: kNeonBlue, size: 18),
              )
            : null,
        onTap: () => Navigator.pop(context),
      ),
    );
  }

  void _showReferralDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D1E36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kNeonBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add, color: kNeonBlue),
            ),
            const SizedBox(width: 12),
            const Text('Invite Friends', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share your referral link and earn 200 tokens for each friend who joins!',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Referral Link:',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'https://nexchat.com/ref/user123',
                style: TextStyle(color: kNeonBlue, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [kNeonBlue, kNeonBlue.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kNeonBlue.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard!'),
                    backgroundColor: kNeonBlue,
                  ),
                );
              },
              child: const Text('Copy Link', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
