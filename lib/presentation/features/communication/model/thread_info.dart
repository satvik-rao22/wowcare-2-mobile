import 'package:wowcare/domain/features/communication/entities/conversation.dart'
    show ConversationParticipant;

/// Typed header/context info for the Staff-Direct thread, carried through the
/// route's `extra` (Mandate 8 — replaces the previous `Map<String, dynamic>`).
///
/// Construction sites populate different subsets (some pass only name/avatar/
/// code), so every field beyond those three is optional with a default that
/// reproduces the old map's "missing key → null/false" behaviour.
class StaffThreadInfo {
  const StaffThreadInfo({
    required this.name,
    required this.avatar,
    required this.code,
    this.staffUserCode,
    this.staffCode,
    this.designation,
    this.email,
    this.isSigned = false,
    this.organizationCode,
    this.schoolCode,
    this.staffStatus,
    this.staffIsActiveParticipant,
  });

  final String name;
  final String avatar;
  final String code;

  /// The counterpart staff member's own account code (`USR_*`) — lets the
  /// header resolve a photo via [ProfileAvatar]'s userCode fallback
  /// when [avatar] itself is empty (the conversation payload doesn't always
  /// carry a resolved photo/media-asset-code for staff).
  final String? staffUserCode;

  /// The counterpart's staff code (`STF_*`), when the caller already has it
  /// (e.g. opened from a classroom roster, which always knows the staff
  /// code directly). Preferred over [staffUserCode] by
  /// [ProfileAvatar] — a direct staffCode lookup is the same
  /// mechanism that reliably resolves the photo everywhere else the staff
  /// list itself renders it, whereas the userCode fallback needs an extra
  /// userCode→staffCode resolution step that isn't always available or
  /// successful for every conversation participant payload.
  final String? staffCode;
  final String? designation;
  final String? email;
  final bool isSigned;
  final String? organizationCode;
  final String? schoolCode;
  final String? staffStatus;
  final bool? staffIsActiveParticipant;
}

/// Typed header/context info for the Parent (Room/Admin) thread, carried
/// through the route's `extra` (Mandate 8 — replaces the previous
/// `Map<String, dynamic>`). Mirrors exactly the bag the old
/// `_buildParentInfo`/`staff_messaging_tab` builders produced.
class ParentThreadInfo {
  const ParentThreadInfo({
    required this.name,
    required this.avatar,
    required this.code,
    this.organizationCode,
    this.schoolCode,
    this.parents = const [],
    this.guardianMap = const {},
    this.participants = const [],
    this.staffList = const [],
    this.privateModeParents = const [],
    this.privateModeActive = false,
    this.privateModeActivatedBy,
    this.privateModeActivatedAt,
    this.studentStatus,
  });

  final String name;
  final String avatar;
  final String code;
  final String? organizationCode;
  final String? schoolCode;

  /// Guardian display names.
  final List<String> parents;

  /// Guardian userCode → display name.
  final Map<String, String> guardianMap;

  /// All participants (legacy [ConversationParticipant] shape, role as String).
  final List<ConversationParticipant> participants;

  /// Staff/admin/teacher/director userCodes — the broadcast recipients.
  final List<String> staffList;

  /// Guardian names currently in private mode.
  final List<String> privateModeParents;
  final bool privateModeActive;
  final String? privateModeActivatedBy;
  final DateTime? privateModeActivatedAt;
  final String? studentStatus;
}
