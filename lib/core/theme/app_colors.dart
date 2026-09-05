import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const themeColor = Color.fromRGBO(89, 120, 247, 1);

  static const primaryColor = Color.fromRGBO(87, 51, 83, 1);
  static const secondaryColor = Color.fromRGBO(27, 35, 126, 1);

  static const cardColor = Colors.white;
  static final cardBorderColor = AppColors.primaryColor.withValues(alpha: 0.15);
  static final inputBorderColor = AppColors.primaryColor.withValues(alpha: 0.4);

  static const Color transparentColor = Colors.transparent;

  static const fieldBackgroundColor = Color.fromRGBO(177, 175, 233, 0.1);

  static const accentColor = Color.fromRGBO(220, 156, 19, 1);
  static const errorColor = Color.fromRGBO(211, 47, 47, 1);
  static const warningColor = Color.fromRGBO(255, 160, 0, 1);
  static const successColor = Color.fromRGBO(56, 142, 60, 1);

  static const dividerColor = Color.fromRGBO(189, 189, 189, 1);

  static const classroomStudentTabColor = Color.fromRGBO(44, 99, 226, 0.1);
  static const classroomStaffTabColor = Color.fromRGBO(203, 246, 255, 0.4);
  static const classroomNotesTabColor = Color.fromRGBO(217, 255, 203, 0.4);

  static const Color lightBlueProgressBar = Color.fromRGBO(155, 232, 255, 1);
  static const Color mustardProgressBar = Color.fromRGBO(253, 205, 22, 1);
  static const Color lightGreenProgressBar = Color.fromRGBO(151, 242, 148, 1);
  static const Color redProgressBar = Color.fromRGBO(240, 111, 111, 1);
  static const Color refundLegendColor = Color(0xFFA8D8FF);
  static const Color paidLegendColor = Color(0xFF25AC7C);
  static const Color colorBox = Color(0xFFACF3AA);
  static const Color colorBox2 = Color(0xFFF38D8D);
  static const Color colorBox3 = Color(0xFF5978F7);

  static const List<Color> scaffoldGradientColors = [
    Color.fromRGBO(255, 255, 255, 1),
    Color.fromRGBO(251, 238, 250, 1),
  ];

  static const List<Color> primaryGradientColors = [
    Color.fromRGBO(111, 140, 255, 1),
    Color.fromRGBO(156, 132, 255, 1),
  ];

  static const List<Color> secondaryGradientColors = [
    Color.fromRGBO(89, 120, 247, 1),
    Color.fromRGBO(156, 132, 255, 1),
  ];

  /// Messaging: every staff/admin/teacher/director message renders with
  /// this gradient, on whichever side the canonical role-based alignment
  /// rule puts it (see docs/messaging/06-ui-standards.md). This is a
  /// semantic alias for the existing [primaryGradientColors] — reusing it
  /// rather than introducing a second, visually-identical token.
  static const List<Color> staffGradientColors = primaryGradientColors;

  /// Messaging: every guardian/parent message renders with this gradient,
  /// on whichever side the canonical role-based alignment rule puts it.
  /// Placeholder tone pending design confirmation — same two-stop,
  /// similar-saturation style as [primaryGradientColors].
  static const List<Color> pinkGradientColors = [
    Color.fromRGBO(255, 154, 196, 1),
    Color.fromRGBO(255, 107, 157, 1),
  ];

  static var chipBackground;

  static LinearGradient buildScaffoldGradient() => const LinearGradient(
    colors: scaffoldGradientColors,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient buildPrimaryGradient({
    List<Color> colors = primaryGradientColors,
    Alignment begin = Alignment.centerLeft,
    Alignment end = Alignment.centerRight,
  }) => LinearGradient(colors: colors, begin: begin, end: end);

  static LinearGradient buildSecondaryGradient({
    List<Color> colors = secondaryGradientColors,
    Alignment begin = Alignment.centerLeft,
    Alignment end = Alignment.centerRight,
  }) => LinearGradient(colors: colors, begin: begin, end: end);

  /// Semantic alias for [buildPrimaryGradient] — see [staffGradientColors].
  static LinearGradient buildStaffGradient({
    Alignment begin = Alignment.centerLeft,
    Alignment end = Alignment.centerRight,
  }) => buildPrimaryGradient(begin: begin, end: end);

  static LinearGradient buildPinkGradient({
    List<Color> colors = pinkGradientColors,
    Alignment begin = Alignment.centerLeft,
    Alignment end = Alignment.centerRight,
  }) => LinearGradient(colors: colors, begin: begin, end: end);

  // Avatar color palette used exclusively by profile initials widgets
  static const List<Color> profileAvatarColors = <Color>[
    Color(0xFFFF9B9B), // soft red
    Color(0xFFFDCD16), // yellow
    Color(0xFF87CEEB), // sky blue
    Color(0xFFFDA758), // orange
    Color(0xFFF67EAF), // pink
    Color(0xFFCB9AFC), // lavender (new)
  ];

  static const List<Color> tagColors = [
    Color(0xFFFFF8E1), // amber pastel
    Color(0x4DB1AFE9), // 5 Days
    Color(0x66CBF6FF), // Full Day
    Color(0x66D9FFCB), // Photo Permission
    Color(0xFFFCE4EC), // soft pink
    Color(0xFFF3E5F5), // purple pastel
    Color(0xFFE0F7FA), // cyan pastel
  ];

  static const List<Color> tagTextColors = [Color(0xFF1B237E)];

  /// Single-value alias for [tagTextColors]'s only entry, usable in const
  /// contexts where indexing into the list isn't const-evaluable.
  static const Color tagTextColor = Color(0xFF1B237E);

  // Billing specific colors
  static const Color billingTextColor = Color(
    0xff573353,
  ); // Primary text color for billing
  static const Color billingTextSecondary = Color(
    0xff573353,
  ); // Secondary text (with opacity)

  // Transaction badge colors
  static const Color billingInvoiceBadgeColor = Color.fromRGBO(
    203,
    246,
    255,
    0.4,
  );
  static const Color billingPaymentBadgeColor = Color.fromRGBO(
    227,
    255,
    203,
    0.4,
  );
  static const Color billingRefundBadgeColor = Color.fromRGBO(
    229,
    231,
    235,
    0.4,
  );
  static const Color billingDefaultBadgeColor = Color(0xFFE4E7F5);

  // Transaction status colors
  static const Color billingStatusInProgressColor = Color.fromRGBO(
    255,
    152,
    0,
    0.3,
  ); // Orange
  static const Color billingStatusCancelledColor = Color.fromRGBO(
    244,
    67,
    54,
    0.3,
  ); // Red

  // Card and container colors
  static const Color billingCardColor = Colors.white;
  static final Color billingCardBorderColor = primaryColor.withValues(
    alpha: 0.2,
  );
  static final Color billingCardShadowColor = Colors.black.withValues(
    alpha: 0.03,
  );

  // Divider colors
  static final Color billingDividerColor = primaryColor.withValues(alpha: 0.1);

  // Button colors
  static const Color billingButtonTextColor = Colors.white;

  // Error/Alert colors for billing
  static final Color billingErrorBackgroundColor = Colors.red.shade50;
  static final Color billingErrorBorderColor = Colors.red.shade200;
  static final Color billingErrorIconColor = Colors.red.shade600;
  static final Color billingErrorTextColor = Colors.red.shade700;

  // Grey shades for billing
  static const Color billingGrey = Colors.grey;
  static final Color billingGreyLight = Colors.grey.shade100;
  static final Color billingGreyMedium = Colors.grey.shade500;
  static final Color billingGreyDark = Colors.grey.shade700;
  static final Color billingGreyTransparent = Colors.grey.withValues(
    alpha: 0.3,
  );

  // Success color
  static const Color billingSuccessColor = Colors.green;

  // Background colors
  static const Color billingBackgroundColor = Colors.white;
  static const Color billingTransparentColor = Colors.transparent;

  // Shadow colors
  static final Color billingShadowColor = Colors.black.withValues(alpha: 0.03);
  static final Color billingShadowColorLight = Colors.black.withValues(
    alpha: 0.05,
  );
  static final Color billingShadowColorMedium = Colors.black.withValues(
    alpha: 0.08,
  );

  // Border colors with opacity
  static const Color billingBorderLight = Color(
    0x1AB1AFE9,
  ); // Light purple border
  static final Color billingBorderMedium = primaryColor.withValues(alpha: 0.2);
  static final Color billingBorderHeavy = primaryColor.withValues(alpha: 0.4);
  static const Color billingDividerLight = Color(0xFFE9ECEF);

  // Button and input colors
  static final Color billingButtonDisabled = Colors.grey[300]!;
  static final Color billingInputBorderDefault = Colors.grey.shade200;
  static final Color billingInputBorderFocused = const Color(0xFF6657F8);
  static final Color billingInputBackgroundDisabled = Colors.grey[200]!;

  // Status indicator colors (for success/error states)
  static const Color billingStatusSuccess = Colors.green;
  static const Color billingStatusError = Color(0xFFFF3B30);

  // Additional billing literals centralized (visual-neutral) — Mandate 4 color batch
  static const Color billingBorderDefault = Color(
    0x66573353,
  ); // Input/card border = billing text @ 40% alpha (recurs 9x)
  static const Color billingTextMuted = Color(
    0x99573353,
  ); // Muted secondary text/icons = billing text @ 60% alpha (recurs 6x)
  static const Color billingAccentBlue = Color(
    0xFF6F8CFF,
  ); // Billing accent blue: card _accent, In-Process status, borders (recurs 6x)
  static const Color billingSuccessBackground = Color(
    0xFFE8FFF1,
  ); // Light green success/primary tag background (recurs 4x)
  static const Color billingSurfaceLight = Color(
    0xFFF8F9FA,
  ); // Light grey surface/background fill (recurs 3x)
  static const Color billingCardAccent = Color(
    0xFF6C7FD8,
  ); // Card action accent, kept billing-scoped (same value as attendanceActionAccentColor) (recurs 3x)

  // Activity Custom tab
  static final List<Color> colorPalette = [
    const Color(0xFFB3E5FC),
    const Color(0xFFFFCCBC),
    const Color(0xFFC8E6C9),
    const Color(0xFFFFE0B2),
    // const Color(0xFFFFF9C4),
    const Color(0xFFE1BEE7),
    const Color(0xFFCCFF90),
    const Color(0xFF80DEEA),
    const Color(0xFFD1C4E9),
    const Color(0xFFFFAB91),
  ];

  // Attendance specific colors
  static const Color attendanceActionAccentColor = Color(
    0xFF6C7FD8,
  ); // Card Edit/Delete outlined button border + label
  static const Color attendanceCardDividerColor = Color(
    0xFFE9ECEF,
  ); // Divider between card sections
  static const Color attendanceDialogBodyTextColor = Color(
    0xFF424242,
  ); // Dialog body text
  static const Color attendanceDialogHintTextColor = Color(
    0xFF757575,
  ); // Dialog hint/label text (was Colors.grey[600])
  static const Color attendanceBorderLightColor = Color(
    0xFFE0E0E0,
  ); // Input borders / placeholder icon+text (was Colors.grey.shade300 / grey[300])
  static const Color attendanceShimmerBaseColor = Color(
    0xFFE0E0E0,
  ); // Loading skeleton base (was Colors.grey.shade300) — kept separate from the border token
  static const Color attendanceShimmerHighlightColor = Color(
    0xFFF5F5F5,
  ); // Loading skeleton highlight (was Colors.grey.shade100)
  static const Color attendanceOverlayScrimColor = Color(
    0x73000000,
  ); // Dialog barrier (was Colors.black.withValues(alpha: 0.45))
  static const Color attendanceCardShadowColor = Color(
    0x1A000000,
  ); // Card/popup shadow (was Colors.black.withValues(alpha: 0.1))
  static const Color attendanceInfoHighlightColor = Color(
    0x1A2196F3,
  ); // Info tint (was Colors.blue.withValues(alpha: 0.1))
  static const Color attendanceIconColor =
      Colors.black; // Popup icon/label (was bare Colors.black)
  static const Color attendancePopupBarrierColor = Color(
    0x8A000000,
  ); // Attendance popup dialog barrier (was Colors.black54)
  static const Color attendanceEmptyStateIconColor = Color(
    0xFFBDBDBD,
  ); // "No data" empty-state icon (was Colors.grey[400])
  static const Color attendanceMutedTextColor = Color(
    0xFF9E9E9E,
  ); // Muted text/border/icon tint (was bare Colors.grey)
  static const Color attendanceCardBorderColor = Color(
    0x1F000000,
  ); // Thin 1px card border (was Colors.black12)
  static const Color attendanceSearchHintColor = Color(
    0xFF616161,
  ); // Search field hint text (was Colors.grey[700])
  static const Color attendanceBodyText87Color = Color(
    0xDD000000,
  ); // Body/detail text (was Colors.black87)
  static const Color attendanceStatBlueColor = Color(
    0xFF4285F4,
  ); // Profile stat icon/value accent (was raw hex)
  static const Color attendanceStatGreenColor = Color(
    0xFF4CAF50,
  ); // "Attended days" stat value (was raw hex)
  static const Color attendanceTabIndicatorColor = Color(
    0xFF3B5BDB,
  ); // Custom-view tab indicator bar (was raw hex)
  static const Color attendanceTabSelectedLabelColor = Color(
    0xFF222B45,
  ); // Custom-view selected tab label (was raw hex)
  static const Color attendanceTabUnselectedLabelColor = Color(
    0xFF8F9BB3,
  ); // Custom-view unselected tab label (was raw hex)

  /// Card-container box shadow, lighter than [attendanceCardShadowColor].
  /// Same value as [billingShadowColor] — reused under an attendance-scoped
  /// name so attendance files don't reference a billing-prefixed constant.
  static final Color attendanceCardShadowLightColor = billingShadowColor;

  /// Selected-row/tile background tint, used by every selectable list item
  /// across the attendance selection forms (was
  /// `Color.fromRGBO(249, 245, 250, 1)` / `Color.fromARGB(255, 249, 245, 250)`).
  static const Color attendanceSelectedTintColor = Color.fromRGBO(
    249,
    245,
    250,
    1,
  );

  /// Distinct danger-red accent (was raw `Color.fromRGBO(179, 38, 30, 1)`),
  /// separate from [errorColor] — not merged since the exact shade differs.
  static const Color attendanceDangerAccentColor = Color.fromRGBO(
    179,
    38,
    30,
    1,
  );

  /// Light purple banner background (was raw
  /// `Color.fromRGBO(243, 238, 250, 1)`).
  static const Color attendanceInfoBannerBackgroundColor = Color.fromRGBO(
    243,
    238,
    250,
    1,
  );

  /// General alias so `.withValues(alpha: ...)` derivatives still resolve
  /// through AppColors rather than a bare `Colors.black` literal.
  static const Color blackColor = Colors.black;

  // Staff specific colors
  //
  // The active/inactive badge pair is reused for two distinct UI elements in
  // StaffCard: the classroom-name badge (always "active" styled) and the
  // schedule day-of-week chips (active = has a schedule that day).
  static const Color staffBadgeActiveBg = Color(
    0x4DB1AFE9,
  ); // Active badge background (classroom badge; schedule day with a shift)
  static const Color staffBadgeInactiveBg = Color(
    0xFFF3F4FB,
  ); // Inactive badge background (schedule day with no shift)
  static const Color staffBadgeActiveText = Color(
    0xFF4B5B7A,
  ); // Active badge text
  static const Color staffBadgeInactiveText = Color(
    0xFFB1AFC9,
  ); // Inactive badge text
  static const Color staffLightBackgroundColor = Color(
    0xFFF8F7FA,
  ); // Light panel/input fill background
  static const Color staffLightBackgroundAltColor = Color(
    0xFFF4F4FB,
  ); // Second light background variant (distinct from staffBadgeInactiveBg's F3F4FB)
  static final Color staffVeryLightGrey = Colors.grey.shade50;
  static const Color staffPhotoUploadOverlayColor = Color(
    0xB3241631,
  ); // Dark scrim over the avatar while a profile-photo upload is in flight
  static final Color staffWarningBannerBg = Colors.orange.shade50;
  static final Color staffWarningBannerBorder = Colors.orange.shade100;
  static final Color staffWarningBannerText = Colors.orange.shade800;
  static final Color staffInfoBannerBg = Colors.blue.shade50;
  static const Color staffInfoText = Colors.blue;
  static final Color staffMutedBlueGreyText = Colors.blueGrey.shade700;

  // Activity module colors — Mandate 4 sweep
  //
  // "Soft purple field/pill" background — a Container decoration applied to
  // date-picker trigger pills, staff-signature bands, and read-only info
  // fields; every call site chains the SAME `.withValues(alpha: 0.102)` onto
  // this base value, so the base is kept as an alias (like [blackColor])
  // rather than baking the alpha into the constant (recurs 5x: date_widget,
  // view_widget, activity_custom_tab, activity_daily_tab,
  // staff_present_widget).
  static const Color activitySoftPurpleFieldColor = Color(0xFFB1AFE9);

  /// Light purple border tint — same value as [billingBorderLight], kept as
  /// an independent activity-scoped alias per the codebase's feature-scoping
  /// convention (recurs 2x: staff_present_widget, upload_photo_video).
  static const Color activityBorderLight = Color(0x1AB1AFE9);

  /// Signature-ID caption text = [primaryColor] base hex @ 50% alpha (recurs
  /// 1x: staff_present_widget's "Signature-ID - ..." label).
  static const Color activityTextColorMuted50 = Color(0x80573353);

  /// Dark circular icon backdrop / shadow tint — used behind play/pause,
  /// remove, and rotate icon buttons on photo/video previews. Numerically
  /// identical to `Colors.black54` (recurs 4x: upload_photo_video's rotate
  /// button backdrop, play/pause circle, remove-button circle, and
  /// view_activity_media's play/pause circle).
  static const Color activityIconBackdropColor = Color(0x8A000000);

  // "Processing" media banner/placeholder palette — shared verbatim across
  // photo_activity, view_activity_media, and avtivity_media_preview.
  static const Color activityProcessingBg = Color(
    0xFFF2F8FF,
  ); // Banner/placeholder background (recurs 2x)
  static const Color activityProcessingBorder = Color(
    0xFFD5E9FF,
  ); // Banner border, photo_activity only (recurs 1x)
  static const Color activityProcessingAccent = Color(
    0xFF1A73E8,
  ); // Spinner accent blue (recurs 3x)
  static const Color activityProcessingText = Color(
    0xFF1F3B64,
  ); // "Processing..." caption text (recurs 3x)

  // avtivity_media_preview's own "processing card" gradient — visually
  // close to but distinct from [activityProcessingBg], kept separate rather
  // than merged (recurs 1x each).
  static const Color activityProcessingCardGradientStart = Color(0xFFEAF4FF);
  static const Color activityProcessingCardGradientEnd = Color(0xFFF5F9FF);

  // avtivity_media_preview's "PROCESSING" badge chip — a distinct blue from
  // [activityProcessingAccent]/[activityProcessingBorder], not merged since
  // the exact shades differ (recurs 1x each).
  static const Color activityProcessingBadgeBg = Color(0xFFD7E9FF);
  static const Color activityProcessingBadgeText = Color(0xFF1A56A5);

  // activity_daily_tab.dart's own pastel palette used to color-code
  // classroom/activity chips by `index % list.length`. NOT unified with the
  // pre-existing [colorPalette] (used the same way by activity_custom_tab):
  // colorPalette has a 9th entry (0xFFCCFF90) inserted mid-sequence, so
  // pointing daily_tab at it would shift every color assigned to an index
  // past the insertion point — a silent, untestable visual regression.
  // Hosting daily_tab's original 8-entry list here (same values, same
  // order) satisfies Mandate 4 without touching either file's behavior.
  static final List<Color> activityDailyColorPalette = [
    const Color(0xFFB3E5FC),
    const Color(0xFFFFCCBC),
    const Color(0xFFC8E6C9),
    const Color(0xFFFFE0B2),
    const Color(0xFFE1BEE7),
    const Color(0xFF80DEEA),
    const Color(0xFFD1C4E9),
    const Color(0xFFFFAB91),
  ];

  // Approval-status legend (activityApprovalStatusBadgeColor in
  // activity_daily_tab.dart) — background per moderation status.
  static const Color activityApprovalStatusNotRequiredColor = Color(
    0xFFE7E7E7,
  ); // NOT_REQUIRED (neutral grey)
  static const Color activityApprovalStatusPendingColor = Color(
    0xFFF3DE8A,
  ); // PENDING_ADMIN_APPROVAL / PARENT_ACKNOWLEDGEMENT_PENDING (recurs 2x)
  static const Color activityApprovalStatusApprovedColor = Color(
    0xFFBFE9D0,
  ); // APPROVED / ACKNOWLEDGED (recurs 2x)
  static const Color activityApprovalStatusRejectedColor = Color(
    0xFFFFC8C8,
  ); // REJECTED
  static const Color activityApprovalStatusDefaultColor = Color(
    0xFFE9E2F7,
  ); // Unknown/default status fallback

  /// Search box fill background (activity_student_selection's classroom
  /// student-search field). Same value as [staffLightBackgroundColor], kept
  /// as an independent activity-scoped constant.
  static const Color activitySearchFieldBg = Color(0xFFF8F7FA);

  // Classroom module colors — Mandate 4 sweep
  //
  // Primary text color for classroom detail cards, roster rows, and dropdown
  // labels (was `Color(0xff573353)`) — same value as [billingTextColor],
  // kept as an independent classroom-scoped alias per the codebase's
  // feature-scoping convention (recurs 20x+).
  static const Color classroomTextColor = Color(0xff573353);

  /// Light mauve border for search bars and dropdown fields across the
  /// classroom feature (was `Color.fromARGB(255, 188, 173, 186)`, recurs 8x).
  static const Color classroomBorderColor = Color.fromARGB(255, 188, 173, 186);

  /// Light grey border for the classroom-detail cards on
  /// [ClassroomInfoScreen] (was `Color.fromARGB(255, 232, 234, 234)`).
  static const Color classroomCardBorderColor = Color.fromARGB(
    255,
    232,
    234,
    234,
  );

  /// Bright "good" status: signed-in attendance dot, ratio-met icon (was
  /// bare `Colors.green`).
  static const Color classroomPositiveStatusColor = Colors.green;

  /// Bright "bad" status: absent attendance dot, ratio-not-met icon, error
  /// text (was bare `Colors.red`).
  static const Color classroomNegativeStatusColor = Colors.red;

  /// Muted icon/text tint — empty-state icons, help tooltips (was bare
  /// `Colors.grey`).
  static const Color classroomMutedIconColor = Colors.grey;

  /// Roster-row border (was `Colors.grey[300]`/`Colors.grey.shade300`).
  static const Color classroomRowBorderColor = Color(0xFFE0E0E0);

  /// Greyed-out roster-row background for staff/students not expected today
  /// (was `Colors.grey[100]`).
  static const Color classroomRowGreyedBackgroundColor = Color(0xFFF5F5F5);

  /// Dropdown placeholder/hint text, e.g. an unselected designation filter
  /// (was `Colors.grey[600]`).
  static const Color classroomPlaceholderTextColor = Color(0xFF757575);

  /// Search-field hint text on the assign-staff/assign-student forms (was
  /// `Colors.grey[700]`).
  static const Color classroomSearchFieldHintColor = Color(0xFF616161);

  /// Status-filter chip background on the staff/students tab cards (was
  /// `Color.fromRGBO(177, 175, 233, 0.3)`).
  static const Color classroomStatusChipBackgroundColor = Color.fromRGBO(
    177,
    175,
    233,
    0.3,
  );

  /// Roster scrollbar thumb color on the staff tab card (was
  /// `Color.fromRGBO(222, 228, 253, 1)`).
  static const Color classroomScrollbarThumbColor = Color.fromRGBO(
    222,
    228,
    253,
    1,
  );

  /// Message/mail icon accent on a staff roster row (was
  /// `Color.fromRGBO(44, 99, 226, 1)`).
  static const Color classroomMessageIconColor = Color.fromRGBO(
    44,
    99,
    226,
    1,
  );

  /// Search-field hint text on the students tab card's own search bar — 70%
  /// [primaryColor] (was `Color.fromRGBO(87, 51, 83, 0.7)`).
  static final Color classroomSearchHintTextColor = primaryColor.withValues(
    alpha: 0.7,
  );

  /// Neutral pastel tint: selected-row background on the assign forms, and
  /// the Ratio Monitoring table's "Classroom" header column (was
  /// `Color.fromRGBO(249, 245, 250, 1)` / `Color.fromARGB(255, 249, 245,
  /// 250)` — numerically identical, same use).
  static const Color classroomNeutralTintColor = Color.fromRGBO(
    249,
    245,
    250,
    1,
  );

  /// Ratio Monitoring table's "Students" header column background (was
  /// `Color.fromRGBO(234, 240, 253, 1)`).
  static const Color classroomRatioStudentsHeaderColor = Color.fromRGBO(
    234,
    240,
    253,
    1,
  );

  /// Ratio Monitoring table's "Staff" header column background (was
  /// `Color.fromRGBO(234, 251, 255, 1)`).
  static const Color classroomRatioStaffHeaderColor = Color.fromRGBO(
    234,
    251,
    255,
    1,
  );

  /// Ratio Monitoring table's "Ratio" header column background (was
  /// `Color.fromRGBO(255, 245, 234, 1)`).
  static const Color classroomRatioCurrentHeaderColor = Color.fromRGBO(
    255,
    245,
    234,
    1,
  );

  /// Ratio Monitoring table header sub-label text, e.g. "Present"/"Current"
  /// (was `Colors.grey.shade800`).
  static const Color classroomRatioHeaderSubtextColor = Color(0xFF424242);

  /// [ClassroomInfoShimmer]'s loading-skeleton base/highlight — kept
  /// separate from [classroomRowBorderColor] despite an identical base
  /// value, matching this file's existing shimmer-vs-border convention (see
  /// [attendanceShimmerBaseColor]).
  static const Color classroomShimmerBaseColor = Color(0xFFE0E0E0);
  static const Color classroomShimmerHighlightColor = Color(0xFFF5F5F5);

  // Bare Colors.* sweep, grouped by confirmed semantic role (see per-file
  // recon before this batch was written).
  static const Color activityUploadSuccessColor =
      Colors.green; // Upload-complete icon/text (recurs 18x)
  static const Color activityUploadWarningColor =
      Colors.orange; // Upload-incomplete icon/text (recurs 8x)
  static const Color activityRequiredFieldMarkerColor =
      Colors.red; // Required-field "*" marker (recurs 6x)
  static const Color activityErrorTextColor =
      Colors.red; // Validation/error message + destructive action text (recurs 3x)
  static const Color activityMediaPlaceholderIconColor =
      Colors.white70; // Icon/text tint on photo/video placeholder overlays (recurs 8x)
  static const Color activityMutedGreyColor =
      Colors.grey; // Muted text/icon/border (recurs 9x, incl. 2 .withValues() derivatives)
  static const Color activityPlaceholderTextColor = Color(
    0xFF757575,
  ); // Hint/placeholder/unselected text (was Colors.grey[600] / grey.shade600, recurs 6x)
  static const Color activitySearchHintColor = Color(
    0xFF616161,
  ); // Search field hint text (was Colors.grey[700], recurs 1x)
  static const Color activityVideoPlaceholderBg = Color(
    0xFF424242,
  ); // Video-thumbnail loading placeholder background (was Colors.grey[800], recurs 2x)
  static const Color activityMediaLoadingPlaceholderBg = Color(
    0xFFE0E0E0,
  ); // Photo/video thumb loading/error placeholder bg (was Colors.grey[300], recurs 2x)
  static const Color activityDisabledButtonBg = Color(
    0xFFE0E0E0,
  ); // Disabled "Choose Media" button background (was Colors.grey[300], recurs 1x)
  static const Color activityBodyTextColor = Color(
    0xDD000000,
  ); // Selected/primary body text (was Colors.black87, recurs 4x)
  static const Color activityTooltipBackgroundColor = Color(
    0xDD000000,
  ); // Black tooltip bubble background (was Colors.black87, recurs 2x)
  static const Color activityMediaPlaceholderBg =
      Colors.black12; // Media placeholder container tint, alpha applied per call site (recurs 3x)
  static const Color activityVideoProgressTrackColor =
      Colors.white24; // Video-progress unplayed track (recurs 1x)
  static const Color activityVideoProgressBufferedColor =
      Colors.white38; // Video-progress buffered segment (recurs 1x)

  // Auth module colors — Mandate 4 sweep
  //
  // Primary headings/icons/body text across sign-in, org/school selection,
  // and password screens (was `Color(0xFF333333)`, recurs 17x).
  static const Color authPrimaryTextColor = Color(0xFF333333);

  /// Org/school selection accent text — same value as [billingTextColor],
  /// kept as an independent auth-scoped alias per the codebase's
  /// feature-scoping convention (was `Color(0xFF573353)`, recurs 5x).
  static const Color authAccentTextColor = Color(0xFF573353);

  /// Thin divider line under the "Select Organization/School" heading (was
  /// `Color(0xFFFFF3E9)`, recurs 4x).
  static const Color authDividerColor = Color(0xFFFFF3E9);

  /// Password field background — same value as [billingSurfaceLight] (was
  /// `Color(0xFFF8F9FA)`, recurs 3x).
  static const Color authSurfaceLight = Color(0xFFF8F9FA);

  /// Password-strength "met" indicator (icon, banner text, success circle) —
  /// was both bare `Colors.green` and the identical `Color(0xFF4CAF50)`
  /// (recurs 3x).
  static const Color authSuccessColor = Colors.green;

  /// Field label above each password input, and the show/hide eye icon (was
  /// `Color(0xFF888888)`, recurs 4x).
  static const Color authFieldLabelColor = Color(0xFF888888);

  /// Password field placeholder/hint text (was `Color(0xFFBBBBBB)`).
  static const Color authHintTextColor = Color(0xFFBBBBBB);

  /// Password field border (was `Color(0xFFEEEEEE)`).
  static const Color authInputBorderColor = Color(0xFFEEEEEE);

  /// Password-strength "met" banner background (was `Color(0xFFEFFBEF)`).
  static const Color authSuccessBackgroundColor = Color(0xFFEFFBEF);

  /// Muted icon tint, e.g. the sign-out confirmation sheet (was bare
  /// `Colors.grey`).
  static const Color authMutedIconColor = Colors.grey;

  /// Bottom-sheet drag handle (was `Colors.grey[300]`, equivalent to
  /// `Colors.grey.shade300`).
  static final Color authDragHandleColor = Colors.grey.shade300;

  /// Role label under the user's name on org/school selection (was
  /// `Colors.grey.shade600`, recurs 2x).
  static final Color authSecondaryTextColor = Colors.grey.shade600;

  // User profile module colors — Mandate 4 sweep
  //
  // Primary purple-brown text — same value as [billingTextColor] /
  // [authAccentTextColor], kept as an independent user-profile-scoped alias
  // (was `Color(0xff573353)`, recurs 11x).
  static const Color userProfileTextColor = Color(0xff573353);

  /// Card/input border — same value as [billingBorderDefault] (user-profile
  /// text @ 40% alpha) (was `Color(0x66573353)`).
  static const Color userProfileBorderColor = Color(0x66573353);

  /// Muted icon tint (was bare `Colors.grey`, recurs 2x).
  static const Color userProfileMutedIconColor = Colors.grey;

  /// Disabled "Save" button background on the edit-profile form — same
  /// value as [billingButtonDisabled] (was `Colors.grey[300]`).
  static final Color userProfileDisabledButtonColor = Colors.grey[300]!;

  /// Disabled "Country" field text on the edit-profile form (was
  /// `Colors.grey.shade700`).
  static final Color userProfileSecondaryTextColor = Colors.grey.shade700;

  /// Validation/required-field marker (was bare `Colors.red`, recurs 2x).
  static const Color userProfileErrorColor = Colors.red;

  /// "Soft purple" header/badge background — same value as
  /// [activitySoftPurpleFieldColor] (was `Color(0xFFB1AFE9)`, recurs 2x).
  static const Color userProfileSoftPurpleColor = Color(0xFFB1AFE9);

  /// Divider — same value as [billingDividerLight] (was `Color(0xFFE9ECEF)`,
  /// recurs 2x).
  static const Color userProfileDividerColor = Color(0xFFE9ECEF);

  /// Divider between the work-schedule and break-schedule sections on the
  /// profile screen (was `Color(0xFFF0ECF4)`).
  static const Color userProfileSectionDividerColor = Color(0xFFF0ECF4);

  /// Light panel background — same value as [staffLightBackgroundColor] (was
  /// `Color(0xFFF8F7FA)`).
  static const Color userProfileLightBackgroundColor = Color(0xFFF8F7FA);

  /// Disabled notification-channel checkbox fill (was `Colors.grey.shade300`).
  static final Color userProfileDisabledCheckboxFillColor =
      Colors.grey.shade300;

  /// Disabled notification-channel checkbox border (was
  /// `Colors.grey.shade400`).
  static final Color userProfileDisabledCheckboxBorderColor =
      Colors.grey.shade400;

  // Onboarding module colors — Mandate 4 sweep
  //
  // Inactive page-indicator dot (was `Colors.grey.shade300`).
  static final Color onboardingInactiveDotColor = Colors.grey.shade300;
}
