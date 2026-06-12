/// Request model for POST /api/v1/conversations.
///
/// Participant type mapping (backend contract):
///   parent / guardian → GUARDIAN
///   staff             → STAFF
///   teacher           → TEACHER
///   admin             → ADMIN
///   director          → DIRECTOR
class CreateConversationRequest {
  final String title;
  final String type;
  final String description;
  final String organizationCode;
  final String schoolCode;
  final String avatarUrl;

  /// Required for ROOM_CHAT and ADMIN_CHAT; optional for STAFF_DIRECT.
  final String? studentCode;

  /// Optional scope hint for ROOM_CHAT (maps conversation to a classroom).
  final String? classroomCode;

  /// Simple participant list — the backend infers roles from the user records.
  /// Use this when you have codes but not role information.
  final List<String> participantUserCodes;

  /// Rich participant list with explicit types and display names.
  /// When supplied, [participantUserCodes] is ignored in [toJson].
  final List<Map<String, dynamic>>? participants;

  CreateConversationRequest({
    required this.title,
    this.type = 'STAFF_DIRECT',
    this.description = '',
    required this.organizationCode,
    required this.schoolCode,
    this.avatarUrl = '',
    this.studentCode,
    this.classroomCode,
    this.participantUserCodes = const [],
    this.participants,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'type': type,
      'description': description,
      'organizationCode': organizationCode,
      'schoolCode': schoolCode,
      if (avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      if (studentCode != null && studentCode!.isNotEmpty)
        'studentCode': studentCode,
      if (classroomCode != null && classroomCode!.isNotEmpty)
        'classroomCode': classroomCode,
    };

    if (participants != null && participants!.isNotEmpty) {
      // Normalize each entry: rename 'role' → 'participantType' and
      // map legacy role values to the new backend enum.
      json['participants'] = participants!
          .map((p) => _normalizeParticipant(p))
          .toList();
    } else if (participantUserCodes.isNotEmpty) {
      json['participantUserCodes'] = participantUserCodes;
    }

    return json;
  }

  /// Converts a participant map to the new backend contract.
  ///
  /// Accepts either the old `role` key or the new `participantType` key.
  static Map<String, dynamic> _normalizeParticipant(Map<String, dynamic> p) {
    final userCode = p['userCode'] as String? ?? '';
    final displayName = p['displayName'] as String? ?? '';

    // Prefer explicit participantType; fall back to legacy 'role'.
    final rawType =
        (p['participantType'] as String?)?.toUpperCase() ??
        (p['role'] as String?)?.toUpperCase() ??
        '';

    final participantType = _mapToParticipantType(rawType);

    return {
      'userCode': userCode,
      'participantType': participantType,
      if (displayName.isNotEmpty) 'displayName': displayName,
    };
  }

  /// Maps legacy role strings and new participantType strings to the canonical
  /// backend enum values.
  static String _mapToParticipantType(String raw) {
    switch (raw) {
      case 'PARENT':
      case 'GUARDIAN':
        return 'GUARDIAN';
      case 'TEACHER':
        return 'TEACHER';
      case 'ADMIN':
        return 'ADMIN';
      case 'DIRECTOR':
        return 'DIRECTOR';
      case 'STAFF':
      default:
        return 'STAFF';
    }
  }
}
