import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/notifications/entities/notification_preference_group.dart';
import 'package:wowcare/redesign/core/widgets/app_checkbox.dart';
import 'package:wowcare/redesign/core/widgets/empty_state.dart';
import 'package:wowcare/redesign/core/widgets/error_state.dart';
import 'package:wowcare/redesign/features/profile/presentation/pages/notification_settings_page.dart';

import 'profile_test_doubles.dart';
import 'profile_widget_harness.dart';

void main() {
  late FakeProfileSource source;

  setUp(() async {
    source = FakeProfileSource();
    await registerProfileWith(source);
  });

  group('NotificationSettingsPage', () {
    testWidgets('13e: the bands, the columns and every description', (
      tester,
    ) async {
      await pumpScreen(tester, const NotificationSettingsPage());

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Saved the moment you tick'), findsOneWidget);
      expect(find.text('WHAT HAPPENS'), findsOneWidget);
      expect(find.text('In-App'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Push'), findsOneWidget);
      expect(find.text('STUDENTS'), findsOneWidget);
      expect(find.text('STAFF'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      // The description line the shipped app returns and ignores.
      expect(
        find.text('A student is signed in, signed out or marked absent'),
        findsOneWidget,
      );
      expect(find.textContaining('not offered'), findsOneWidget);
    });

    testWidgets('13e: a tick saves that one group at once', (tester) async {
      await pumpScreen(tester, const NotificationSettingsPage());

      // The first row's In-App cell.
      await tester.tap(find.byType(AppCheckbox).first);
      await settle(tester);

      expect(source.updated?.groupCode, 'g1');
      expect(
        source.updated?.isChannelEnabled(NotificationChannel.inApp),
        isFalse,
      );
    });

    testWidgets('a failed save puts the tick back and toasts', (tester) async {
      source.throwsOnWrite = true;
      await pumpScreen(tester, const NotificationSettingsPage());

      await tester.tap(find.byType(AppCheckbox).first);
      await settle(tester);

      expect(
        find.text('Could not save that preference. It has been put back.'),
        findsOneWidget,
      );
      await settleToast(tester);
    });

    testWidgets('a school with no groups gets the empty state', (tester) async {
      source.preferences = const <NotificationPreferenceGroup>[];
      await pumpScreen(tester, const NotificationSettingsPage());

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No notification preferences yet'), findsOneWidget);
    });

    testWidgets('a failed fetch offers Try again', (tester) async {
      source.throwsOnRead = true;
      await pumpScreen(tester, const NotificationSettingsPage());

      expect(find.byType(ErrorState), findsOneWidget);
    });
  });
}
