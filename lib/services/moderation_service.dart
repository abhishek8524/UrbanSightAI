import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_paths.dart';

const int _trustScorePenalty = 10;
const int _suspensionStrikeThreshold = 3;
const int _suspensionDays = 7;

/// Strike/trust/suspension and appeal logic.
class ModerationService {
  ModerationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Admin confirms report is irrelevant: apply strike and trust penalty to
  /// report creator; suspend 7 days if strikes >= 3. Idempotent if already confirmed.
  Future<void> confirmIrrelevant(String reportId) async {
    final reportRef = _firestore.collection(reportsCollection).doc(reportId);
    final reportSnap = await reportRef.get();
    if (!reportSnap.exists || reportSnap.data() == null) return;
    final data = reportSnap.data()!;
    if ((data['irrelevantConfirmed'] as bool?) == true) return;

    final createdBy = data['createdBy'] as String?;
    if (createdBy == null || createdBy.isEmpty) return;

    final userRef = _firestore.collection(usersCollection).doc(createdBy);
    final userSnap = await userRef.get();
    if (!userSnap.exists || userSnap.data() == null) return;

    final userData = userSnap.data()!;
    final currentStrikes = (userData['strikes'] as num?)?.toInt() ?? 0;
    final currentTrust = (userData['trustScore'] as num?)?.toInt() ?? 50;
    final now = DateTime.now();

    final newStrikes = currentStrikes + 1;
    final newTrust = (currentTrust - _trustScorePenalty).clamp(0, 100);

    await _firestore.runTransaction((tx) async {
      tx.update(userRef, {
        'strikes': newStrikes,
        'trustScore': newTrust,
        if (newStrikes >= _suspensionStrikeThreshold)
          'suspendedUntil': Timestamp.fromDate(
            now.add(const Duration(days: _suspensionDays)),
          ),
      });
      tx.update(reportRef, {'irrelevantConfirmed': true});
    });
  }

  /// Citizen requests appeal on a flagged report. Sets appealRequested=true for admin review.
  Future<void> requestAppeal(String reportId) async {
    await _firestore.collection(reportsCollection).doc(reportId).update({
      'appealRequested': true,
    });
  }
}
