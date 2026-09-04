import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/features/staff/presentation/pages/edit_staff_page.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

import 'harness.dart';

void main() {
  group('the edit form behind 6c', () {
    useSource(const PreviewStaffSource());

    testWidgets('seeds the fields from the record', (tester) async {
      await pumpScreen(tester, const EditStaffPage(staffId: 'dana'));

      expect(find.text(StaffStrings.editTitle), findsOneWidget);
      expect(find.text('Dana'), findsOneWidget);
      expect(find.text('Whitfield'), findsOneWidget);
      expect(find.text('Nashua'), findsOneWidget);
      expect(find.text(AppStrings.save), findsOneWidget);
    });

    testWidgets('says out loud what an Admin sets and this form does not', (
      tester,
    ) async {
      await pumpScreen(tester, const EditStaffPage(staffId: 'dana'));

      expect(find.text(StaffStrings.adminOnlyNote), findsOneWidget);
      expect(find.textContaining(StaffStrings.designation), findsOneWidget);
    });

    testWidgets('refuses a phone number that is not ten digits', (
      tester,
    ) async {
      await pumpScreen(tester, const EditStaffPage(staffId: 'dana'));

      await tester.enterText(find.byType(TextField).at(3), '123');
      await tester.pump();
      await tester.tap(find.text(AppStrings.save));
      await tester.pump(settle);

      expect(find.text(StaffStrings.invalidPhone), findsOneWidget);
    });
  });

  group('when the record cannot be reached', () {
    useSource(const FailingStaffSource());

    testWidgets('says so, with one way to try again', (tester) async {
      await pumpScreen(tester, const EditStaffPage(staffId: 'dana'));

      expect(find.text(StaffStrings.couldNotReachTitle), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
    });
  });
}
