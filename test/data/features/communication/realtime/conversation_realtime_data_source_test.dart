import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/communication/realtime/conversation_realtime_data_source.dart';

void main() {
  group('resolveRoleAwareUnreadCount', () {
    test('null roleBucket always trusts the flat count', () {
      expect(
        resolveRoleAwareUnreadCount({
          'conversationType': 'ADMIN_CHAT',
          'unreadCount': 5,
          'unreadByRole': {'GUARDIAN': 0},
        }, null),
        5,
      );
    });

    test('STAFF_DIRECT trusts the flat count even when unreadByRole has an '
        'entry for a different role (e.g. the sender\'s), matching a staff -> '
        'admin message the admin has not yet read', () {
      expect(
        resolveRoleAwareUnreadCount({
          'conversationType': 'STAFF_DIRECT',
          'unreadCount': 3,
          'unreadByRole.STAFF': 0,
        }, 'ADMIN'),
        3,
      );
    });

    test('STAFF_DIRECT trusts the flat count even with a nested unreadByRole '
        'map missing the reader\'s bucket', () {
      expect(
        resolveRoleAwareUnreadCount({
          'conversationType': 'STAFF_DIRECT',
          'unreadCount': 2,
          'unreadByRole': {'STAFF': 0},
        }, 'ADMIN'),
        2,
      );
    });

    test('ADMIN_CHAT still resolves 0 when the doc has role-aware tracking but '
        'no entry for the reader\'s bucket (dual-persona stale-count guard, '
        'unchanged)', () {
      expect(
        resolveRoleAwareUnreadCount({
          'conversationType': 'ADMIN_CHAT',
          'unreadCount': 7,
          'unreadByRole': {'GUARDIAN': 4},
        }, 'ADMIN'),
        0,
      );
    });

    test(
      'ADMIN_CHAT resolves the dotted-key entry for the reader\'s bucket',
      () {
        expect(
          resolveRoleAwareUnreadCount({
            'conversationType': 'ADMIN_CHAT',
            'unreadCount': 7,
            'unreadByRole.ADMIN': 4,
          }, 'ADMIN'),
          4,
        );
      },
    );

    test('a legacy doc with no unreadByRole data at all still trusts the flat '
        'count regardless of type', () {
      expect(
        resolveRoleAwareUnreadCount({
          'conversationType': 'ROOM_CHAT',
          'unreadCount': 1,
        }, 'ADMIN'),
        1,
      );
    });
  });
}
