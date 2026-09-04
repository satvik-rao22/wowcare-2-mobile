import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/preview/preview_session_source.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_di.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/source/classrooms_source.dart';
import 'package:wowcare/redesign/features/classrooms/source/preview_classrooms_source.dart';

/// What M07's screens are pumped in, and the two stand-in sources its edge
/// states need.

/// Long enough for the preview source's latency to resolve. `pumpAndSettle`
/// is no good here: the loading ring never stops animating.
const Duration settle = Duration(milliseconds: 1500);

/// Wraps [child] in the theme and the session every M07 screen reads.
Widget host(Widget child, {SessionUser? user}) {
  final session = SessionCubit(source: const PreviewSessionSource())
    ..signedIn(user ?? DemoData.admin);

  return MaterialApp(
    theme: AppTheme.light,
    home: BlocProvider<SessionCubit>.value(value: session, child: child),
  );
}

/// The phone the frames are drawn at. Pumping at the default 800 by 600 would
/// lay these screens out at a width the design never draws.
const Size phone = Size(390, 844);

/// Pumps a screen on a phone-sized surface and lets its first load land.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget child, {
  SessionUser? user,
}) async {
  tester.view.physicalSize = phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(host(child, user: user));
  // Twice: the first lets the load land, the second lets the frame that
  // follows it settle, including a FAB that leaves as the state changes.
  await tester.pump(settle);
  await tester.pump(settle);
}

/// Lets a toast live out its three seconds, so no timer outlives the test.
Future<void> settleToast(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 4));

/// Registers M07 on the redesign's own locator with [source] behind it, and
/// tears the registrations down again after the test.
void useSource(ClassroomsSource source) {
  setUp(() {
    registerClassroomsDependencies(redesignLocator);
    redesignLocator
      ..unregister<ClassroomsSource>()
      ..registerSingleton<ClassroomsSource>(source);
  });
  tearDown(redesignLocator.reset);
}

/// A source that fails every call, for the states 7j draws when nothing can
/// be reached.
class FailingClassroomsSource implements ClassroomsSource {
  const FailingClassroomsSource();

  Never _fail() => throw Exception('offline');

  @override
  Future<ClassroomBoard> loadBoard() async => _fail();

  @override
  Future<ClassroomDetail> loadClassroom(String id) async => _fail();

  @override
  Future<ClassroomProfile> loadProfile(String id) async => _fail();

  @override
  Future<ClassroomNote> postNote({
    required String classroomId,
    required String text,
  }) async => _fail();

  @override
  Future<ClassroomPhoto> uploadPhoto({
    required String classroomId,
    required String fileName,
  }) async => _fail();

  @override
  Future<void> removePhoto(String classroomId) async => _fail();

  @override
  Future<List<AssignCandidate>> loadCandidates({
    required String classroomId,
    required AssignKind kind,
  }) async => _fail();

  @override
  Future<void> assign({
    required String classroomId,
    required AssignKind kind,
    required List<String> ids,
  }) async => _fail();

  @override
  Future<void> removeStudent({
    required String classroomId,
    required String studentId,
  }) async => _fail();

  @override
  Future<void> moveStudent({
    required String fromClassroomId,
    required String toClassroomId,
    required String studentId,
  }) async => _fail();

  @override
  Future<ClassroomSummary> createClassroom(ClassroomDraft draft) async =>
      _fail();
}

/// A school with no classrooms on it yet, for 7b.
class EmptyClassroomsSource extends PreviewClassroomsSource {
  const EmptyClassroomsSource();

  @override
  Future<ClassroomBoard> loadBoard() async => const ClassroomBoard();
}
