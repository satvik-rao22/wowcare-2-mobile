import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/shared/room_chat_privacy_helper.dart';

void main() {
  group('RoomChatPrivacyHelper', () {
    test('guardian can only see own private messages', () {
      final context = RoomChatPrivacyContext(
        conversationType: ConversationType.roomChat,
        viewerRole: RoomChatViewerRole.guardian,
        viewerUserCode: 'P1',
      );

      expect(
        RoomChatPrivacyHelper.canViewerSeeMessage(
          context: context,
          isPrivate: true,
          privateParentUserCode: 'P1',
        ),
        isTrue,
      );
      expect(
        RoomChatPrivacyHelper.canViewerSeeMessage(
          context: context,
          isPrivate: true,
          privateParentUserCode: 'P2',
        ),
        isFalse,
      );
    });

    test('staff can see all private room messages', () {
      final context = RoomChatPrivacyContext(
        conversationType: ConversationType.roomChat,
        viewerRole: RoomChatViewerRole.staffOrAdmin,
        viewerUserCode: 'STF-1',
      );

      expect(
        RoomChatPrivacyHelper.canViewerSeeMessage(
          context: context,
          isPrivate: true,
          privateParentUserCode: 'P2',
        ),
        isTrue,
      );
    });

    test('guardian merged thread keeps public and own private messages', () {
      final merged = RoomChatPrivacyHelper.messagesForGuardianMergedThread(
        messages: [
          Message(
            id: '1',
            code: '1',
            text: 'public',
            isSentByMe: false,
            time: DateTime(2026, 1, 1),
          ),
          Message(
            id: '2',
            code: '2',
            text: 'mine',
            isSentByMe: false,
            time: DateTime(2026, 1, 2),
            isPrivate: true,
            privateParentUserCode: 'P1',
          ),
          Message(
            id: '3',
            code: '3',
            text: 'other',
            isSentByMe: false,
            time: DateTime(2026, 1, 3),
            isPrivate: true,
            privateParentUserCode: 'P2',
          ),
        ],
        currentGuardianUserCode: 'P1',
      );

      expect(merged.map((m) => m.code), ['1', '2']);
    });
  });
}
