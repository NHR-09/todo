import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get displayName => AuthService.displayName;
  String? get photoUrl => AuthService.photoUrl;
  String? get email => AuthService.email;

  AuthProvider() {
    _user = AuthService.currentUser;
    // Listen to auth state changes
    AuthService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AuthService.signInWithGoogle();
      if (result != null) {
        _user = result.user;
        // Trigger sync: upload local data first, then pull remote
        SyncService.syncToCloud().then((_) => SyncService.pullRemoteChanges());
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false; // User cancelled
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    await AuthService.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Trigger a manual sync (upload + pull).
  Future<void> syncNow() async {
    if (!isSignedIn) return;
    _isLoading = true;
    notifyListeners();
    try {
      await SyncService.syncToCloud();
      await SyncService.pullRemoteChanges();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }
}
