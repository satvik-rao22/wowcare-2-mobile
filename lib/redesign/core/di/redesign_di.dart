import 'package:get_it/get_it.dart';
import 'package:wowcare/redesign/core/preview/preview_session_source.dart';
import 'package:wowcare/redesign/core/session/session_cubit.dart';
import 'package:wowcare/redesign/features/activities/activities_di.dart';
import 'package:wowcare/redesign/features/attendance/attendance_di.dart';
import 'package:wowcare/redesign/features/auth/auth_di.dart';
import 'package:wowcare/redesign/features/billing/billing_di.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_di.dart';
import 'package:wowcare/redesign/features/communication/communication_di.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_di.dart';
import 'package:wowcare/redesign/features/events/events_di.dart';
import 'package:wowcare/redesign/features/movements/movements_di.dart';
import 'package:wowcare/redesign/features/newsletter/newsletter_di.dart';
import 'package:wowcare/redesign/features/notifications/notifications_di.dart';
import 'package:wowcare/redesign/features/profile/profile_di.dart';
import 'package:wowcare/redesign/features/reports/reports_di.dart';
import 'package:wowcare/redesign/features/scheduling/scheduling_di.dart';
import 'package:wowcare/redesign/features/staff/staff_di.dart';
import 'package:wowcare/redesign/features/students/students_di.dart';

/// The redesign's own registrations, on the redesign's own locator.
///
/// A separate [GetIt] instance rather than the app's global `serviceLocator`:
/// the two presentation layers coexist behind the launcher and must not see
/// each other's registrations. Phase 5 is where a feature's preview source is
/// swapped for the real usecase, and that usecase is fetched from the app's
/// locator at that point.
///
/// Idempotent, so both entrypoints (the launcher and `main_redesign.dart`) can
/// call it without checking.
final GetIt redesignLocator = GetIt.asNewInstance();

bool _registered = false;

void registerRedesignDependencies() {
  if (_registered) return;
  _registered = true;

  final sl = redesignLocator;

  sl.registerLazySingleton<SessionSource>(PreviewSessionSource.new);
  sl.registerLazySingleton<SessionCubit>(
    () => SessionCubit(source: sl<SessionSource>()),
  );

  registerAuthDependencies(sl);
  registerDashboardDependencies(sl);
  registerAttendanceDependencies(sl);
  registerStudentsDependencies(sl);
  registerStaffDependencies(sl);
  registerClassroomsDependencies(sl);
  registerActivitiesDependencies(sl);
  registerCommunicationDependencies(sl);
  registerBillingDependencies(sl);
  registerMovementsDependencies(sl);
  registerNotificationsDependencies(sl);
  registerProfileDependencies(sl);
  registerSchedulingDependencies(sl);
  registerNewsletterDependencies(sl);
  registerReportsDependencies(sl);
  registerEventsDependencies(sl);
}
