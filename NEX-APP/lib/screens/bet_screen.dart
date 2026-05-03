import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/token_provider.dart';
import '../utils/formatters.dart';

class BetScreen extends StatefulWidget {
  static const routeName = '/bet';
  const BetScreen({super.key});

  @override
  State<BetScreen> createState() => _BetScreenState();
}

class _BetScreenState extends State<BetScreen> {
  final TextEditingController stakeController = TextEditingController(text: '1000');
  final Random random = Random();
  String aviatorMessage = 'Select your stake and launch the flight. Good luck!';
  String minesMessage = 'Start Mines and clear safe tiles without hitting a mine.';
  String wheelMessage = 'Spin the wheel and multiply your stake for bonus tokens.';
  final List<double> wheelMultipliers = [0.0, 0.5, 1, 1.5, 2, 3, 5];
  bool minesActive = false;
  Set<int> minePositions = {};
  Set<int> revealedCells = {};
  int minesStake = 0;

  void placeAviatorBet(int balance) {
    final stake = int.tryParse(stakeController.text.replaceAll(',', '').trim()) ?? 0;
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
        aviatorMessage = 'Aviator landed at x${crashPoint.toStringAsFixed(2)}. You cashed out at x${cashOut.toStringAsFixed(2)} and won ${formatBalanceDisplay(payout)} tokens!';
      });
    } else {
      setState(() {
        aviatorMessage = 'Aviator crashed at x${crashPoint.toStringAsFixed(2)}. You lost ${formatBalanceDisplay(stake)} tokens.';
      });
    }
  }

  void startMinesGame(int balance) {
    final stake = int.tryParse(stakeController.text.replaceAll(',', '').trim()) ?? 0;
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
      minesMessage = 'Mines started! Reveal 3 safe tiles without hitting a mine.';
    });
  }

  void revealMinesCell(int index) {
    if (!minesActive || revealedCells.contains(index)) return;
    final tokenProvider = Provider.of<TokenProvider>(context, listen: false);

    if (minePositions.contains(index)) {
      minesActive = false;
      tokenProvider.deductTokens(minesStake);
      setState(() {
        minesMessage = 'Boom! Tile $index had a mine. You lost ${formatBalanceDisplay(minesStake)} tokens.';
      });
      return;
    }

    revealedCells.add(index);
    if (revealedCells.length >= 3) {
      minesActive = false;
      final reward = (minesStake * 2.5).round();
      tokenProvider.addTokens(reward);
      setState(() {
        minesMessage = 'You cleared 3 safe tiles and won ${formatBalanceDisplay(reward)} tokens!';
      });
      return;
    }

    setState(() {
      minesMessage = 'Safe! ${revealedCells.length}/3 cleared. Keep going.';
    });
  }

  void spinWheel(int balance) {
    final stake = int.tryParse(stakeController.text.replaceAll(',', '').trim()) ?? 0;
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
    final multiplier = wheelMultipliers[random.nextInt(wheelMultipliers.length)];
    final payout = (stake * multiplier).round();
    if (payout > 0) {
      tokenProvider.addTokens(payout);
    }

    setState(() {
      if (multiplier == 0) {
        wheelMessage = 'Oh no! The wheel landed on 0x. You lost ${formatBalanceDisplay(stake)} tokens.';
      } else {
        wheelMessage = 'Great spin! You won ${formatBalanceDisplay(payout)} tokens at ${multiplier}x multiplier.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final balance = Provider.of<TokenProvider>(context).balance;
    return Scaffold(
      backgroundColor: const Color(0xFF06101F),
      appBar: AppBar(
        title: const Text('Bet Hub'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF081827),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF00FF66).withValues(alpha: 0.16)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live gameplay', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    const Text('Neon betting arena', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Text('Balance: ${formatBalanceDisplay(balance)} tokens', style: const TextStyle(color: Color(0xFF00FF66), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 18),
                    TextField(
                      controller: stakeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Stake amount',
                        hintText: '1000',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF081827),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF00FF66).withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Aviator', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(aviatorMessage, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => placeAviatorBet(balance),
                      child: const Text('Launch Aviator', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF081827),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF00FF66).withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Mines', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(minesMessage, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 18),
                    GridView.builder(
                      itemCount: 6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final revealed = revealedCells.contains(index);
                        final hasMine = minePositions.contains(index);
                        final color = !minesActive && revealed && hasMine
                            ? Colors.redAccent
                            : revealed
                                ? const Color(0xFF00FF66)
                                : const Color(0xFF11234A);
                        return GestureDetector(
                          onTap: () => revealMinesCell(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFF00FF66).withValues(alpha: 0.24)),
                            ),
                            child: Center(
                              child: revealed
                                  ? Icon(hasMine ? Icons.warning : Icons.check, color: Colors.black87, size: 28)
                                  : const Text('?', style: TextStyle(color: Colors.white54, fontSize: 24)),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => startMinesGame(balance),
                      child: const Text('Start Mines', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF081827),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFF00FF66).withValues(alpha: 0.16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Spin Wheel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(wheelMessage, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: () => spinWheel(balance),
                      child: const Text('Spin the Wheel', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
