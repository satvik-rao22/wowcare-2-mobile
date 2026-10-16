import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/messaging_screen.dart';

/// Back from a notification-opened thread lands on the inbox sub-tab that
/// lists that conversation — see [MessagingScreen.inboxRouteFor].
void main() {
  group('MessagingScreen.inboxRouteFor — staff/admin', () {
    const cases = {
      ConversationType.staffDirect: MessagingScreen.staffMessagingRoute,
      ConversationType.classroomChat: MessagingScreen.staffMessagingRoute,
      ConversationType.roomChat: MessagingScreen.parentMessagingRoute,
      ConversationType.adminChat: MessagingScreen.parentMessagingRoute,
    };

    cases.forEach((type, expected) {
      test('${type.toApiString()} → $expected', () {
        expect(
          MessagingScreen.inboxRouteFor(type, isParent: false),
          expected,
        );
      });
    });

    test('unknown type → plain messaging home', () {
      expect(
        MessagingScreen.inboxRouteFor(null, isParent: false),
        MessagingScreen.routeName,
      );
    });
  });

  group('MessagingScreen.inboxRouteFor — guardian', () {
    test('every type → plain messaging home (no sub-tabs)', () {
      for (final type in [...ConversationType.values, null]) {
        expect(
          MessagingScreen.inboxRouteFor(type, isParent: true),
          MessagingScreen.routeName,
          reason: 'type=$type',
        );
      }
    });
  });
}
