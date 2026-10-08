import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/modules/attendance_v2/core/utils/av2_date_formatter.dart';

void main() {
  group('Av2DateFormatter.compactTime', () {
    test('spells the meridiem out as AM/PM, like every other screen', () {
      expect(Av2DateFormatter.compactTime(DateTime(2026, 9, 21, 9)), '09:00 AM');
      expect(
        Av2DateFormatter.compactTime(DateTime(2026, 9, 21, 19, 30)),
        '07:30 PM',
      );
    });

    test('noon and midnight land on the right side', () {
      expect(Av2DateFormatter.compactTime(DateTime(2026, 9, 21, 12)), '12:00 PM');
      expect(Av2DateFormatter.compactTime(DateTime(2026, 9, 21)), '12:00 AM');
    });
  });
}
