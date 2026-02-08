import 'package:cloud_firestore/cloud_firestore.dart';

class StatusEntry {
  const StatusEntry({
    required this.status,
    this.note,
    required this.timestamp,
    required this.updatedBy,
  });

  final String status;
  final String? note;
  final DateTime timestamp;
  final String updatedBy;

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'note': note,
      'timestamp': Timestamp.fromDate(timestamp),
      'updatedBy': updatedBy,
    };
  }

  static StatusEntry fromMap(Map<String, dynamic> map) {
    return StatusEntry(
      status: map['status'] as String? ?? '',
      note: map['note'] as String?,
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
      updatedBy: map['updatedBy'] as String? ?? '',
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  StatusEntry copyWith({
    String? status,
    String? note,
    DateTime? timestamp,
    String? updatedBy,
  }) {
    return StatusEntry(
      status: status ?? this.status,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
