import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums.dart';

class AppUser {
  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.role = UserRole.citizen,
    this.trustScore = 50,
    this.strikes = 0,
    this.suspendedUntil,
    required this.createdAt,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final UserRole role;
  final int trustScore;
  final int strikes;
  final DateTime? suspendedUntil;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'role': role.value,
      'trustScore': trustScore,
      'strikes': strikes,
      'suspendedUntil': suspendedUntil != null
          ? Timestamp.fromDate(suspendedUntil!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static AppUser fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String? ?? '',
      displayName: map['displayName'] as String?,
      email: map['email'] as String?,
      role: UserRoleX.from(map['role'] as String?),
      trustScore: (map['trustScore'] as num?)?.toInt() ?? 50,
      strikes: (map['strikes'] as num?)?.toInt() ?? 0,
      suspendedUntil: _parseDateTime(map['suspendedUntil']),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  AppUser copyWith({
    String? uid,
    String? displayName,
    String? email,
    UserRole? role,
    int? trustScore,
    int? strikes,
    DateTime? suspendedUntil,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      role: role ?? this.role,
      trustScore: trustScore ?? this.trustScore,
      strikes: strikes ?? this.strikes,
      suspendedUntil: suspendedUntil ?? this.suspendedUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
