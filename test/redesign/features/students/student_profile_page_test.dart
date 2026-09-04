import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/student_profile_page.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/person_card.dart';

import 'students_test_doubles.dart';
import 'students_widget_harness.dart';

void main() {
  late FakeStudentsSource source;

  setUp(() async {
    source = FakeStudentsSource();
    await registerStudentsWith(source);
  });

  Future<void> open(WidgetTester tester, {Persona persona = Persona.admin}) =>
      pumpScreen(
        tester,
        const StudentProfilePage(studentId: 'aria'),
        persona: persona,
      );

  /// Five tabs do not fit a phone, so one may have to be scrolled to first.
  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pump();
    await tester.tap(find.text(label));
    await settle(tester);
  }

  group('StudentProfilePage', () {
    testWidgets('opens on About, with the student in the header', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('Aria Rowan'), findsOneWidget);
      expect(find.text('Sunflower · 4 yrs 2 mo'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(find.text('About Aria'), findsOneWidget);
      expect(find.text('Active since 8 Sep 2025'), findsOneWidget);
      expect(find.text('Message family'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('every tab is there, and each draws its own record', (
      tester,
    ) async {
      await open(tester);
      for (final label in <String>[
        'Profile',
        'Health',
        'Attendance',
        'Dates',
        'Documents',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      await tapTab(tester, 'Documents');
      expect(find.text('Enrollment form'), findsOneWidget);
      expect(find.text('Add a document'), findsOneWidget);

      await tapTab(tester, 'Attendance');
      expect(find.text('AUGUST'), findsOneWidget);
      expect(find.text('13 days in · 1 absent · 91 hours'), findsOneWidget);
      expect(find.text('Thu 20 Aug'), findsOneWidget);

      await tapTab(tester, 'Dates');
      expect(find.text('Important dates'), findsOneWidget);
      expect(find.text('4 Sep 2025'), findsOneWidget);
    });

    testWidgets('Family shows who is called first', (tester) async {
      await open(tester);
      await tapTab(tester, 'Family');

      expect(find.byType(PersonCard), findsOneWidget);
      expect(find.text('Nadia Rowan'), findsOneWidget);
      expect(find.text('Emergency contact'), findsOneWidget);
      expect(find.text('Add a parent'), findsOneWidget);
    });

    testWidgets('the Immunization tab leads with the overdue one', (
      tester,
    ) async {
      await open(tester);
      await tapTab(tester, 'Health');
      await tapTab(tester, 'Immunization');

      expect(
        find.text(
          'Varicella is overdue. It was due on 1 July, and no exemption '
          'is on file.',
        ),
        findsOneWidget,
      );
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('a staff member reads it, and no Edit key is offered', (
      tester,
    ) async {
      await open(tester, persona: Persona.staff);

      expect(find.text('About Aria'), findsOneWidget);
      expect(find.text('Edit'), findsNothing);
    });

    testWidgets('a failed fetch offers Try again', (tester) async {
      source.throwsOnRead = true;
      await open(tester);

      expect(find.byType(ErrorState), findsOneWidget);
      expect(
        find.text("This student's record could not be loaded."),
        findsOneWidget,
      );
    });
  });
}
