import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenProvider extends ChangeNotifier {
  int _balance = 0;
  bool _initialized = false;
  bool dailyBonusClaimed = false;

  TokenProvider() {
    _loadState();
  }

  int get balance => _balance;
  bool get hasTokens => _balance > 0;
  bool get isInitialized => _initialized;

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt('token_balance') ?? 0;
    dailyBonusClaimed = prefs.getBool('daily_bonus_claimed') ?? false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('token_balance', _balance);
    await prefs.setBool('daily_bonus_claimed', dailyBonusClaimed);
  }

  void _persist() {
    _saveState();
  }

  void setBalance(int value) {
    _balance = value;
    _persist();
    notifyListeners();
  }

  void addTokens(int amount) {
    if (amount <= 0) return;
    _balance += amount;
    _persist();
    notifyListeners();
  }

  void deductTokens(int amount) {
    if (amount <= 0) return;
    _balance = (_balance - amount).clamp(0, double.infinity.toInt());
    _persist();
    notifyListeners();
  }

  bool transferTokens(int amount) {
    if (amount <= 0 || amount > _balance) {
      return false;
    }
    _balance -= amount;
    _persist();
    notifyListeners();
    return true;
  }

  void claimDailyBonus(int amount) {
    if (!dailyBonusClaimed && amount > 0) {
      _balance += amount;
      dailyBonusClaimed = true;
      _persist();
      notifyListeners();
    }
  }
}
