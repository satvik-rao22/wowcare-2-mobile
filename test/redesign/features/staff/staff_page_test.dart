import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/staff_page.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

import 'harness.dart';

/// How far a scroll gesture moves per step when hunting for a row that starts
/// below the fold.
const double _scrollStep = -220;

void main() {
  group('6a, the roster an Admin gets', () {
    useSource(const PreviewStaffSource());

    testWidgets('draws the title, the counts and the rows', (tester) async {
      await pumpScreen(tester, const StaffPage());

      expect(find.text(StaffStrings.title), findsOneWidget);
      expect(find.text(StaffStrings.activeStaff), findsOneWidget);
      expect(find.text(StaffStrings.startingSoon), findsWidgets);
      expect(find.text('Dana Whitfield'), findsOneWidget);
      expect(find.text('Marcus Whitfield'), findsOneWidget);
    });

    testWidgets('names the hire who has not started yet, at the foot of the '
        'list', (tester) async {
      await pumpScreen(tester, const StaffPage());

      for (
        var i = 0;
        i < 12 && find.text('Lena Fontaine').evaluate().isEmpty;
        i++
      ) {
        await tester.drag(find.byType(ListView), const Offset(0, _scrollStep));
        await tester.pump();
      }

      expect(find.text('Lena Fontaine'), findsOneWidget);
    });

    testWidgets('a row opens in place with its facts and its three keys', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffPage());

      await tester.tap(find.text('Dana Whitfield'));
      await tester.pump(settle);

      expect(find.text(StaffStrings.designation), findsOneWidget);
      expect(find.text(StaffStrings.allowedIn), findsOneWidget);
      expect(find.text(StaffStrings.call), findsOneWidget);
      expect(find.text(StaffStrings.moreActions), findsOneWidget);
      expect(find.text(StaffStrings.openProfile), findsOneWidget);
    });

    testWidgets('Select docks the bulk bar, which is dead until somebody is '
        'picked', (tester) async {
      await pumpScreen(tester, const StaffPage());

      await tester.tap(find.text('Select'));
      await tester.pump(settle);

      expect(find.text(StaffStrings.pickStaffToMessage), findsOneWidget);
    });

    testWidgets('the filter sheet opens on the chip row', (tester) async {
      await pumpScreen(tester, const StaffPage());

      await tester.tap(find.text(StaffStrings.allDesignations));
      await tester.pump(settle);

      // A section eyebrow renders its label uppercase.
      expect(find.text(StaffStrings.filterTitle), findsOneWidget);
      expect(
        find.text(StaffStrings.statusPickOne.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(StaffStrings.attendanceToday.toUpperCase()),
        findsOneWidget,
      );
    });
  });

  group('6e, a teacher looking', () {
    useSource(const PreviewStaffSource());

    testWidgets('gets the view-only banner, their own record and their team', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffPage(), user: DemoData.staff);

      expect(find.text(StaffStrings.viewOnlyBanner), findsOneWidget);
      expect(find.text(StaffStrings.yourRecord), findsOneWidget);
      expect(find.text(StaffStrings.teamFootnote), findsOneWidget);
      expect(find.text(StaffStrings.searchHint), findsNothing);
    });
  });

  group('6e, no access', () {
    useSource(const PreviewStaffSource());

    testWidgets('a guardian is refused before anything is fetched', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffPage(), user: DemoData.guardian);

      expect(find.text(StaffStrings.deniedTitle), findsOneWidget);
      expect(find.text(StaffStrings.switchSchool), findsOneWidget);
    });
  });

  group('6e, offline', () {
    useSource(const FailingStaffSource());

    testWidgets('says it is waiting for a signal, with one way back', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffPage());

      expect(find.text(StaffStrings.offlineTitle), findsOneWidget);
      expect(find.text(StaffStrings.offlineBody), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('an empty school', () {
    useSource(const EmptyStaffSource());

    testWidgets('offers the first record rather than a blank list', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffPage());

      expect(find.text(StaffStrings.noStaffTitle), findsOneWidget);
      expect(find.text(StaffStrings.addStaff), findsOneWidget);
    });
  });
}
