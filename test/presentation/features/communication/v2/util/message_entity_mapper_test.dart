import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/presentation/features/communication/v2/util/message_entity_mapper.dart';

void main() {
  MessageEntity buildEntity({
    String? privateParentUserCode,
    String? threadParentCode,
  }) {
    return MessageEntity(
      id: 'ID_1',
      code: 'MSG_1',
      conversationCode: 'CONV_1',
      senderCode: 'PARENT_1',
      senderName: 'Parent One',
      senderRole: ParticipantRole.parent,
      text: 'hello',
      messageType: MessageType.text,
      status: MessageStatus.sent,
      sentAt: DateTime(2024, 1, 1),
      organizationCode: 'ORG_1',
      schoolCode: 'SCHOOL_1',
      privateParentUserCode: privateParentUserCode,
      threadParentCode: threadParentCode,
    );
  }

  group('mapMessageEntityToMessage — privateParentUserCode', () {
    test('preserves privateParentUserCode when set', () {
      final entity = buildEntity(privateParentUserCode: 'PARENT_42');

      final message = mapMessageEntityToMessage(entity, 'PARENT_1');

      expect(message.privateParentUserCode, 'PARENT_42');
    });

    test('preserves null privateParentUserCode', () {
      final entity = buildEntity();

      final message = mapMessageEntityToMessage(entity, 'PARENT_1');

      expect(message.privateParentUserCode, isNull);
    });
  });

  group('mapMessageEntityToMessage — quotedMessageId', () {
    test('maps quotedMessageId from threadParentCode', () {
      final entity = buildEntity(threadParentCode: 'MSG_PARENT_99');

      final message = mapMessageEntityToMessage(entity, 'PARENT_1');

      expect(message.quotedMessageId, 'MSG_PARENT_99');
    });

    test('quotedMessageId is null when there is no thread parent', () {
      final entity = buildEntity();

      final message = mapMessageEntityToMessage(entity, 'PARENT_1');

      expect(message.quotedMessageId, isNull);
    });
  });
}
