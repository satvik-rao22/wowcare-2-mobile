/// Route paths for the reports feature.
///
/// Mandate 1 requires route paths to live as constants rather than inline in
/// the router. Only the reports entries are declared here; the rest of the
/// app's paths still live on `AppRoutes` in `lib/src/app_router.dart` and on
/// the individual screens' `routeName` statics. A second class named
/// `AppRoutes` would collide with that one (§6.5), so these are namespaced
/// under [ReportRoutes].
///
/// The form routes are children of the dashboard shell's `reports` route, so
/// they render inside the nav shell exactly as the plain `Navigator.push`
/// they replaced did — and, being real GoRouter locations, they are finally
/// visible to the kiosk redirect.
class ReportRoutes {
  const ReportRoutes._();

  /// The reports hub. Matches `ReportsScreen.routeName`.
  static const String hub = '/dashboard/reports';

  // ── Relative segments, as registered under the `reports` GoRoute ──────────
  static const String studentDailyAttendanceSegment =
      'student/daily-attendance';
  static const String studentAbsentSegment = 'student/absent';
  static const String studentAttendancePerStudentSegment =
      'student/attendance-per-student';
  static const String studentsAndFamilySegment = 'student/students-and-family';
  static const String studentImmunizationSegment = 'student/immunization';
  static const String studentEmergencyContactSegment =
      'student/emergency-contact';
  static const String studentIncidentSegment = 'student/incident';

  static const String staffAttendancePerWeekSegment =
      'staff/attendance-per-week';
  static const String staffDetailsSegment = 'staff/details';
  static const String staffAbsentSegment = 'staff/absent';
  static const String staffScheduleSegment = 'staff/schedule';

  static const String complianceAnnualStateImmunizationSegment =
      'compliance/annual-state-immunization';

  static const String billingTransactionSegment = 'billing/transaction';
  static const String billingFormSegment = 'billing/form';

  static const String fileViewerSegment = 'file-viewer';

  // ── Absolute locations, for context.push ─────────────────────────────────
  static const String studentDailyAttendance =
      '$hub/$studentDailyAttendanceSegment';
  static const String studentAbsent = '$hub/$studentAbsentSegment';
  static const String studentAttendancePerStudent =
      '$hub/$studentAttendancePerStudentSegment';
  static const String studentsAndFamily = '$hub/$studentsAndFamilySegment';
  static const String studentImmunization = '$hub/$studentImmunizationSegment';
  static const String studentEmergencyContact =
      '$hub/$studentEmergencyContactSegment';
  static const String studentIncident = '$hub/$studentIncidentSegment';

  static const String staffAttendancePerWeek =
      '$hub/$staffAttendancePerWeekSegment';
  static const String staffDetails = '$hub/$staffDetailsSegment';
  static const String staffAbsent = '$hub/$staffAbsentSegment';
  static const String staffSchedule = '$hub/$staffScheduleSegment';

  static const String complianceAnnualStateImmunization =
      '$hub/$complianceAnnualStateImmunizationSegment';

  static const String billingTransaction = '$hub/$billingTransactionSegment';

  /// The one form screen shared by five billing report types
  /// (invoice, payment summary, outstanding, refund, student mapping).
  /// Which one it renders comes from `BillingReportFormArgs.reportType`.
  static const String billingForm = '$hub/$billingFormSegment';

  /// In-app file viewer opened from the reports hub. Nested under the hub so
  /// it is pushed on the dashboard branch navigator — the nav shell stays
  /// visible, as it did under the previous `Navigator.push`.
  static const String fileViewer = '$hub/$fileViewerSegment';

  /// The same viewer screen opened from the billing statements tabs. This one
  /// is registered at the router root, so it covers the nav shell. Path string
  /// is unchanged from the `ReportFileViewerArgs.routeName` it replaced.
  static const String billingFileViewer = '/billing/report-file-viewer';
}

/// Route paths for the staff feature.
///
/// Mandate 1 requires route paths to live as constants rather than inline
/// string literals at each `context.push` site. The staff screens were already
/// registered with GoRouter, but every caller retyped the path by hand — a
/// typo in one of them is a silent runtime "no route" rather than a build
/// error, and a rename means finding all of them again.
///
/// Namespaced like [ReportRoutes] rather than added to the app-wide
/// `AppRoutes` in `lib/src/app_router.dart`: a second class of that name would
/// collide with it (§6.5).
class StaffRoutes {
  const StaffRoutes._();

  /// The dashboard shell branch these routes are registered under.
  static const String _dashboard = '/dashboard';

  // ── Relative segments, as registered under the dashboard GoRoute ──────────
  static const String listSegment = 'staff';
  static const String profileSegment = 'staff-profile';
  static const String profileByCodeSegment = 'staff-profile-by-code';
  static const String addSegment = 'add-staff-screen';
  static const String editProfileDetailsSegment = 'edit-profile-details-screen';
  static const String filterSegment = 'staff-filter-screen';
  static const String documentFormSegment = 'add-document-screen';
  static const String editScheduleSegment = 'edit-schedule-screen';
  static const String editImportantDatesSegment =
      'edit-important-dates-screen';

  // ── Absolute locations, for context.push ─────────────────────────────────

  /// The staff list. Matches `StaffScreen.routeName`.
  static const String list = '$_dashboard/$listSegment';

  /// Staff profile. Matches `StaffProfileScreen.routeName`.
  static const String profile = '$_dashboard/$profileSegment';

  /// Staff profile resolved from a notification deep-link's staff code.
  static const String profileByCode = '$_dashboard/$profileByCodeSegment';

  /// The add-staff form.
  static const String add = '$_dashboard/$addSegment';

  /// The edit-staff-profile form.
  static const String editProfileDetails =
      '$_dashboard/$editProfileDetailsSegment';

  /// The shared staff filter sheet, also opened from attendance and classroom.
  static const String filter = '$_dashboard/$filterSegment';

  /// The add/edit staff-document form.
  static const String documentForm = '$_dashboard/$documentFormSegment';

  /// The edit-schedule form.
  static const String editSchedule = '$_dashboard/$editScheduleSegment';

  /// The edit-important-dates form.
  static const String editImportantDates =
      '$_dashboard/$editImportantDatesSegment';

  /// Full-screen viewer for a staff document (PDF / image / video).
  ///
  /// Registered at the router ROOT, not under the dashboard shell: the
  /// `MaterialPageRoute` it replaced covered the nav shell, and a shell-nested
  /// route would leave the bottom bar visible over the document.
  static const String documentViewer = '/document-viewer';
}

/// Route paths for the scheduling feature.
///
/// Mirrors [ReportRoutes] / [StaffRoutes]: named `SchedulingRoutes` rather
/// than `AppRoutes` because a class of that name already exists on
/// `lib/src/app_router.dart` (§6.5).
abstract final class SchedulingRoutes {
  static const String scheduling = '/dashboard/scheduling';
  static const String staffScheduling = '/dashboard/staff-scheduling';

  /// Reachable from both [scheduling] and [staffScheduling] — siblings of
  /// both under the same `/dashboard` shell, not nested under either parent,
  /// since both entry screens push the same four destinations.
  static const String addShift = '/dashboard/add-shift-screen';
  static const String editShift = '/dashboard/edit-shift-screen';
  static const String viewShift = '/dashboard/view-shift-screen';
  static const String publishShifts = '/dashboard/publish-shifts-screen';
}

/// Route paths for the dashboard feature.
///
/// Mandate 1 requires route paths to live as constants rather than inline in
/// the router or retyped at each `context.go`/`context.push` site. Before this
/// existed, every dashboard destination was declared twice — once as a
/// `static const routeName` on the screen class (which callers used) and once
/// as a bare segment literal in `lib/src/app_router.dart` (which registration
/// used) — with nothing linking the two. Renaming the router segment left the
/// caller's constant compiling and 404-ing at runtime.
///
/// Namespaced like [ReportRoutes] and [StaffRoutes] rather than added to the
/// app-wide `AppRoutes` in `lib/src/app_router.dart`: a second class of that
/// name would collide with it (§6.5).
///
/// **Every entry below is a child of [root]**, so it is pushed on the dashboard
/// shell branch's navigator and renders inside the nav shell — exactly as the
/// `Navigator.push(MaterialPageRoute(...))` calls they replaced did. A route
/// registered at the router root would be pushed on the ROOT navigator and
/// would cover the bottom bar, which would be a visible behaviour change.
class DashboardRoutes {
  const DashboardRoutes._();

  /// The dashboard itself — shell branch 0. Matches `DashboardScreen.routeName`.
  static const String root = '/dashboard';

  // ── Relative segments, as registered under the dashboard GoRoute ──────────







  /// Full-screen QR scanner, opened from `QrScanButton`. Presented as a
  /// fullscreen dialog to match the `fullscreenDialog: true` it replaced.
  static const String qrScannerSegment = 'qr-scanner';


  /// Mixed sign-in/out selection, reached from `MyChildsDayCard` and from a QR
  /// scan. Already registered; the constant replaces the retyped literal.
  static const String childSignInOutSelectionSegment =
      'student-sign-in-out-selection';


  // ── Destinations the dashboard's cards navigate to ────────────────────────
  // Registered as literals in lib/src/app_router.dart and retyped as a
  // `routeName` static on each screen, with nothing linking the two: renaming
  // the router segment left every caller compiling and 404-ing at runtime.
  // Both sides now read these.
  static const String schedulingSegment = 'scheduling';
  static const String staffSchedulingSegment = 'staff-scheduling';
  static const String futureAvailabilitySegment = 'future-availability';
  static const String individualMovementSegment = 'individual-movement';
  static const String billingSegment = 'billing';
  static const String parentNewsletterSegment = 'parent-newsletter';
  static const String studentAttendanceTabbedViewSegment = 'student-attendance-tabbed-view';
  static const String staffAttendanceTabbedViewSegment = 'staff-attendance-tabbed-view';
  static const String studentAttendanceProfileSegment = 'student-attendance-profile';
  static const String staffAttendanceProfileSegment = 'staff-attendance-profile';

  // ── Absolute locations, for context.push / context.go ────────────────────

  static const String qrScanner = '$root/$qrScannerSegment';
  static const String scheduling = '$root/$schedulingSegment';
  static const String staffScheduling = '$root/$staffSchedulingSegment';
  static const String futureAvailability = '$root/$futureAvailabilitySegment';
  static const String individualMovement = '$root/$individualMovementSegment';
  static const String billing = '$root/$billingSegment';
  static const String parentNewsletter = '$root/$parentNewsletterSegment';
  static const String studentAttendanceTabbedView = '$root/$studentAttendanceTabbedViewSegment';
  static const String staffAttendanceTabbedView = '$root/$staffAttendanceTabbedViewSegment';
  static const String studentAttendanceProfile = '$root/$studentAttendanceProfileSegment';
  static const String staffAttendanceProfile = '$root/$staffAttendanceProfileSegment';

  static const String childSignInOutSelection =
      '$root/$childSignInOutSelectionSegment';
}

/// Shell branch roots the dashboard jumps to cross-branch. Declared here so
/// the dashboard stops retyping the literal at each `context.go`; the values
/// match `AppRoutes` in `lib/src/app_router.dart`, which registers them.
class ShellBranchRoutes {
  const ShellBranchRoutes._();

  /// Matches `ActivityFeedScreen.routeName` / `AppRoutes.activityFeed`.
  static const String activityFeed = '/activityFeed';
}

/// Route paths for the kiosk feature.
///
/// Only [root] is declared — it is referenced from outside the kiosk feature
/// (the router's kiosk redirect and `DashboardScreen`'s last-resort guard),
/// which is exactly the case Mandate 1 wants a constant for. The kiosk's own
/// child routes stay registered as segments under it.
class KioskRoutes {
  const KioskRoutes._();

  /// Matches `KioskDashboardScreen.routeName`.
  static const String root = '/kiosk';
}
