import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/presentation/pages/profile_page.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/guardian_children_card.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_failed_card.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/work_schedule_card.dart';

import 'profile_test_doubles.dart';
import 'profile_widget_harness.dart';

void main() {
  late FakeProfileSource source;

  setUp(() async {
    source = FakeProfileSource();
    await registerProfileWith(source);
  });

  group('ProfilePage', () {
    testWidgets('13a: the record, the roles and the work schedule', (
      tester,
    ) async {
      await pumpScreen(tester, const ProfilePage());

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Marcus Whitfield'), findsWidgets);
      expect(find.text('Director · Maple View'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('(615) 442-9087'), findsOneWidget);
      expect(find.byType(WorkScheduleCard), findsOneWidget);
      expect(find.text('7:00 AM – 4:00 PM'), findsOneWidget);
      expect(find.text('Version 2.4.1 · build 318'), findsOneWidget);
    });

    testWidgets('13a: the PIN is masked until Show is pressed', (tester) async {
      await pumpScreen(tester, const ProfilePage());

      expect(find.text('Sign-In PIN'), findsOneWidget);
      expect(find.text('••••'), findsOneWidget);
      expect(find.text('4821'), findsNothing);

      // The actions card is at the foot of a long page.
      await tester.ensureVisible(find.text('Show'));
      await settle(tester);
      await tester.tap(find.text('Show'));
      await settle(tester);

      expect(find.text('4821'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);
    });

    testWidgets('13a: Staff get the Admin only chip, not the Edit key', (
      tester,
    ) async {
      await pumpScreen(tester, const ProfilePage(), persona: Persona.staff);

      expect(find.text('Work Schedule'), findsOneWidget);
      expect(find.text('Admin only'), findsOneWidget);
      // The one "Edit" left is the pink key in the header.
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('13c: a guardian gets their children and the note', (
      tester,
    ) async {
      source.snapshot = const ProfileSnapshot(
        record: FakeProfileSource.guardianRecord,
      );
      await pumpScreen(tester, const ProfilePage(), persona: Persona.guardian);

      expect(find.text('Me'), findsOneWidget);
      expect(find.byType(GuardianChildrenCard), findsOneWidget);
      expect(find.text('Amara Okafor'), findsOneWidget);
      expect(find.text('Sunflower · Signed In 8:09 AM'), findsOneWidget);
      expect(find.text('Sunflower · Not Marked'), findsOneWidget);
      expect(find.byType(WorkScheduleCard), findsNothing);
      expect(find.textContaining('a guardian holds one role'), findsOneWidget);
      // A guardian's PIN is simply shown: there is nothing to press.
      expect(find.text('7390'), findsOneWidget);
      expect(find.text('Show'), findsNothing);
    });

    testWidgets('13a: no photo yet invites one instead of a Change key', (
      tester,
    ) async {
      source.snapshot = ProfileSnapshot(
        record: FakeProfileSource.staffRecord.copyWith(hasPhoto: false),
      );
      await pumpScreen(tester, const ProfilePage());

      expect(find.text('Change photo'), findsNothing);
      expect(find.text('Choose from library'), findsOneWidget);
      expect(
        find.textContaining('helps a parent recognize you'),
        findsOneWidget,
      );
    });

    testWidgets('13a: the photo sheet sends a new photo up', (tester) async {
      await pumpScreen(tester, const ProfilePage());

      await tester.ensureVisible(find.text('Change photo'));
      await settle(tester);
      await tester.tap(find.text('Change photo'));
      await settle(tester);

      expect(find.text('Profile photo'), findsOneWidget);
      expect(find.text('Remove photo'), findsOneWidget);

      await tester.tap(find.text('Choose from library'));
      await settle(tester);

      expect(find.text('Photo updated'), findsOneWidget);
      await settleToast(tester);
    });

    testWidgets('13a: a failed upload leaves the record alone', (tester) async {
      source.uploadFails = true;
      await pumpScreen(tester, const ProfilePage());

      await tester.ensureVisible(find.text('Change photo'));
      await settle(tester);
      await tester.tap(find.text('Change photo'));
      await settle(tester);
      await tester.tap(find.text('Choose from library'));
      await settle(tester);

      expect(find.text('Photo did not upload'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // Nothing else on the screen was affected.
      expect(find.text('(615) 442-9087'), findsOneWidget);
    });

    testWidgets('13f: loading draws the skeleton', (tester) async {
      source.readDelay = const Duration(milliseconds: 200);
      await tester.binding.setSurfaceSize(phoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        host(const ProfilePage(), session: sessionAs(Persona.admin)),
      );
      await tester.pump();

      expect(find.byType(ProfileSkeleton), findsOneWidget);
      expect(find.text('Loading your profile…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await settle(tester);
      expect(find.byType(ProfileSkeleton), findsNothing);
    });

    testWidgets('13f: a failed load still names the person', (tester) async {
      source.throwsOnRead = true;
      await pumpScreen(tester, const ProfilePage());

      expect(find.byType(ProfileFailedCard), findsOneWidget);
      expect(find.text('Failed to load profile'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      // Kept from sign-in: the name and the email are still on screen.
      expect(find.text('Marcus Whitfield'), findsOneWidget);
      expect(find.text('marcus.whitfield@mapleview.school'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('13f: offline says where the record came from', (tester) async {
      source.snapshot = ProfileSnapshot(
        record: FakeProfileSource.staffRecord,
        isFromCache: true,
        cachedAtLabel: '9:02 AM',
      );
      await pumpScreen(tester, const ProfilePage());

      expect(
        find.text('No connection. Showing what was saved on this phone.'),
        findsOneWidget,
      );
      expect(find.text('Saved on this phone · 9:02 AM'), findsOneWidget);
      expect(find.textContaining('all need a connection'), findsOneWidget);
    });
  });
}
