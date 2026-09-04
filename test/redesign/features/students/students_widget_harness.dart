import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/redesign/core/constants/app_durations.dart';
import 'package:wowcare/redesign/core/di/redesign_di.dart';
import 'package:wowcare/redesign/core/preview/demo_data.dart';
import 'package:wowcare/redesign/core/preview/preview_session_source.dart';
import 'package:wowcare/redesign/core/session/persona.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/core/theme/app_theme.dart';
import 'package:wowcare/redesign/features/students/source/students_source.dart';
import 'package:wowcare/redesign/features/students/students_di.dart';

import 'students_test_doubles.dart';

/// Registers M05 on the redesign locator with [source] standing in for the
/// preview one, so a screen test drives the same wiring the app does.
Future<void> registerStudentsWith(FakeStudentsSource source) async {
  await redesignLocator.reset();
  registerStudentsDependencies(redesignLocator);
  await redesignLocator.unregister<StudentsSource>();
  redesignLocator.registerLazySingleton<StudentsSource>(() => source);
}

/// A session signed in as [persona], which is what every M05 screen reads to
/// decide what it may offer.
SessionCubit sessionAs(Persona persona) {
  final user = switch (persona) {
    Persona.admin => DemoData.admin,
    Persona.staff => DemoData.staff,
    Persona.guardian => DemoData.guardian,
  };
  return SessionCubit(source: const PreviewSessionSource())
    ..signedIn(user)
    ..switchPersona(persona);
}

/// The app around one screen: the theme, and the session it reads.
Widget host(Widget screen, {required SessionCubit session}) => MaterialApp(
  theme: AppTheme.light,
  home: BlocProvider<SessionCubit>.value(value: session, child: screen),
);

/// The phone the design draws, so a screen under test lays out the way it
/// does on the device rather than on the test harness's default 800 by 600.
const Size phoneSize = Size(390, 844);

/// Pumps [screen] on a phone-sized surface as [persona], then lets its first
/// fetch resolve.
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Persona persona = Persona.admin,
}) async {
  await tester.binding.setSurfaceSize(phoneSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(host(screen, session: sessionAs(persona)));
  await settle(tester);
}

/// Lets a toast run its course, so the test does not end on a pending timer.
Future<void> settleToast(WidgetTester tester) async {
  await tester.pump(AppDurations.toastError + AppDurations.toast);
  await tester.pumpAndSettle();
}

/// Lets a screen's fetches resolve, then lets its animations finish.
///
/// The zero-duration pumps come first and drain the microtasks a fetch
/// resolves on; `pumpAndSettle` alone would advance the clock past a sheet's
/// transition before the sheet had been asked for.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
