import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/preview/preview_session_source.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/source/preview_staff_source.dart';
import 'package:wowcare/redesign/features/staff/source/staff_source.dart';
import 'package:wowcare/redesign/features/staff/staff_di.dart';

/// What M06's screens are pumped in, and the stand-in sources its edge states
/// need.

/// Long enough for the preview source's latency to resolve. `pumpAndSettle`
/// is no good here: the loading ring never stops animating.
const Duration settle = Duration(milliseconds: 1500);

/// The phone the frames are drawn at. Pumping at the default 800 by 600 would
/// lay these screens out at a width the design never draws.
const Size phone = Size(390, 844);

/// The Admin lens, which is what 6a and 6c are drawn for.
const StaffLens adminLens = StaffLens(
  persona: Persona.admin,
  viewerId: 'marcus',
);

/// A teacher looking, which is 6e's first state.
const StaffLens staffLens = StaffLens(
  persona: Persona.staff,
  viewerId: 'dana',
  viewerClassroom: 'Sunflower',
);

/// A guardian, who has no Staff module at all: 6e's refusal.
const StaffLens guardianLens = StaffLens(persona: Persona.guardian);

/// Wraps [child] in the theme and the session every M06 screen reads.
Widget host(Widget child, {SessionUser? user, Persona? persona}) {
  final session = SessionCubit(source: const PreviewSessionSource())
    ..signedIn(user ?? DemoData.admin);
  if (persona != null) session.switchPersona(persona);

  return MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<SessionCubit>.value(value: session, child: child),
  );
}

/// Pumps a screen on a phone-sized surface and lets its first load land.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  SessionUser? user,
  Persona? persona,
}) async {
  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(host(child, user: user, persona: persona));
  // Twice: the first lets the load land, the second lets the frame that
  // follows it settle, including a FAB that leaves as the state changes.
  await tester.pump(settle);
  await tester.pump(settle);
}

/// Lets a toast live out its three seconds, so no timer outlives the test.
Future<void> settleToast(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 4));

/// Registers M06 on the redesign's own locator with [source] behind it, and
/// tears the registrations down again after the test.
void useSource(StaffSource source) {
  setUp(() {
    registerStaffDependencies(redesignLocator);
    redesignLocator
      ..unregister<StaffSource>()
      ..registerSingleton<StaffSource>(source);
  });
  tearDown(redesignLocator.reset);
}

/// A source that fails every call, for 6e's "Waiting for a signal".
class FailingStaffSource implements StaffSource {
  const FailingStaffSource();

  Never _fail() => throw Exception('offline');

  @override
  Future<StaffRoster> loadRoster() async => _fail();

  @override
  Future<StaffProfile> loadProfile(String id) async => _fail();

  @override
  Future<StaffOptions> loadOptions() async => _fail();

  @override
  Future<StaffMember> createStaff(StaffDraft draft) async => _fail();

  @override
  Future<StaffProfile> updateDetails({
    required String id,
    required StaffDetailsDraft draft,
  }) async => _fail();

  @override
  Future<StaffProfile> updateSchedule({
    required String id,
    required List<StaffShift> week,
  }) async => _fail();

  @override
  Future<StaffMember> setActive({
    required String id,
    required bool isActive,
  }) async => _fail();

  @override
  Future<StaffDocument> addDocument({
    required String staffId,
    required String name,
    required String type,
    DateTime? expiresOn,
  }) async => _fail();
}

/// A school with nobody on the books yet, for the roster's empty state.
class EmptyStaffSource extends PreviewStaffSource {
  const EmptyStaffSource();

  @override
  Future<StaffRoster> loadRoster() async => const StaffRoster();
}
