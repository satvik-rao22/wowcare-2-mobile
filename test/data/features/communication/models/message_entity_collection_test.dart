import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/communication/models/message_entity_collection.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

void main() {
  MessageEntity buildEntity({String? privateParentUserCode}) {
    return MessageEntity(
      id: '123',
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
    );
  }

  group('MessageEntity -> MessageEntityCollection -> MessageEntity', () {
    test('preserves privateParentUserCode when present', () {
      final entity = buildEntity(privateParentUserCode: 'PARENT_42');

      final collection = MessageEntityCollection.fromEntity(entity);
      expect(collection.privateParentUserCode, 'PARENT_42');

      final roundTripped = collection.toEntity();
      expect(roundTripped.privateParentUserCode, 'PARENT_42');
    });

    test('preserves null privateParentUserCode', () {
      final entity = buildEntity();

      final collection = MessageEntityCollection.fromEntity(entity);
      expect(collection.privateParentUserCode, isNull);

      final roundTripped = collection.toEntity();
      expect(roundTripped.privateParentUserCode, isNull);
    });
  });
}
