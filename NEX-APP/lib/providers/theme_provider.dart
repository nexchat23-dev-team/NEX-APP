import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;
  late SharedPreferences _prefs;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _initPreferences();
  }

  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  ThemeData getThemeData() {
    return _isDarkMode ? _buildDarkTheme() : _buildLightTheme();
  }

  ThemeData _buildDarkTheme() {
    const kNeonGreen = Color(0xFF25D366);
    const kNeonBlue = Color(0xFF00B8F4);
    const kNeonPurple = Color(0xFF9D4EDD);
    const kPrimaryGreen = Color(0xFF075E54);
    const kPrimaryBlue = Color(0xFF054A85);
    const kDarkBackground = Color(0xFF0B1410);
    const kSurfaceColor = Color(0xFF0F1E1B);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: kPrimaryGreen,
      scaffoldBackgroundColor: kDarkBackground,
      canvasColor: kDarkBackground,
      cardColor: kSurfaceColor,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: kNeonGreen,
        secondary: kNeonBlue,
        tertiary: kNeonPurple,
        surface: kSurfaceColor,
        onSurface: Colors.white,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kNeonGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          side: const BorderSide(color: kNeonBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D2F49),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const kNeonGreen = Color(0xFF25D366);
    const kNeonBlue = Color(0xFF00B8F4);
    const kNeonPurple = Color(0xFF9D4EDD);
    const kPrimaryGreen = Color(0xFF075E54);
    const kPrimaryBlue = Color(0xFF054A85);
    const kLightBackground = Color(0xFFF5F5F5);
    const kLightSurface = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: kPrimaryGreen,
      scaffoldBackgroundColor: kLightBackground,
      canvasColor: kLightBackground,
      cardColor: kLightSurface,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.light(
        primary: kNeonGreen,
        secondary: kNeonBlue,
        tertiary: kNeonPurple,
        surface: kLightSurface,
        onSurface: Colors.black87,
        onPrimary: Colors.white,
        onSecondary: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kPrimaryBlue,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kNeonGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.black87,
          side: const BorderSide(color: kNeonBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: const TextStyle(color: Colors.black87),
        hintStyle: const TextStyle(color: Colors.black54),
      ),
    );
  }
}
