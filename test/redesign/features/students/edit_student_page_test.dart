import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/edit_student_page.dart';

import 'students_test_doubles.dart';
import 'students_widget_harness.dart';

void main() {
  late FakeStudentsSource source;

  setUp(() async {
    source = FakeStudentsSource();
    await registerStudentsWith(source);
  });

  group('EditStudentPage', () {
    testWidgets('opens on the record, with Save on', (tester) async {
      await pumpScreen(tester, const EditStudentPage(studentId: 'aria'));

      expect(find.text("Edit Aria's details"), findsOneWidget);
      expect(find.text('Aria'), findsOneWidget);
      expect(find.text('Rowan'), findsOneWidget);
      expect(find.text('Sunflower'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.textContaining('changes both classrooms'), findsOneWidget);
    });

    testWidgets('an empty first name is named, and Save goes off', (
      tester,
    ) async {
      await pumpScreen(tester, const EditStudentPage(studentId: 'aria'));

      await tester.enterText(find.byType(TextField).first, '');
      await settle(tester);
      await tester.tap(find.text('Save changes'));
      await settle(tester);

      expect(
        find.text('One field needs a look before this can save.'),
        findsOneWidget,
      );
      expect(find.text('First name is required'), findsOneWidget);
      expect(source.updated, isNull);
    });

    testWidgets('fixing the field clears the message', (tester) async {
      await pumpScreen(tester, const EditStudentPage(studentId: 'aria'));

      await tester.enterText(find.byType(TextField).first, '');
      await settle(tester);
      await tester.tap(find.text('Save changes'));
      await settle(tester);
      expect(find.text('First name is required'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Aria');
      await settle(tester);
      expect(find.text('First name is required'), findsNothing);
    });

    testWidgets('a clean save writes the record', (tester) async {
      await pumpScreen(tester, const EditStudentPage(studentId: 'aria'));

      await tester.enterText(find.byType(TextField).first, 'Arya');
      await settle(tester);
      await tester.tap(find.text('Save changes'));
      await settle(tester);

      expect(source.updated?.firstName, 'Arya');
      await settleToast(tester);
    });

    testWidgets('a failed load offers Try again', (tester) async {
      source.throwsOnRead = true;
      await pumpScreen(tester, const EditStudentPage(studentId: 'aria'));

      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}
