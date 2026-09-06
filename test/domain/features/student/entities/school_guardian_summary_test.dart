import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/school_guardian_summary.dart';

void main() {
  // Note: `SchoolGuardianSummary.fromMap` was moved to the data-layer mapper
  // `schoolGuardianSummaryFromMap` in Step 4; its parsing is covered by
  // test/data/features/student/mappers/school_guardian_summary_mapper_test.dart.
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
