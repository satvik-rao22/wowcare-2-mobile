import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/features/profile/presentation/pages/edit_profile_page.dart';

import 'profile_test_doubles.dart';
import 'profile_widget_harness.dart';

void main() {
  late FakeProfileSource source;

  setUp(() async {
    source = FakeProfileSource();
    await registerProfileWith(source);
  });

  group('EditProfilePage', () {
    testWidgets('13b: the form opens on the record, with Save on', (
      tester,
    ) async {
      await pumpScreen(tester, const EditProfilePage());

      expect(find.text('Edit My Profile'), findsOneWidget);
      expect(find.text('Marcus'), findsOneWidget);
      expect(find.text('Whitfield'), findsOneWidget);
      expect(find.text('Nashua'), findsOneWidget);
      expect(find.text('New Hampshire'), findsOneWidget);
      // Email and country are shown and refused rather than left out.
      expect(find.text('Cannot be edited'), findsOneWidget);
      expect(find.text('United States'), findsOneWidget);
      expect(
        find.text(
          'Your email is your sign-in. An Admin changes it on the web.',
        ),
        findsOneWidget,
      );
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('13b: an empty city is named on its own field', (tester) async {
      await pumpScreen(tester, const EditProfilePage());

      await tester.enterText(find.widgetWithText(TextField, 'Nashua'), '');
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(find.text('City is required'), findsOneWidget);
      expect(source.saved, isNull);
    });

    testWidgets('fixing the field clears the message', (tester) async {
      await pumpScreen(tester, const EditProfilePage());

      await tester.enterText(find.widgetWithText(TextField, 'Nashua'), '');
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);
      expect(find.text('City is required'), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(5), 'Manchester');
      await settle(tester);
      expect(find.text('City is required'), findsNothing);
    });

    testWidgets('a clean save writes the record', (tester) async {
      await pumpScreen(tester, const EditProfilePage());

      await tester.enterText(find.byType(TextField).first, 'Marc');
      await settle(tester);
      await tester.tap(find.text('Save'));
      await settle(tester);

      expect(source.saved?.firstName, 'Marc');
      await settleToast(tester);
    });

    testWidgets('a failed load offers Try again', (tester) async {
      source.throwsOnRead = true;
      await pumpScreen(tester, const EditProfilePage());

      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}
