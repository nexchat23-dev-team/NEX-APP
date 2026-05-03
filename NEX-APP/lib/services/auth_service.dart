import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _lastError;

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;
  String? get lastError => _lastError;

  AuthService() {
    _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required.');
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _ensureUserDocument(_auth.currentUser);
      _lastError = null;
    } on FirebaseAuthException catch (e) {
      _lastError = e.message ?? 'Sign in failed';
      throw Exception(_lastError);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        throw Exception('Email, password, and username are required.');
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(username);
      // Create user document in Firestore
      await _createUserDocument(userCredential.user?.uid, username, email);
      _lastError = null;
    } on FirebaseAuthException catch (e) {
      _lastError = e.message ?? 'Sign up failed';
      throw Exception(_lastError);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> _createUserDocument(String? uid, String username, String email) async {
    try {
      if (uid == null) return;
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error creating user document: $e');
      // Don't rethrow - user is still created, just not in firestore
    }
  }

  Future<void> _ensureUserDocument(User? user) async {
    try {
      if (user == null) return;
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users').doc(user.uid);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await userRef.set({
          'username': user.displayName ?? user.email?.split('@').first ?? 'NEX User',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      final data = snapshot.data();
      if (data != null && (data['username'] == null || data['username'].toString().isEmpty)) {
        await userRef.set({
          'username': user.displayName ?? user.email?.split('@').first ?? 'NEX User',
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error ensuring user document: $e');
      // Don't rethrow - this is not critical
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      if (email.isEmpty) {
        throw Exception('Email is required.');
      }
      await _auth.sendPasswordResetEmail(email: email);
      _lastError = null;
    } on FirebaseAuthException catch (e) {
      _lastError = e.message ?? 'Password reset failed';
      throw Exception(_lastError);
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }
}
