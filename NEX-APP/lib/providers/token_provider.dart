import 'package:flutter/material.dart';

class TokenProvider extends ChangeNotifier {
  int _balance = 0;

  int get balance => _balance;
  bool get hasTokens => _balance > 0;

  void setBalance(int value) {
    _balance = value;
    notifyListeners();
  }

  void addTokens(int amount) {
    _balance += amount;
    notifyListeners();
  }

  void deductTokens(int amount) {
    _balance = (_balance - amount).clamp(0, double.infinity.toInt());
    notifyListeners();
  }

  bool dailyBonusClaimed = false;

  void claimDailyBonus(int amount) {
    if (!dailyBonusClaimed) {
      _balance += amount;
      dailyBonusClaimed = true;
      notifyListeners();
    }
  }
}
