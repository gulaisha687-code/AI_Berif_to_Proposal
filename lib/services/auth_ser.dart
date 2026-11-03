import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Thrown with a message that is safe to show to the user.
class AuthFailure implements Exception {
  final String message;
  AuthFailure(this.message);
}

// All sign-in code lives here, so the screens never touch Firebase directly.
class AuthService {
  static final _auth = FirebaseAuth.instance;
  static const _seenKey = 'onboarded';
  static bool _googleReady = false;

  static User? get currentUser => _auth.currentUser;
  static bool get signedIn => _auth.currentUser != null;

  // Skip the welcome screen if the user is signed in or already chose guest.
  static Future<bool> hasOnboarded() async {
    try {
      final user = await _auth
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 3), onTimeout: () => _auth.currentUser);
      if (user != null) return true;
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markOnboarded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {}
  }

  // Returns true when signed in, false when the user closed the Google window.
  // Returns true when signed in, false when the user closed the Google window.
  static Future<bool> signInWithGoogle() async {
    try {
      // On web, keep the pop-up flow.
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider());
        return true;
      }

      // On phones, use Google's own account picker.
      final google = GoogleSignIn.instance;
      if (!_googleReady) {
        await google.initialize();
        _googleReady = true;
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthFailure(
          'Google did not return a sign-in token. Check the Firebase setup.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _auth.signInWithCredential(credential);
      debugPrint('Auth: signed in as ${_auth.currentUser?.email}');
      return true;
    } on GoogleSignInException catch (e) {
      debugPrint('Auth: Google sign-in error: $e');
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      throw AuthFailure('Google sign-in failed (${e.code.name}).');
    } on FirebaseAuthException catch (e) {
      const cancelled = {'popup-closed-by-user', 'cancelled-popup-request'};
      if (cancelled.contains(e.code)) return false;
      throw AuthFailure(_message(e));
    }
  }

  static Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  static Future<void> signUpWithEmail(
      String name,
      String email,
      String password,
      ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(name);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e));
    }
  }

  static Future<void> signOut() async {
    try {
      if (_googleReady) await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  static String _message(FirebaseAuthException e) {
    debugPrint('Auth error: ${e.code} ${e.message}');
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try signing in.';
      case 'weak-password':
        return 'Choose a stronger password (at least 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'network-request-failed':
        return 'Network problem. Check your internet connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not turned on in Firebase yet.';
      default:
        return 'Sign-in failed (${e.code}).';
    }
  }
}