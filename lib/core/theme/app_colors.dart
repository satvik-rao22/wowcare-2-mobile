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

  // AutoPay payment methods screen — Mandate 4 sweep
  static const Color billingAutopayTagBackground = Color(
    0xFFEEE9FF,
  ); // "AutoPay"/tag chip background
  static const Color billingAutopayTagForeground = Color(
    0xFF6F52FF,
  ); // "AutoPay"/tag chip text+icon, add-method accent
  static const Color billingMutedSlateText = Color(
    0xFF718096,
  ); // "Saving your payment method…" caption
  static const Color billingSelectedCardBackground = Color(
    0xFFF1FFF6,
  ); // Selected payment-method card fill
  static const Color billingEditActionColor = Color(
    0xFF667EEA,
  ); // Edit icon action button
  static const Color billingDeleteActionColor = Color(
    0xFFE53E3E,
  ); // Delete icon action button
  static const Color billingEcheckCardBackground = Color(0xFFE8F4FC);
  static const Color billingEcheckCardBorder = Color(0xFFB8DAEF);
  static const Color billingEcheckTitleColor = Color(0xFF334455);
  static const List<Color> billingVisaGradientColors = [
    Color(0xFF667EEA),
    Color(0xFF764BA2),
  ];
  static const List<Color> billingMastercardGradientColors = [
    Color(0xFFF093FB),
    Color(0xFFF5576C),
  ];
  static const List<Color> billingDiscoverGradientColors = [
    Color(0xFFFF9966),
    Color(0xFFFF5E62),
  ];
  static const List<Color> billingGenericCardGradientColors = [
    Color(0xFF5B5B5B),
    Color(0xFF1A1A1A),
  ];
  static const List<Color> billingCardChipGradientColors = [
    Color(0xFFD1D1D1),
    Color(0xFFFCFCFC),
  ];
  static const Color billingAddMethodButtonBackground = Color(0xFFF7F6FD);

  // Grey/black/white shade aliases used by the auto-pay screens (billing-scoped
  // per the codebase's per-feature token convention).
  static const Color billingBorderStrong = Color(
    0xFFE0E0E0,
  ); // was Colors.grey.shade300
  static const Color billingBadgeInactiveBackground = Color(
    0xFFEEEEEE,
  ); // was Colors.grey.shade200 (badge/border fill)
  static const Color billingMutedIconColor = Color(
    0xFF9E9E9E,
  ); // was Colors.grey.shade500 / bare Colors.grey
  static const Color billingCaptionTextColor = Color(
    0xFF757575,
  ); // was Colors.grey.shade600
  static const Color billingBlackText87 = Color(0xDD000000); // Colors.black87
  static const Color billingBlackText54 = Color(0x8A000000); // Colors.black54
  static const Color billingBlackText26 = Color(0x42000000); // Colors.black26
  static const Color billingDetailLabelOnDark = Color(
    0xB3FFFFFF,
  ); // Colors.white70, detail label on a dark/gradient card
  static const Color billingCardOnColorText =
      Colors.white; // Text/icon painted on a gradient or dark card surface

  // Receive-payment / issue-refund screen — Mandate 4 sweep
  static const Color billingBorderFaint = Color(
    0x33573353,
  ); // billing text @ 20% alpha — unfocused amount-row border
  static const Color billingInactiveFieldBackground = Color(
    0xFFF4F4F6,
  ); // Amount box fill when `active` is false
  static const List<Color> billingAvatarPalette = [
    Color(0xFFB983FF),
    Color(0xFFF6D365),
    billingAccentBlue,
    Color(0xFF7ED9A6),
    Color(0xFFFF9AA2),
  ]; // Sibling-row initials-avatar background palette (indexed by name hash)
  static const Color billingUserAvatarBackground =
      Colors.orange; // Transaction user-info initials avatar

  // Analytics section — Mandate 4 sweep
  static const List<Color> billingRevenueGradientColors = [
    Color(0xFF1BB686),
    Color(0xFF31C9A5),
  ];
  static const List<Color> billingInvoicedGradientColors = [
    Color(0xFF5A86FF),
    Color(0xFF3F7DE3),
  ];
  static const List<Color> billingRefundsGradientColors = [
    Color(0xFFFF5A68),
    Color(0xFFEF3D4B),
  ];
  static const List<Color> billingSubsidyBalanceGradientColors = [
    Color(0xFFFFC453),
    Color(0xFFFFA600),
  ];
  static const List<Color> billingSubsidyInvoicedGradientColors = [
    Color(0xFF8E6EFF),
    Color(0xFF6A57E0),
  ];
  static const List<Color> billingSubsidyReceivedGradientColors = [
    Color(0xFF2BC7A2),
    Color(0xFF1CA482),
  ];
  static const Color billingChartGridLineColor = Color(0xFFE9E8EF);
  static const Color billingChartZeroLineColor = Color(0xFFCFCAD8);

  // Add-credit / receipt screens — Mandate 4 sweep
  static const Color billingFamilyAvatarBackground = Color(0xFF67C2A6);

  // AutoPay new-method screen — Mandate 4 sweep
  static const Color billingInfoBannerBackground = Color(
    0xFFFFF3E0,
  ); // "Outstanding balance" info block
  static const Color billingInfoBannerBorder = Color(0x4DFDB813);
  static const Color billingWarningIconColor = Color(
    0xFFDD6B20,
  ); // Shared by both info/fee banners on this screen
  static const Color billingInfoBannerTextColor = Color(0xFFD97706);
  static const Color billingFeeBannerBackground = Color(0xFFFFFAF0);
  static const Color billingFeeBannerBorder = Color(0x40FF9F40);
  static const Color billingFeeBannerTextColor = Color(0xFFC05621);

  // General ledger detail screen — Mandate 4 sweep
  static const Color billingLedgerDebitColor = Color(0xFFF85A5A);
  static const Color billingLedgerCreditColor = Color(0xFF4CAF50);
  static const Color billingLedgerTypeChipColor = Color(0xFF1565C0);

  // Create-invoice-type dialog — Mandate 4 sweep
  static const Color billingHighlightSecondaryText =
      Colors.white70; // Secondary/caption text on the highlighted (selected) tile
  static const Color billingHighlightIconBackground =
      Colors.white24; // Icon backdrop on the highlighted tile

  // Sibling-cards stats legend — Mandate 4 sweep
  static const Color billingSiblingPaidColor = Color(0xFF2E9E5B);
  static const Color billingSiblingRefundedColor = Color(0xFFE08600);
  static const Color billingSiblingUnpaidColor = Color(0xFFD64545);

  // Amount-invoiced stat bar legend — Mandate 4 sweep (own palette, distinct
  // from the sibling-cards legend above)
  static final Color billingStatBarNetPaidColor = Colors.greenAccent.shade100;
  static final Color billingStatBarOutstandingColor = Colors.redAccent.shade100;
  static const Color billingStatBarInProcessColor = Colors.yellow;

  /// Popup drag-handle circle — same value as the second stop of
  /// [primaryGradientColors]/[secondaryGradientColors], kept as its own
  /// named token since it's used standalone here, not as part of a gradient.
  static const Color billingCircleAccentColor = Color.fromRGBO(
    156,
    132,
    255,
    1,
  );

  /// Selected-chip tint on the generate-statement screen — same value as
  /// [attendanceSelectedTintColor], kept billing-scoped per convention.
  static const Color billingSelectedTintColor = Color.fromRGBO(
    249,
    245,
    250,
    1,
  );

  /// Shimmer skeleton base — same value as [billingBorderStrong]
  /// (`Colors.grey.shade300`), kept as its own alias since the role
  /// (loading placeholder) is distinct from a border.
  static const Color billingShimmerBaseColor = billingBorderStrong;
  static const Color billingShimmerHighlightColor = Color(
    0xFFF5F5F5,
  ); // was Colors.grey.shade100

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
  static const Color activityErrorTextColor = Colors
      .red; // Validation/error message + destructive action text (recurs 3x)
  static const Color activityMediaPlaceholderIconColor = Colors
      .white70; // Icon/text tint on photo/video placeholder overlays (recurs 8x)
  static const Color activityMutedGreyColor = Colors
      .grey; // Muted text/icon/border (recurs 9x, incl. 2 .withValues() derivatives)
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
  static const Color activityMediaPlaceholderBg = Colors
      .black12; // Media placeholder container tint, alpha applied per call site (recurs 3x)
  static const Color activityVideoProgressTrackColor =
      Colors.white24; // Video-progress unplayed track (recurs 1x)
  static const Color activityVideoProgressBufferedColor =
      Colors.white38; // Video-progress buffered segment (recurs 1x)

  // Student specific colors
  //
  // General white alias so bare `Colors.white` surfaces/icons resolve through
  // AppColors, matching the existing [blackColor] alias.
  static const Color whiteColor = Colors.white;

  // Profile status-chip palette (StudentAboutTabCard): each status pairs a
  // saturated label color with a 10%-alpha background of the same hue.
  // Waitlist/Graduated reuse [secondaryColor] (label) + [staffBadgeActiveBg]
  // (background) — no dedicated token needed.
  static const Color studentStatusActiveColor = Color(
    0xFF38C820,
  ); // Active label (was rgbo(56,200,32,1))
  static const Color studentStatusActiveBg = Color(
    0x1A38C820,
  ); // Active chip bg (was rgbo(56,200,32,0.1))
  static const Color studentStatusInactiveColor = Color(
    0xFFFA4141,
  ); // Inactive label (was rgbo(250,65,65,1))
  static const Color studentStatusInactiveBg = Color(
    0x1AFA4141,
  ); // Inactive chip bg (was rgbo(250,65,65,0.1))
  static const Color studentStatusUpcomingColor = Color(
    0xFF8A6E00,
  ); // Upcoming label (was fromARGB(255,138,110,0))
  static const Color studentStatusUpcomingBg = Color(
    0xFFF2EEB0,
  ); // Upcoming chip bg (was fromARGB(255,242,238,176))

  // Health / immunization / important-dates status palette (health tab cards):
  // a saturated hue for icons/labels plus a 10%-alpha tint of the same hue for
  // the row/badge background. [errorColor] (0xFFD32F2F) covers the red case;
  // [studentErrorBg] is its 10% tint.
  static const Color studentHealthOrangeColor = Color(0xFFEF6C00); // overdue/warning
  static const Color studentHealthOrangeBg = Color(0x1AEF6C00);
  static const Color studentHealthYellowColor = Color(0xFFEABA00); // due-soon
  static const Color studentHealthYellowBg = Color(0x1AEABA00);
  static const Color studentStatusActiveBgSolid = Color(
    0xFFE8F5E9,
  ); // solid green "complete" background (was 0xFFE8F5E9)
  static const Color studentErrorBg = Color(0x1AD32F2F); // errorColor @ 10%
  static const Color studentHealthRedDark = Color(0xFFC62828); // strong error text
  static const Color studentHealthGreenDark = Color(0xFF1B5E20); // strong success text
  static const Color studentHealthBlue = Color(0xFF3B82F6); // info accent
  static const Color studentHealthRedBg = Color(0xFFFFEBEE); // light error background
  static const Color studentHealthBlueBg = Color(0xFFE8F1FE); // light info background
  static const Color studentAmberBg = Color(0xFFFFF8E1); // light amber background

  // Neutral greys used across student cards/forms.
  static const Color studentMutedText = Color(0xFF6C6377); // muted plum-grey label/icon
  static const Color studentBorderGrey = Color(0xFFC9C5CE); // input/card border
  static const Color studentDisabledGrey = Color(0xFFB8B3BE); // disabled/placeholder
  static const Color studentDividerGrey = Color(0xFFECEFF1); // light divider/border
  static const Color studentSurfaceGrey = Color(0xFFF2F2F2); // light surface fill
  static const Color studentGrey = Color(0xFF828282); // medium neutral text/icon
  static const Color studentDarkPlum = Color(0xFF241631); // avatar/photo overlay base

  // Purple / lavender accents (add-student wizard, chips).
  static const Color studentLavenderTint = Color(0x66EAD6FF); // light lavender chip bg
  static const Color studentLavenderBorder = Color(
    0xB3C8BFFF,
  ); // lavender border (was rgbo(200,191,255,0.7))
  static const Color studentPurpleTint = Color(
    0xFFF1EAFF,
  ); // light purple fill (was rgbo(241,234,255,1))
  static const Color studentPurple = Color(
    0xFFAA8DFF,
  ); // purple accent (was rgbo(170,141,255,1))
  static const Color studentAccentPurple = Color(
    0xFF9C84FF,
  ); // gradient purple accent (was rgbo(156,132,255,1))

  // Info blue (was bare Colors.blue / Colors.blue[50]).
  static const Color studentInfoColor = Color(0xFF2196F3);
  static const Color studentInfoBg = Color(0xFFE3F2FD);
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
  // ── Reports (Mandate M4) ────────────────────────────────────────────────
  /// Error-state icon on the Generated-reports failure panel. This is the
  /// exact value of the `Colors.red` it replaced (#F44336), NOT
  /// [errorColor] (#D32F2F) — substituting the nearer token would have
  /// changed the rendered colour. Worth consolidating with [errorColor] as a
  /// deliberate design decision, not as part of a centralisation pass.
  static const Color reportsErrorIconColor = Color(0xFFF44336);

  /// Muted/inactive grey across the reports module — empty-state icons,
  /// file-preview placeholder icons, unselected checkbox borders and the
  /// disabled download gradient. Exact value of the `Colors.grey[400]` /
  /// `Colors.grey.shade400` it replaced (#BDBDBD). Shares its hex with
  /// [dividerColor] but means "inactive", not "rule between rows".
  static const Color reportsMutedColor = Color(0xFFBDBDBD);

  /// Indigo accent — section labels and the "All ... selected by default"
  /// notes. Exact value of the `Color(0xff4F46E5)` it replaced.
  static const Color reportsAccentColor = Color(0xFF4F46E5);

  /// Hairline divider inside the report cards (#E9ECEF).
  static const Color reportsCardDividerColor = Color(0xFFE9ECEF);

  /// Inline "could not load classrooms" panel on the report forms.
  static const Color reportsInlineErrorBackgroundColor = Color(0xFFFDECEC);
  static const Color reportsInlineErrorBorderColor = Color(0xFFE53935);
  static const Color reportsInlineErrorTextColor = Color(0xFFB71C1C);

  /// Selected month chip in the month/year picker (#EEEDF0).
  static const Color reportsMonthPickerSelectedColor = Color(0xFFEEEDF0);

  /// Disabled control surface — exact value of `Colors.grey[300]` (#E0E0E0).
  static const Color reportsDisabledSurfaceColor = Color(0xFFE0E0E0);

  /// Disabled control foreground — exact value of `Colors.grey[600]`
  /// / `Colors.grey.shade600` (#757575).
  static const Color reportsDisabledForegroundColor = Color(0xFF757575);

  /// Required-field "*" marker. Same value and meaning as
  /// [activityRequiredFieldMarkerColor]; the two should collapse into one
  /// shared semantic token in a cross-feature pass.
  static const Color reportsRequiredFieldMarkerColor = Colors.red;

  // Individual Movements (Mandate 4) — see
  // lib/presentation/features/availability/**. Board-column background tints
  // are distinct per bucket (Overdue/Upcoming/Confirmed/Rejected); badge and
  // dialog-chrome colors reuse existing semantic tokens where the shade
  // already matches (see [errorColor]/[warningColor]/[successColor] and the
  // `attendanceDialogXxx`/`attendanceBorderLightColor` tokens above).
  static const Color movementOverdueBackground = Color(0xFFF8F6FF);
  static const Color movementUpcomingBackground = Color(0xFFFFFBEE);
  static const Color movementConfirmedBackground = Color(0xFFEFFFF4);
  static const Color movementRejectedBackground = Color(0xFFFFF0F0);
  static const Color movementDialogHeaderColor = Color(
    0xFFF3EEFA,
  ); // Drag/drop confirmation dialog header band
  static const Color movementDueTimeIconColor = Color(
    0xFFF3B413,
  ); // Row clock icon

  // Future Availability (Mandate 4) — see
  // lib/presentation/features/availability/view/future_availability_screen.dart.
  static const Color futureAvailabilityColumnTint = Color.fromRGBO(247, 245, 249, 1);
  static const Color futureAvailabilityHeaderTint = Color.fromRGBO(245, 243, 247, 1);
  static const Color futureAvailabilityToggleTrackBg = Color.fromRGBO(246, 244, 248, 1);
  static const Color futureAvailabilityNegativeCountColor = Color.fromRGBO(236, 99, 99, 1);
  static const Color futureAvailabilityPositiveCountColor = Color.fromRGBO(0, 145, 94, 1);

  // ── Dashboard: geofence attendance state (SEMANTIC) ────────────────────────
  // Mandate 4: these encode whether GPS self-attendance is currently possible,
  // so they are named semantic tokens, not palette entries. Exact hexes carried
  // over from my_day_card.dart — rendered output is unchanged.
  //
  // NOTE (§4.3 accessibility): the inside/outside states are ALSO distinguished
  // by their label text and dot, not by colour alone.

  /// Dot shown when the user is inside the school geofence.
  static const Color geofenceInsideIndicator = Color(0xFF22C55E);

  /// Label text for the inside-geofence state.
  static const Color geofenceInsideText = Color(0xFF16A34A);

  /// Unread-count badge on a dashboard chat-preview row.
  static const Color chatUnreadBadge = Color(0xFF00B894);

  /// Tint behind the chat-preview strip at the foot of the My Day card.
  static const Color chatPreviewSurface = Color.fromRGBO(44, 99, 226, 0.05);

  /// Fill behind the Work Time / Break Time chips on the My Day card.
  static const Color myDayChipSurface = Color.fromRGBO(177, 175, 233, 0.3);

  // ── Dashboard: disabled / shimmer chrome ──────────────────────────────────

  /// Label of a disabled self-attendance action button.
  static const Color disabledActionLabel = Color(0xFF757575); // Colors.grey[600]

  /// Border of a disabled self-attendance action button.
  static const Color disabledActionBorder = Color(0xFFBDBDBD); // Colors.grey[400]

  /// Shimmer skeleton base / highlight.
  static const Color shimmerBase = Color(0xFFE0E0E0);      // Colors.grey[300]
  static const Color shimmerHighlight = Color(0xFFF5F5F5); // Colors.grey[100]

  // ── Newsletter (Mandate 4) ────────────────────────────────────────────────
  // Feature-prefixed, matching the `billing*` convention already in this file.
  //
  // NOTE FOR THE OTHER MODULES: the newsletter's *content* colours are NOT
  // here and must not be. `NewsletterThemeColors` resolves a per-newsletter
  // palette chosen by the author (vibrant / ocean / forest / sunset /
  // professional) — that is DATA arriving with the record, not app theming.
  // Only the app's own chrome around the content is tokenised below.

  /// Unselected newsletter tab label. Was `Color.fromARGB(50, 36, 22, 49)`.
  static const Color newsletterTabUnselectedLabel = Color.fromARGB(
    50,
    36,
    22,
    49,
  );

  /// Unselected newsletter tab chip fill. Was
  /// `Color.fromARGB(102, 203, 246, 255)`.
  static const Color newsletterTabUnselectedBackground = Color.fromARGB(
    102,
    203,
    246,
    255,
  );

  /// Attachment tile fill in the preview grid.
  /// Was `Color.fromRGBO(244, 247, 254, 1)`.
  static const Color newsletterAttachmentTileBackground = Color.fromRGBO(
    244,
    247,
    254,
    1,
  );

  /// Document (non-image) thumbnail fill on a list card, when the asset
  /// resolved. Was `Color(0xFFEAF2FF)`.
  static const Color newsletterDocumentThumbnailBackground = Color(0xFFEAF2FF);

  /// Document thumbnail fill when no asset resolved, and the fallback behind a
  /// failed placeholder image. Was `Colors.grey.shade200`.
  static const Color newsletterThumbnailPlaceholderBackground = Color(
    0xFFEEEEEE,
  );

  /// Letterbox behind a component image while it loads.
  /// Was `Colors.grey.shade100`.
  ///
  /// Same hex as [shimmerHighlight] but a different meaning, so it is its own
  /// token rather than a reuse (§4: a colour that encodes meaning gets a named
  /// semantic token).
  static const Color newsletterImageLoadingBackground = Color(0xFFF5F5F5);

  /// Background of the "loaded from cache, refresh failed" banner on the
  /// preview screen. A SEMANTIC state colour, not a palette entry — it is the
  /// only thing distinguishing a stale newsletter from a fresh one, and it
  /// pairs with the banner's own text. Was `Colors.orange.shade50`.
  static const Color newsletterStaleBannerBackground = Color(0xFFFFF3E0);

  /// Scrim behind the "+N" extra-attachment count on a card thumbnail.
  /// Was `Colors.black.withValues(alpha: 0.65)`.
  static final Color newsletterAttachmentCountScrim = blackColor.withValues(
    alpha: 0.65,
  );

  /// Card surface of the full-screen image preview overlay.
  /// Was `Colors.white.withValues(alpha: 0.95)`.
  static final Color newsletterOverlaySurface = whiteColor.withValues(
    alpha: 0.95,
  );
}
