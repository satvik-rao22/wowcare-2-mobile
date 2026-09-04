import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/widgets/app_chip.dart';
import 'package:wowcare/redesign/core/widgets/app_fab.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/pages/attendance_page.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_row.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_select_key.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/day_picker_sheet.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/guardian_child_card.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/record_actions_sheet.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/self_shift_card.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/staff_gap_card.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/students_locked_card.dart';
import 'package:wowcare/redesign/features/attendance/source/attendance_source.dart';

import 'attendance_test_doubles.dart';
import 'attendance_widget_harness.dart';

void main() {
  late FakeAttendanceSource source;

  setUp(() async {
    source = FakeAttendanceSource();
    await registerAttendanceWith(source);
  });

  group('AttendancePage · 4a', () {
    testWidgets('draws the day, its groups and their counts', (tester) async {
      await pumpScreen(tester, const AttendancePage());

      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Today · Thu 20 Aug'), findsOneWidget);
      expect(find.byType(AttendanceRow), findsNWidgets(4));

      expect(find.text('SUNFLOWER'), findsOneWidget);
      expect(find.text('BLUEBELL'), findsOneWidget);
      expect(
        find.textContaining('1 of 2 in · 1 staff · In Ratio'),
        findsOneWidget,
      );
    });

    testWidgets('a row carries the method and who took it', (tester) async {
      await pumpScreen(tester, const AttendancePage());

      expect(find.text('Sunflower · in 8:12 · PIN'), findsOneWidget);
      expect(find.text('In 8:12'), findsOneWidget);
      expect(find.text('Not Marked'), findsWidgets);
      expect(find.text('Out 12:07'), findsOneWidget);
    });

    testWidgets('a tap opens the record in place, not the sheet', (
      tester,
    ) async {
      await pumpScreen(tester, const AttendancePage());
      await tester.tap(find.text('Aria Rowan'));
      await settle(tester);

      expect(find.byType(RecordActionsSheet), findsNothing);
      expect(find.text('Signed In'), findsWidgets);
      expect(find.text('8:12 · PIN'), findsOneWidget);
      expect(find.text('Dana Whitfield'), findsOneWidget);
      expect(find.text('More actions'), findsOneWidget);
    });

    testWidgets('a signed-out record works its own duration out', (
      tester,
    ) async {
      await pumpScreen(tester, const AttendancePage());
      await tester.tap(find.text('Rumi Tanaka'));
      await settle(tester);

      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('4h 5m'), findsOneWidget);
    });

    testWidgets('isExpectedToday is on the row and in the record', (
      tester,
    ) async {
      await pumpScreen(tester, const AttendancePage());

      expect(find.text('Sunflower · not expected today'), findsOneWidget);
      await tester.tap(find.text('Jonah Park'));
      await settle(tester);
      expect(find.text('Not today'), findsOneWidget);
    });

    testWidgets('More actions opens the sheet, with its refusals dimmed', (
      tester,
    ) async {
      await pumpScreen(tester, const AttendancePage());
      await tester.tap(find.text('Aria Rowan'));
      await settle(tester);
      await tester.tap(find.text('More actions'));
      await settle(tester);

      expect(find.byType(RecordActionsSheet), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Mark Absent'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Edit times'), findsOneWidget);
      expect(find.text('Open profile'), findsOneWidget);
      expect(find.textContaining('Mark Absent is off'), findsOneWidget);
    });

    testWidgets('an absent record offers Override Sign In', (tester) async {
      await pumpScreen(tester, const AttendancePage());
      await tester.tap(find.text('Felix Duarte'));
      await settle(tester);
      await tester.tap(find.text('More actions'));
      await settle(tester);

      expect(find.text('Override Sign In'), findsOneWidget);
      expect(find.text('Undo absence'), findsOneWidget);
    });

    testWidgets('the FAB enters select mode rather than opening a form', (
      tester,
    ) async {
      await pumpScreen(tester, const AttendancePage());
      expect(find.byType(AppFab), findsOneWidget);

      await tester.tap(find.byType(AppFab));
      await settle(tester);

      expect(find.text('Select students'), findsOneWidget);
      expect(find.text('Pick who arrived'), findsOneWidget);

      await tester.tap(find.text('Aria Rowan'));
      await settle(tester);
      expect(find.text('1 selected'), findsOneWidget);
      expect(find.text('Sign In 1 student'), findsOneWidget);
    });

    testWidgets('the day strip opens the day sheet', (tester) async {
      await pumpScreen(tester, const AttendancePage());
      await tester.tap(find.text('Today · Thu 20 Aug'));
      await settle(tester);

      expect(find.byType(DayPickerSheet), findsOneWidget);
      expect(find.text('Which day?'), findsOneWidget);
      expect(find.text('A range of days'), findsOneWidget);
      expect(find.text('Show this day'), findsOneWidget);
    });

    testWidgets('a chip narrows the list', (tester) async {
      await pumpScreen(tester, const AttendancePage());
      final chip = find.widgetWithText(AppChip, 'Absent');
      await tester.ensureVisible(chip);
      await settle(tester);
      await tester.tap(chip);
      await settle(tester);

      expect(find.byType(AttendanceRow), findsOneWidget);
      expect(find.text('Felix Duarte'), findsOneWidget);
    });
  });

  group('AttendancePage · 4e states', () {
    testWidgets('a failed day is a Try again, not an empty list', (
      tester,
    ) async {
      source.throwsOnRead = true;
      await pumpScreen(tester, const AttendancePage());

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.byType(AttendanceRow), findsNothing);
    });

    testWidgets('offline keeps the day and says it is read only', (
      tester,
    ) async {
      source.dayResult = const AttendanceDayOffline(
        snapshot: FakeAttendanceSource.defaultSnapshot,
        asOfLabel: '8:02 this morning',
      );
      await pumpScreen(tester, const AttendancePage());

      expect(find.text('TODAY COULD NOT LOAD'), findsOneWidget);
      expect(find.textContaining('8:02 this morning'), findsOneWidget);
      expect(find.text('Keep reading the cache'), findsOneWidget);
      expect(find.byType(AppFab), findsNothing, reason: 'read only');
    });

    testWidgets('nobody on the roll is its own sentence', (tester) async {
      source.dayResult = const AttendanceDayLoaded(AttendanceSnapshot());
      await pumpScreen(tester, const AttendancePage());

      expect(find.text('Nobody on the roll yet'), findsOneWidget);
    });
  });

  group('AttendancePage · 4d the staff lens', () {
    setUp(() {
      source.dayResult = AttendanceDayLoaded(
        AttendanceSnapshot(
          rows: const <AttendanceRecord>[
            FakeAttendanceSource.aria,
            FakeAttendanceSource.jonah,
          ],
          classroomNames: const <String>['Sunflower'],
          enrolled: const <String, int>{'Sunflower': 2},
          selfShift: source.selfShift,
        ),
      );
    });

    testWidgets('their own shift comes first, and the classroom is locked', (
      tester,
    ) async {
      await pumpScreen(tester, const AttendancePage(), persona: Persona.staff);

      expect(find.byType(SelfShiftCard), findsOneWidget);
      expect(find.text('Not signed in yet'), findsOneWidget);
      expect(find.text('Sign myself in'), findsOneWidget);
      expect(find.byType(StudentsLockedCard), findsOneWidget);
      expect(find.byType(AppFab), findsNothing);
    });

    testWidgets('signing themselves in unlocks the classroom', (tester) async {
      await pumpScreen(tester, const AttendancePage(), persona: Persona.staff);
      await tester.tap(find.text('Sign myself in'));
      await settle(tester);

      expect(find.text('Signed In 7:48'), findsOneWidget);
      expect(find.byType(StudentsLockedCard), findsNothing);
      expect(find.byType(AppFab), findsOneWidget);
    });

    testWidgets('the Select key is there and dead until they sign in', (
      tester,
    ) async {
      await pumpScreen(tester, const AttendancePage(), persona: Persona.staff);

      final key = tester.widget<AttendanceSelectKey>(
        find.byType(AttendanceSelectKey),
      );
      expect(key.onTap, isNull);
    });
  });

  group('AttendancePage · 4c the staff list', () {
    testWidgets('the cover card leads the staff list', (tester) async {
      source.dayResult = const AttendanceDayLoaded(
        FakeAttendanceSource.staffSnapshot,
      );
      await pumpScreen(tester, const AttendancePage());
      await tester.tap(find.text('Staff'));
      await settle(tester);

      expect(find.byType(StaffGapCard), findsOneWidget);
      expect(find.text('Bluebell needs 1 more staff at 11:30'), findsOneWidget);
      expect(find.text('Open Scheduling'), findsOneWidget);
      expect(find.text('ON SHIFT TODAY'), findsOneWidget);
      expect(find.text('Due 12:00'), findsOneWidget);
    });
  });

  group('AttendancePage · 4a the guardian lens', () {
    testWidgets('a guardian sees their own child and the month', (
      tester,
    ) async {
      source.dayResult = const AttendanceDayLoaded(
        FakeAttendanceSource.guardianSnapshot,
      );
      await pumpScreen(
        tester,
        const AttendancePage(),
        persona: Persona.guardian,
      );

      expect(find.byType(GuardianChildCard), findsOneWidget);
      expect(find.text("Aria's attendance"), findsOneWidget);
      expect(find.text('Aria is in'), findsOneWidget);
      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('13 days in · 1 absent · 91 hours'), findsOneWidget);
      expect(find.byType(AppFab), findsNothing);
      expect(find.byType(AttendanceSelectKey), findsNothing);
    });
  });
}
