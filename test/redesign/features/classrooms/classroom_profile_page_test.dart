import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/classroom_profile_page.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

void main() {
  group('ClassroomProfilePage', () {
    useSource(const PreviewClassroomsSource());

    testWidgets('7f draws the record, its places and its photo well', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const ClassroomProfilePage(
          classroomId: PreviewClassroomsSource.sunflowerId,
        ),
      );

      expect(find.text(ClassroomsStrings.classroomProfile), findsOneWidget);
      expect(find.text(ClassroomsStrings.editClassroom), findsOneWidget);
      expect(find.text('Sunflower'), findsOneWidget);
      expect(
        find.text(ClassroomsStrings.leads('Dana Whitfield')),
        findsOneWidget,
      );

      expect(find.text(ClassroomsStrings.places.toUpperCase()), findsOneWidget);
      expect(find.text(ClassroomsStrings.placesLeft(3)), findsOneWidget);
      expect(find.text(ClassroomsStrings.enrolledNow), findsOneWidget);
      expect(find.text(ClassroomsStrings.startingSoon), findsOneWidget);

      expect(find.text(ClassroomsStrings.addPhotoTitle), findsOneWidget);
      expect(find.text(ClassroomsStrings.startUpload), findsOneWidget);
    });

    testWidgets('the day, the moves and the school below it', (tester) async {
      await pumpScreen(
        tester,
        const ClassroomProfilePage(
          classroomId: PreviewClassroomsSource.sunflowerId,
        ),
      );

      final scroller = find.byType(Scrollable).first;

      for (final label in <String>[
        ClassroomsStrings.studentsExpectedToday.toUpperCase(),
        ClassroomsStrings.staffExpectedToday.toUpperCase(),
        ClassroomsStrings.movements.toUpperCase(),
        ClassroomsStrings.acrossTheCenter.toUpperCase(),
      ]) {
        await tester.dragUntilVisible(
          find.text(label),
          scroller,
          const Offset(0, -120),
        );
        expect(find.text(label), findsOneWidget, reason: label);
      }

      expect(find.text(ClassroomsStrings.totalPlaces), findsOneWidget);
      expect(find.text(ClassroomsStrings.columnRatio), findsOneWidget);
    });
  });

  group('ClassroomProfilePage · nothing reachable', () {
    useSource(const FailingClassroomsSource());

    testWidgets('7j says so and offers a retry', (tester) async {
      await pumpScreen(
        tester,
        const ClassroomProfilePage(
          classroomId: PreviewClassroomsSource.sunflowerId,
        ),
      );

      expect(find.text(ClassroomsStrings.couldNotReachTitle), findsOneWidget);
      expect(find.text(ClassroomsStrings.tryAgain), findsOneWidget);
    });
  });
}
