import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/token_provider.dart';

class MarketplaceScreen extends StatefulWidget {
  static const routeName = '/market';
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final TextEditingController promoController = TextEditingController();
  String promoMessage = '';

  @override
  void dispose() {
    promoController.dispose();
    super.dispose();
  }

  void redeemPromo(TokenProvider tokenProvider) {
    final code = promoController.text.trim().toUpperCase();
    if (code == 'NEXBONUS') {
      tokenProvider.addTokens(5000);
      setState(() {
        promoMessage = 'Promo applied: 5,000 free tokens added!';
      });
    } else if (code == 'MEGABOOST') {
      tokenProvider.addTokens(12000);
      setState(() {
        promoMessage = 'Promo applied: 12,000 free tokens added!';
      });
    } else {
      setState(() {
        promoMessage = 'Invalid promo code. Try NEXBONUS or MEGABOOST.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenProvider = Provider.of<TokenProvider>(context);
    final packs = [
      {'title': 'Starter Pack', 'subtitle': '5,000 tokens', 'amount': 5000, 'price': '\$0.99'},
      {'title': 'Pro Bundle', 'subtitle': '20,000 tokens', 'amount': 20000, 'price': '\$3.99'},
      {'title': 'Elite Pack', 'subtitle': '55,000 tokens', 'amount': 55000, 'price': '\$9.99'},
      {'title': 'Mystery Crate', 'subtitle': 'Up to 80,000 tokens', 'amount': 80000, 'price': '\$7.99'},
      {'title': 'Master Pack', 'subtitle': '120,000 tokens', 'amount': 120000, 'price': '\$19.99'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B1410),
      appBar: AppBar(
        title: const Text('Marketplace'),
        elevation: 0,
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
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.24), blurRadius: 18, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quick token packages for instant play.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 16),
                    Text('Your balance: ${tokenProvider.balance} tokens', style: const TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1E1B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF00B8F4).withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Promo code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: promoController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter promo code',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => redeemPromo(tokenProvider),
                      child: const Text('Apply Code', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    Text(promoMessage, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemCount: packs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final pack = packs[index];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1E1B),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF00B8F4).withValues(alpha: 0.16)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(pack['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(pack['subtitle'] as String, style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF25D366),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(pack['price'] as String, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              tokenProvider.addTokens(pack['amount'] as int);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Purchased ${pack['subtitle']}. Your balance has been updated.'),
                                  backgroundColor: const Color(0xFF25D366),
                                ),
                              );
                            },
                            child: const Text('Buy now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
