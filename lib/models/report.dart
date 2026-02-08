import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/enums.dart';

class ReportAi {
  const ReportAi({
    this.relevanceScore,
    this.suggestedCategory,
    this.reason,
  });

  final num? relevanceScore;
  final String? suggestedCategory;
  final String? reason;

  Map<String, dynamic> toMap() {
    return {
      'relevanceScore': relevanceScore,
      'suggestedCategory': suggestedCategory,
      'reason': reason,
    };
  }

  static ReportAi? fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return null;
    return ReportAi(
      relevanceScore: map['relevanceScore'] as num?,
      suggestedCategory: map['suggestedCategory'] as String?,
      reason: map['reason'] as String?,
    );
  }
}

class Report {
  const Report({
    required this.id,
    this.title,
    required this.description,
    required this.department,
    required this.category,
    required this.issueType,
    this.photoUrl,
    required this.locationLat,
    required this.locationLng,
    this.locationAddress,
    this.assignedDepartment,
    this.assignee,
    this.status = ReportStatus.reported,
    this.priorityScore = 0,
    this.duplicateOf,
    this.duplicateCount = 0,
    this.irrelevantConfirmed = false,
    this.appealRequested = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.ai,
  });

  final String id;
  final String? title;
  final String description;
  final String department;
  final String category;
  final String issueType;
  final String? photoUrl;
  final double locationLat;
  final double locationLng;
  final String? locationAddress;
  final String? assignedDepartment;
  final String? assignee;
  final ReportStatus status;
  final int priorityScore;
  final String? duplicateOf;
  final int duplicateCount;
  final bool irrelevantConfirmed;
  final bool appealRequested;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ReportAi? ai;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'department': department,
      'category': category,
      'issueType': issueType,
      'photoUrl': photoUrl,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'locationAddress': locationAddress,
      'assignedDepartment': assignedDepartment,
      'assignee': assignee,
      'status': status.value,
      'priorityScore': priorityScore,
      'duplicateOf': duplicateOf,
      'duplicateCount': duplicateCount,
      'irrelevantConfirmed': irrelevantConfirmed,
      'appealRequested': appealRequested,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'ai': ai?.toMap(),
    };
  }

  static Report fromMap(Map<String, dynamic> map) {
    final aiMap = map['ai'];
    return Report(
      id: map['id'] as String? ?? '',
      title: map['title'] as String?,
      description: map['description'] as String? ?? '',
      department: map['department'] as String? ?? '',
      category: map['category'] as String? ?? '',
      issueType: map['issueType'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      locationLat: (map['locationLat'] as num?)?.toDouble() ?? 0.0,
      locationLng: (map['locationLng'] as num?)?.toDouble() ?? 0.0,
      locationAddress: map['locationAddress'] as String?,
      assignedDepartment: map['assignedDepartment'] as String?,
      assignee: map['assignee'] as String?,
      status: ReportStatusX.from(map['status'] as String?),
      priorityScore: (map['priorityScore'] as num?)?.toInt() ?? 0,
      duplicateOf: map['duplicateOf'] as String?,
      duplicateCount: (map['duplicateCount'] as num?)?.toInt() ?? 0,
      irrelevantConfirmed: map['irrelevantConfirmed'] as bool? ?? false,
      appealRequested: map['appealRequested'] as bool? ?? false,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      ai: aiMap is Map<String, dynamic> ? ReportAi.fromMap(aiMap) : null,
    );
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  Report copyWith({
    String? id,
    String? title,
    String? description,
    String? department,
    String? category,
    String? issueType,
    String? photoUrl,
    double? locationLat,
    double? locationLng,
    String? locationAddress,
    String? assignedDepartment,
    String? assignee,
    ReportStatus? status,
    int? priorityScore,
    String? duplicateOf,
    int? duplicateCount,
    bool? irrelevantConfirmed,
    bool? appealRequested,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReportAi? ai,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      department: department ?? this.department,
      category: category ?? this.category,
      issueType: issueType ?? this.issueType,
      photoUrl: photoUrl ?? this.photoUrl,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      locationAddress: locationAddress ?? this.locationAddress,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      assignee: assignee ?? this.assignee,
      status: status ?? this.status,
      priorityScore: priorityScore ?? this.priorityScore,
      duplicateOf: duplicateOf ?? this.duplicateOf,
      duplicateCount: duplicateCount ?? this.duplicateCount,
      irrelevantConfirmed: irrelevantConfirmed ?? this.irrelevantConfirmed,
      appealRequested: appealRequested ?? this.appealRequested,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ai: ai ?? this.ai,
    );
  }
}
