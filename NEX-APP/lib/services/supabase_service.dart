import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://opiheuvxtzmbkolkurmd.supabase.co',
  );
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool _initialized = false;
  static String? _initError;

  static bool get isConfigured => _initialized && _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;
  static String? get initError => _initError;

  static Future<void> initialize() async {
    if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
      _initialized = false;
      _initError = 'Supabase anon key is not configured. Add SUPABASE_ANON_KEY and restart the app.';
      debugPrint(_initError);
      return;
    }

    try {
      await Supabase.initialize(
        url: _supabaseUrl,
        anonKey: _supabaseAnonKey,
      );
      _initialized = true;
      _initError = null;
    } catch (error) {
      _initialized = false;
      _initError = error.toString();
      debugPrint('Supabase initialization error: $error');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}
