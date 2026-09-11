import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/data/features/communication/models/conversation_entity_dto.dart';

/// Characterisation test (Mandate 8) for the v2 conversation DTOs. `old*` are
/// verbatim copies of the pre-conversion hand-written parsers; the generated
/// parsers must match them field-for-field AND emit an identical `toJson`
/// (including the `includeIfNull: false` omissions and nested-list mapping).

String _pick(List<String?> values) {
  for (final v in values) {
    if (v != null && v.trim().isNotEmpty) return v;
  }
  return '';
}

ParticipantEntityDto oldPart(Map<String, dynamic> json) => ParticipantEntityDto(
  id: json['id'] as int? ?? 0,
  conversationId: json['conversationId'] as int? ?? 0,
  userCode: json['userCode'] as String? ?? '',
  userName: (json['displayName'] as String?)?.isNotEmpty == true
      ? json['displayName'] as String
      : (json['userName'] as String? ?? ''),
  role: (json['participantType'] as String?)?.isNotEmpty == true
      ? json['participantType'] as String
      : (json['role'] as String? ?? 'PARENT'),
  avatarUrl: _pick([
    json['photoUrl'] as String?,
    json['avatarUrl'] as String?,
    (json['user'] as Map<String, dynamic>?)?['photoUrl'] as String?,
    json['profileAssetCode'] as String?,
    json['profilePhotoAssetCode'] as String?,
  ]),
  joinedAt: DateTime.parse(
    json['joinedAt'] as String? ?? AppTime.nowUtc().toIso8601String(),
  ),
  leftAt: json['leftAt'] != null
      ? DateTime.parse(json['leftAt'] as String)
      : null,
  lastReadAt: json['lastReadAt'] != null
      ? DateTime.parse(json['lastReadAt'] as String)
      : null,
  muted: json['muted'] as bool? ?? false,
  notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
  createdAt: DateTime.parse(
    json['createdAt'] as String? ?? AppTime.nowUtc().toIso8601String(),
  ),
  updatedAt: DateTime.parse(
    json['updatedAt'] as String? ?? AppTime.nowUtc().toIso8601String(),
  ),
  staffCode: json['staffCode'] as String?,
  guardianCode: json['guardianCode'] as String?,
  adminCode: json['adminCode'] as String?,
  organizationCode: json['organizationCode'] as String?,
  schoolCode: json['schoolCode'] as String?,
  unreadCount: json['unreadCount'] as int? ?? 0,
  active: json['active'] as bool? ?? true,
  staffStatus: json['staffStatus'] as String?,
);

ConversationEntityDto oldConv(Map<String, dynamic> json) {
  final studentName = (json['studentName'] as String?)?.trim();
  final rawTitle = (json['title'] as String?)?.trim() ?? '';
  return ConversationEntityDto(
    id: json['id'] as int? ?? 0,
    code: json['code'] as String? ?? '',
    title: (studentName != null && studentName.isNotEmpty)
        ? studentName
        : rawTitle,
    type: json['type'] as String? ?? 'ROOM_CHAT',
    organizationCode: json['organizationCode'] as String? ?? '',
    schoolCode: json['schoolCode'] as String? ?? '',
    status: json['status'] as String? ?? 'ACTIVE',
    description: json['description'] as String? ?? '',
    avatarUrl: _pick([
      json['avatarUrl'] as String?,
      (json['student'] as Map<String, dynamic>?)?['photoUrl'] as String?,
      (json['student'] as Map<String, dynamic>?)?['avatarUrl'] as String?,
      (json['student'] as Map<String, dynamic>?)?['profileAssetCode']
          as String?,
    ]),
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : AppTime.nowUtc(),
    createdBy: json['createdBy'] as String? ?? '',
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : AppTime.nowUtc(),
    updatedBy: json['updatedBy'] as String? ?? '',
    participantCount: json['participantCount'] as int? ?? 0,
    unreadCount: json['unreadCount'] as int? ?? 0,
    lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
    participants:
        (json['participants'] as List<dynamic>?)
            ?.map((e) => oldPart(e as Map<String, dynamic>))
            .toList() ??
        [],
    studentCode: json['studentCode'] as String?,
    studentStatus: json['studentStatus'] as String?,
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
    privateModeStates:
        (json['privateModeStates'] as List<dynamic>?)
            ?.map((e) => PrivateModeStateDto.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
  );
}

void main() {
  const dates = {
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-02T00:00:00.000Z',
    'joinedAt': '2026-01-01T00:00:00.000Z',
  };

  group('ConversationEntityDto — old vs generated', () {
    final fixtures = <String, Map<String, dynamic>>{
      'defaults (dates present)': {...dates},
      'studentName preferred + nested student avatar': {
        ...dates,
        'title': 'STD_X',
        'studentName': ' Ava ',
        'student': {'photoUrl': 'https://x/ava.jpg'},
      },
      'lastMessageAt unparseable → null': {
        ...dates,
        'lastMessageAt': 'nope',
      },
      'full with participants (both alias styles + nested user avatar)': {
        ...dates,
        'id': 5,
        'code': 'C1',
        'type': 'STAFF_DIRECT',
        'privateModeActive': true,
        'studentCode': 'STD1',
        'classroomCode': 'CLS1',
        'lastMessageAt': '2026-02-02T00:00:00.000Z',
        'participants': [
          {
            ...dates,
            'id': 1,
            'displayName': 'Guardian A',
            'participantType': 'GUARDIAN',
            'photoUrl': 'https://x/g.jpg',
            'active': false,
            'leftAt': '2026-01-05T00:00:00.000Z',
          },
          {
            ...dates,
            'id': 2,
            'userName': 'Legacy',
            'role': 'STAFF',
            'user': {'photoUrl': 'https://x/u.jpg'},
            'staffStatus': 'ACTIVE',
          },
        ],
        'privateModeStates': [
          {
            'parentCode': 'P1',
            'enabled': true,
            'owner': 'P1',
            'enabledAt': '2026-01-03T00:00:00.000Z',
          },
        ],
      },
    };

    fixtures.forEach((name, json) {
      test(name, () {
        final a = oldConv(json);
        final b = ConversationEntityDto.fromJson(json);
        // Compare via toJson map equality (covers every field + omissions +
        // nested participants/privateModeStates) and the entity round-trip.
        expect(b.toJson(), a.toJson());
        expect(b.title, a.title);
        expect(b.avatarUrl, a.avatarUrl);
        expect(b.type, a.type);
        expect(b.lastMessageAt, a.lastMessageAt);
        expect(b.participants.length, a.participants.length);
        expect(b.toEntity().participants.length, a.participants.length);
      });
    });

    test('toJson omits null optionals, keeps required', () {
      final json = ConversationEntityDto.fromJson({...dates}).toJson();
      for (final k in [
        'studentCode',
        'studentStatus',
        'classroomCode',
        'lastMessageAt',
        'lastMessageBy',
        'privateModeActivatedBy',
        'privateModeActivatedAt',
      ]) {
        expect(json.containsKey(k), false, reason: '$k should be omitted');
      }
      expect(json.containsKey('avatarUrl'), true);
      expect(json.containsKey('privateModeActive'), true);
      expect(json.containsKey('privateModeStates'), true);
    });
  });
}
