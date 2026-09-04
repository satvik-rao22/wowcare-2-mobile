import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/add_staff_page.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

import 'harness.dart';

void main() {
  group('6d, Add Admin or Staff', () {
    useSource(const PreviewStaffSource());

    testWidgets('opens on step one, with the three steps listed above it', (
      tester,
    ) async {
      await pumpScreen(tester, const AddStaffPage());

      expect(find.text(StaffStrings.addStaff), findsOneWidget);
      expect(find.text(StaffStrings.step1Title), findsOneWidget);
      expect(find.text(StaffStrings.step2Title), findsOneWidget);
      expect(find.text(StaffStrings.step3Title), findsOneWidget);
      expect(find.text(StaffStrings.optional), findsOneWidget);
    });

    testWidgets('step one asks for the name, the work email and the phone', (
      tester,
    ) async {
      await pumpScreen(tester, const AddStaffPage());

      // A required field's label is a `Text.rich` carrying the pink asterisk,
      // so it is matched by its span rather than as a whole string.
      expect(find.textContaining(StaffStrings.firstName), findsOneWidget);
      expect(find.textContaining(StaffStrings.lastName), findsOneWidget);
      expect(find.textContaining(StaffStrings.workEmail), findsOneWidget);
      expect(find.text(StaffStrings.workEmailHint), findsOneWidget);
      expect(find.text(StaffStrings.nextWhatTheyCanDo), findsOneWidget);
    });

    testWidgets('the wizard refuses to move on from a blank step one', (
      tester,
    ) async {
      await pumpScreen(tester, const AddStaffPage());

      await tester.tap(find.text(StaffStrings.nextWhatTheyCanDo));
      await tester.pump(settle);

      expect(find.text(StaffStrings.nameRequired), findsWidgets);
      expect(find.text(StaffStrings.invalidEmail), findsOneWidget);
      expect(find.text(StaffStrings.invalidPhone), findsOneWidget);
    });

    testWidgets('a filled step one leads to what they can do', (tester) async {
      await pumpScreen(tester, const AddStaffPage());

      await tester.enterText(find.byType(TextField).at(0), 'Aisha');
      await tester.enterText(find.byType(TextField).at(1), 'Noor');
      await tester.enterText(
        find.byType(TextField).at(2),
        'aisha.noor@mapleview.school',
      );
      await tester.enterText(find.byType(TextField).at(3), '(603) 555-0188');
      await tester.pump();

      await tester.tap(find.text(StaffStrings.nextWhatTheyCanDo));
      await tester.pump(settle);

      expect(find.textContaining(StaffStrings.role), findsWidgets);
      expect(find.text(StaffStrings.roleHint), findsOneWidget);
      expect(find.text(StaffStrings.pickDesignation), findsWidgets);
      expect(find.text(StaffStrings.nextTheirShifts), findsOneWidget);
    });

    testWidgets('there is no PIN field anywhere in the wizard', (tester) async {
      await pumpScreen(tester, const AddStaffPage());

      expect(find.text(StaffStrings.signInPin), findsNothing);
      expect(find.textContaining('PIN'), findsNothing);
    });
  });
}
