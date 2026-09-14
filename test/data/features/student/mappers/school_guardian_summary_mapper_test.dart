import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/student/mappers/school_guardian_summary_mapper.dart';

void main() {
  group('schoolGuardianSummaryFromMap', () {
    test('coerces + trims each field', () {
      final entity = schoolGuardianSummaryFromMap(<String, dynamic>{
        'code': '  G1 ',
        'firstName': ' Ann ',
        'lastName': ' Lee ',
        'email': ' ann@x.com ',
        'mobile': ' 5551234567 ',
      });
      expect(entity.code, 'G1');
      expect(entity.firstName, 'Ann');
      expect(entity.lastName, 'Lee');
      expect(entity.email, 'ann@x.com');
      expect(entity.mobile, '5551234567');
      expect(entity.fullName, 'Ann Lee');
    });

    test('missing keys default to empty strings', () {
      final entity = schoolGuardianSummaryFromMap(<String, dynamic>{});
      expect(entity.code, '');
      expect(entity.firstName, '');
      expect(entity.lastName, '');
      expect(entity.email, '');
      expect(entity.mobile, '');
    });

    test('non-string values are coerced via toString', () {
      final entity = schoolGuardianSummaryFromMap(<String, dynamic>{
        'code': 123,
        'mobile': 5551234567,
      });
      expect(entity.code, '123');
      expect(entity.mobile, '5551234567');
    });
  });
}
