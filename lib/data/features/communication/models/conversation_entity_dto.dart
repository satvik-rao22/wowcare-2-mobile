import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/core/util/app_time.dart';

/// First non-empty (trimmed) string from [values], or '' if none — the avatar-field resolution
/// mirrors web's pickString(), so mobile reads the same photo fields the backend actually sends.
String _pickNonEmpty(List<String?> values) {
  for (final v in values) {
    if (v != null && v.trim().isNotEmpty) return v;
  }
  return '';
}

/// API response DTO for a conversation.
/// Maps directly from the JSON payload returned by the backend.
class ConversationEntityDto {
  const ConversationEntityDto({
    required this.id,
    required this.code,
    required this.title,
    required this.type,
    required this.organizationCode,
    required this.schoolCode,
    required this.status,
    required this.description,
    required this.avatarUrl,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    required this.participantCount,
    required this.unreadCount,
    required this.lastMessagePreview,
    required this.participants,
    this.studentCode,
    this.classroomCode,
    this.lastMessageAt,
    this.lastMessageBy,
    this.lastMessageSenderName,
    this.privateModeActive = false,
    this.privateModeActivatedBy,
    this.privateModeActivatedAt,
    this.privateModeStates = const [],
  });

  final int id;
  final String code;
  final String title;
  final String type;
  final String organizationCode;
  final String schoolCode;
  final String status;
  final String description;
  final String avatarUrl;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int participantCount;
  final int unreadCount;
  final String lastMessagePreview;
  final List<ParticipantEntityDto> participants;
  final String? studentCode;
  final String? classroomCode;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;
  final String? lastMessageSenderName;
  final bool privateModeActive;
  final String? privateModeActivatedBy;
  final DateTime? privateModeActivatedAt;
  final List<PrivateModeStateDto> privateModeStates;

  factory ConversationEntityDto.fromJson(Map<String, dynamic> json) {
    return ConversationEntityDto(
      id: json['id'] as int? ?? 0,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'ROOM_CHAT',
      organizationCode: json['organizationCode'] as String? ?? '',
      schoolCode: json['schoolCode'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      description: json['description'] as String? ?? '',
      // Room/Admin conversations are student-scoped: the avatar is the student's photo, which the
      // backend nests under `student` (web reads pickString(conversation.avatarUrl, student.photoUrl,
      // student.avatarUrl)). Mobile only read the top-level avatarUrl, so those rows/titles were blank.
      avatarUrl: _pickNonEmpty([
        json['avatarUrl'] as String?,
        (json['student'] as Map<String, dynamic>?)?['photoUrl'] as String?,
        (json['student'] as Map<String, dynamic>?)?['avatarUrl'] as String?,
        (json['student'] as Map<String, dynamic>?)?['profileAssetCode'] as String?,
      ]),
      createdAt: _parseDate(json['createdAt']),
      createdBy: json['createdBy'] as String? ?? '',
      updatedAt: _parseDate(json['updatedAt']),
      updatedBy: json['updatedBy'] as String? ?? '',
      participantCount: json['participantCount'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ParticipantEntityDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      studentCode: json['studentCode'] as String?,
      classroomCode: json['classroomCode'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      lastMessageBy: json['lastMessageBy'] as String?,
      lastMessageSenderName: json['lastMessageSenderName'] as String?,
      privateModeActive: json['privateModeActive'] as bool? ?? false,
      privateModeActivatedBy: json['privateModeActivatedBy'] as String?,
      privateModeActivatedAt: json['privateModeActivatedAt'] != null
          ? DateTime.tryParse(json['privateModeActivatedAt'] as String)
          : null,
      privateModeStates: (json['privateModeStates'] as List<dynamic>?)
              ?.map((e) => PrivateModeStateDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'type': type,
        'organizationCode': organizationCode,
        'schoolCode': schoolCode,
        'status': status,
        'description': description,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'updatedAt': updatedAt.toIso8601String(),
        'updatedBy': updatedBy,
        'participantCount': participantCount,
        'unreadCount': unreadCount,
        'lastMessagePreview': lastMessagePreview,
        'participants': participants.map((e) => e.toJson()).toList(),
        if (studentCode != null) 'studentCode': studentCode,
        if (classroomCode != null) 'classroomCode': classroomCode,
        if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
        if (lastMessageBy != null) 'lastMessageBy': lastMessageBy,
        if (lastMessageSenderName != null) 'lastMessageSenderName': lastMessageSenderName,
        'privateModeActive': privateModeActive,
        if (privateModeActivatedBy != null)
          'privateModeActivatedBy': privateModeActivatedBy,
        if (privateModeActivatedAt != null)
          'privateModeActivatedAt': privateModeActivatedAt!.toIso8601String(),
        'privateModeStates': privateModeStates.map((e) => e.toJson()).toList(),
      };

  /// Maps this DTO to the domain [ConversationEntity].
  ConversationEntity toEntity() {
    return ConversationEntity(
      id: id,
      code: code,
      title: title,
      type: ConversationType.fromApiString(type),
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      status: status,
      description: description,
      avatarUrl: avatarUrl,
      createdAt: createdAt,
      createdBy: createdBy,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      participantCount: participantCount,
      unreadCount: unreadCount,
      lastMessagePreview: lastMessagePreview,
      participants: participants.map((e) => e.toEntity()).toList(),
      studentCode: studentCode,
      classroomCode: classroomCode,
      lastMessageAt: lastMessageAt,
      lastMessageBy: lastMessageBy,
      lastMessageSenderName: lastMessageSenderName,
      privateModeActive: privateModeActive,
      privateModeActivatedBy: privateModeActivatedBy,
      privateModeActivatedAt: privateModeActivatedAt,
      privateModeStates: {
        for (final s in privateModeStates) s.parentCode: s.toEntity()
      },
    );
  }

  static DateTime _parseDate(dynamic value) =>
      value != null ? DateTime.parse(value as String) : AppTime.nowUtc();
}

class ParticipantEntityDto {
  const ParticipantEntityDto({
    required this.id,
    required this.conversationId,
    required this.userCode,
    required this.userName,
    required this.role,
    required this.joinedAt,
    required this.muted,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.leftAt,
    this.lastReadAt,
    this.avatarUrl,
    this.staffCode,
    this.guardianCode,
    this.adminCode,
    this.organizationCode,
    this.schoolCode,
  });

  final int id;
  final int conversationId;
  final String userCode;
  final String userName;
  final String role;
  final String? avatarUrl;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime? lastReadAt;
  final bool muted;
  final bool notificationsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Not currently sent by the backend participant payload — parsed
  // defensively so they populate the moment the backend adds them, with no
  // further Flutter changes required. Until then these are always null.
  final String? staffCode;
  final String? guardianCode;
  final String? adminCode;
  final String? organizationCode;
  final String? schoolCode;

  factory ParticipantEntityDto.fromJson(Map<String, dynamic> json) {
    return ParticipantEntityDto(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversationId'] as int? ?? 0,
      userCode: json['userCode'] as String? ?? '',
      userName: (json['displayName'] as String?)?.isNotEmpty == true
          ? json['displayName'] as String
          : (json['userName'] as String? ?? ''),
      role: (json['participantType'] as String?)?.isNotEmpty == true
          ? json['participantType'] as String
          : (json['role'] as String? ?? 'PARENT'),
      // The backend puts the RESOLVED participant photo in `photoUrl` (this is what web reads first,
      // via pickString(photoUrl, avatarUrl, user.photoUrl)); mobile previously only read `avatarUrl`,
      // which is null, so every participant-driven avatar fell back to initials. A profile-asset code
      // (non-http) is also accepted — DocumentImageWidget resolves it as a mediaAssetCode.
      avatarUrl: _pickNonEmpty([
        json['photoUrl'] as String?,
        json['avatarUrl'] as String?,
        (json['user'] as Map<String, dynamic>?)?['photoUrl'] as String?,
        json['profileAssetCode'] as String?,
        json['profilePhotoAssetCode'] as String?,
      ]),
      joinedAt: DateTime.parse(json['joinedAt'] as String? ?? AppTime.nowUtc().toIso8601String()),
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt'] as String) : null,
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt'] as String) : null,
      muted: json['muted'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? AppTime.nowUtc().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? AppTime.nowUtc().toIso8601String()),
      staffCode: json['staffCode'] as String?,
      guardianCode: json['guardianCode'] as String?,
      adminCode: json['adminCode'] as String?,
      organizationCode: json['organizationCode'] as String?,
      schoolCode: json['schoolCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversationId': conversationId,
        'userCode': userCode,
        'userName': userName,
        'role': role,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'joinedAt': joinedAt.toIso8601String(),
        if (leftAt != null) 'leftAt': leftAt!.toIso8601String(),
        if (lastReadAt != null) 'lastReadAt': lastReadAt!.toIso8601String(),
        'muted': muted,
        'notificationsEnabled': notificationsEnabled,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (staffCode != null) 'staffCode': staffCode,
        if (guardianCode != null) 'guardianCode': guardianCode,
        if (adminCode != null) 'adminCode': adminCode,
        if (organizationCode != null) 'organizationCode': organizationCode,
        if (schoolCode != null) 'schoolCode': schoolCode,
      };

  ParticipantEntity toEntity() {
    return ParticipantEntity(
      id: id,
      conversationId: conversationId,
      userCode: userCode,
      userName: userName,
      role: ParticipantRole.fromApiString(role),
      avatarUrl: avatarUrl,
      joinedAt: joinedAt,
      leftAt: leftAt,
      lastReadAt: lastReadAt,
      muted: muted,
      notificationsEnabled: notificationsEnabled,
      createdAt: createdAt,
      updatedAt: updatedAt,
      staffCode: staffCode,
      guardianCode: guardianCode,
      adminCode: adminCode,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}

class PrivateModeStateDto {
  const PrivateModeStateDto({
    required this.parentCode,
    required this.enabled,
    required this.owner,
    required this.enabledAt,
  });

  final String parentCode;
  final bool enabled;
  final String owner;
  final DateTime enabledAt;

  factory PrivateModeStateDto.fromJson(Map<String, dynamic> json) {
    return PrivateModeStateDto(
      parentCode: json['parentCode'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
      owner: json['owner'] as String? ?? '',
      enabledAt: DateTime.parse(
        json['enabledAt'] as String? ?? AppTime.nowUtc().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'parentCode': parentCode,
        'enabled': enabled,
        'owner': owner,
        'enabledAt': enabledAt.toIso8601String(),
      };

  PrivateModeState toEntity() {
    return PrivateModeState(
      parentCode: parentCode,
      enabled: enabled,
      owner: owner,
      enabledAt: enabledAt,
    );
  }
}
