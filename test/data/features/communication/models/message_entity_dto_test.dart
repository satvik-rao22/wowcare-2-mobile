import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/communication/models/message_entity_dto.dart';

void main() {
  group('MessageEntityDto.fromJson — privateParentUserCode', () {
    Map<String, dynamic> baseJson({Object? privateParentUserCode}) => {
      'id': '1',
      'code': 'MSG_1',
      'conversationCode': 'CONV_1',
      'senderUserCode': 'USER_1',
      'senderName': 'Parent One',
      'senderRole': 'PARENT',
      'content': 'hello',
      'messageType': 'TEXT',
      'status': 'SENT',
      'createdAt': '2024-01-01T00:00:00.000Z',
      'organizationCode': 'ORG_1',
      'schoolCode': 'SCHOOL_1',
      if (privateParentUserCode != null)
        'privateParentUserCode': privateParentUserCode,
    };

    test('parses privateParentUserCode when present in the response', () {
      final dto = MessageEntityDto.fromJson(
        baseJson(privateParentUserCode: 'PARENT_42'),
      );

      expect(dto.privateParentUserCode, 'PARENT_42');
    });

    test('is null when the response omits privateParentUserCode', () {
      final dto = MessageEntityDto.fromJson(baseJson());

      expect(dto.privateParentUserCode, isNull);
    });

    test('toEntity() preserves privateParentUserCode', () {
      final dto = MessageEntityDto.fromJson(
        baseJson(privateParentUserCode: 'PARENT_42'),
      );

      final entity = dto.toEntity();

      expect(entity.privateParentUserCode, 'PARENT_42');
    });

    test('toJson() round-trips privateParentUserCode', () {
      final dto = MessageEntityDto.fromJson(
        baseJson(privateParentUserCode: 'PARENT_42'),
      );

      final json = dto.toJson();

      expect(json['privateParentUserCode'], 'PARENT_42');
    });
  });
}
