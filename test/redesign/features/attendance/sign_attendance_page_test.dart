import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/pages/sign_attendance_page.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/sign_person_tile.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/unexpected_sign_in_card.dart';

import 'attendance_test_doubles.dart';
import 'attendance_widget_harness.dart';

void main() {
  late FakeAttendanceSource source;

  Widget page({
    SignKind kind = SignKind.signIn,
    List<String> ids = const <String>['aria'],
  }) => SignAttendancePage(
    args: SignAttendanceArgs(
      kind: kind,
      audience: AttendanceAudience.students,
      ids: ids,
    ),
  );

  setUp(() async {
    source = FakeAttendanceSource();
    await registerAttendanceWith(source);
  });

  group('SignAttendancePage', () {
    testWidgets('is the tiles and exactly two fields', (tester) async {
      await pumpScreen(tester, page());

      expect(find.text('Sign In'), findsWidgets);
      expect(find.byType(SignPersonTile), findsOneWidget);
      expect(find.text('Aria Rowan'), findsOneWidget);

      expect(find.byType(DropdownField), findsNWidgets(2));
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('Thu 20 Aug'), findsOneWidget);
      expect(find.text('9:41'), findsOneWidget);
    });

    testWidgets('says who it will record, and that it is never typed', (
      tester,
    ) async {
      await pumpScreen(tester, page());

      expect(
        find.textContaining('taken from who is signed in on this device'),
        findsOneWidget,
      );
      expect(find.text('Sign In 1 student'), findsOneWidget);
    });

    testWidgets('someone unexpected has to be acknowledged first', (
      tester,
    ) async {
      await pumpScreen(tester, page(ids: <String>['aria', 'jonah']));

      expect(find.byType(UnexpectedSignInCard), findsOneWidget);
      expect(find.textContaining('not expected today'), findsWidgets);

      final key = tester.widget<PrimaryKey>(
        find.widgetWithText(PrimaryKey, 'Sign In 2 students'),
      );
      expect(key.enabled, isFalse);

      await tester.tap(find.text('Sign in anyway'));
      await settle(tester);

      final armed = tester.widget<PrimaryKey>(
        find.widgetWithText(PrimaryKey, 'Sign In 2 students'),
      );
      expect(armed.enabled, isTrue);
    });

    testWidgets('outside the geofence the key is off and it says why', (
      tester,
    ) async {
      source.insideGeofence = false;
      await pumpScreen(tester, page());

      expect(
        find.textContaining('Move on site to sign yourself in'),
        findsOneWidget,
      );
      final key = tester.widget<PrimaryKey>(
        find.widgetWithText(PrimaryKey, 'Sign In 1 student'),
      );
      expect(key.enabled, isFalse);
    });

    testWidgets('a tile can be taken off the form', (tester) async {
      await pumpScreen(tester, page(ids: <String>['aria', 'jonah']));
      expect(find.byType(SignPersonTile), findsNWidgets(2));

      await tester.tap(find.bySemanticsLabel('Remove Jonah Park'));
      await settle(tester);

      expect(find.byType(SignPersonTile), findsOneWidget);
      expect(find.byType(UnexpectedSignInCard), findsNothing);
    });

    testWidgets('sign out is the same form, the other way round', (
      tester,
    ) async {
      await pumpScreen(tester, page(kind: SignKind.signOut));

      expect(find.text('Sign Out'), findsWidgets);
      expect(find.text('Sign Out 1 student'), findsOneWidget);
      expect(find.byType(UnexpectedSignInCard), findsNothing);
    });

    testWidgets('a form with nobody on it says so', (tester) async {
      await pumpScreen(tester, page(ids: const <String>[]));

      expect(find.text('Pick at least one name first.'), findsOneWidget);
      expect(find.byType(SignPersonTile), findsNothing);
    });
  });
}
