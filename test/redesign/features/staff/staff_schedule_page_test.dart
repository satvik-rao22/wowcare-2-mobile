import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/staff_schedule_page.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

import 'harness.dart';

void main() {
  group('the work schedule an Admin edits', () {
    useSource(const PreviewStaffSource());

    testWidgets('draws the week, the copy key and the one way to save', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffSchedulePage(staffId: 'dana'));

      expect(find.text(StaffStrings.scheduleTitle), findsOneWidget);
      expect(find.text(StaffStrings.shiftAndBreak), findsOneWidget);
      expect(find.text(StaffStrings.copyToAllDays), findsOneWidget);
      expect(find.text(StaffStrings.saveSchedule), findsOneWidget);
      expect(find.text(StaffStrings.shiftHint), findsOneWidget);
    });

    testWidgets('names every weekday of the working week', (tester) async {
      await pumpScreen(tester, const StaffSchedulePage(staffId: 'dana'));

      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.friday;
        weekday++
      ) {
        expect(find.text(StaffStrings.weekday(weekday)), findsOneWidget);
      }
    });
  });

  group('a staff member reaching it', () {
    useSource(const PreviewStaffSource());

    testWidgets('is refused, because a work schedule is Admin-only', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const StaffSchedulePage(staffId: 'dana'),
        user: DemoData.staff,
      );

      expect(find.text(StaffStrings.scheduleDeniedTitle), findsOneWidget);
      expect(find.text(StaffStrings.scheduleDeniedBody), findsOneWidget);
      expect(find.text(StaffStrings.saveSchedule), findsNothing);
    });
  });
}
