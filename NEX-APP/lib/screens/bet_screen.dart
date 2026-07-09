import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/token_provider.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class BettingScreen extends StatefulWidget {
  static const routeName = '/betting';
  const BettingScreen({super.key});

  @override
  State<BettingScreen> createState() => _BetScreenState();
}

class _BetScreenState extends State<BettingScreen> {
  final TextEditingController stakeController =
      TextEditingController(text: '1000');
  final Random random = Random();
  String aviatorMessage = 'Select your stake and launch the flight. Good luck!';
  String minesMessage =
      'Start Mines and clear safe tiles without hitting a mine.';
  String wheelMessage =
      'Spin the wheel and multiply your stake for bonus tokens.';
  String diceMessage = 'Roll the dice and beat the odds.';
  final List<double> wheelMultipliers = [0.0, 0.5, 1, 1.5, 2, 3, 5];
  bool minesActive = false;
  Set<int> minePositions = {};
  Set<int> revealedCells = {};
  int minesStake = 0;

  void placeAviatorBet(int balance) {
    final stake =
        int.tryParse(stakeController.text.replaceAll(',', '').trim()) ?? 0;
    if (stake <= 0) {
      setState(() {
        aviatorMessage = 'Enter a valid stake amount.';
      });
      return;
    }
    if (stake > balance) {
      setState(() {
        aviatorMessage = 'Not enough tokens for the  bet.';
      });
      return;
    }

    final tokenProvider = Provider.of<TokenProvider>(context, listen: false);
    tokenProvider.deductTokens(stake);

    final crashPoint = 1 + random.nextDouble() * 10;
    final cashOut = 1 + random.nextDouble() * 5;
    final payout = (stake * cashOut).round();

    if (crashPoint >= cashOut) {
      tokenProvider.addTokens(payout);
      setState(() {
        aviatorMessage =
            'Aviator landed at x${crashPoint.toStringAsFixed(2)}. You cashed out at x${cashOut.toStringAsFixed(2)} and won ${formatBalanceDisplay(payout)} tokens!';
      });
    } else {
      setState(() {
        aviatorMessage =
            'Aviator crashed at x${crashPoint.toStringAsFixed(2)}. You lost ${formatBalanceDisplay(stake)} tokens.';
      });
    }
  }

  void startMinesGame(int balance) {
    final stake =
        int.tryParse(stakeController.text.replaceAll(',', '').trim()) ?? 0;
    if (stake <= 0) {
      setState(() {
        minesMessage = 'Enter a stake to play Mines.';
      });
      return;
    }
    if (stake > balance) {
      setState(() {
        minesMessage = 'Not enough tokens for that bet.';
      });
      return;
    }

    minesStake = stake;
    minePositions = {};
    final positions = List.generate(6, (index) => index)..shuffle(random);
    minePositions.addAll(positions.take(2));
    revealedCells.clear();
    minesActive = true;
    setState(() {
      minesMessage =
          'Mines started! Reveal 3 safe tiles without hitting a mine.';
    });
  }

  void revealMinesCell(int index) {
    if (!minesActive || revealedCells.contains(index)) return;
    final tokenProvider = Provider.of<TokenProvider>(context, listen: false);

    if (minePositions.contains(index)) {
      minesActive = false;
      tokenProvider.deductTokens(minesStake);
      setState(() {
        minesMessage =
            'Boom! Tile $index had a mine. You lost ${formatBalanceDisplay(minesStake)} tokens.';
      });
      return;
    }

    revealedCells.add(index);
    if (revealedCells.length >= 3) {
      minesActive = false;
      final reward = (minesStake * 2.5).round();
      tokenProvider.addTokens(reward);
      setState(() {
        minesMessage =
            'You cleared 3 safe tiles and won ${formatBalanceDisplay(reward)} tokens!';
      });
      return;
    }

    setState(() {
      minesMessage = 'Safe! ${revealedCells.length}/3 cleared. Keep going.';
    });
  }

  void spinWheel(int balance) {
    final stake =
        int.tryParse(stakeController.text.replaceAll(',', '').trim()) ?? 0;
    if (stake <= 0) {
      setState(() {
        wheelMessage = 'Enter a valid stake amount to spin the wheel.';
      });
      return;
    }
    if (stake > balance) {
      setState(() {
        wheelMessage = 'You don’t have enough tokens to spin with that stake.';
      });
      return;
    }

    final tokenProvider = Provider.of<TokenProvider>(context, listen: false);
    tokenProvider.deductTokens(stake);
    final multiplier =
        wheelMultipliers[random.nextInt(wheelMultipliers.length)];
    final payout = (stake * multiplier).round();
    if (payout > 0) {
      tokenProvider.addTokens(payout);
    }

    setState(() {
      if (multiplier == 0) {
        wheelMessage =
            'Oh no! The wheel landed on 0x. You lost ${formatBalanceDisplay(stake)} tokens.';
      } else {
        wheelMessage =
            'Great spin! You won ${formatBalanceDisplay(payout)} tokens at ${multiplier}x multiplier.';
      }
    });
  }

  void rollDice(int balance) {
    final stake =
        int.tryParse(stakeController.text.replaceAll(',', '').trim()) ?? 0;
    if (stake <= 0) {
      setState(() {
        diceMessage = 'Enter a valid stake to roll the dice.';
      });
      return;
    }
    if (stake > balance) {
      setState(() {
        diceMessage = 'Not enough tokens for that roll.';
      });
      return;
    }

    final tokenProvider = Provider.of<TokenProvider>(context, listen: false);
    tokenProvider.deductTokens(stake);
    final roll = random.nextInt(6) + 1;
    final payout = (stake * (1 + roll / 4)).round();

    if (roll >= 4) {
      tokenProvider.addTokens(payout);
      setState(() {
        diceMessage =
            'Dice rolled $roll. You won ${formatBalanceDisplay(payout)} tokens!';
      });
    } else {
      setState(() {
        diceMessage =
            'Dice rolled $roll. You lost ${formatBalanceDisplay(stake)} tokens.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenProvider = Provider.of<TokenProvider>(context);
    final balance = tokenProvider.isInitialized ? tokenProvider.balance : 0;
    final balanceLabel = tokenProvider.isInitialized
        ? formatBalanceDisplay(balance)
        : 'Loading...';
    return Scaffold(
      backgroundColor: const Color(0xFF06101F),
      appBar: AppBar(
        title: const Text('💰 Betting Arena',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: const Color(0xFF0A1929),
        elevation: 2,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: kNeonGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: kNeonGreen, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      balanceLabel,
                      style: const TextStyle(
                          color: kNeonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kNeonPurple.withValues(alpha: 0.15),
                      kNeonBlue.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: kNeonBlue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Neon Betting Arena',
                        style: TextStyle(
                            color: kNeonBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Test your luck and win amazing rewards',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                              'Balance', 'Balance', balanceLabel, kNeonGreen),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                              'Win Rate', 'Win Rate', '42%', kNeonBlue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stake Input
              const Text('Set Your Stake',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1C2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: kNeonBlue.withValues(alpha: 0.3), width: 2),
                ),
                child: TextField(
                  controller: stakeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    prefixIcon:
                        Icon(Icons.attach_money, color: kNeonGreen, size: 24),
                    prefixIconConstraints:
                        BoxConstraints(minWidth: 40, minHeight: 40),
                    hintText: 'Enter amount',
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stake Buttons
              const Text('Quick Amounts',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: ['500', '1000', '5000', '10000']
                    .map((amount) => Expanded(
                          child: GestureDetector(
                            onTap: () => stakeController.text = amount,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: kNeonBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: kNeonBlue.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                amount,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: kNeonBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                        ))
                    .toList()
                    .expand((widget) => [widget, const SizedBox(width: 8)])
                    .toList()
                  ..removeLast(),
              ),
              const SizedBox(height: 28),

              // Aviator Game
              _buildBettingGameCard(
                title: 'Aviator',
                subtitle: 'Watch the multiplier climb or crash',
                icon: Icons.trending_up,
                color: kNeonGreen,
                onTap: () => placeAviatorBet(balance),
                message: aviatorMessage,
                buttonText: 'Launch Aviator',
                multiplier: '5.25x',
                winChance: '45%',
              ),
              const SizedBox(height: 16),

              // Mines Game
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withValues(alpha: 0.1),
                      Colors.red.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.warning,
                              color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mines',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Find safe tiles and avoid mines',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('High Risk',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(minesMessage,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 16),
                    GridView.builder(
                      itemCount: 6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final revealed = revealedCells.contains(index);
                        final hasMine = minePositions.contains(index);
                        final color = !minesActive && revealed && hasMine
                            ? Colors.red.withValues(alpha: 0.4)
                            : revealed
                                ? kNeonGreen.withValues(alpha: 0.3)
                                : const Color(0xFF11234A);
                        return GestureDetector(
                          onTap: () => revealMinesCell(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: revealed
                                    ? (hasMine ? Colors.red : kNeonGreen)
                                    : Colors.white24,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: revealed
                                  ? Icon(
                                      hasMine
                                          ? Icons.warning
                                          : Icons.check_circle,
                                      color: hasMine ? Colors.red : kNeonGreen,
                                      size: 28)
                                  : const Text('?',
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => startMinesGame(balance),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Mines'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Wheel Game
              _buildBettingGameCard(
                title: '🎡 Spin Wheel',
                subtitle: 'Spin and win big multipliers',
                icon: Icons.blur_circular,
                color: kNeonPurple,
                onTap: () => spinWheel(balance),
                message: wheelMessage,
                buttonText: 'Spin the Wheel',
                multiplier: '3.50x',
                winChance: '50%',
              ),
              const SizedBox(height: 16),
              _buildBettingGameCard(
                title: '🎲 Turbo Dice',
                subtitle: 'Roll high and beat the system',
                icon: Icons.casino,
                color: kNeonGreen,
                onTap: () => rollDice(balance),
                message: diceMessage,
                buttonText: 'Roll Dice',
                multiplier: '2.25x',
                winChance: '48%',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBettingGameCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String message,
    required String buttonText,
    required String multiplier,
    required String winChance,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(multiplier,
                      style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  const Text('avg payout',
                      style: TextStyle(color: Colors.white30, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: color, size: 14),
                const SizedBox(width: 6),
                Text('Win chance: $winChance',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Potential payout: stake × $multiplier',
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.black,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }
}
