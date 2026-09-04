import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/widgets/app_text_field.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/pages/create_classroom_page.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

import 'harness.dart';

void main() {
  group('CreateClassroomPage', () {
    useSource(const PreviewClassroomsSource());

    testWidgets('the form asks for the four fields a classroom needs', (
      tester,
    ) async {
      await pumpScreen(tester, const CreateClassroomPage());

      expect(find.text(ClassroomsStrings.newClassroomTitle), findsOneWidget);
      expect(find.text(ClassroomsStrings.saveClassroom), findsOneWidget);
      expect(find.byType(AppTextField), findsNWidgets(5));

      // A field's label is rich text, because of its pink asterisk.
      for (final label in <String>[
        ClassroomsStrings.fieldName,
        ClassroomsStrings.fieldAgeFrom,
        ClassroomsStrings.fieldAgeTo,
        ClassroomsStrings.fieldCapacity,
        ClassroomsStrings.fieldRatio,
      ]) {
        expect(
          find.textContaining(label, findRichText: true),
          findsOneWidget,
          reason: label,
        );
      }
      expect(find.text(ClassroomsStrings.fieldRatioHelp), findsOneWidget);
    });

    testWidgets('an empty form says what is missing, under the field', (
      tester,
    ) async {
      await pumpScreen(tester, const CreateClassroomPage());

      await tester.tap(find.text(ClassroomsStrings.saveClassroom));
      await tester.pump();

      expect(find.text(ClassroomsStrings.nameRequired), findsOneWidget);
      expect(find.text(ClassroomsStrings.capacityInvalid), findsOneWidget);
      expect(find.text(ClassroomsStrings.ratioInvalid), findsOneWidget);
    });

    testWidgets('a filled form creates the classroom and says its name', (
      tester,
    ) async {
      await pumpScreen(tester, const CreateClassroomPage());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Rosemary');
      await tester.enterText(fields.at(3), '16');
      await tester.enterText(fields.at(4), '8');
      await tester.pump();

      await tester.tap(find.text(ClassroomsStrings.saveClassroom));
      await tester.pump(settle);
      await tester.pump();

      expect(
        find.text(ClassroomsStrings.classroomCreated('Rosemary')),
        findsOneWidget,
      );
      await settleToast(tester);
    });
  });
}
