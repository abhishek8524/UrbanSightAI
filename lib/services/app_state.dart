import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../utils/enums.dart';
import '../utils/firestore_paths.dart';
import 'auth_service.dart';

/// Global app state: Firebase user, Firestore profile, and derived isAdmin.
/// Listens to auth changes and loads user profile from Firestore.
class AppState extends ChangeNotifier {
  AppState({required AuthService authService})
      : _authService = authService {
    _subscription = _authService.currentUserStream.listen(_onAuthChanged);
  }

  final AuthService _authService;
  StreamSubscription<User?>? _subscription;

  User? _firebaseUser;
  AppUser? _appUser;

  /// Current Firebase User (null when signed out).
  User? get currentUser => _firebaseUser;

  /// Current user profile from Firestore (null when signed out or doc missing).
  AppUser? get appUser => _appUser;

  /// True when [appUser] has role admin.
  bool get isAdmin => _appUser?.role == UserRole.admin;

  /// Reload the current user's profile from Firestore (e.g. after role change).
  Future<void> refreshProfile() async {
    if (_firebaseUser == null) return;
    await _loadProfile(_firebaseUser!.uid);
  }

  void _onAuthChanged(User? user) {
    _firebaseUser = user;
    if (_firebaseUser == null) {
      _appUser = null;
      notifyListeners();
      return;
    }
    _loadProfile(_firebaseUser!.uid);
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final snap = await userRef(uid).get();
      if (snap.exists && snap.data() != null) {
        _appUser = AppUser.fromMap(snap.data()!);
      } else {
        _appUser = null;
      }
    } catch (_) {
      _appUser = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
