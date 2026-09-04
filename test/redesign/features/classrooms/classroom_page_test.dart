import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/classroom_page.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

void main() {
  group('ClassroomPage · an Admin', () {
    useSource(const PreviewClassroomsSource());

    testWidgets('7c heads the classroom and opens on its roster', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const ClassroomPage(classroomId: PreviewClassroomsSource.sunflowerId),
      );

      expect(find.text('Sunflower'), findsOneWidget);
      expect(find.text(ClassroomsStrings.classroomProfile), findsOneWidget);
      expect(find.text(ClassroomsStrings.tileStudentsIn), findsOneWidget);
      expect(find.text(ClassroomsStrings.tileStaffOnDuty), findsOneWidget);
      expect(find.text(ClassroomsStrings.placesFilled(23, 26)), findsOneWidget);

      expect(find.text(ClassroomsStrings.tabStudents), findsOneWidget);
      expect(find.text(ClassroomsStrings.tabStaff), findsOneWidget);
      expect(find.text(ClassroomsStrings.tabNotes), findsOneWidget);

      expect(find.text('Aria Rowan'), findsOneWidget);
      expect(find.text(ClassroomsStrings.showingAll(14)), findsOneWidget);
      expect(find.text(ClassroomsStrings.select), findsOneWidget);
    });

    testWidgets('the Staff tab says the ratio in counts', (tester) async {
      await pumpScreen(
        tester,
        const ClassroomPage(classroomId: PreviewClassroomsSource.sunflowerId),
      );

      await tester.tap(find.text(ClassroomsStrings.tabStaff));
      await tester.pump();

      expect(
        find.text(ClassroomsStrings.staffForStudents(3, 14, 2)),
        findsOneWidget,
      );
      expect(find.text('Dana Whitfield'), findsOneWidget);
      expect(find.text(ClassroomsStrings.assignStaff), findsOneWidget);
    });

    testWidgets('the Notes tab carries the thread and its composer', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const ClassroomPage(classroomId: PreviewClassroomsSource.sunflowerId),
      );

      await tester.tap(find.text(ClassroomsStrings.tabNotes));
      await tester.pump();

      expect(find.text(ClassroomsStrings.today), findsOneWidget);
      expect(find.text(ClassroomsStrings.writeNote), findsOneWidget);
      expect(
        find.text(ClassroomsStrings.newCount(2).toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('7j draws a classroom with nobody on the roll', (tester) async {
      await pumpScreen(
        tester,
        const ClassroomPage(classroomId: PreviewClassroomsSource.willowId),
      );

      expect(find.text('Willow'), findsOneWidget);
      expect(find.text(ClassroomsStrings.nobodyHereTitle), findsOneWidget);
      expect(find.text(ClassroomsStrings.assignStudents), findsWidgets);
    });
  });

  group('ClassroomPage · a teacher', () {
    useSource(const PreviewClassroomsSource());

    testWidgets('7e locks the roster until they are on the clock', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const ClassroomPage(
          classroomId: PreviewClassroomsSource.sunflowerId,
          isOwn: true,
        ),
        user: DemoData.staff,
      );

      expect(find.text(ClassroomsStrings.yourClassroom), findsOneWidget);
      expect(find.text(ClassroomsStrings.notClockedIn), findsOneWidget);
      expect(find.text(ClassroomsStrings.clockInNow), findsOneWidget);
      expect(find.text(ClassroomsStrings.lockedTitle), findsOneWidget);
      expect(find.text(ClassroomsStrings.tabStaff), findsNothing);
      expect(find.text(ClassroomsStrings.noStaffTabNote), findsOneWidget);

      await tester.tap(find.text(ClassroomsStrings.clockInNow));
      await tester.pump();

      expect(find.text(ClassroomsStrings.lockedTitle), findsNothing);
      expect(find.text(ClassroomsStrings.notClockedIn), findsNothing);
    });
  });

  group('ClassroomPage · nothing reachable', () {
    useSource(const FailingClassroomsSource());

    testWidgets('7j says so and offers a retry', (tester) async {
      await pumpScreen(
        tester,
        const ClassroomPage(classroomId: PreviewClassroomsSource.sunflowerId),
      );

      expect(find.text(ClassroomsStrings.couldNotReachTitle), findsOneWidget);
      expect(find.text(ClassroomsStrings.tryAgain), findsOneWidget);
    });
  });
}
