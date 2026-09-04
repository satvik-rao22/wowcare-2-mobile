import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/assign_page.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

void main() {
  group('AssignPage · students', () {
    useSource(const PreviewClassroomsSource());

    testWidgets('7g opens on step one with nothing picked', (tester) async {
      await pumpScreen(
        tester,
        const AssignPage(
          classroomId: PreviewClassroomsSource.sunflowerId,
          kind: AssignKind.students,
        ),
      );

      expect(find.text(ClassroomsStrings.assignStudentsTitle), findsOneWidget);
      expect(
        find.text(ClassroomsStrings.toClassroom('Sunflower')),
        findsOneWidget,
      );
      expect(find.text(ClassroomsStrings.stepPickStudents), findsOneWidget);
      expect(find.text(ClassroomsStrings.stepReview), findsOneWidget);
      expect(find.text(ClassroomsStrings.pickAStudentFirst), findsOneWidget);
      expect(find.text('Rumi Tanaka'), findsOneWidget);
    });

    testWidgets('picking somebody moves the key on to the review step', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const AssignPage(
          classroomId: PreviewClassroomsSource.sunflowerId,
          kind: AssignKind.students,
        ),
      );

      await tester.tap(find.text('Rumi Tanaka'));
      await tester.pump();
      expect(find.text(ClassroomsStrings.reviewStudents(1)), findsOneWidget);

      await tester.tap(find.text(ClassroomsStrings.reviewStudents(1)));
      await tester.pump();

      expect(
        find.text(ClassroomsStrings.whatThisChanges.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(ClassroomsStrings.goesTo('Sunflower', 24, 26)),
        findsOneWidget,
      );
      expect(find.text(ClassroomsStrings.immediately), findsOneWidget);
      expect(find.text(ClassroomsStrings.assignNStudents(1)), findsOneWidget);
    });
  });

  group('AssignPage · staff', () {
    useSource(const PreviewClassroomsSource());

    testWidgets('7h says what the classroom holds and leaves shifts alone', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const AssignPage(
          classroomId: PreviewClassroomsSource.sunflowerId,
          kind: AssignKind.staff,
        ),
      );

      expect(find.text(ClassroomsStrings.assignStaffTitle), findsOneWidget);
      expect(find.text(ClassroomsStrings.stepPickStaff), findsOneWidget);

      await tester.tap(find.text('Priya Raman'));
      await tester.pump();
      await tester.tap(find.text(ClassroomsStrings.reviewStaff(1)));
      await tester.pump();

      expect(find.text(ClassroomsStrings.becomes(3, 4)), findsOneWidget);
      expect(find.text(ClassroomsStrings.holdsUpTo(32)), findsOneWidget);
      expect(find.text(ClassroomsStrings.unchanged), findsOneWidget);
      expect(find.text(ClassroomsStrings.assignNStaff(1)), findsOneWidget);
    });
  });

  group('AssignPage · nothing reachable', () {
    useSource(const FailingClassroomsSource());

    testWidgets('it says so and offers a retry', (tester) async {
      await pumpScreen(
        tester,
        const AssignPage(
          classroomId: PreviewClassroomsSource.sunflowerId,
          kind: AssignKind.students,
        ),
      );

      expect(find.text(ClassroomsStrings.tryAgain), findsOneWidget);
    });
  });
}
