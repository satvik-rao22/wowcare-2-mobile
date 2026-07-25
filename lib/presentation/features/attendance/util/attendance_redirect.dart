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
