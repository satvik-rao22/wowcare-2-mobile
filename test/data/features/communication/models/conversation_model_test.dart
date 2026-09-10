import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/data/features/communication/models/conversation_model.dart';

/// Characterisation test (Mandate 8) for [ConversationModel] /
/// [ConversationParticipantModel]. The `old*` helpers are verbatim copies of
/// the pre-conversion hand-written parsers; the generated parsers must match
/// them field-for-field — covering the `studentName`→`title`,
/// `displayName`→`userName` and `participantType`→`role` derivations, the
/// `DateTime.parse`/`tryParse` handling, nulls, missing keys and defaults.
///
/// Parity fixtures always carry the required date fields so both parsers read
/// the same string (the `!= null ? parse : now` fallback would otherwise pick
/// two different "now"s). The missing-date fallback is checked separately
/// against the new parser alone.

ConversationParticipantModel oldParticipant(Map<String, dynamic> json) =>
    ConversationParticipantModel(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversationId'] as int? ?? 0,
      userCode: json['userCode'] as String? ?? '',
      privateModeEnabled: json['privateModeEnabled'] as bool? ?? false,
      userName: (json['displayName'] as String?)?.isNotEmpty == true
          ? json['displayName'] as String
          : json['userName'] as String? ?? '',
      role:
          json['participantType'] as String? ??
          json['role'] as String? ??
          'STAFF',
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : AppTime.nowUtc(),
      leftAt: json['leftAt'] != null
          ? DateTime.parse(json['leftAt'] as String)
          : null,
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.parse(json['lastReadAt'] as String)
          : null,
      muted: json['muted'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : AppTime.nowUtc(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : AppTime.nowUtc(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      active: json['active'] as bool? ?? true,
      staffStatus: json['staffStatus'] as String?,
    );

ConversationModel oldConversation(Map<String, dynamic> json) {
  final studentName = (json['studentName'] as String?)?.trim();
  final rawTitle = (json['title'] as String?)?.trim() ?? '';
  return ConversationModel(
    id: json['id'] as int? ?? 0,
    code: json['code'] as String? ?? '',
    title: (studentName != null && studentName.isNotEmpty)
        ? studentName
        : rawTitle,
    type: json['type'] as String? ?? 'DIRECT',
    organizationCode: json['organizationCode'] as String? ?? '',
    schoolCode: json['schoolCode'] as String? ?? '',
    status: json['status'] as String? ?? 'ACTIVE',
    description: json['description'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : AppTime.nowUtc(),
    createdBy: json['createdBy'] as String? ?? '',
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : AppTime.nowUtc(),
    updatedBy: json['updatedBy'] as String? ?? '',
    lastMessageAt: json['lastMessageAt'] != null
        ? DateTime.parse(json['lastMessageAt'] as String)
        : null,
    lastMessageBy: json['lastMessageBy'] as String?,
    lastMessageSenderName: json['lastMessageSenderName'] as String?,
    privateModeActive: json['privateModeActive'] as bool? ?? false,
    privateModeActivatedBy: json['privateModeActivatedBy'] as String?,
    privateModeActivatedAt: json['privateModeActivatedAt'] != null
        ? DateTime.tryParse(json['privateModeActivatedAt'] as String)
        : null,
    participantCount: json['participantCount'] as int? ?? 0,
    unreadCount: json['unreadCount'] as int? ?? 0,
    lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
    participants:
        (json['participants'] as List<dynamic>?)
            ?.map((e) => oldParticipant(e as Map<String, dynamic>))
            .toList() ??
        [],
    studentStatus: json['studentStatus'] as String?,
    classroomCode: json['classroomCode'] as String?,
  );
}

void expectParticipant(
  ConversationParticipantModel a,
  ConversationParticipantModel b,
) {
  expect(b.id, a.id);
  expect(b.conversationId, a.conversationId);
  expect(b.userCode, a.userCode);
  expect(b.userName, a.userName);
  expect(b.role, a.role);
  expect(b.joinedAt, a.joinedAt);
  expect(b.leftAt, a.leftAt);
  expect(b.lastReadAt, a.lastReadAt);
  expect(b.muted, a.muted);
  expect(b.notificationsEnabled, a.notificationsEnabled);
  expect(b.createdAt, a.createdAt);
  expect(b.updatedAt, a.updatedAt);
  expect(b.privateModeEnabled, a.privateModeEnabled);
  expect(b.unreadCount, a.unreadCount);
  expect(b.active, a.active);
  expect(b.staffStatus, a.staffStatus);
}

void expectConversation(ConversationModel a, ConversationModel b) {
  expect(b.id, a.id);
  expect(b.code, a.code);
  expect(b.title, a.title);
  expect(b.type, a.type);
  expect(b.organizationCode, a.organizationCode);
  expect(b.schoolCode, a.schoolCode);
  expect(b.status, a.status);
  expect(b.description, a.description);
  expect(b.avatarUrl, a.avatarUrl);
  expect(b.createdAt, a.createdAt);
  expect(b.createdBy, a.createdBy);
  expect(b.updatedAt, a.updatedAt);
  expect(b.updatedBy, a.updatedBy);
  expect(b.lastMessageAt, a.lastMessageAt);
  expect(b.lastMessageBy, a.lastMessageBy);
  expect(b.lastMessageSenderName, a.lastMessageSenderName);
  expect(b.privateModeActive, a.privateModeActive);
  expect(b.privateModeActivatedBy, a.privateModeActivatedBy);
  expect(b.privateModeActivatedAt, a.privateModeActivatedAt);
  expect(b.participantCount, a.participantCount);
  expect(b.unreadCount, a.unreadCount);
  expect(b.lastMessagePreview, a.lastMessagePreview);
  expect(b.studentStatus, a.studentStatus);
  expect(b.classroomCode, a.classroomCode);
  expect(b.participants.length, a.participants.length);
  for (var i = 0; i < a.participants.length; i++) {
    expectParticipant(a.participants[i], b.participants[i]);
  }
}

void main() {
  const dates = {
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-02T00:00:00.000Z',
    'joinedAt': '2026-01-01T00:00:00.000Z',
  };

  group('ConversationModel — old vs generated', () {
    final fixtures = <String, Map<String, dynamic>>{
      'empty (all defaults, dates present to avoid now-skew)': {...dates},
      'studentName preferred over title': {
        ...dates,
        'title': 'STD_AC88244D',
        'studentName': '  Ava Long  ',
      },
      'title used when studentName blank': {
        ...dates,
        'title': 'Room A',
        'studentName': '   ',
      },
      'privateModeActivatedAt unparseable → null': {
        ...dates,
        'privateModeActivatedAt': 'not-a-date',
      },
      'privateModeActivatedAt valid': {
        ...dates,
        'privateModeActivatedAt': '2026-03-03T03:03:03.000Z',
      },
      'nullable dates present': {
        ...dates,
        'lastMessageAt': '2026-02-02T00:00:00.000Z',
      },
      'full with participants (both alias styles)': {
        ...dates,
        'id': 7,
        'code': 'CONV_1',
        'title': 'T',
        'type': 'ROOM_CHAT',
        'organizationCode': 'ORG',
        'schoolCode': 'SCH',
        'status': 'ACTIVE',
        'privateModeActive': true,
        'participantCount': 2,
        'unreadCount': 3,
        'lastMessagePreview': 'hi',
        'studentStatus': 'UPCOMING',
        'classroomCode': 'CLS_1',
        'participants': [
          {
            ...dates,
            'id': 1,
            'displayName': 'Guardian A',
            'participantType': 'GUARDIAN',
            'active': false,
          },
          {
            ...dates,
            'id': 2,
            'userName': 'Legacy Name',
            'role': 'TEACHER',
            'staffStatus': 'ACTIVE',
          },
        ],
      },
    };

    fixtures.forEach((name, json) {
      test(name, () {
        expectConversation(
          oldConversation(json),
          ConversationModel.fromJson(json),
        );
      });
    });

    test('missing dates fall back to a DateTime (now)', () {
      final m = ConversationModel.fromJson(const {});
      expect(m.createdAt, isA<DateTime>());
      expect(m.updatedAt, isA<DateTime>());
      expect(m.title, '');
      expect(m.type, 'DIRECT');
      expect(m.status, 'ACTIVE');
    });

    group('participant profile photo', () {
      test('reads photoUrl / avatarUrl / asset-code fields, in that order', () {
        String? avatarOf(Map<String, dynamic> participant) =>
            ConversationParticipantModel.fromJson({
              ...dates,
              'id': 1,
              ...participant,
            }).avatarUrl;

        expect(
          avatarOf({
            'photoUrl': 'https://cdn/photo.jpg',
            'avatarUrl': 'https://cdn/avatar.jpg',
          }),
          'https://cdn/photo.jpg',
        );
        expect(avatarOf({'avatarUrl': 'https://cdn/avatar.jpg'}),
            'https://cdn/avatar.jpg');
        expect(avatarOf({'profilePhotoUrl': 'https://cdn/profile.jpg'}),
            'https://cdn/profile.jpg');
        expect(
          avatarOf({
            'user': <String, dynamic>{'photoUrl': 'https://cdn/nested.jpg'},
          }),
          'https://cdn/nested.jpg',
        );
        // Raw asset codes are accepted too — the avatar widget resolves them.
        expect(avatarOf({'profilePhotoAssetCode': 'AST_1'}), 'AST_1');
        // Blank values are skipped rather than winning over a later field.
        expect(avatarOf({'photoUrl': '   ', 'avatarUrl': 'AST_2'}), 'AST_2');
      });

      test('is null when the payload carries no photo at all', () {
        final participant = ConversationParticipantModel.fromJson({
          ...dates,
          'id': 1,
          'userCode': 'USR_1',
        });
        expect(participant.avatarUrl, isNull);
        expect(participant.staffCode, isNull);
        expect(participant.toEntity().avatarUrl, isNull);
      });

      test('carries photo and staffCode through to the entity', () {
        final entity = ConversationParticipantModel.fromJson({
          ...dates,
          'id': 1,
          'userCode': 'USR_1',
          'staffCode': 'STF_1',
          'photoUrl': 'https://cdn/photo.jpg',
        }).toEntity();
        expect(entity.avatarUrl, 'https://cdn/photo.jpg');
        expect(entity.staffCode, 'STF_1');
      });
    });

    test('toJson omits null studentStatus/classroomCode', () {
      final m = ConversationModel.fromJson({...dates, 'id': 1});
      final json = m.toJson();
      expect(json.containsKey('studentStatus'), false);
      expect(json.containsKey('classroomCode'), false);
      // present-but-null optional dates are still emitted (includeIfNull true)
      expect(json.containsKey('lastMessageAt'), true);
      expect(json['lastMessageAt'], isNull);
    });
  });
}
