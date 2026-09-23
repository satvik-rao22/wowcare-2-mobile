/// Centralized user-visible copy for the reports feature (Mandate M4).
///
/// Mirrors the existing [BillingStrings] convention rather than a global
/// `AppStrings`, so feature copy stays next to the feature.
///
/// Every display string in the reports module resolves through this class.
/// Code/enum values, log tags, storage keys, API payload keys and
/// `ReportType.backendValue` strings are intentionally NOT here — they are
/// logic, not display copy.
///
/// Report NAMES live here safely only because Step 0 of this mandate moved
/// navigation onto [ReportType]; nothing switches on these strings any more.
class ReportsStrings {
  const ReportsStrings._();

  // ── Hub chrome ──────────────────────────────────────────────────────────
  static const String reports = 'Reports';
  static const String scrollTabs = 'Scroll tabs';

  // Tab labels
  static const String tabGenerated = 'Generated';
  static const String tabStudent = 'Student';
  static const String tabStaff = 'Staff';
  static const String tabCompliance = 'Compliance';
  static const String tabBilling = 'Billing';

  // ── Report card names ───────────────────────────────────────────────────
  static const String studentDailyAttendanceName = 'Student Daily Attendance';
  static const String studentAbsentName = 'Absent Report';
  static const String studentAttendancePerStudentName =
      'Attendance per Student';
  static const String studentsAndFamilyName = 'Students and Family';
  static const String studentImmunizationName = 'School Immunization Report';
  static const String studentEmergencyContactName =
      'Student Emergency Contact List';
  static const String studentIncidentName = 'School Incident Report';

  static const String staffAttendancePerStaffName = 'Attendance Per Staff';
  static const String staffDetailsName = 'Staff Details';

  /// Deliberately a separate constant from [studentAbsentName] even though the
  /// copy is identical: they are different reports on different tabs and may
  /// diverge (or localise differently) without affecting each other.
  static const String staffAbsentName = 'Absent Report';
  static const String staffSchedulingName = 'Staff Scheduling';

  static const String annualStateImmunizationName =
      'Annual State Immunization Report';

  static const String billingTransactionName = 'Transaction Report';
  static const String billingInvoiceName = 'Invoice Report';
  static const String billingPaymentSummaryName = 'Payment Summary';
  static const String billingOutstandingName = 'Outstanding Report';
  static const String billingRefundName = 'Refund Report';
  static const String billingStudentMappingName = 'Students & Billing Mapping';

  // ── Report card descriptions ────────────────────────────────────────────
  static const String studentDailyAttendanceDesc =
      'Sign in-out records time signed by.';
  static const String studentAbsentDesc =
      'List of students with no sign-in for day.';
  static const String studentAttendancePerStudentDesc =
      'Sign in-out records for weekly, entire month.';
  static const String studentsAndFamilyDesc =
      'Download all students and family information.';
  static const String studentImmunizationDesc =
      'Download all immunization information.';
  static const String studentEmergencyContactDesc =
      'Download all students emergency information.';
  static const String studentIncidentDesc =
      'All incident information, including approvals & acknowledgements.';

  static const String staffAttendancePerStaffDesc =
      'Sign In-Out records for entire month and date range Selection.';
  static const String staffDetailsDesc = 'Download all staff information.';
  static const String staffAbsentDesc =
      'List of Staff with no sign-in for day.';
  static const String staffSchedulingDesc = 'List of all Staff schedule.';

  static const String annualStateImmunizationDesc =
      'Download student state immunization information.';

  static const String billingTransactionDesc =
      'Payments, invoices, refunds and credits for a date range.';
  static const String billingInvoiceDesc =
      'Issued invoices with total, paid and balance due.';
  static const String billingPaymentSummaryDesc =
      'Total payments and transaction count over the period.';
  static const String billingOutstandingDesc =
      'Open invoice balances by student / family.';
  static const String billingRefundDesc = 'Refunds issued over the period.';
  static const String billingStudentMappingDesc =
      'Each student mapped to their invoices (total, paid, balance).';

  // ── Empty / error states ────────────────────────────────────────────────
  static const String failedToLoadReports = 'Failed to load reports';
  static const String unknownError = 'Unknown error';
  static const String retry = 'Retry';
  static const String noReportsGeneratedYet = 'No reports generated yet';
  static const String generateYourFirstReport =
      'Generate your first report to see it here';
  static const String noReportsAvailableYet = 'No reports available yet.';

  /// Shown in the Generated list when a report has no file name.
  static const String unknownFileName = 'Unknown';

  // ── Download / save feedback ────────────────────────────────────────────
  static const String downloadingReport = 'Downloading report...';
  static const String failedToDownloadReport = 'Failed to download report';
  static const String failedToSaveFile = 'Failed to save file';
  static const String savedOpenFromFileManager =
      'Saved. Open from file manager to view';
  static const String savingFile = 'Saving file...';
  static const String generateAction = 'Generate';
  static const String toDateBeforeFromDate =
      'To date cannot be before From date';
  static const String unableToResolveSchoolName =
      'Unable to resolve school name';
  static const String classroomsLabelPlural = 'classrooms';

  // Empty-state placeholders for the report filter dropdowns. An unselected
  // filter means "no filter" — the request omits the key and the backend
  // returns every row — so the field reads "All ..." rather than "Select ...".
  static const String allClassrooms = 'All Classrooms';
  static const String allStudents = 'All Students';
  static const String allStaffMembers = 'All Staff Members';
  static const String allTags = 'All Tags';
  static const String allVaccines = 'All Vaccines';
  static const String allInvoiceStatuses = 'All Invoice Statuses';
  static const String allTransactionStatuses = 'All Transaction Statuses';
  static const String allPaymentMethods = 'All Payment Methods';

  /// Interpolated copy. Kept as functions so the surrounding text is
  /// centralised even though the value is not.
  static String comingSoon(String action) => '$action — coming soon';
  static String downloadingNamedFile(String fileName) =>
      'Downloading $fileName...';
  static String savedSuccessfully(String fileName) =>
      '$fileName saved successfully';
  static String errorWithDetail(Object error) => 'Error: $error';

  // ── Form field labels, hints and validation copy ──────────────────────
  static const String address = 'Address';
  static const String all = 'All';
  static const String allergies = 'Allergies';
  static const String apr = 'Apr';
  static const String asOfDate = 'As-Of Date';
  static const String aug = 'Aug';
  static const String billingPlan = 'Billing Plan';
  static const String cdaExpirationDate = 'CDA Expiration Date';
  static const String chooseTheBelowFieldsAndGenerateAReport =
      'Choose the below fields and generate a report';
  static const String classroom = 'Classroom';
  static const String classrooms = 'Classrooms';
  static const String clockInOutPin = 'Clock-In-Out Pin';
  static const String close = 'Close';
  static const String couldNotLoadClassroomsTapToRetry =
      'Could not load classrooms. Tap to retry.';
  static const String couldNotPreviewSpreadsheet =
      'This spreadsheet could not be previewed. Download it to open in '
      'another app.';
  static const String cprExpirationDate = 'CPR Expiration Date';
  static const String date = 'Date';
  static const String dateOfBirth = 'Date Of Birth';
  static const String dateRange = 'Date Range';
  static const String dec = 'Dec';
  static const String description = 'Description';
  static const String designation = 'Designation';
  static const String dietRestriction = 'Diet Restriction';
  static const String dob = 'DOB';
  static const String download = 'Download';
  static const String downloadFile = 'Download File';
  static const String email = 'Email';
  static const String emailId = 'Email ID';
  static const String emergencyContact = 'Emergency Contact';
  static const String endDate = 'End Date';
  static const String endDateCannotBeBeforeStartDate =
      'End date cannot be before Start date';
  static const String enrollDate = 'Enroll Date';
  static const String excelFilePreview = 'Excel File Preview';
  static const String exportFormat = 'Export Format';
  static const String feb = 'Feb';
  static const String fields = 'FIELDS';
  static const String filePreview = 'File Preview';
  static const String fileTypeNotSupportedForPreview =
      'File type not supported for preview';
  static const String filterByTag = 'Filter by Tag';
  static const String firstName = 'First name';
  static const String frequency = 'Frequency';
  static const String from = 'From';
  static const String fullName = 'Full Name';
  static const String generateReport = 'Generate Report';
  static const String generatedReports = 'Generated Reports';
  static const String grouping = 'Grouping';
  static const String hireDate = 'Hire Date';
  static const String invoiceStatus = 'Invoice Status';
  static const String jan = 'Jan';
  static const String jul = 'Jul';
  static const String jun = 'Jun';
  static const String lastName = 'Last name';
  static const String lastPhysicalDate = 'Last Physical Date';
  static const String loadingStudents = 'Loading Students...';
  static const String mar = 'Mar';
  static const String may = 'May';
  static const String medications = 'Medications';
  static const String name = 'Name';
  static const String noReportsGeneratedYetAlt = 'No reports generated yet.';
  static const String note = 'Note';
  static const String noteAllClassroomsIncludedByDefault =
      'Note: All Classrooms are included unless you select specific ones.';
  static const String noteAllStudentsIncludedByDefault =
      'Note: All Students are included unless you select specific ones.';
  static const String noteAllTagsIncludedByDefault =
      'Note: All Tags are included unless you select specific ones.';
  static const String nov = 'Nov';
  static const String oct = 'Oct';
  static const String parentGuardianAuthorizedPickupInfo =
      'PARENT/GUARDIAN & AUTHORIZED PICKUP INFO';
  static const String paymentMethod = 'Payment Method';
  static const String period = 'Period';
  static const String phoneNumber = 'Phone Number';
  static const String phoneNumberAlt = 'Phone number';
  static const String pleaseCloseAndReopenThisFormThenReselectThem =
      'Please close and reopen this form, then reselect them.';
  static const String pleaseSelectAtLeastOneField =
      'Please select at least one field';
  static const String preparingPreview = 'Preparing preview…';
  static const String previewShowsPartOfThisSheet =
      'Preview shows the first part of this sheet. Download the file to see '
      'all of it.';
  static const String primaryClassroom = 'Primary Classroom';
  static const String recentlyGeneratedReports = 'Recently Generated Reports';
  static const String relation = 'Relation';
  static const String reportGeneratedSuccessfully =
      'Report generated successfully';
  static const String reportPeriodType = 'Report Period Type';
  static const String schedule = 'Schedule';
  static const String schoolLeavingDate = 'School Leaving Date';
  static const String searchClassrooms = 'Search Classrooms';
  static const String searchStaff = 'Search Staff';
  static const String searchStudents = 'Search Students';
  static const String select = 'Select';
  static const String selectAll = 'Select All';
  static const String selectFormat = 'Select Format';
  static const String selectGrouping = 'Select Grouping';
  static const String selectMonth = 'Select Month';
  static const String sep = 'Sep';
  static const String showParentNameAndEmails = 'Show Parent name and emails';
  static const String signInPin = 'Sign-in-Pin';
  static const String staffMember = 'Staff Member';
  static const String staffMembers = 'Staff Members';
  static const String startDate = 'Start Date';
  static const String startDateMustBeOnOrBeforeEndDate =
      'Start date must be on or before end date';
  static const String status = 'Status';
  static const String students = 'Students';
  static const String tag = 'Tag';
  static const String tags = 'Tags';
  static const String tapDownloadToSaveAndOpenThisExcelFile =
      'Tap download to save and open this Excel file';
  static const String thisSheetHasNoData = 'This sheet has no data.';
  static const String time = 'Time';
  static const String transactionStatus = 'Transaction Status';
  static const String unableToDownloadInvalidReportIdentifier =
      'Unable to download: Invalid report identifier';
  static const String unableToResolveSchoolCodeForTagLookup =
      'Unable to resolve school code for tag lookup';
  static const String unableToResolveSchoolTapToRetry =
      'Unable to resolve school. Tap to retry.';
  static const String vaccines = 'Vaccines';
  static const String view = 'View';
}
