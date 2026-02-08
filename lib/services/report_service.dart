import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/report.dart';
import '../models/status_entry.dart';
import '../utils/enums.dart';
import '../utils/firestore_paths.dart';
import '../utils/geo.dart';
import 'ai_service.dart';

const String _reportPhotosPath = 'report_photos';
const double _duplicateRadiusMeters = 100;
const int _duplicateLookbackHours = 48;

/// Report creation payload: all fields except id, photoUrl, status, priorityScore,
/// duplicateOf, duplicateCount, createdAt, updatedAt, ai (set by service).
class CreateReportData {
  const CreateReportData({
    this.title,
    required this.description,
    required this.department,
    required this.category,
    required this.issueType,
    required this.locationLat,
    required this.locationLng,
    this.locationAddress,
    required this.createdBy,
  });

  final String? title;
  final String description;
  final String department;
  final String category;
  final String issueType;
  final double locationLat;
  final double locationLng;
  final String? locationAddress;
  final String createdBy;

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'department': department,
        'category': category,
        'issueType': issueType,
        'locationLat': locationLat,
        'locationLng': locationLng,
        'locationAddress': locationAddress,
        'createdBy': createdBy,
      };
}

/// Handles report CRUD, image uploads, and status history.
class ReportService {
  ReportService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    AiService? aiService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _aiService = aiService ?? AiService();

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AiService _aiService;

  /// Uploads image bytes to Storage and returns download URL. Path: report_photos/{reportId}. Works on all platforms including web.
  Future<String> _uploadReportPhoto(String reportId, Uint8List imageBytes) async {
    final ref = _storage.ref().child('$_reportPhotosPath/$reportId');
    await ref.putData(imageBytes);
    return ref.getDownloadURL();
  }

  /// Finds the earliest report in the last [_duplicateLookbackHours] with same
  /// category and within [_duplicateRadiusMeters]. Returns null if none or on error.
  Future<String?> _findDuplicateMainReport(CreateReportData data) async {
    try {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: _duplicateLookbackHours));
      final snap = await _firestore
          .collection(reportsCollection)
          .where('category', isEqualTo: data.category)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .get();

      final withinRadius = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final d = doc.data();
        final lat = (d['locationLat'] as num?)?.toDouble();
        final lng = (d['locationLng'] as num?)?.toDouble();
        final createdAt = d['createdAt'];
        if (lat == null || lng == null) continue;
        final ts = createdAt is Timestamp
            ? createdAt.toDate()
            : (createdAt is DateTime ? createdAt : null);
        if (ts == null) continue;
        final dist = haversineDistanceMeters(
          data.locationLat,
          data.locationLng,
          lat,
          lng,
        );
        if (dist < _duplicateRadiusMeters) {
          withinRadius.add({'id': doc.id, 'createdAt': ts});
        }
      }
      if (withinRadius.isEmpty) return null;
      withinRadius.sort((a, b) =>
          (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime));
      return withinRadius.first['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Creates a report; optionally uploads [imageBytes] and sets photoUrl.
  /// Runs duplicate detection (same category, within 100m, last 48h); on match
  /// sets duplicateOf and increments main report's duplicateCount. Duplicate
  /// detection failures do not block submission.
  Future<Report> createReport(CreateReportData data, {Uint8List? imageBytes}) async {
    final docRef = _firestore.collection(reportsCollection).doc();
    final reportId = docRef.id;
    final now = DateTime.now();

    String? duplicateOf;
    try {
      duplicateOf = await _findDuplicateMainReport(data);
    } catch (_) {}

    String? photoUrl;
    if (imageBytes != null) {
      photoUrl = await _uploadReportPhoto(reportId, imageBytes);
    }

    final report = Report(
      id: reportId,
      title: data.title,
      description: data.description,
      department: data.department,
      category: data.category,
      issueType: data.issueType,
      photoUrl: photoUrl,
      locationLat: data.locationLat,
      locationLng: data.locationLng,
      locationAddress: data.locationAddress,
      status: ReportStatus.reported,
      priorityScore: 0,
      duplicateOf: duplicateOf,
      duplicateCount: 0,
      createdBy: data.createdBy,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(report.toMap());

    final entry = StatusEntry(
      status: ReportStatus.reported.value,
      note: null,
      timestamp: now,
      updatedBy: data.createdBy,
    );
    await docRef.collection(statusHistorySubcollection).add(entry.toMap());

    if (duplicateOf != null) {
      try {
        await _firestore
            .collection(reportsCollection)
            .doc(duplicateOf)
            .update({'duplicateCount': FieldValue.increment(1)});
      } catch (_) {}
    }

    try {
      final aiResult = await _aiService.analyzeReport(
        photoUrl ?? '',
        data.description,
        data.category,
      );
      await _firestore.collection(reportsCollection).doc(reportId).update({
        'ai': aiResult,
      });
      final score = (aiResult['relevanceScore'] as num?)?.toDouble();
      if (score != null && score < 0.3) {
        await updateStatus(
          reportId: reportId,
          newStatus: ReportStatus.needsReview,
          note: 'Auto-flagged: low relevance score',
          updatedBy: data.createdBy,
        );
      }
    } catch (_) {}

    return report;
  }

  /// Stream of a single report by id.
  Stream<Report?> getReportStream(String reportId) {
    return _firestore
        .collection(reportsCollection)
        .doc(reportId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Report.fromMap(snap.data()!..['id'] = snap.id);
    });
  }

  /// Stream of status history for a report, newest first.
  Stream<List<StatusEntry>> getStatusHistoryStream(String reportId) {
    return _firestore
        .collection(reportsCollection)
        .doc(reportId)
        .collection(statusHistorySubcollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => StatusEntry.fromMap(d.data()))
            .toList());
  }

  /// Stream of reports created by [uid].
  Stream<List<Report>> getMyReports(String uid) {
    return _firestore
        .collection(reportsCollection)
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Report.fromMap(d.data()..['id'] = d.id)).toList());
  }

  /// Stream of all reports (admin). Order by createdAt descending.
  Stream<List<Report>> getAllReports() {
    return _firestore
        .collection(reportsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Report.fromMap(d.data()..['id'] = d.id)).toList());
  }

  /// Updates report status, updatedAt, and appends a statusHistory entry.
  Future<void> updateStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? note,
    required String updatedBy,
  }) async {
    final now = DateTime.now();
    final ref = _firestore.collection(reportsCollection).doc(reportId);

    await _firestore.runTransaction((tx) async {
      tx.update(ref, {
        'status': newStatus.value,
        'updatedAt': Timestamp.fromDate(now),
      });
      final entry = StatusEntry(
        status: newStatus.value,
        note: note,
        timestamp: now,
        updatedBy: updatedBy,
      );
      tx.set(ref.collection(statusHistorySubcollection).doc(), entry.toMap());
    });
  }

  /// Partially update report fields. Does not touch statusHistory.
  /// [patch] can include status; use [updateStatus] if you need a status history entry.
  Future<void> updateReportFields(String reportId, Map<String, dynamic> patch) async {
    final ref = _firestore.collection(reportsCollection).doc(reportId);
    final normalized = _normalizePatch(patch);
    if (normalized.isEmpty) return;
    await ref.update(normalized);
  }

  /// Convert DateTime in patch to Timestamp for Firestore.
  Map<String, dynamic> _normalizePatch(Map<String, dynamic> patch) {
    final out = <String, dynamic>{};
    for (final e in patch.entries) {
      if (e.value is DateTime) {
        out[e.key] = Timestamp.fromDate(e.value as DateTime);
      } else {
        out[e.key] = e.value;
      }
    }
    return out;
  }
}
