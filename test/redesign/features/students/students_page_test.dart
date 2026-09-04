import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/app_fab.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/presentation/pages/students_page.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/select_mode_key.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/student_roster_row.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/students_edge_state.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';

import 'students_test_doubles.dart';
import 'students_widget_harness.dart';

void main() {
  late FakeStudentsSource source;

  setUp(() async {
    source = FakeStudentsSource();
    await registerStudentsWith(source);
  });

  group('StudentsPage', () {
    testWidgets('draws the roster, its counts and its classroom headers', (
      tester,
    ) async {
      await pumpScreen(tester, const StudentsPage());

      expect(find.text('Students'), findsOneWidget);
      expect(find.text('Aria Rowan'), findsOneWidget);
      expect(find.text('Rumi Tanaka'), findsOneWidget);
      expect(find.byType(StudentRosterRow), findsNWidgets(3));

      expect(find.text('3'), findsOneWidget, reason: 'active students');
      expect(find.text('Active students'), findsOneWidget);
      expect(find.text('Starting soon'), findsOneWidget);

      expect(find.text('SUNFLOWER'), findsOneWidget);
      expect(
        find.textContaining('2 students · 1 in · 1 not marked'),
        findsOneWidget,
      );
    });

    testWidgets('an admin gets the add key and select mode', (tester) async {
      await pumpScreen(tester, const StudentsPage());

      expect(find.byType(AppFab), findsOneWidget);
      expect(find.byType(SelectModeKey), findsOneWidget);
      expect(find.text('Select'), findsOneWidget);
    });

    testWidgets('a staff member gets neither, and is told why', (tester) async {
      await pumpScreen(tester, const StudentsPage(), persona: Persona.staff);

      expect(find.byType(AppFab), findsNothing);
      expect(find.byType(SelectModeKey), findsNothing);
      expect(
        find.textContaining('Adding, editing and deactivating students'),
        findsOneWidget,
      );
    });

    testWidgets('a guardian is refused with the view-only state', (
      tester,
    ) async {
      source.roster = const RosterRestricted();
      await pumpScreen(tester, const StudentsPage(), persona: Persona.guardian);

      expect(find.text('Students are not shared with you'), findsOneWidget);
      expect(find.textContaining('only have view access'), findsOneWidget);
      expect(find.byType(StudentRosterRow), findsNothing);
    });

    testWidgets('a school with nobody on it invites the first student', (
      tester,
    ) async {
      source.roster = const RosterLoaded(RosterSnapshot());
      await pumpScreen(tester, const StudentsPage());

      expect(find.byType(StudentsEdgeState), findsOneWidget);
      expect(find.text('No students yet'), findsOneWidget);
      expect(find.text('Bulk import is on the web'), findsOneWidget);
    });

    testWidgets('offline says what is on the phone and when it is from', (
      tester,
    ) async {
      source.roster = RosterOffline(
        snapshot: FakeStudentsSource.defaultSnapshot,
        asOfLabel: '8:12 this morning',
      );
      await pumpScreen(tester, const StudentsPage());

      expect(
        find.textContaining('as it was at 8:12 this morning'),
        findsOneWidget,
      );
      expect(find.text('Waiting for a signal'), findsOneWidget);
      expect(find.textContaining('The 3 students saved'), findsOneWidget);
    });

    testWidgets('a failed fetch offers Try again', (tester) async {
      source.throwsOnRead = true;
      await pumpScreen(tester, const StudentsPage());

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('The roster could not be loaded.'), findsOneWidget);
    });

    testWidgets('tapping a row opens it in place', (tester) async {
      await pumpScreen(tester, const StudentsPage());
      expect(find.text('Attendance today'), findsNothing);

      await tester.tap(find.text('Aria Rowan'));
      await settle(tester);

      expect(find.text('Attendance today'), findsOneWidget);
      expect(find.text('Signed In 8:12'), findsOneWidget);
      expect(find.text('Open profile'), findsOneWidget);
      expect(find.text('More actions'), findsOneWidget);
    });

    testWidgets('the filter sheet applies and the roster narrows', (
      tester,
    ) async {
      await pumpScreen(tester, const StudentsPage());

      await tester.tap(find.byIcon(AppIcons.filter));
      await settle(tester);
      expect(find.text('Filter students'), findsOneWidget);
      expect(find.text('STATUS · PICK ONE'), findsOneWidget);
      expect(find.text('Active 3'), findsOneWidget);
      expect(find.text('Any tag'), findsOneWidget);

      await tester.ensureVisible(find.text('Bluebell'));
      await tester.pump();
      await tester.tap(find.text('Bluebell'));
      await settle(tester);
      await tester.tap(find.text('Apply'));
      await settle(tester);

      expect(find.text('Rumi Tanaka'), findsOneWidget);
      expect(find.text('Aria Rowan'), findsNothing);
    });

    testWidgets('More actions offers the five doors and Open profile', (
      tester,
    ) async {
      await pumpScreen(tester, const StudentsPage());
      await tester.tap(find.text('Aria Rowan'));
      await settle(tester);
      await tester.tap(find.text('More actions'));
      await settle(tester);

      expect(find.text('Sign In or Sign Out'), findsOneWidget);
      expect(find.text('Add an activity'), findsOneWidget);
      expect(find.text('Message the family'), findsOneWidget);
      expect(find.text('Edit details'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
      expect(find.text('Open profile'), findsWidgets);
    });

    testWidgets('Deactivate asks what it costs before it does it', (
      tester,
    ) async {
      await pumpScreen(tester, const StudentsPage());
      await tester.tap(find.text('Aria Rowan'));
      await settle(tester);
      await tester.tap(find.text('More actions'));
      await settle(tester);
      await tester.ensureVisible(find.text('Deactivate'));
      await tester.pump();
      await tester.tap(find.text('Deactivate'));
      await settle(tester);

      expect(find.text('Deactivate Aria?'), findsOneWidget);
      expect(find.text('WHAT CHANGES TODAY'), findsOneWidget);
      expect(find.text('Records, documents, history'), findsOneWidget);
      expect(find.text('Keep them active'), findsOneWidget);
      expect(source.deactivated, isNull);

      await tester.tap(find.text('Deactivate Aria'));
      await settle(tester);
      expect(source.deactivated, 'aria');
      await settleToast(tester);
    });

    testWidgets('select mode docks a key that is off until a row is picked', (
      tester,
    ) async {
      await pumpScreen(tester, const StudentsPage());
      await tester.tap(find.text('Select'));
      await settle(tester);

      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Pick students to act on'), findsOneWidget);

      await tester.tap(find.text('Aria Rowan'));
      await settle(tester);
      expect(find.text('Sign In 1 student'), findsOneWidget);
    });
  });
}
