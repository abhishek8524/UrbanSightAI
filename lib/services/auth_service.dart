import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/enums.dart';
import '../utils/firestore_paths.dart';

/// Handles Firebase Auth and keeps Firestore user doc in sync on sign-in.
class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  /// Stream of the current Firebase User (null when signed out).
  Stream<User?> get currentUserStream => _auth.authStateChanges();

  /// Sign in anonymously. Creates or updates user doc in Firestore.
  Future<UserCredential> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    await _upsertUserDoc(cred.user!);
    return cred;
  }

  /// Sign in with email and password. Creates or updates user doc in Firestore.
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) await _upsertUserDoc(cred.user!);
    return cred;
  }

  /// Sign up with email and password. Creates Firebase Auth user and user doc in Firestore.
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (cred.user != null) await _upsertUserDoc(cred.user!);
    return cred;
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();

  /// Dev only: set current user's role to admin in /users/{uid}. No-op if not signed in. Uses merge so doc is created if missing.
  Future<void> setRoleAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection(usersCollection).doc(user.uid).set(
      {'role': UserRole.admin.value},
      SetOptions(merge: true),
    );
  }

  /// Create or update the user document in Firestore (merge so we keep role, trustScore, etc.).
  Future<void> _upsertUserDoc(User user) async {
    final ref = _firestore.collection(usersCollection).doc(user.uid);
    final existing = await ref.get();
    final now = DateTime.now();
    final data = <String, dynamic>{
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'createdAt': existing.exists ? (existing.data()?['createdAt'] ?? Timestamp.fromDate(now)) : Timestamp.fromDate(now),
    };
    if (!existing.exists) {
      data['role'] = UserRole.citizen.value;
      data['trustScore'] = 50;
      data['strikes'] = 0;
    }
    await ref.set(data, SetOptions(merge: true));
  }
}
