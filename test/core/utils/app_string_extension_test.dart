import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/app_string_extension.dart';

void main() {
  group('initials', () {
    test('first and last word', () {
      expect('Sara Malik'.initials, 'SM');
      expect('Sara Jane Malik'.initials, 'SM');
      expect('  sara   malik '.initials, 'SM');
    });

    test('one word, hyphens and blanks', () {
      expect('Sara'.initials, 'S');
      expect('Room-A'.initials, 'RA');
      expect(''.initials, '');
      expect('   '.initials, '');
    });
  });

  test('toDisplayRole', () {
    expect('SCHOOL_ADMIN'.toDisplayRole, 'School Admin');
    expect(''.toDisplayRole, '');
  });
}
