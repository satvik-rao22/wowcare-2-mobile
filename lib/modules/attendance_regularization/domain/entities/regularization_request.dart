/// `PENDING` → `APPROVED`. There is no reject and no cancel: a wrong request
/// is edited while pending.
enum RegStatus { pending, approved }

extension RegStatusX on RegStatus {
  String get label => this == RegStatus.pending ? 'Pending' : 'Approved';

  String get wireValue => this == RegStatus.pending ? 'PENDING' : 'APPROVED';

  bool get isPending => this == RegStatus.pending;
  bool get isApproved => this == RegStatus.approved;
}

/// Throws on an unknown value rather than defaulting — a status we don't
/// understand must not render an Approve button.
RegStatus regStatusFromWire(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'PENDING':
      return RegStatus.pending;
    case 'APPROVED':
      return RegStatus.approved;
    default:
      throw ArgumentError.value(raw, 'status', 'Unknown regularization status');
  }
}

/// A missed sign-out correction.
class RegularizationRequest {
  const RegularizationRequest({
    required this.code,
    required this.staffCode,
    required this.staffName,
    required this.attendanceCode,
    required this.attendanceDate,
    required this.requestedSignOutTime,
    required this.reason,
    required this.status,
    required this.raisedByCode,
    required this.createdAt,
    this.method = '',
    this.autoApproved = false,
    this.approvedSignOutTime,
    this.approvalByCode,
    this.approvalByName,
    this.approvalAt,
    this.approvalNote,
    this.updatedAt,
  });

  final String code;
  final String staffCode;
  final String staffName;
  final String attendanceCode;
  final DateTime attendanceDate;

  /// What the raiser asked for. Never overwritten by an approval.
  final DateTime requestedSignOutTime;

  final String reason;
  final RegStatus status;
  final String raisedByCode;
  final String method;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// True when an admin raised it and the server approved it in the same call.
  final bool autoApproved;

  /// What the approver committed. May differ from [requestedSignOutTime].
  final DateTime? approvedSignOutTime;

  final String? approvalByCode;
  final String? approvalByName;
  final DateTime? approvalAt;
  final String? approvalNote;

  bool get isEditable => status.isPending;

  /// Drives the "(adjusted)" badge.
  bool get wasModified =>
      approvedSignOutTime != null &&
      approvedSignOutTime != requestedSignOutTime;

  bool get wasEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  DateTime get effectiveSignOutTime =>
      approvedSignOutTime ?? requestedSignOutTime;
}
