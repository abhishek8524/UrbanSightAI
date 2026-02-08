/// User role for authorization and UI.
enum UserRole { citizen, admin }

extension UserRoleX on UserRole {
  /// Firestore/API string value.
  String get value => switch (this) {
        UserRole.citizen => 'citizen',
        UserRole.admin => 'admin',
      };

  /// Parse from stored string; defaults to [UserRole.citizen] if invalid.
  static UserRole from(String? v) {
    if (v == 'admin') return UserRole.admin;
    return UserRole.citizen;
  }
}

/// Report lifecycle status.
enum ReportStatus {
  reported,
  inProgress,
  resolved,
  needsReview,
}

extension ReportStatusX on ReportStatus {
  /// Firestore/API string value.
  String get value => switch (this) {
        ReportStatus.reported => 'Reported',
        ReportStatus.inProgress => 'InProgress',
        ReportStatus.resolved => 'Resolved',
        ReportStatus.needsReview => 'NeedsReview',
      };

  /// Parse from stored string; defaults to [ReportStatus.reported] if invalid.
  static ReportStatus from(String? v) {
    switch (v) {
      case 'InProgress':
        return ReportStatus.inProgress;
      case 'Resolved':
        return ReportStatus.resolved;
      case 'NeedsReview':
        return ReportStatus.needsReview;
      default:
        return ReportStatus.reported;
    }
  }
}
