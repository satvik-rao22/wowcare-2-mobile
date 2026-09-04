import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/add_student_page.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/wizard_step_list.dart';

import 'students_test_doubles.dart';
import 'students_widget_harness.dart';

/// A field's label is rich text, because it carries the pink required
/// asterisk, so it is found by the widget rather than by its words.
Finder fieldLabel(String text) =>
    find.byWidgetPredicate((w) => w is FieldLabel && w.text == text);

void main() {
  late FakeStudentsSource source;

  setUp(() async {
    source = FakeStudentsSource(
      guardians: const <GuardianOption>[
        GuardianOption(
          id: 'wei',
          name: 'Wei Chen',
          email: 'wei.chen@example.com',
        ),
      ],
    );
    await registerStudentsWith(source);
  });

  group('AddStudentPage', () {
    testWidgets('opens on step one with all three steps in view', (
      tester,
    ) async {
      await pumpScreen(tester, const AddStudentPage());

      expect(find.text('Add a student'), findsOneWidget);
      expect(find.byType(WizardStepList), findsOneWidget);
      expect(find.text('The student'), findsOneWidget);
      expect(find.text('A parent'), findsOneWidget);
      expect(find.text('The schedule'), findsOneWidget);
      expect(find.text('Optional'), findsNWidgets(2));

      expect(fieldLabel('First name'), findsOneWidget);
      expect(find.text('Pick a classroom'), findsOneWidget);
      expect(find.text('Next, a parent'), findsOneWidget);
    });

    testWidgets('step one refuses to be left with fields missing', (
      tester,
    ) async {
      await pumpScreen(tester, const AddStudentPage());
      await tester.tap(find.text('Next, a parent'));
      await settle(tester);

      expect(find.text('First name is required'), findsOneWidget);
      expect(find.text('Last name is required'), findsOneWidget);
      expect(find.text('Classroom is required'), findsOneWidget);
      expect(find.text('Next, a parent'), findsOneWidget);
    });

    testWidgets('a filled step one moves on to the parent, which can be '
        'skipped', (tester) async {
      await pumpScreen(tester, const AddStudentPage());

      // An upcoming student, so the date the form asks for is the school
      // start rather than a birth date, and today satisfies it.
      await tester.tap(find.text('Upcoming'));
      await settle(tester);
      expect(fieldLabel('School start date'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(0), 'Bo');
      await tester.enterText(find.byType(TextField).at(1), 'Chen');
      await settle(tester);

      await tester.ensureVisible(find.text('Pick a classroom'));
      await tester.pump();
      await tester.tap(find.text('Pick a classroom'));
      await settle(tester);
      await tester.tap(find.text('Bluebell').last);
      await settle(tester);

      await tester.ensureVisible(find.text('Pick a date').last);
      await tester.pump();
      await tester.tap(find.text('Pick a date').last);
      await settle(tester);
      await tester.tap(find.text('OK'));
      await settle(tester);

      await tester.tap(find.text('Next, a parent'));
      await settle(tester);

      expect(fieldLabel('Where the parent comes from'), findsOneWidget);
      expect(find.text('Skip, add a parent later'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });
  });
}
