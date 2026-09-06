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
