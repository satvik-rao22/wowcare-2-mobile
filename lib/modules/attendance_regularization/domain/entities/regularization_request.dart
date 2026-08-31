/// Lifecycle of a request. There is deliberately **no `rejected`** state:
/// admins approve (optionally modifying) or leave pending, and the staff
/// cancels for edge cases.
enum RegStatus { pending, approved, cancelled }

extension RegStatusX on RegStatus {
  String get label {
    switch (this) {
      case RegStatus.pending:
        return 'Pending';
      case RegStatus.approved:
        return 'Approved';
      case RegStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isPending => this == RegStatus.pending;
}

/// An attendance correction request for a **missed sign-out** (the only kind
/// this module handles — see docs/attendance_regularization_requirements.md
/// §7.5 for why there is no `type`).
class RegularizationRequest {
  const RegularizationRequest({
    required this.code,
    required this.staffCode,
    required this.staffName,
    required this.attendanceDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.classroomName,
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

  /// What the raiser asked for.
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
