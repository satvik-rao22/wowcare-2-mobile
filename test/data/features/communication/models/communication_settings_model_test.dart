import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/communication/models/communication_settings_model.dart';

/// Characterisation test (Mandate 8): pins the previous hand-written
/// `fromJson` behaviour and asserts the generated `json_serializable`
/// parser produces field-for-field identical results across valid, missing,
/// null and wrong-type inputs. `oldParse` below is a verbatim copy of the
/// parser that existed before the conversion — the two must never diverge.
CommunicationSettingsModel oldParse(Map<String, dynamic> json) =>
    CommunicationSettingsModel(
      schoolCode: (json['schoolCode'] as String?) ?? '',
      adminCanDeleteAny: json['adminCanDeleteAny'] as bool? ?? false,
      deleteTimeLimitMinutes: (json['deleteTimeLimitMinutes'] as num?)?.toInt(),
      notifyStaffToParent: json['notifyStaffToParent'] as bool? ?? true,
      notifyStaffToStaff: json['notifyStaffToStaff'] as bool? ?? true,
      notifyParentToStaff: json['notifyParentToStaff'] as bool? ?? true,
    );

void expectSameFields(
  CommunicationSettingsModel a,
  CommunicationSettingsModel b,
) {
  expect(b.schoolCode, a.schoolCode);
  expect(b.adminCanDeleteAny, a.adminCanDeleteAny);
  expect(b.deleteTimeLimitMinutes, a.deleteTimeLimitMinutes);
  expect(b.notifyStaffToParent, a.notifyStaffToParent);
  expect(b.notifyStaffToStaff, a.notifyStaffToStaff);
  expect(b.notifyParentToStaff, a.notifyParentToStaff);
}

void main() {
  group('CommunicationSettingsModel — old vs generated parser parity', () {
    final fixtures = <String, Map<String, dynamic>>{
      'full valid': {
        'schoolCode': 'SCH001',
        'adminCanDeleteAny': true,
        'deleteTimeLimitMinutes': 15,
        'notifyStaffToParent': false,
        'notifyStaffToStaff': false,
        'notifyParentToStaff': false,
      },
      'empty (all keys missing)': {},
      'explicit nulls': {
        'schoolCode': null,
        'adminCanDeleteAny': null,
        'deleteTimeLimitMinutes': null,
        'notifyStaffToParent': null,
        'notifyStaffToStaff': null,
        'notifyParentToStaff': null,
      },
      'deleteTimeLimitMinutes double-encoded': {
        'schoolCode': 'SCH002',
        'deleteTimeLimitMinutes': 30.0,
      },
      'partial (schoolCode only)': {'schoolCode': 'SCH003'},
    };

    fixtures.forEach((name, json) {
      test(name, () {
        expectSameFields(
          oldParse(json),
          CommunicationSettingsModel.fromJson(json),
        );
      });
    });

    test('defaults from empty match the documented fallback', () {
      final m = CommunicationSettingsModel.fromJson(const {});
      expect(m.schoolCode, '');
      expect(m.adminCanDeleteAny, false);
      expect(m.deleteTimeLimitMinutes, isNull);
      expect(m.notifyStaffToParent, true);
      expect(m.notifyStaffToStaff, true);
      expect(m.notifyParentToStaff, true);
    });

    test('double-encoded limit becomes an int', () {
      final m = CommunicationSettingsModel.fromJson(const {
        'deleteTimeLimitMinutes': 30.0,
      });
      expect(m.deleteTimeLimitMinutes, 30);
    });
  });
}
