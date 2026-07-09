import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/token_provider.dart';
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _client = SupabaseService.client;
  String? _lastError;

  User? get user => _client.auth.currentUser;
  bool get isLoggedIn => user != null;
  String? get lastError => _lastError;

  AuthService() {
    _client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  // Secure storage for biometric quick-sign
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: 'saved_email', value: email);
      await _secureStorage.write(key: 'saved_password', value: password);
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  Future<void> clearSavedCredentials() async {
    try {
      await _secureStorage.delete(key: 'saved_email');
      await _secureStorage.delete(key: 'saved_password');
    } catch (e) {
      debugPrint('Error clearing saved credentials: $e');
    }
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'saved_email');
      final password = await _secureStorage.read(key: 'saved_password');
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      debugPrint('Error reading saved credentials: $e');
    }
    return null;
  }

  /// Attempts to sign in using saved credentials. Returns true on success.
  Future<bool> signInWithSavedCredentials() async {
    try {
      final creds = await getSavedCredentials();
      if (creds == null) return false;
      await signIn(creds['email']!, creds['password']!);
      return true;
    } catch (e) {
      debugPrint('Error signing in with saved credentials: $e');
      return false;
    }
  }

  Future<void> _ensureSupabaseReady() async {
    if (!SupabaseService.isConfigured) {
      throw Exception(SupabaseService.initError ?? 'Supabase auth is not ready yet.');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required.');
      }

      await _ensureSupabaseReady();
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _ensureUserDocument(_client.auth.currentUser);
      _lastError = null;
    } on AuthException catch (e) {
      _lastError = e.message ?? 'Sign in failed';
      throw Exception(_lastError);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String username,
      {String? referralCode}) async {
    try {
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        throw Exception('Email, password, and username are required.');
      }

      await _ensureSupabaseReady();
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      final user = response.user;
      await _createUserDocument(user, referralCode: referralCode);
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        await _applyReferralCode(referralCode.trim(), user?.id ?? '');
      }
      _lastError = null;
    } on AuthException catch (e) {
      _lastError = e.message ?? 'Sign up failed';
      throw Exception(_lastError);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> _createUserDocument(User? user, {String? referralCode}) async {
    try {
      if (user == null) return;
      final code = _generateReferralCode(user.id);
      await _client.from('users').upsert({
        'id': user.id,
        'username': user.userMetadata?['username'] ?? user.email?.split('@').first ?? 'NEX User',
        'email': user.email ?? '',
        'photo_url': user.userMetadata?['avatar_url'] ?? '',
        'referral_code': code,
        'created_at': DateTime.now().toIso8601String(),
        'referral_count': 0,
        'pending_referral_tokens': 0,
        'referred_by': referralCode != null && referralCode.isNotEmpty
            ? referralCode
            : null,
      });
    } catch (e) {
      debugPrint('Error creating user document: $e');
    }
  }

  String _generateReferralCode(String uid) {
    return uid.substring(0, 8).toUpperCase();
  }

  Future<void> _applyReferralCode(String referralCode, String newUserId) async {
    try {
      if (referralCode.isEmpty || newUserId.isEmpty) return;
      final query = await _client
          .from('users')
          .select()
          .eq('referral_code', referralCode)
          .limit(1)
          .maybeSingle();
      if (query == null) return;

      final referrer = query as Map<String, dynamic>;
      await _client.from('users').update({
        'pending_referral_tokens': ((referrer['pending_referral_tokens'] as int?) ?? 0) + 10000,
        'referral_count': ((referrer['referral_count'] as int?) ?? 0) + 1,
      }).eq('id', referrer['id']);

      await _client.from('users').upsert({
        'id': newUserId,
        'referred_by': referrer['id'],
        'joined_with_referral': true,
      });
    } catch (e) {
      debugPrint('Error applying referral code: $e');
    }
  }

  Future<int> syncPendingReferralRewards(TokenProvider tokenProvider) async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      final data = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      final pendingTokens = data?['pending_referral_tokens'] as int? ?? 0;
      if (pendingTokens > 0) {
        tokenProvider.addTokens(pendingTokens);
        await _client.from('users').update({'pending_referral_tokens': 0}).eq('id', user.id);
      }
      return pendingTokens;
    } catch (e) {
      debugPrint('Error syncing referral rewards: $e');
      return 0;
    }
  }

  Future<void> _ensureUserDocument(User? user) async {
    try {
      if (user == null) return;
      final existing = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .limit(1)
          .maybeSingle();

      if (existing == null) {
        await _client.from('users').upsert({
          'id': user.id,
          'username': user.userMetadata?['username'] ?? user.email?.split('@').first ?? 'NEX User',
          'email': user.email ?? '',
          'photo_url': user.userMetadata?['avatar_url'] ?? '',
          'created_at': DateTime.now().toIso8601String(),
        });
        return;
      }

      final data = existing as Map<String, dynamic>;
      final updated = <String, dynamic>{};
      if (data['username'] == null || data['username'].toString().isEmpty) {
        updated['username'] = user.userMetadata?['username'] ?? user.email?.split('@').first ?? 'NEX User';
      }
      if (data['email'] == null || data['email'].toString().isEmpty) {
        updated['email'] = user.email ?? '';
      }
      if (data['photo_url'] == null || data['photo_url'].toString().isEmpty) {
        updated['photo_url'] = user.userMetadata?['avatar_url'] ?? '';
      }
      if (updated.isNotEmpty) {
        await _client.from('users').update(updated).eq('id', user.id);
      }
    } catch (e) {
      debugPrint('Error ensuring user document: $e');
    }
  }

  Future<String?> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null || bytes.isEmpty) return null;

    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final contentType = _contentTypeForFileName(fileName);

    try {
      await _client.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
      final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
      await updateProfile(photoUrl: publicUrl);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final payload = <String, dynamic>{'id': user.id};
    if (displayName != null && displayName.trim().isNotEmpty) {
      payload['username'] = displayName.trim();
      payload['name'] = displayName.trim();
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      payload['photo_url'] = photoUrl;
    }

    if (payload.length == 1) return;

    await _client.from('users').upsert(payload);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client.from('users').select().eq('id', userId).maybeSingle();
      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      return null;
    }
  }

  String _contentTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw Exception('Email is required.');
      }
      await _ensureSupabaseReady();
      await _client.auth.resetPasswordForEmail(email);
      _lastError = null;
    } on AuthException catch (e) {
      _lastError = e.message ?? 'Password reset failed';
      throw Exception(_lastError);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _ensureSupabaseReady();
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: null,
      );
      _lastError = null;
    } on AuthException catch (e) {
      _lastError = e.message ?? 'Google sign in failed';
      throw Exception(_lastError);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }
}
