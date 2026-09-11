import 'package:equatable/equatable.dart';

/// School-level messaging policy — `GET
/// /api/v1/messaging/communication-settings?schoolCode=...`. Drives the
/// "Delete" option shown in a message's context menu: whether an admin can
/// delete any message (not just their own), and how long a sender has to
/// delete their own message after sending it.
class CommunicationSettings extends Equatable {
  const CommunicationSettings({
    required this.schoolCode,
    required this.adminCanDeleteAny,
    required this.deleteTimeLimitMinutes,
    required this.notifyStaffToParent,
    required this.notifyStaffToStaff,
    required this.notifyParentToStaff,
  });

  /// Conservative fallback used when the settings fetch fails: nobody gets
  /// the admin-delete-any override, and senders keep the previous (implicit,
  /// unlimited) delete window rather than suddenly losing the ability to
  /// delete their own message because of a network hiccup.
  const CommunicationSettings.fallback({required this.schoolCode})
    : adminCanDeleteAny = false,
      deleteTimeLimitMinutes = null,
      notifyStaffToParent = true,
      notifyStaffToStaff = true,
      notifyParentToStaff = true;

  final String schoolCode;
  final bool adminCanDeleteAny;

  /// Null/non-positive means no time limit — the sender can always delete
  /// their own message regardless of how long ago it was sent.
  final int? deleteTimeLimitMinutes;
  final bool notifyStaffToParent;
  final bool notifyStaffToStaff;
  final bool notifyParentToStaff;

  bool get hasDeleteTimeLimit =>
      deleteTimeLimitMinutes != null && deleteTimeLimitMinutes! > 0;

  @override
  List<Object?> get props => [
    schoolCode,
    adminCanDeleteAny,
    deleteTimeLimitMinutes,
    notifyStaffToParent,
    notifyStaffToStaff,
    notifyParentToStaff,
  ];
}
