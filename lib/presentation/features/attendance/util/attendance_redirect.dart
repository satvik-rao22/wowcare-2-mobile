import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Redirects to the Daily attendance view ([tabbedViewRoute]) after an
/// attendance action (Sign In / Sign Out / Transfer / Mark Absent) completes.
///
/// The attendance forms, selection forms and the student/staff profile are
/// reached with imperative `Navigator.push`, which go_router's `go` does NOT
/// clear — so a plain `context.go(...)` leaves the pushed pages on top and the
/// user never sees the redirect. This first pops every imperatively-pushed
/// page off the current navigator, then routes to the tabbed view, so the user
/// reliably lands on the Daily view regardless of the entry point.
void redirectToAttendanceDaily(BuildContext context, String tabbedViewRoute) {
  // Capture the router before popping — `context` is unmounted after popUntil.
  final router = GoRouter.of(context);
  final navigator = Navigator.of(context);
  navigator.popUntil((route) => route.isFirst);
  router.go(tabbedViewRoute);
}

/// Redirects a staff (non-admin) persona back to THEIR OWN attendance profile
/// after a self-service Sign-In/Sign-Out/Transfer/Mark-Absent action, instead
/// of the admin-only all-staff tabbed view. That view lists every staff
/// member's attendance — sending a plain staff persona there after their own
/// action would leak other staff members' attendance data.
///
/// Mirrors [redirectToAttendanceDaily]'s pop-then-go pattern so the
/// imperatively-pushed action form is cleared off the stack first.
void redirectToOwnStaffAttendanceProfile(
  BuildContext context, {
  required String staffCode,
  required String staffName,
}) {
  final router = GoRouter.of(context);
  final navigator = Navigator.of(context);
  navigator.popUntil((route) => route.isFirst);
  final uri = Uri(
    path: '/dashboard/staff-attendance-profile-by-code',
    queryParameters: {
      'code': staffCode,
      'name': staffName.trim().isNotEmpty ? staffName.trim() : '-',
    },
  );
  router.go(uri.toString());
}
