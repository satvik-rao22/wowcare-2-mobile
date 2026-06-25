/// Kind of correction being requested.
enum RegType { missedSignOut, missedSignIn, missedFullDay, timeCorrection }

/// Lifecycle of a request.
enum RegStatus { pending, approved, rejected, cancelled }

extension RegTypeX on RegType {
  String get label {
    switch (this) {
      case RegType.missedSignOut:
        return 'Missed sign-out';
      case RegType.missedSignIn:
        return 'Missed sign-in';
      case RegType.missedFullDay:
        return 'Missed full day';
      case RegType.timeCorrection:
        return 'Time correction';
    }
  }
}

extension RegStatusX on RegStatus {
  String get label {
    switch (this) {
      case RegStatus.pending:
        return 'Pending';
      case RegStatus.approved:
        return 'Approved';
      case RegStatus.rejected:
        return 'Rejected';
      case RegStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isPending => this == RegStatus.pending;
}

/// A staff-raised attendance correction request.
class RegularizationRequest {
  const RegularizationRequest({
    required this.code,
    required this.staffCode,
    required this.staffName,
    required this.attendanceDate,
    required this.type,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.classroomName,
    this.requestedSignInAt,
    this.requestedSignOutAt,
    this.softSignOutAt,
    this.decidedByName,
    this.decidedAt,
    this.decisionNote,
  });

  final String code;
  final String staffCode;
  final String staffName;
  final String? classroomName;
  final DateTime attendanceDate;
  final RegType type;

  /// What the staff asked for.
  final DateTime? requestedSignInAt;
  final DateTime? requestedSignOutAt;

  /// The system soft sign-out time (school end) being corrected, for context.
  final DateTime? softSignOutAt;

  final String reason;
  final RegStatus status;
  final DateTime createdAt;

  // Decision (set once resolved).
  final String? decidedByName;
  final DateTime? decidedAt;
  final String? decisionNote;

  String get initials {
    final parts = staffName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
