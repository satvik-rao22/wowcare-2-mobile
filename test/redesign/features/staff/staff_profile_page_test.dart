import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/staff_profile_page.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

import 'harness.dart';

void main() {
  group('6c, an Admin reading a record', () {
    useSource(const PreviewStaffSource());

    testWidgets('opens on the Profile tab with the record and the two keys', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffProfilePage(staffId: 'dana'));

      expect(find.text('Dana Whitfield'), findsWidgets);
      expect(find.text(StaffStrings.designation), findsOneWidget);
      expect(find.text(StaffStrings.message), findsOneWidget);
      expect(find.text(StaffStrings.callName('Dana')), findsWidgets);
    });

    testWidgets('shows the Sign-In PIN read only, and never calls it a Kiosk '
        'PIN', (tester) async {
      await pumpScreen(tester, const StaffProfilePage(staffId: 'dana'));

      expect(find.text(StaffStrings.signInPin), findsOneWidget);
      expect(find.text('5106'), findsOneWidget);
      expect(find.textContaining('Kiosk'), findsNothing);
      expect(find.textContaining('Reset'), findsNothing);
    });

    testWidgets('draws all five tabs', (tester) async {
      await pumpScreen(tester, const StaffProfilePage(staffId: 'dana'));

      expect(find.text(StaffStrings.tabProfile), findsOneWidget);
      expect(find.text(StaffStrings.tabSchedule), findsOneWidget);
      expect(find.text(AppStrings.attendance), findsOneWidget);
      expect(find.text(StaffStrings.tabDates), findsOneWidget);
      expect(find.text(StaffStrings.tabDocuments), findsOneWidget);
    });

    testWidgets('the Schedule tab shows the week and the way to edit it', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffProfilePage(staffId: 'dana'));

      await tester.ensureVisible(find.text(StaffStrings.tabSchedule));
      await tester.pump();
      await tester.tap(find.text(StaffStrings.tabSchedule));
      await tester.pump(settle);

      expect(find.text(StaffStrings.thisWeek), findsOneWidget);
      expect(find.text(StaffStrings.editTheWeek), findsOneWidget);
    });

    testWidgets('the Dates tab names the five dates on record', (tester) async {
      await pumpScreen(tester, const StaffProfilePage(staffId: 'dana'));

      await tester.ensureVisible(find.text(StaffStrings.tabDates));
      await tester.pump();
      await tester.tap(find.text(StaffStrings.tabDates));
      await tester.pump(settle);

      expect(find.text(StaffStrings.hireDate), findsOneWidget);
      expect(find.text(StaffStrings.firstAidExpiry), findsOneWidget);
    });

    testWidgets('the Documents tab lists the files and offers another', (
      tester,
    ) async {
      await pumpScreen(tester, const StaffProfilePage(staffId: 'dana'));

      await tester.ensureVisible(find.text(StaffStrings.tabDocuments));
      await tester.pump();
      await tester.tap(find.text(StaffStrings.tabDocuments));
      await tester.pump(settle);

      expect(find.text('Signed contract'), findsOneWidget);
      expect(find.text(StaffStrings.addDocument), findsOneWidget);
    });
  });

  group('6c, a teacher reading a colleague', () {
    useSource(const PreviewStaffSource());

    testWidgets('gets the profile tab only, with no PIN and no Edit key', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const StaffProfilePage(staffId: 'priya'),
        user: DemoData.staff,
      );

      expect(find.text('Priya Raman'), findsWidgets);
      expect(find.text(StaffStrings.tabSchedule), findsNothing);
      expect(find.text(StaffStrings.signInPin), findsNothing);
      expect(find.text(AppStrings.edit), findsNothing);
    });
  });

  group('6c, when the record cannot be reached', () {
    useSource(const FailingStaffSource());

    testWidgets('says so, with one way to try again', (tester) async {
      await pumpScreen(tester, const StaffProfilePage(staffId: 'dana'));

      expect(find.text(StaffStrings.couldNotReachTitle), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });
  });
}
