import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/classrooms_page.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/classroom_card.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

void main() {
  group('ClassroomsPage · the floor', () {
    useSource(const PreviewClassroomsSource());

    testWidgets('7a draws the school, the chips and every classroom', (
      tester,
    ) async {
      await pumpScreen(tester, const ClassroomsPage());

      expect(find.text(ClassroomsStrings.title), findsOneWidget);
      expect(find.text(ClassroomsStrings.studentsIn(47)), findsOneWidget);
      expect(
        find.text(ClassroomsStrings.staffOnDutyAcross(12, 5)),
        findsOneWidget,
      );
      expect(
        find.text(ClassroomsStrings.enrolledOfPlaces(78, 96, 81)),
        findsOneWidget,
      );
      expect(find.text(ClassroomsStrings.chipAll), findsOneWidget);
      expect(find.text('Bluebell'), findsOneWidget);
      expect(find.text(ClassroomsStrings.createClassroom), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('Willow'),
        find.byType(Scrollable).first,
        const Offset(0, -200),
      );
      expect(find.text('Sunflower'), findsOneWidget);
    });

    testWidgets('the short classroom leads, and says what it needs', (
      tester,
    ) async {
      await pumpScreen(tester, const ClassroomsPage());

      expect(find.text(ClassroomsStrings.classroomsOver(1)), findsOneWidget);
      expect(find.text(ClassroomsStrings.moreStaff(1)), findsOneWidget);
      expect(find.text(ClassroomsStrings.needsMoreStaff(1)), findsOneWidget);
      final first = tester.widget<ClassroomCard>(
        find.byType(ClassroomCard).first,
      );
      expect(first.classroom.name, 'Bluebell');
    });

    testWidgets('a teacher never sees the list, only their own classroom', (
      tester,
    ) async {
      await pumpScreen(tester, const ClassroomsPage(), user: DemoData.staff);

      expect(find.text(ClassroomsStrings.yourClassroom), findsOneWidget);
      expect(find.text(ClassroomsStrings.chipAll), findsNothing);
    });
  });

  group('ClassroomsPage · no classrooms', () {
    useSource(const EmptyClassroomsSource());

    testWidgets('7b offers the one key that fixes it', (tester) async {
      await pumpScreen(tester, const ClassroomsPage());

      expect(find.text(ClassroomsStrings.noClassroomsTitle), findsOneWidget);
      expect(find.text(ClassroomsStrings.noClassroomsBody), findsOneWidget);
      expect(find.text(ClassroomsStrings.createClassroom), findsOneWidget);
    });
  });

  group('ClassroomsPage · nothing reachable', () {
    useSource(const FailingClassroomsSource());

    testWidgets('7j says so and offers a retry', (tester) async {
      await pumpScreen(tester, const ClassroomsPage());

      expect(
        find.text(ClassroomsStrings.couldNotReachListTitle),
        findsOneWidget,
      );
      expect(find.text(ClassroomsStrings.tryAgain), findsOneWidget);
    });
  });
}
