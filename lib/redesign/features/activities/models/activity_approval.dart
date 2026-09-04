import 'package:wowcare/redesign/core/widgets/status_pill.dart';

/// Where an activity has got to in the school's approval chain.
///
/// The names are the API's own `approvalStatus`, normalized the way
/// `activity_feed_card_permissions.dart` does it: an empty status means the
/// type never needed a signature.
enum ActivityApproval {
  notRequired('', 'NOT_REQUIRED'),
  pending('Pending Admin Approval', 'PENDING_ADMIN_APPROVAL'),
  approved('Approved', 'APPROVED'),
  rejected('Rejected', 'REJECTED'),
  parentAckPending(
    'Parent Acknowledgement Pending',
    'PARENT_ACKNOWLEDGEMENT_PENDING',
  ),
  acknowledged('Acknowledged', 'ACKNOWLEDGED');

  const ActivityApproval(this.label, this.code);

  /// What the filter sheet and the detail badge write.
  final String label;

  /// The wire value, so Phase 5 maps without a lookup table.
  final String code;

  /// The short badge a feed card wears, where there is room for less.
  String get shortLabel => switch (this) {
    ActivityApproval.pending => 'Pending',
    ActivityApproval.parentAckPending => 'Ack pending',
    _ => label,
  };

  /// Colour carries meaning: pink is waiting on this school, amber is
  /// waiting on a family, green is done, red is refused.
  PillTone get tone => switch (this) {
    ActivityApproval.approved || ActivityApproval.acknowledged =>
      PillTone.success,
    ActivityApproval.rejected => PillTone.danger,
    ActivityApproval.parentAckPending => PillTone.staff,
    ActivityApproval.pending => PillTone.custom,
    ActivityApproval.notRequired => PillTone.neutral,
  };

  /// Whether a badge is drawn at all. A card that never needed a signature
  /// says nothing about one.
  bool get isVisible => this != ActivityApproval.notRequired;

  /// A director's queue is exactly these.
  bool get needsDirector => this == ActivityApproval.pending;

  /// The guardian's Acknowledge key exists only here.
  bool get needsGuardian => this == ActivityApproval.parentAckPending;

  /// Rejected locks edit and delete for everyone, so the record cannot
  /// quietly change after a director refused it.
  bool get isLocked => this == ActivityApproval.rejected;

  /// Which of these a family may see at all: nothing pending or rejected
  /// ever reaches the guardian's feed.
  bool get isVisibleToGuardian =>
      this == ActivityApproval.notRequired ||
      this == ActivityApproval.approved ||
      this == ActivityApproval.parentAckPending ||
      this == ActivityApproval.acknowledged;

  /// The four the filter sheet offers (8c). Acknowledged is a state, not a
  /// thing anybody filters a day by.
  static const List<ActivityApproval> filterOptions = <ActivityApproval>[
    ActivityApproval.pending,
    ActivityApproval.approved,
    ActivityApproval.rejected,
    ActivityApproval.parentAckPending,
  ];

  static ActivityApproval fromCode(String? raw) {
    final wanted = (raw ?? '').trim().toUpperCase();
    if (wanted.isEmpty) return ActivityApproval.notRequired;
    for (final value in ActivityApproval.values) {
      if (value.code == wanted) return value;
    }
    // The shipped app treats a bare PENDING the same as the long form.
    if (wanted == 'PENDING') return ActivityApproval.pending;
    return ActivityApproval.notRequired;
  }
}
