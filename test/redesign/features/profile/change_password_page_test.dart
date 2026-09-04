import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/features/profile/presentation/pages/change_password_page.dart';

import 'profile_test_doubles.dart';
import 'profile_widget_harness.dart';

void main() {
  late FakeProfileSource source;

  setUp(() async {
    source = FakeProfileSource();
    await registerProfileWith(source);
  });

  group('ChangePasswordPage', () {
    testWidgets('the three wells and the rule under the new one', (
      tester,
    ) async {
      await pumpScreen(tester, const ChangePasswordPage());

      expect(find.text('Change Password'), findsNWidgets(2));
      expect(find.textContaining('Current password'), findsOneWidget);
      expect(find.textContaining('New password'), findsOneWidget);
      expect(find.textContaining('Confirm new password'), findsOneWidget);
      expect(
        find.text('At least 8 characters and one special character.'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('an empty form is refused on the first press', (tester) async {
      await pumpScreen(tester, const ChangePasswordPage());

      await tester.tap(find.text('Change Password').last);
      await settle(tester);

      expect(find.text('Please enter your current password'), findsOneWidget);
      expect(find.text('Please enter a new password'), findsOneWidget);
      expect(source.changedTo, isNull);
    });

    testWidgets('a confirmation that does not match is named', (tester) async {
      await pumpScreen(tester, const ChangePasswordPage());

      await tester.enterText(find.byType(TextField).at(0), 'oldpass!1');
      await tester.enterText(find.byType(TextField).at(1), 'newpass!1');
      await tester.enterText(find.byType(TextField).at(2), 'newpass!2');
      await settle(tester);
      await tester.tap(find.text('Change Password').last);
      await settle(tester);

      expect(
        find.text('New password and confirm password do not match'),
        findsOneWidget,
      );
      expect(source.changedTo, isNull);
    });

    testWidgets('a clean change is sent', (tester) async {
      await pumpScreen(tester, const ChangePasswordPage());

      await tester.enterText(find.byType(TextField).at(0), 'oldpass!1');
      await tester.enterText(find.byType(TextField).at(1), 'newpass!1');
      await tester.enterText(find.byType(TextField).at(2), 'newpass!1');
      await settle(tester);
      await tester.tap(find.text('Change Password').last);
      await settle(tester);

      expect(source.changedTo, 'newpass!1');
      await settleToast(tester);
    });
  });
}
