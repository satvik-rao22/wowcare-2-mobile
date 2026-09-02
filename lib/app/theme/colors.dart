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
}
