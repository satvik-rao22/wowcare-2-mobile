import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/notifications/deep_link_parser.dart';

void main() {
  test('returns null when the link has no action and matches no known '
      'action-less link family', () {
    final uri = Uri.parse(
      'https://wowcare-uat.childcarewow.app/some/unrelated/path?foo=bar',
    );

    expect(pushNotificationFromDeepLinkUri(uri), isNull);
  });

  test(
    'a plain action= link is parsed as-is, with the whole URL stashed under '
    '__deepLink',
    () {
      final uri = Uri.parse(
        'https://wowcare-uat.childcarewow.app/billing'
        '?action=INVOICE_GENERATED&invoiceCode=INV_1&studentCode=STD_1'
        '&organizationCode=ORG_1&schoolCode=SCH_1&userCode=USR_1',
      );

      final notification = pushNotificationFromDeepLinkUri(uri);

      expect(notification, isNotNull);
      expect(notification!.action, 'INVOICE_GENERATED');
      expect(notification.data['invoiceCode'], 'INV_1');
      expect(notification.data['studentCode'], 'STD_1');
      expect(notification.userCode, 'USR_1');
      expect(notification.role, isNull);
      expect(notification.data['__deepLink'], uri.toString());
    },
  );

  test(
    'a daily-activities share link (no action= at all) infers '
    'ACTIVITY_RECORDED and maps targetCode/recordCode onto the keys the '
    'resolver reads',
    () {
      final uri = Uri.parse(
        'https://wowcare-uat.childcarewow.app/activities/daily-activities'
        '?targetCode=STD_8E45E412&recordCode=ACT_7FAC2C5B-C'
        '&date=2026-09-17&userCode=USR-0d1bf4e1&role=GUARDIAN',
      );

      final notification = pushNotificationFromDeepLinkUri(uri);

      expect(notification, isNotNull);
      expect(notification!.action, 'ACTIVITY_RECORDED');
      expect(notification.data['studentCode'], 'STD_8E45E412');
      expect(notification.data['activityCode'], 'ACT_7FAC2C5B-C');
      expect(notification.data['date'], '2026-09-17');
      expect(notification.userCode, 'USR-0d1bf4e1');
      expect(notification.role, 'GUARDIAN');
    },
  );

  test(
    'targetCode/recordCode normalization never overwrites an explicit '
    'studentCode/activityCode the link already set',
    () {
      final uri = Uri.parse(
        'https://wowcare-uat.childcarewow.app/activities/daily-activities'
        '?targetCode=STD_WRONG&recordCode=ACT_WRONG'
        '&studentCode=STD_RIGHT&activityCode=ACT_RIGHT',
      );

      final notification = pushNotificationFromDeepLinkUri(uri);

      expect(notification, isNotNull);
      expect(notification!.data['studentCode'], 'STD_RIGHT');
      expect(notification.data['activityCode'], 'ACT_RIGHT');
    },
  );
}
