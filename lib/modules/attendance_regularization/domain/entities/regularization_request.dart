/// Lifecycle of a request — **exactly two values** (§6).
///
/// There is deliberately no `rejected` and no `cancelled`. Admins approve or
/// leave pending; a request raised with the wrong time or reason is **edited
/// in place** while it is still pending (§9.4), never withdrawn. Keeping the
/// `PENDING` row alive is what stops a staff re-blocking themselves mid-day by
/// correcting their own request (§8.4).
enum RegStatus { pending, approved }

extension RegStatusX on RegStatus {
  String get label {
    switch (this) {
      case RegStatus.pending:
        return 'Pending';
      case RegStatus.approved:
        return 'Approved';
    }
  }

  /// Wire value used by the API (`status` query param and DTO field).
  String get wireValue {
    switch (this) {
      case RegStatus.pending:
        return 'PENDING';
      case RegStatus.approved:
        return 'APPROVED';
    }
  }

  bool get isPending => this == RegStatus.pending;
  bool get isApproved => this == RegStatus.approved;
}

/// Parses the API's `status` string. Kept next to the enum so the wire
/// vocabulary is defined once — a mapper inventing its own table is how
/// `CANCELLED` would quietly come back.
///
/// Throws on an unknown value rather than defaulting: a status we don't
/// understand means the contract moved, and silently treating it as `pending`
/// would show an Approve button on something that is not pending.
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

/// An attendance correction request for a **missed sign-out** — the only kind
/// this module handles (§7.5 explains why there is no `type`).
///
/// Maps the `staff_attendance_regularization` row (§7.2).
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
    this.approvedSignOutTime,
    this.approvalByCode,
    this.approvalByName,
    this.approvalAt,
    this.approvalNote,
    this.updatedAt,
  });

  /// `SREG_…`
  final String code;

  final String staffCode;

  /// Resolved at read time from [staffCode] (§7.5) — not a stored column.
  final String staffName;

  /// FK to the attendance row being corrected (§7.2, NOT NULL). Needed to
  /// edit (§9.4) and to correlate with the gate.
  final String attendanceCode;

  final DateTime attendanceDate;

  /// What the raiser asked for. **Never overwritten** — an admin's
  /// modification lands in [approvedSignOutTime] instead (§7.4).
  final DateTime requestedSignOutTime;

  /// Always present and non-blank (§8.2). An edit may replace it, never clear
  /// it (§9.4).
  final String reason;

  final RegStatus status;

  /// Who raised it — staff or admin. The raiser's *role* is not persisted;
  /// it is enforced server-side from the token (§7.2).
  final String raisedByCode;

  final DateTime createdAt;

  /// Set by an edit (§9.4). Its presence is the only signal that a pending
  /// request was revised.
  final DateTime? updatedAt;

  /// What the approver actually committed — may differ from
  /// [requestedSignOutTime]. Stored, never derived from the attendance row,
  /// because that row's `signed_out_at` is mutable by an unrelated flow (§7.4).
  final DateTime? approvedSignOutTime;

  final String? approvalByCode;

  /// Resolved at read time from [approvalByCode] (§7.5) — not a stored column.
  final String? approvalByName;

  final DateTime? approvalAt;

  /// The admin's "reason for change" (§9.6).
  final String? approvalNote;

  /// True when the raiser approved their own request — i.e. an admin raised it
  /// and the backend auto-approved it (§8.2b).
  ///
  /// Derived, not stored: `raised_by_role` and `auto_approved` were dropped
  /// from the model precisely because these two actor columns already answer
  /// "was this reviewed by a second person?" (§7.2).
  bool get isAutoApproved =>
      approvalByCode != null && approvalByCode == raisedByCode;

  /// True while the request can still be edited (§8.6). `APPROVED` is terminal
  /// and immutable — an edit against it returns `409` (§9.4).
  bool get isEditable => status.isPending;

  /// True when the approver committed a different time than was asked for.
  /// Both values are kept so "staff asked 6:00 PM, admin approved 5:45 PM"
  /// survives later edits to the attendance row (§7.4).
  bool get wasModified =>
      approvedSignOutTime != null &&
      approvedSignOutTime != requestedSignOutTime;

  /// True when a pending request has been revised since it was raised.
  bool get wasEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  /// The time that counts: what was approved if it has been, else what was
  /// asked for.
  DateTime get effectiveSignOutTime =>
      approvedSignOutTime ?? requestedSignOutTime;

  String get initials {
    final parts = staffName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
