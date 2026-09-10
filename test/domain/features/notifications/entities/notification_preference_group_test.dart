import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';

NotificationPreferenceGroup _group({
  String categoryName = '',
  String categoryCode = '',
}) =>
    NotificationPreferenceGroup(
      groupCode: 'G1',
      title: 'Classroom shifts/schedule needs attention',
      categoryCode: categoryCode,
      categoryName: categoryName,
    );

void main() {
  group('categoryLabel', () {
    test('title-cases a screaming-snake-case categoryName', () {
      expect(
        _group(categoryName: 'STAFF_SCHEDULING').categoryLabel,
        'Staff Scheduling',
      );
    });

    test('title-cases a single all-caps categoryName', () {
      expect(_group(categoryName: 'INCIDENT').categoryLabel, 'Incident');
    });

    test('leaves a human-written categoryName untouched', () {
      expect(_group(categoryName: 'Activities').categoryLabel, 'Activities');
      expect(
        _group(categoryName: 'Staff Scheduling').categoryLabel,
        'Staff Scheduling',
      );
    });

    test('falls back to categoryCode when categoryName is missing', () {
      expect(
        _group(categoryCode: 'STAFF_SCHEDULING').categoryLabel,
        'Staff Scheduling',
      );
    });

    test('is empty when neither name nor code is present', () {
      expect(_group().categoryLabel, '');
    });
  });
}
