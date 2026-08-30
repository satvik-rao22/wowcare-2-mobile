import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/school_guardian_summary.dart';

void main() {
  group('SchoolGuardianSummary.fromMap', () {
    test('maps all keys and trims whitespace', () {
      final summary = SchoolGuardianSummary.fromMap({
        'code': '  G1  ',
        'firstName': '  Ann  ',
        'lastName': '  Lee  ',
        'email': '  ann@example.com  ',
        'mobile': '  5551234567  ',
      });

      expect(summary.code, 'G1');
      expect(summary.firstName, 'Ann');
      expect(summary.lastName, 'Lee');
      expect(summary.email, 'ann@example.com');
      expect(summary.mobile, '5551234567');
    });

    test('missing keys default to empty strings', () {
      final summary = SchoolGuardianSummary.fromMap(const {});

      expect(summary.code, '');
      expect(summary.firstName, '');
      expect(summary.lastName, '');
      expect(summary.email, '');
      expect(summary.mobile, '');
    });

    test('null values default to empty strings', () {
      final summary = SchoolGuardianSummary.fromMap(const {
        'code': null,
        'firstName': null,
        'lastName': null,
        'email': null,
        'mobile': null,
      });

      expect(summary.code, '');
      expect(summary.firstName, '');
      expect(summary.lastName, '');
      expect(summary.email, '');
      expect(summary.mobile, '');
    });

    test('coerces non-string values to strings', () {
      final summary = SchoolGuardianSummary.fromMap(const {
        'mobile': 5551234567,
      });

      expect(summary.mobile, '5551234567');
    });
  });

  group('fullName', () {
    test('composes first and last name', () {
      const summary = SchoolGuardianSummary(
        code: 'G1',
        firstName: 'Ann',
        lastName: 'Lee',
        email: '',
        mobile: '',
      );

      expect(summary.fullName, 'Ann Lee');
    });

    test('trims when a name part is empty', () {
      const first = SchoolGuardianSummary(
        code: 'G1',
        firstName: 'Ann',
        lastName: '',
        email: '',
        mobile: '',
      );
      expect(first.fullName, 'Ann');

      const last = SchoolGuardianSummary(
        code: 'G2',
        firstName: '',
        lastName: 'Lee',
        email: '',
        mobile: '',
      );
      expect(last.fullName, 'Lee');

      const empty = SchoolGuardianSummary(
        code: 'G3',
        firstName: '',
        lastName: '',
        email: '',
        mobile: '',
      );
      expect(empty.fullName, '');
    });
  });

  test('value equality via Equatable props', () {
    const a = SchoolGuardianSummary(
      code: 'G1',
      firstName: 'Ann',
      lastName: 'Lee',
      email: 'ann@example.com',
      mobile: '5551234567',
    );
    const b = SchoolGuardianSummary(
      code: 'G1',
      firstName: 'Ann',
      lastName: 'Lee',
      email: 'ann@example.com',
      mobile: '5551234567',
    );

    expect(a, b);
  });
}
