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
  ///
  /// Deliberately distinct from `DocumentViewerScreen.routeName`
  /// (`/document-viewer`) — go_router matches routes in declaration order,
  /// and that shared Map-`extra`-based route was registered first, so a
  /// shared path here silently swallowed every staff push (it cast this
  /// route's `DocumentViewerArgs` extra as a `Map`, throwing at navigation
  /// time and making "View" on a staff document a no-op/crash).
  static const String documentViewer = '/staff-document-viewer';
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

  /// Matches `MessagingScreen.routeName` / `AppRoutes.messaging` — shell
  /// branch 3, which hosts the staff/admin newsletter tab.
  static const String messaging = '/messageFeed';
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

/// Route paths for the newsletter feature.
///
/// ## The convention this class establishes
///
/// The other feature modules should copy this shape verbatim:
///
/// * **`abstract final class <Feature>Routes`.** Not `AppRoutes` — a class of
///   that name already exists on `lib/src/app_router.dart` and a second one
///   would collide (§6.5). `abstract final` (as [SchedulingRoutes] already
///   uses) is preferred over the older `class X { const X._(); }` idiom in
///   this file: it makes the "namespace, never instantiated" intent a compile
///   error rather than a convention.
/// * **Path-parameter names are constants too** ([codeParam]), so the
///   `GoRoute(path:)` registration and the `state.pathParameters[...]` read on
///   the other side of the router cannot drift apart. A typo in either half is
///   otherwise a silent runtime null, not a build error.
/// * **Three blocks, in this order:** parameter names, relative segments (what
///   `GoRoute(path:)` is registered with), then absolute locations/helpers
///   (what callers pass to `context.push`). Segment and absolute are derived
///   from one another by interpolation, never retyped.
/// * **A path parameter gets a helper method, not a constant.** A caller must
///   not be able to hand `context.push` a pattern string with a live `:code`
///   in it. [dashboardPreview] / [messagingPreview] are the only way to build
///   these locations, and they encode the value.
/// * **Non-path arguments are a declared class in the feature's `model/`
///   folder**, passed through `extra` — here
///   `NewsletterPreviewArgs`. Never a raw map, never `Object?` at the
///   receiving end.
///
/// ## Why the preview screen is registered twice
///
/// `PreviewNewsletterScreen` is opened from two different shell branches: the
/// parent newsletter list and the parent dashboard card (branch 0,
/// `/dashboard`) and the staff/admin Sent tab (branch 3, `/messageFeed`). The
/// `Navigator.of(context).push` calls these replaced resolved to the *branch*
/// navigator, so the bottom nav bar stayed visible. A single route registered
/// at the router root would be pushed on the ROOT navigator and would cover
/// the nav shell — a visible behaviour change.
///
/// So the same screen is registered once per branch, which is already the
/// house pattern: see [ReportRoutes.fileViewer] vs
/// [ReportRoutes.billingFileViewer], which exist for exactly this reason.
///
/// Within the dashboard branch the preview is a **sibling** of
/// [DashboardRoutes.parentNewsletter], not a child of it, because two
/// different screens in that branch push it (the list tab and the dashboard's
/// newsletter card). That mirrors [SchedulingRoutes.addShift], which is a
/// sibling of both entry screens that push it for the same reason.
///
/// The notification deep-link route (`AppRoutes.newsletterPreviewByCode`,
/// `/newsletter-preview-by-code?code=…`) is a third registration and stays on
/// `AppRoutes`: it is a root-level route by design — a notification tap should
/// open the newsletter over the shell — and its query-string shape is part of
/// the contract with `notification_route_resolver.dart`.
abstract final class NewsletterRoutes {
  // ── Path parameter names ─────────────────────────────────────────────────

  /// The newsletter's business code. Read back with
  /// `state.pathParameters[NewsletterRoutes.codeParam]`.
  static const String codeParam = 'newsletterCode';

  // ── Relative segments, as registered with `GoRoute(path:)` ───────────────

  /// Registered under [DashboardRoutes.root] and under
  /// [ShellBranchRoutes.messaging].
  static const String previewSegment = 'newsletter/:$codeParam';

  // ── Absolute locations ───────────────────────────────────────────────────

  /// The parent-facing newsletter list. Aliases the entry that
  /// [DashboardRoutes] already owns rather than declaring a second constant
  /// with the same value — the dashboard registers it as one of its shell
  /// children, so that class stays the single source of truth.
  static const String parentList = DashboardRoutes.parentNewsletter;

  /// The staff/admin-facing newsletter list. Not a route of its own: the Sent
  /// list is a `TabBarView` child of `MessagingScreen`, selected by that
  /// screen's `?tab=newsletter` query parameter. Kept here so the two entry
  /// points are findable from one place.
  static const String staffList = '${ShellBranchRoutes.messaging}?tab=newsletter';

  /// The registered pattern for the dashboard-branch preview, for reference
  /// and tests. Callers use [dashboardPreview].
  static const String dashboardPreviewPattern =
      '${DashboardRoutes.root}/$previewSegment';

  /// The registered pattern for the messaging-branch preview, for reference
  /// and tests. Callers use [messagingPreview].
  static const String messagingPreviewPattern =
      '${ShellBranchRoutes.messaging}/$previewSegment';

  // ── Helpers for path parameters ──────────────────────────────────────────

  /// Newsletter preview, pushed on the **dashboard** branch navigator. Use
  /// from the parent newsletter list and the parent dashboard's newsletter
  /// card; the nav shell stays visible.
  static String dashboardPreview(String newsletterCode) =>
      '${DashboardRoutes.root}/newsletter/${Uri.encodeComponent(newsletterCode)}';

  /// Newsletter preview, pushed on the **messaging** branch navigator. Use
  /// from the staff/admin Sent newsletter tab; the nav shell stays visible.
  static String messagingPreview(String newsletterCode) =>
      '${ShellBranchRoutes.messaging}/newsletter/${Uri.encodeComponent(newsletterCode)}';
}
