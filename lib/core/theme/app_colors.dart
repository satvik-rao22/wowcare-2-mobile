import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// The app's colours, addressed by name.
///
/// This class is a **directory, not a definition**. The semantic tokens below
/// resolve to the roles in [AppPalette], and the feature-scoped ones resolve
/// to [AppPalette], [LegacyHues] or [MaterialHues] wherever their value
/// matches a token. The values themselves live in
/// `lib/core/theme/app_theme_config.dart` — that one file is what re-skins the
/// app, and it is the only place a new colour should be defined.
///
/// Feature-scoped entries (`billing*`, `attendance*`, `activity*`, …) follow
/// the codebase's existing convention: a decorative one-off that means
/// something only inside its own module keeps its own name here, so the
/// semantic layer stays small and honest. When a feature colour turns out to
/// mean "error" or "card surface", point it at the role instead.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────

  /// The headline brand colour: app bars, primary buttons, active states.
  static const Color themeColor = AppPalette.brand;

  /// The default text colour for headings and body copy.
  static const Color primaryColor = AppPalette.textPrimary;

  /// The secondary brand tone.
  static const Color secondaryColor = AppPalette.brandSecondary;

  // ── Surfaces, borders, dividers ───────────────────────────────────────────

  /// The page ground: the warm tray every scaffold, drawer and bar sits on.
  /// Distinct from [cardColor], which is the cooler face of anything *raised*
  /// off that tray.
  static const Color pageBackgroundColor = AppPalette.surfacePage;

  /// A card, sheet or dialog surface.
  static const Color cardColor = AppPalette.surfaceCard;

  static final Color cardBorderColor = AppColors.primaryColor.withValues(
    alpha: 0.15,
  );
  static final Color inputBorderColor = AppColors.primaryColor.withValues(
    alpha: 0.4,
  );

  static const Color transparentColor = Colors.transparent;

  /// The fill behind a form field or an inline chip.
  static const Color fieldBackgroundColor = AppPalette.surfaceField;

  /// A divider between sections.
  static const Color dividerColor = AppPalette.divider;

  // ── Status ────────────────────────────────────────────────────────────────

  /// The highlight/attention colour. Not a status — see [warningColor].
  static const Color accentColor = AppPalette.actionHighlight;

  /// The soft brand wash a badge, banner or selected row sits on.
  static const Color brandSoftColor = AppPalette.brandSoft;

  /// Ink and glyphs on a saturated or dark face. Warm white — the only white
  /// the brand skin has.
  static const Color textOnDarkColor = AppPalette.textOnDark;

  static const Color errorColor = AppPalette.statusError;
  static const Color warningColor = AppPalette.statusWarning;
  static const Color successColor = AppPalette.statusSuccess;

  static const classroomStudentTabColor = AppPalette.domainStudentSoft;
  static const classroomStaffTabColor = AppPalette.domainStaffSoft;
  static const classroomNotesTabColor = AppPalette.surfaceSunken;

  static const Color lightBlueProgressBar = AppPalette.dataTealSoft;
  static const Color mustardProgressBar = AppPalette.dataSun;
  static const Color lightGreenProgressBar = AppPalette.dataGreenSoft;
  static const Color redProgressBar = AppPalette.statusError;
  static const Color refundLegendColor = AppPalette.dataTealSoft;
  static const Color paidLegendColor = AppPalette.statusSuccess;
  static const Color colorBox = AppPalette.dataGreenSoft;
  static const Color colorBox2 = AppPalette.dataOrangeSoft;
  static const Color colorBox3 = AppPalette.dataPurple;

  // ── Staffing-ratio compliance (scheduling week/day views, dashboard) ──────
  //
  // Semantic tokens for ratio state: they are named for the state they mean
  // and are never re-declared at the call site. They deduplicate the
  // `colorBox` values above, which is why both groups resolve to the same
  // palette roles.
  //
  // Colour alone must NOT carry the meaning — every surface using these also
  // renders an icon or text label (see `SchedulingBlockStatusStyle.weekViewIcon`
  // and `ratioBadgeLabel`).

  /// Fewer staff scheduled than required.
  static const Color ratioUnderStaffedColor = AppPalette.statusErrorSoft;

  /// Scheduled staff exactly meets requirement.
  static const Color ratioInRatioColor = AppPalette.statusSuccessSoft;

  /// More staff scheduled than required.
  static const Color ratioExtraStaffColor = AppPalette.brand;

  /// No monitoring data for the block (outside the window, or all counts zero).
  static const Color ratioEmptyColor = AppPalette.borderHairline;

  /// Higher-contrast in-ratio fill used on badges, where the pale
  /// [ratioInRatioColor] would not carry enough contrast against white text.
  static const Color ratioInRatioBadgeColor = AppPalette.statusSuccessStrong;

  // Avatar color palette used exclusively by profile initials widgets
  static const List<Color> profileAvatarColors = <Color>[
    AppPalette.dataPink,
    AppPalette.dataSun,
    AppPalette.dataTeal,
    AppPalette.dataOrange,
    AppPalette.dataGreen,
    AppPalette.dataPurple,
  ];

  static const List<Color> tagColors = <Color>[
    AppPalette.dataSunSoft,
    AppPalette.dataPurpleSoft,
    AppPalette.dataTealSoft,
    AppPalette.dataGreenSoft,
    AppPalette.dataPinkSoft,
    AppPalette.dataOrangeSoft,
    AppPalette.statusInfoSoft,
  ];

  static const List<Color> tagTextColors = <Color>[AppPalette.textPrimary];

  /// Single-value alias for [tagTextColors]'s only entry, usable in const
  /// contexts where indexing into the list isn't const-evaluable.
  static const Color tagTextColor = AppPalette.textPrimary;

  // Billing specific colors
  static const Color billingTextColor =
      AppPalette.textPrimary; // Primary text color for billing
  static const Color billingTextSecondary =
      AppPalette.textSecondary; // Secondary text (with opacity)

  // Transaction badge colors
  static const Color billingInvoiceBadgeColor = AppPalette.statusInfoSoft;
  static const Color billingPaymentBadgeColor = AppPalette.statusSuccessSoft;
  static const Color billingRefundBadgeColor = AppPalette.surfaceMuted;
  static const Color billingDefaultBadgeColor = AppPalette.surfaceField;

  // Transaction status colors
  static const Color billingStatusInProgressColor =
      AppPalette.statusWarningSoft; // Orange
  static const Color billingStatusCancelledColor =
      AppPalette.statusErrorSoft; // Red

  // Card and container colors
  static const Color billingCardColor = AppPalette.surfaceCard;
  static final Color billingCardBorderColor = primaryColor.withValues(
    alpha: 0.2,
  );
  static final Color billingCardShadowColor = AppPalette.shadowAmbient
      .withValues(alpha: 0.03);

  // Divider colors
  static final Color billingDividerColor = primaryColor.withValues(alpha: 0.1);

  // Button colors
  static const Color billingButtonTextColor = AppPalette.textOnDark;

  // Error/Alert colors for billing
  static const Color billingErrorBackgroundColor = AppPalette.statusErrorSoft;
  static const Color billingErrorBorderColor = AppPalette.statusError;
  static const Color billingErrorIconColor = AppPalette.statusError;
  static const Color billingErrorTextColor = AppPalette.statusErrorStrong;

  // Grey shades for billing
  static const Color billingGrey = AppPalette.textMuted;
  static const Color billingGreyLight = AppPalette.surfaceMuted;
  static const Color billingGreyMedium = AppPalette.textMuted;
  static const Color billingGreyDark = AppPalette.textSecondary;
  static final Color billingGreyTransparent = AppPalette.textMuted.withValues(
    alpha: 0.3,
  );

  // Success color
  static const Color billingSuccessColor = AppPalette.statusSuccess;

  // Background colors
  static const Color billingBackgroundColor = AppPalette.surfaceCard;
  static const Color billingTransparentColor = Colors.transparent;

  // Shadow colors
  static final Color billingShadowColor = AppPalette.shadowAmbient.withValues(
    alpha: 0.03,
  );
  static final Color billingShadowColorLight = AppPalette.shadowAmbient
      .withValues(alpha: 0.05);
  static final Color billingShadowColorMedium = AppPalette.shadowAmbient
      .withValues(alpha: 0.08);

  // Border colors with opacity
  static const Color billingBorderLight =
      AppPalette.border; // Light purple border
  static final Color billingBorderMedium = primaryColor.withValues(alpha: 0.2);
  static final Color billingBorderHeavy = primaryColor.withValues(alpha: 0.4);
  static const Color billingDividerLight = AppPalette.divider;

  // Button and input colors
  static const Color billingButtonDisabled = AppPalette.surfaceField;
  static const Color billingInputBorderDefault = AppPalette.borderStrong;
  static final Color billingInputBorderFocused = AppPalette.focusRing;
  static const Color billingInputBackgroundDisabled = AppPalette.surfaceField;

  // Status indicator colors (for success/error states)
  static const Color billingStatusSuccess = AppPalette.statusSuccess;
  static const Color billingStatusError = AppPalette.statusError;

  // AutoPay payment methods screen — Mandate 4 sweep
  static const Color billingAutopayTagBackground =
      AppPalette.brandSoft; // "AutoPay"/tag chip background
  static const Color billingAutopayTagForeground =
      AppPalette.brandDark; // "AutoPay"/tag chip text+icon, add-method accent
  static const Color billingMutedSlateText =
      AppPalette.textSecondary; // "Saving your payment method…" caption
  static const Color billingSelectedCardBackground =
      AppPalette.statusSuccessSoft; // Selected payment-method card fill
  static const Color billingEditActionColor =
      AppPalette.actionSecondary; // Edit icon action button
  static const Color billingDeleteActionColor =
      AppPalette.statusError; // Delete icon action button
  static const Color billingEcheckCardBackground = AppPalette.statusInfoSoft;
  static const Color billingEcheckCardBorder = AppPalette.dataTealSoft;
  static const Color billingEcheckTitleColor = AppPalette.textSecondary;
  static const Color billingVisaCardFace = AppPalette.surfaceInverse;
  static const Color billingMastercardCardFace = AppPalette.surfaceInverse;
  static const Color billingDiscoverCardFace = AppPalette.surfaceInverse;
  static const Color billingGenericCardFace = AppPalette.surfaceInverse;
  static const Color billingCardChipColor = AppPalette.actionHighlight;
  static const Color billingAddMethodButtonBackground =
      AppPalette.surfaceSunken;

  // Grey/black/white shade aliases used by the auto-pay screens (billing-scoped
  // per the codebase's per-feature token convention).
  static const Color billingBorderStrong = AppPalette.borderStrong;
  static const Color billingBadgeInactiveBackground =
      AppPalette.surfaceField; // was Colors.grey.shade200 (badge/border fill)
  static const Color billingMutedIconColor = AppPalette.textMuted;
  static const Color billingCaptionTextColor = AppPalette.textSecondary;
  static const Color billingBlackText87 = AppPalette.textPrimary;
  static const Color billingBlackText54 = AppPalette.textSecondary;
  static const Color billingBlackText26 = AppPalette.textMuted;
  static const Color billingDetailLabelOnDark = MaterialHues
      .white70; // Colors.white70, detail label on a dark/gradient card
  static const Color billingCardOnColorText = AppPalette
      .textOnDark; // Text/icon painted on a gradient or dark card surface

  // Receive-payment / issue-refund screen — Mandate 4 sweep
  static const Color billingBorderFaint = AppPalette
      .border; // billing text @ 20% alpha — unfocused amount-row border
  static const Color billingInactiveFieldBackground =
      AppPalette.surfaceMuted; // Amount box fill when `active` is false
  static const List<Color> billingAvatarPalette = <Color>[
    AppPalette.dataPurple,
    AppPalette.dataSun,
    AppPalette.dataTeal,
    AppPalette.dataGreen,
    AppPalette.dataPink,
  ]; // Sibling-row initials-avatar background palette (indexed by name hash)
  static const Color billingUserAvatarBackground =
      AppPalette.dataOrange; // Transaction user-info initials avatar

  // Analytics section — Mandate 4 sweep
  static const Color billingRevenueSeriesColor = AppPalette.statusSuccess;
  static const Color billingInvoicedSeriesColor = AppPalette.statusInfo;
  static const Color billingRefundsSeriesColor = AppPalette.statusError;
  static const Color billingSubsidyBalanceSeriesColor =
      AppPalette.statusWarning;
  static const Color billingSubsidyInvoicedSeriesColor = AppPalette.dataPurple;
  static const Color billingSubsidyReceivedSeriesColor = AppPalette.dataTeal;
  static const Color billingChartGridLineColor = AppPalette.surfaceField;
  static const Color billingChartZeroLineColor = AppPalette.borderStrong;

  // Add-credit / receipt screens — Mandate 4 sweep
  static const Color billingFamilyAvatarBackground = AppPalette.dataTeal;

  // AutoPay new-method screen — Mandate 4 sweep
  static const Color billingInfoBannerBackground =
      AppPalette.statusWarningSoft; // "Outstanding balance" info block
  static const Color billingInfoBannerBorder = AppPalette.statusWarningSoft;
  static const Color billingWarningIconColor = AppPalette
      .statusWarningStrong; // Shared by both info/fee banners on this screen
  static const Color billingInfoBannerTextColor =
      AppPalette.statusWarningStrong;
  static const Color billingFeeBannerBackground = AppPalette.surfacePage;
  static const Color billingFeeBannerBorder = AppPalette.statusWarningSoft;
  static const Color billingFeeBannerTextColor = AppPalette.statusWarningStrong;

  // General ledger detail screen — Mandate 4 sweep
  static const Color billingLedgerDebitColor = AppPalette.statusError;
  static const Color billingLedgerCreditColor = AppPalette.statusSuccess;
  static const Color billingLedgerTypeChipColor = AppPalette.statusInfo;

  // Create-invoice-type dialog — Mandate 4 sweep
  static const Color billingHighlightSecondaryText = MaterialHues
      .white70; // Secondary/caption text on the highlighted (selected) tile
  static const Color billingHighlightIconBackground =
      AppPalette.onMediaTrack; // Icon backdrop on the highlighted tile

  // Sibling-cards stats legend — Mandate 4 sweep
  static const Color billingSiblingPaidColor = AppPalette.statusSuccess;
  static const Color billingSiblingRefundedColor =
      AppPalette.statusWarningStrong;
  static const Color billingSiblingUnpaidColor = AppPalette.statusError;

  // Amount-invoiced stat bar legend — Mandate 4 sweep (own palette, distinct
  // from the sibling-cards legend above)
  static const Color billingStatBarNetPaidColor = AppPalette.statusSuccessSoft;
  static const Color billingStatBarOutstandingColor =
      AppPalette.statusErrorSoft;
  static const Color billingStatBarInProcessColor =
      AppPalette.statusWarningSoft;

  /// Popup drag-handle circle — same value as the second stop of
  /// [primaryGradientColors]/[secondaryGradientColors], kept as its own
  /// named token since it's used standalone here, not as part of a gradient.
  static const Color billingCircleAccentColor = AppPalette.dataPurple;

  /// Selected-chip tint on the generate-statement screen — same value as
  /// [attendanceSelectedTintColor], kept billing-scoped per convention.
  static const Color billingSelectedTintColor = AppPalette.surfaceSelected;

  /// Shimmer skeleton base — same value as [billingBorderStrong]
  /// (`Colors.grey.shade300`), kept as its own alias since the role
  /// (loading placeholder) is distinct from a border.
  static const Color billingShimmerBaseColor = billingBorderStrong;
  static const Color billingShimmerHighlightColor = AppPalette.surfaceMuted;

  // Additional billing literals centralized (visual-neutral) — Mandate 4 color batch
  static const Color billingBorderDefault = AppPalette
      .borderStrong; // Input/card border = billing text @ 40% alpha (recurs 9x)
  static const Color billingTextMuted = AppPalette
      .textMuted; // Muted secondary text/icons = billing text @ 60% alpha (recurs 6x)
  static const Color billingAccentBlue = AppPalette
      .dataTeal; // Billing accent blue: card _accent, In-Process status, borders (recurs 6x)
  static const Color billingSuccessBackground = AppPalette
      .statusSuccessSoft; // Light green success/primary tag background (recurs 4x)
  static const Color billingSurfaceLight = AppPalette
      .surfaceSunken; // Light grey surface/background fill (recurs 3x)
  static const Color billingCardAccent = AppPalette
      .brand; // Card action accent, kept billing-scoped (same value as attendanceActionAccentColor) (recurs 3x)

  // Activity Custom tab
  static final List<Color> colorPalette = <Color>[
    AppPalette.dataTealSoft,
    AppPalette.dataOrangeSoft,
    AppPalette.dataGreenSoft,
    AppPalette.dataSunSoft,
    AppPalette.dataPurpleSoft,
    AppPalette.dataGreen,
    AppPalette.dataTeal,
    AppPalette.dataPurple,
    AppPalette.dataOrange,
  ];

  // Attendance specific colors
  static const Color attendanceActionAccentColor =
      AppPalette.brand; // Card Edit/Delete outlined button border + label
  static const Color attendanceCardDividerColor =
      AppPalette.divider; // Divider between card sections
  static const Color attendanceDialogBodyTextColor =
      AppPalette.textPrimary; // Dialog body text
  static const Color attendanceDialogHintTextColor =
      AppPalette.textSecondary; // Dialog hint/label text (was Colors.grey[600])
  static const Color attendanceBorderLightColor = MaterialHues
      .grey300; // Input borders / placeholder icon+text (was Colors.grey.shade300 / grey[300])
  static const Color attendanceShimmerBaseColor = MaterialHues
      .grey300; // Loading skeleton base (was Colors.grey.shade300) — kept separate from the border token
  static const Color attendanceShimmerHighlightColor = MaterialHues
      .grey100; // Loading skeleton highlight (was Colors.grey.shade100)
  static const Color attendanceOverlayScrimColor = AppPalette
      .mediaScrim; // Dialog barrier (was Colors.black.withValues(alpha: 0.45))
  static const Color attendanceCardShadowColor = AppPalette
      .shadowAmbient; // Card/popup shadow (was Colors.black.withValues(alpha: 0.1))
  static const Color attendanceInfoHighlightColor = AppPalette
      .brandSoft; // Info tint (was Colors.blue.withValues(alpha: 0.1))
  static const Color attendanceIconColor =
      AppPalette.iconDefault; // Popup icon/label (was bare Colors.black)
  static const Color attendancePopupBarrierColor = MaterialHues
      .black54; // Attendance popup dialog barrier (was Colors.black54)
  static const Color attendanceEmptyStateIconColor =
      AppPalette.textMuted; // "No data" empty-state icon (was Colors.grey[400])
  static const Color attendanceMutedTextColor = MaterialHues
      .grey500; // Muted text/border/icon tint (was bare Colors.grey)
  static const Color attendanceCardBorderColor =
      AppPalette.border; // Thin 1px card border (was Colors.black12)
  static const Color attendanceSearchHintColor =
      AppPalette.textMuted; // Search field hint text (was Colors.grey[700])
  static const Color attendanceBodyText87Color =
      AppPalette.textPrimary; // Body/detail text (was Colors.black87)
  static const Color attendanceStatBlueColor =
      AppPalette.statusInfo; // Profile stat icon/value accent (was raw hex)
  static const Color attendanceStatGreenColor =
      AppPalette.statusSuccess; // "Attended days" stat value (was raw hex)
  static const Color attendanceTabIndicatorColor =
      AppPalette.brand; // Custom-view tab indicator bar (was raw hex)
  static const Color attendanceTabSelectedLabelColor =
      AppPalette.textPrimary; // Custom-view selected tab label (was raw hex)
  static const Color attendanceTabUnselectedLabelColor =
      AppPalette.textMuted; // Custom-view unselected tab label (was raw hex)

  /// Card-container box shadow, lighter than [attendanceCardShadowColor].
  /// Same value as [billingShadowColor] — reused under an attendance-scoped
  /// name so attendance files don't reference a billing-prefixed constant.
  static final Color attendanceCardShadowLightColor = billingShadowColor;

  /// Selected-row/tile background tint, used by every selectable list item
  /// across the attendance selection forms (was
  /// `Color.fromRGBO(249, 245, 250, 1)` / `Color.fromARGB(255, 249, 245, 250)`).
  static const Color attendanceSelectedTintColor = AppPalette.surfaceSelected;

  /// Distinct danger-red accent (was raw `Color.fromRGBO(179, 38, 30, 1)`),
  /// separate from [errorColor] — not merged since the exact shade differs.
  static const Color attendanceDangerAccentColor = AppPalette.statusErrorStrong;

  /// Light purple banner background (was raw
  /// `Color.fromRGBO(243, 238, 250, 1)`).
  static const Color attendanceInfoBannerBackgroundColor =
      AppPalette.surfaceSunken;

  /// General alias so `.withValues(alpha: ...)` derivatives still resolve
  /// through AppColors rather than a bare `Colors.black` literal.
  static const Color blackColor = AppPalette.textPrimary;

  // Staff specific colors
  //
  // The active/inactive badge pair is reused for two distinct UI elements in
  // StaffCard: the classroom-name badge (always "active" styled) and the
  // schedule day-of-week chips (active = has a schedule that day).
  static const Color staffBadgeActiveBg = AppPalette
      .domainStaffSoft; // Active badge background (classroom badge; schedule day with a shift)
  static const Color staffBadgeInactiveBg = AppPalette
      .surfaceMuted; // Inactive badge background (schedule day with no shift)
  static const Color staffBadgeActiveText =
      AppPalette.domainStaffInk; // Active badge text
  static const Color staffBadgeInactiveText =
      AppPalette.textMuted; // Inactive badge text
  static const Color staffLightBackgroundColor =
      AppPalette.surfaceSunken; // Light panel/input fill background
  static const Color staffLightBackgroundAltColor = AppPalette
      .surfaceMuted; // Second light background variant (distinct from staffBadgeInactiveBg's F3F4FB)
  static const Color staffVeryLightGrey = AppPalette.surfaceSunken;
  static const Color staffPhotoUploadOverlayColor = AppPalette
      .mediaScrim; // Dark scrim over the avatar while a profile-photo upload is in flight
  static const Color staffWarningBannerBg = AppPalette.statusWarningSoft;
  static const Color staffWarningBannerBorder = AppPalette.statusWarning;
  static const Color staffWarningBannerText = AppPalette.statusWarningStrong;
  static const Color staffInfoBannerBg = AppPalette.statusInfoSoft;
  static const Color staffInfoText = AppPalette.statusInfo;
  static const Color staffMutedBlueGreyText = AppPalette.textSecondary;

  // Activity module colors — Mandate 4 sweep
  //
  // "Soft purple field/pill" background — a Container decoration applied to
  // date-picker trigger pills, staff-signature bands, and read-only info
  // fields; every call site chains the SAME `.withValues(alpha: 0.102)` onto
  // this base value, so the base is kept as an alias (like [blackColor])
  // rather than baking the alpha into the constant (recurs 5x: date_widget,
  // view_widget, activity_custom_tab, activity_daily_tab,
  // staff_present_widget).
  static const Color activitySoftPurpleFieldColor = AppPalette.brandSecondary;

  /// Light purple border tint — same value as [billingBorderLight], kept as
  /// an independent activity-scoped alias per the codebase's feature-scoping
  /// convention (recurs 2x: staff_present_widget, upload_photo_video).
  static const Color activityBorderLight = AppPalette.border;

  /// Signature-ID caption text = [primaryColor] base hex @ 50% alpha (recurs
  /// 1x: staff_present_widget's "Signature-ID - ..." label).
  static const Color activityTextColorMuted50 = AppPalette.textMuted;

  /// Dark circular icon backdrop / shadow tint — used behind play/pause,
  /// remove, and rotate icon buttons on photo/video previews. Numerically
  /// identical to `Colors.black54` (recurs 4x: upload_photo_video's rotate
  /// button backdrop, play/pause circle, remove-button circle, and
  /// view_activity_media's play/pause circle).
  static const Color activityIconBackdropColor = AppPalette.mediaScrim;

  // "Processing" media banner/placeholder palette — shared verbatim across
  // photo_activity, view_activity_media, and avtivity_media_preview.
  static const Color activityProcessingBg =
      AppPalette.statusInfoSoft; // Banner/placeholder background (recurs 2x)
  static const Color activityProcessingBorder =
      AppPalette.dataTealSoft; // Banner border, photo_activity only (recurs 1x)
  static const Color activityProcessingAccent =
      AppPalette.statusInfo; // Spinner accent blue (recurs 3x)
  static const Color activityProcessingText =
      AppPalette.textPrimary; // "Processing..." caption text (recurs 3x)

  // avtivity_media_preview's own "processing card" gradient — visually
  // close to but distinct from [activityProcessingBg], kept separate rather
  // than merged (recurs 1x each).
  static const Color activityProcessingCardGradientStart =
      AppPalette.surfaceSunken;
  static const Color activityProcessingCardGradientEnd = AppPalette.surfaceCard;

  // avtivity_media_preview's "PROCESSING" badge chip — a distinct blue from
  // [activityProcessingAccent]/[activityProcessingBorder], not merged since
  // the exact shades differ (recurs 1x each).
  static const Color activityProcessingBadgeBg = AppPalette.statusInfoSoft;
  static const Color activityProcessingBadgeText = AppPalette.statusInfo;

  // activity_daily_tab.dart's own pastel palette used to color-code
  // classroom/activity chips by `index % list.length`. NOT unified with the
  // pre-existing [colorPalette] (used the same way by activity_custom_tab):
  // colorPalette has a 9th entry (0xFFCCFF90) inserted mid-sequence, so
  // pointing daily_tab at it would shift every color assigned to an index
  // past the insertion point — a silent, untestable visual regression.
  // Hosting daily_tab's original 8-entry list here (same values, same
  // order) satisfies Mandate 4 without touching either file's behavior.
  static final List<Color> activityDailyColorPalette = <Color>[
    AppPalette.dataTealSoft,
    AppPalette.dataOrangeSoft,
    AppPalette.dataGreenSoft,
    AppPalette.dataSunSoft,
    AppPalette.dataPurpleSoft,
    AppPalette.dataTeal,
    AppPalette.dataPurple,
    AppPalette.dataOrange,
  ];

  // Approval-status legend (activityApprovalStatusBadgeColor in
  // activity_daily_tab.dart) — background per moderation status.
  static const Color activityApprovalStatusNotRequiredColor =
      AppPalette.surfaceMuted; // NOT_REQUIRED (neutral grey)
  static const Color activityApprovalStatusPendingColor = AppPalette
      .statusWarningSoft; // PENDING_ADMIN_APPROVAL / PARENT_ACKNOWLEDGEMENT_PENDING (recurs 2x)
  static const Color activityApprovalStatusApprovedColor =
      AppPalette.statusSuccessSoft; // APPROVED / ACKNOWLEDGED (recurs 2x)
  static const Color activityApprovalStatusRejectedColor =
      AppPalette.statusErrorSoft; // REJECTED
  static const Color activityApprovalStatusDefaultColor =
      AppPalette.surfaceSunken; // Unknown/default status fallback

  /// Search box fill background (activity_student_selection's classroom
  /// student-search field). Same value as [staffLightBackgroundColor], kept
  /// as an independent activity-scoped constant.
  static const Color activitySearchFieldBg = AppPalette.surfaceField;

  // Classroom module colors — Mandate 4 sweep
  //
  // Primary text color for classroom detail cards, roster rows, and dropdown
  // labels (was `Color(0xff573353)`) — same value as [billingTextColor],
  // kept as an independent classroom-scoped alias per the codebase's
  // feature-scoping convention (recurs 20x+).
  static const Color classroomTextColor = AppPalette.textPrimary;

  /// Light mauve border for search bars and dropdown fields across the
  /// classroom feature (was `Color.fromARGB(255, 188, 173, 186)`, recurs 8x).
  static const Color classroomBorderColor = AppPalette.borderStrong;

  /// Light grey border for the classroom-detail cards on
  /// [ClassroomInfoScreen] (was `Color.fromARGB(255, 232, 234, 234)`).
  static const Color classroomCardBorderColor = AppPalette.border;

  /// Bright "good" status: signed-in attendance dot, ratio-met icon (was
  /// bare `Colors.green`).
  static const Color classroomPositiveStatusColor = AppPalette.statusSuccess;

  /// Bright "bad" status: absent attendance dot, ratio-not-met icon, error
  /// text (was bare `Colors.red`).
  static const Color classroomNegativeStatusColor = AppPalette.statusError;

  /// Muted icon/text tint — empty-state icons, help tooltips (was bare
  /// `Colors.grey`).
  static const Color classroomMutedIconColor = AppPalette.textMuted;

  /// Roster-row border (was `Colors.grey[300]`/`Colors.grey.shade300`).
  static const Color classroomRowBorderColor = AppPalette.borderStrong;

  /// Greyed-out roster-row background for staff/students not expected today
  /// (was `Colors.grey[100]`).
  static const Color classroomRowGreyedBackgroundColor =
      AppPalette.surfaceMuted;

  /// Dropdown placeholder/hint text, e.g. an unselected designation filter
  /// (was `Colors.grey[600]`).
  static const Color classroomPlaceholderTextColor = AppPalette.textSecondary;

  /// Search-field hint text on the assign-staff/assign-student forms (was
  /// `Colors.grey[700]`).
  static const Color classroomSearchFieldHintColor = AppPalette.textMuted;

  /// Status-filter chip background on the staff/students tab cards (was
  /// `Color.fromRGBO(177, 175, 233, 0.3)`).
  static const Color classroomStatusChipBackgroundColor =
      AppPalette.surfaceSunken;

  /// Roster scrollbar thumb color on the staff tab card (was
  /// `Color.fromRGBO(222, 228, 253, 1)`).
  static const Color classroomScrollbarThumbColor = AppPalette.surfaceField;

  /// Message/mail icon accent on a staff roster row (was
  /// `Color.fromRGBO(44, 99, 226, 1)`).
  static const Color classroomMessageIconColor = AppPalette.statusInfo;

  /// Search-field hint text on the students tab card's own search bar — 70%
  /// [primaryColor] (was `Color.fromRGBO(87, 51, 83, 0.7)`).
  static final Color classroomSearchHintTextColor = primaryColor.withValues(
    alpha: 0.7,
  );

  /// Neutral pastel tint: selected-row background on the assign forms, and
  /// the Ratio Monitoring table's "Classroom" header column (was
  /// `Color.fromRGBO(249, 245, 250, 1)` / `Color.fromARGB(255, 249, 245,
  /// 250)` — numerically identical, same use).
  static const Color classroomNeutralTintColor = AppPalette.surfaceSunken;

  /// Ratio Monitoring table's "Students" header column background (was
  /// `Color.fromRGBO(234, 240, 253, 1)`).
  static const Color classroomRatioStudentsHeaderColor =
      AppPalette.domainStudentSoft;

  /// Ratio Monitoring table's "Staff" header column background (was
  /// `Color.fromRGBO(234, 251, 255, 1)`).
  static const Color classroomRatioStaffHeaderColor =
      AppPalette.domainStaffSoft;

  /// Ratio Monitoring table's "Ratio" header column background (was
  /// `Color.fromRGBO(255, 245, 234, 1)`).
  static const Color classroomRatioCurrentHeaderColor =
      AppPalette.surfaceSunken;

  /// Ratio Monitoring table header sub-label text, e.g. "Present"/"Current"
  /// (was `Colors.grey.shade800`).
  static const Color classroomRatioHeaderSubtextColor =
      AppPalette.textSecondary;

  /// [ClassroomInfoShimmer]'s loading-skeleton base/highlight — kept
  /// separate from [classroomRowBorderColor] despite an identical base
  /// value, matching this file's existing shimmer-vs-border convention (see
  /// [attendanceShimmerBaseColor]).
  static const Color classroomShimmerBaseColor = AppPalette.surfaceField;
  static const Color classroomShimmerHighlightColor = AppPalette.surfaceMuted;

  // Bare Colors.* sweep, grouped by confirmed semantic role (see per-file
  // recon before this batch was written).
  static const Color activityUploadSuccessColor =
      AppPalette.statusSuccess; // Upload-complete icon/text (recurs 18x)
  static const Color activityUploadWarningColor =
      AppPalette.statusWarning; // Upload-incomplete icon/text (recurs 8x)
  static const Color activityRequiredFieldMarkerColor =
      AppPalette.statusError; // Required-field "*" marker (recurs 6x)
  static const Color activityErrorTextColor = Colors
      .red; // Validation/error message + destructive action text (recurs 3x)
  static const Color activityMediaPlaceholderIconColor = Colors
      .white70; // Icon/text tint on photo/video placeholder overlays (recurs 8x)
  static const Color activityMutedGreyColor = Colors
      .grey; // Muted text/icon/border (recurs 9x, incl. 2 .withValues() derivatives)
  static const Color activityPlaceholderTextColor = MaterialHues
      .grey600; // Hint/placeholder/unselected text (was Colors.grey[600] / grey.shade600, recurs 6x)
  static const Color activitySearchHintColor = MaterialHues
      .grey700; // Search field hint text (was Colors.grey[700], recurs 1x)
  static const Color activityVideoPlaceholderBg = MaterialHues
      .grey800; // Video-thumbnail loading placeholder background (was Colors.grey[800], recurs 2x)
  static const Color activityMediaLoadingPlaceholderBg = MaterialHues
      .grey300; // Photo/video thumb loading/error placeholder bg (was Colors.grey[300], recurs 2x)
  static const Color activityDisabledButtonBg = MaterialHues
      .grey300; // Disabled "Choose Media" button background (was Colors.grey[300], recurs 1x)
  static const Color activityBodyTextColor = MaterialHues
      .black87; // Selected/primary body text (was Colors.black87, recurs 4x)
  static const Color activityTooltipBackgroundColor = MaterialHues
      .black87; // Black tooltip bubble background (was Colors.black87, recurs 2x)
  static const Color activityMediaPlaceholderBg = Colors
      .black12; // Media placeholder container tint, alpha applied per call site (recurs 3x)
  static const Color activityVideoProgressTrackColor =
      AppPalette.onMediaTrack; // Video-progress unplayed track (recurs 1x)
  static const Color activityVideoProgressBufferedColor =
      AppPalette.onMediaHint; // Video-progress buffered segment (recurs 1x)

  // Student specific colors
  //
  // General white alias so bare `Colors.white` surfaces/icons resolve through
  // AppColors, matching the existing [blackColor] alias.
  static const Color whiteColor = AppPalette.surfaceCard;

  // Profile status-chip palette (StudentAboutTabCard): each status pairs a
  // saturated label color with a 10%-alpha background of the same hue.
  // Waitlist/Graduated reuse [secondaryColor] (label) + [staffBadgeActiveBg]
  // (background) — no dedicated token needed.
  static const Color studentStatusActiveColor =
      AppPalette.statusSuccess; // Active label (was rgbo(56,200,32,1))
  static const Color studentStatusActiveBg =
      AppPalette.statusSuccessSoft; // Active chip bg (was rgbo(56,200,32,0.1))
  static const Color studentStatusInactiveColor =
      AppPalette.statusError; // Inactive label (was rgbo(250,65,65,1))
  static const Color studentStatusInactiveBg =
      AppPalette.statusErrorSoft; // Inactive chip bg (was rgbo(250,65,65,0.1))
  static const Color studentStatusUpcomingColor = AppPalette
      .statusWarningStrong; // Upcoming label (was fromARGB(255,138,110,0))
  static const Color studentStatusUpcomingBg = AppPalette
      .statusWarningSoft; // Upcoming chip bg (was fromARGB(255,242,238,176))

  // Health / immunization / important-dates status palette (health tab cards):
  // a saturated hue for icons/labels plus a 10%-alpha tint of the same hue for
  // the row/badge background. [errorColor] (0xFFD32F2F) covers the red case;
  // [studentErrorBg] is its 10% tint.
  static const Color studentHealthOrangeColor =
      AppPalette.statusWarningStrong; // overdue/warning
  static const Color studentHealthOrangeBg = AppPalette.statusWarningSoft;
  static const Color studentHealthYellowColor =
      AppPalette.statusWarning; // due-soon
  static const Color studentHealthYellowBg = AppPalette.statusWarningSoft;
  static const Color studentStatusActiveBgSolid = AppPalette
      .statusSuccessSoft; // solid green "complete" background (was 0xFFE8F5E9)
  static const Color studentErrorBg =
      AppPalette.statusErrorSoft; // errorColor @ 10%
  static const Color studentHealthRedDark =
      AppPalette.statusErrorStrong; // strong error text
  static const Color studentHealthGreenDark =
      AppPalette.statusSuccessStrong; // strong success text
  static const Color studentHealthBlue = AppPalette.statusInfo; // info accent
  static const Color studentHealthRedBg =
      AppPalette.statusErrorSoft; // light error background
  static const Color studentHealthBlueBg =
      AppPalette.statusInfoSoft; // light info background
  static const Color studentAmberBg =
      AppPalette.statusWarningSoft; // light amber background

  // Neutral greys used across student cards/forms.
  static const Color studentMutedText =
      AppPalette.textSecondary; // muted plum-grey label/icon
  static const Color studentBorderGrey =
      AppPalette.borderStrong; // input/card border
  static const Color studentDisabledGrey =
      AppPalette.textMuted; // disabled/placeholder
  static const Color studentDividerGrey =
      AppPalette.surfaceField; // light divider/border
  static const Color studentSurfaceGrey =
      AppPalette.surfaceMuted; // light surface fill
  static const Color studentGrey =
      AppPalette.textMuted; // medium neutral text/icon
  static const Color studentDarkPlum =
      AppPalette.textPrimary; // avatar/photo overlay base

  // Purple / lavender accents (add-student wizard, chips).
  static const Color studentLavenderTint =
      AppPalette.surfaceSunken; // light lavender chip bg
  static const Color studentLavenderBorder =
      AppPalette.border; // lavender border (was rgbo(200,191,255,0.7))
  static const Color studentPurpleTint =
      AppPalette.surfaceSunken; // light purple fill (was rgbo(241,234,255,1))
  static const Color studentPurple =
      AppPalette.dataPurple; // purple accent (was rgbo(170,141,255,1))
  static const Color studentAccentPurple = AppPalette
      .domainStudent; // gradient purple accent (was rgbo(156,132,255,1))

  // Info blue (was bare Colors.blue / Colors.blue[50]).
  static const Color studentInfoColor = AppPalette.domainStudent;
  static const Color studentInfoBg = AppPalette.domainStudentSoft;
  // Auth module colors — Mandate 4 sweep
  //
  // Primary headings/icons/body text across sign-in, org/school selection,
  // and password screens (was `Color(0xFF333333)`, recurs 17x).
  static const Color authPrimaryTextColor = AppPalette.textPrimary;

  /// Org/school selection accent text — same value as [billingTextColor],
  /// kept as an independent auth-scoped alias per the codebase's
  /// feature-scoping convention (was `Color(0xFF573353)`, recurs 5x).
  static const Color authAccentTextColor = AppPalette.textPrimary;

  /// Thin divider line under the "Select Organization/School" heading (was
  /// `Color(0xFFFFF3E9)`, recurs 4x).
  static const Color authDividerColor = AppPalette.divider;

  /// Password field background — same value as [billingSurfaceLight] (was
  /// `Color(0xFFF8F9FA)`, recurs 3x).
  static const Color authSurfaceLight = AppPalette.surfaceSunken;

  /// Password-strength "met" indicator (icon, banner text, success circle) —
  /// was both bare `Colors.green` and the identical `Color(0xFF4CAF50)`
  /// (recurs 3x).
  static const Color authSuccessColor = AppPalette.statusSuccess;

  /// Field label above each password input, and the show/hide eye icon (was
  /// `Color(0xFF888888)`, recurs 4x).
  static const Color authFieldLabelColor = AppPalette.textSecondary;

  /// Password field placeholder/hint text (was `Color(0xFFBBBBBB)`).
  static const Color authHintTextColor = AppPalette.textMuted;

  /// Password field border (was `MaterialHues.grey200`).
  static const Color authInputBorderColor = AppPalette.borderStrong;

  /// Password-strength "met" banner background (was `Color(0xFFEFFBEF)`).
  static const Color authSuccessBackgroundColor = AppPalette.statusSuccessSoft;

  /// Muted icon tint, e.g. the sign-out confirmation sheet (was bare
  /// `Colors.grey`).
  static const Color authMutedIconColor = AppPalette.textMuted;

  /// Bottom-sheet drag handle (was `Colors.grey[300]`, equivalent to
  /// `Colors.grey.shade300`).
  static const Color authDragHandleColor = AppPalette.borderStrong;

  /// Role label under the user's name on org/school selection (was
  /// `Colors.grey.shade600`, recurs 2x).
  static const Color authSecondaryTextColor = AppPalette.textSecondary;

  // User profile module colors — Mandate 4 sweep
  //
  // Primary purple-brown text — same value as [billingTextColor] /
  // [authAccentTextColor], kept as an independent user-profile-scoped alias
  // (was `Color(0xff573353)`, recurs 11x).
  static const Color userProfileTextColor = AppPalette.textPrimary;

  /// Card/input border — same value as [billingBorderDefault] (user-profile
  /// text @ 40% alpha) (was `Color(0x66573353)`).
  static const Color userProfileBorderColor = AppPalette.border;

  /// Muted icon tint (was bare `Colors.grey`, recurs 2x).
  static const Color userProfileMutedIconColor = AppPalette.textMuted;

  /// Disabled "Save" button background on the edit-profile form — same
  /// value as [billingButtonDisabled] (was `Colors.grey[300]`).
  static const Color userProfileDisabledButtonColor = AppPalette.surfaceField;

  /// Disabled "Country" field text on the edit-profile form (was
  /// `Colors.grey.shade700`).
  static const Color userProfileSecondaryTextColor = AppPalette.textSecondary;

  /// Validation/required-field marker (was bare `Colors.red`, recurs 2x).
  static const Color userProfileErrorColor = AppPalette.statusError;

  /// "Soft purple" header/badge background — same value as
  /// [activitySoftPurpleFieldColor] (was `Color(0xFFB1AFE9)`, recurs 2x).
  static const Color userProfileSoftPurpleColor = AppPalette.brandSecondary;

  /// Divider — same value as [billingDividerLight] (was `Color(0xFFE9ECEF)`,
  /// recurs 2x).
  static const Color userProfileDividerColor = AppPalette.divider;

  /// Divider between the work-schedule and break-schedule sections on the
  /// profile screen (was `Color(0xFFF0ECF4)`).
  static const Color userProfileSectionDividerColor = AppPalette.divider;

  /// Light panel background — same value as [staffLightBackgroundColor] (was
  /// `Color(0xFFF8F7FA)`).
  static const Color userProfileLightBackgroundColor = AppPalette.surfaceSunken;

  /// Disabled notification-channel checkbox fill (was `Colors.grey.shade300`).
  static const Color userProfileDisabledCheckboxFillColor =
      AppPalette.surfaceField;

  /// Disabled notification-channel checkbox border (was
  /// `Colors.grey.shade400`).
  static const Color userProfileDisabledCheckboxBorderColor =
      AppPalette.borderStrong;

  // ── Reports (Mandate M4) ────────────────────────────────────────────────
  /// Error-state icon on the Generated-reports failure panel. This is the
  /// exact value of the `Colors.red` it replaced (#F44336), NOT
  /// [errorColor] (#D32F2F) — substituting the nearer token would have
  /// changed the rendered colour. Worth consolidating with [errorColor] as a
  /// deliberate design decision, not as part of a centralisation pass.
  static const Color reportsErrorIconColor = AppPalette.statusError;

  /// Muted/inactive grey across the reports module — empty-state icons,
  /// file-preview placeholder icons, unselected checkbox borders and the
  /// disabled download gradient. Exact value of the `Colors.grey[400]` /
  /// `Colors.grey.shade400` it replaced (#BDBDBD). Shares its hex with
  /// [dividerColor] but means "inactive", not "rule between rows".
  static const Color reportsMutedColor = AppPalette.textMuted;

  /// Indigo accent — section labels and the "All ... selected by default"
  /// notes. Exact value of the `Color(0xff4F46E5)` it replaced.
  static const Color reportsAccentColor = AppPalette.actionSecondary;

  /// Hairline divider inside the report cards (#E9ECEF).
  static const Color reportsCardDividerColor = AppPalette.divider;

  /// Inline "could not load classrooms" panel on the report forms.
  static const Color reportsInlineErrorBackgroundColor =
      AppPalette.statusErrorSoft;
  static const Color reportsInlineErrorBorderColor = AppPalette.statusError;
  static const Color reportsInlineErrorTextColor = AppPalette.statusErrorStrong;

  /// Selected month chip in the month/year picker (#EEEDF0).
  static const Color reportsMonthPickerSelectedColor =
      AppPalette.surfaceSelected;

  /// Disabled control surface — exact value of `Colors.grey[300]` (#E0E0E0).
  static const Color reportsDisabledSurfaceColor = AppPalette.surfaceField;

  /// Disabled control foreground — exact value of `Colors.grey[600]`
  /// / `Colors.grey.shade600` (#757575).
  static const Color reportsDisabledForegroundColor = AppPalette.textSecondary;

  /// Required-field "*" marker. Same value and meaning as
  /// [activityRequiredFieldMarkerColor]; the two should collapse into one
  /// shared semantic token in a cross-feature pass.
  static const Color reportsRequiredFieldMarkerColor = AppPalette.statusError;

  // Individual Movements (Mandate 4) — see
  // lib/presentation/features/availability/**. Board-column background tints
  // are distinct per bucket (Overdue/Upcoming/Confirmed/Rejected); badge and
  // dialog-chrome colors reuse existing semantic tokens where the shade
  // already matches (see [errorColor]/[warningColor]/[successColor] and the
  // `attendanceDialogXxx`/`attendanceBorderLightColor` tokens above).
  static const Color movementOverdueBackground = AppPalette.statusWarningSoft;
  static const Color movementUpcomingBackground = AppPalette.statusInfoSoft;
  static const Color movementConfirmedBackground = AppPalette.statusSuccessSoft;
  static const Color movementRejectedBackground = AppPalette.statusErrorSoft;
  static const Color movementDialogHeaderColor =
      AppPalette.surfaceSunken; // Drag/drop confirmation dialog header band
  static const Color movementDueTimeIconColor =
      AppPalette.statusWarning; // Row clock icon

  // Future Availability (Mandate 4) — see
  // lib/presentation/features/availability/view/future_availability_screen.dart.
  static const Color futureAvailabilityColumnTint = AppPalette.surfaceSunken;
  static const Color futureAvailabilityHeaderTint = AppPalette.surfaceMuted;
  static const Color futureAvailabilityToggleTrackBg = AppPalette.surfaceField;
  static const Color futureAvailabilityNegativeCountColor =
      AppPalette.statusError;
  static const Color futureAvailabilityPositiveCountColor =
      AppPalette.statusSuccess;
  static const Color futureAvailabilityZeroCountColor = AppPalette.statusWarning;

  // ── Dashboard: geofence attendance state (SEMANTIC) ────────────────────────
  // Mandate 4: these encode whether GPS self-attendance is currently possible,
  // so they are named semantic tokens, not palette entries. Exact hexes carried
  // over from my_day_card.dart — rendered output is unchanged.
  //
  // NOTE (§4.3 accessibility): the inside/outside states are ALSO distinguished
  // by their label text and dot, not by colour alone.

  /// Dot shown when the user is inside the school geofence.
  static const Color geofenceInsideIndicator = AppPalette.statusSuccess;

  /// Label text for the inside-geofence state.
  static const Color geofenceInsideText = AppPalette.statusSuccessStrong;

  /// Unread-count badge on a dashboard chat-preview row.
  static const Color chatUnreadBadge = AppPalette.brand;

  /// Tint behind the chat-preview strip at the foot of the My Day card.
  static const Color chatPreviewSurface = AppPalette.surfaceSunken;

  /// Fill behind the Work Time / Break Time chips on the My Day card.
  static const Color myDayChipSurface = AppPalette.surfaceSunken;

  // ── Dashboard: disabled / shimmer chrome ──────────────────────────────────

  /// Label of a disabled self-attendance action button.
  static const Color disabledActionLabel = AppPalette.textSecondary;

  /// Border of a disabled self-attendance action button.
  static const Color disabledActionBorder = AppPalette.borderStrong;

  /// Shimmer skeleton base / highlight.
  static const Color shimmerBase = AppPalette.surfaceField;
  static const Color shimmerHighlight = AppPalette.surfaceMuted;

  // ── Newsletter (Mandate 4) ────────────────────────────────────────────────
  // Feature-prefixed, matching the `billing*` convention already in this file.
  //
  // NOTE FOR THE OTHER MODULES: the newsletter's *content* colours are NOT
  // here and must not be. `NewsletterThemeColors` resolves a per-newsletter
  // palette chosen by the author (vibrant / ocean / forest / sunset /
  // professional) — that is DATA arriving with the record, not app theming.
  // Only the app's own chrome around the content is tokenised below.

  /// Unselected newsletter tab label. Was `Color.fromARGB(50, 36, 22, 49)`.
  static const Color newsletterTabUnselectedLabel = AppPalette.textMuted;

  /// Unselected newsletter tab chip fill. Was
  /// `Color.fromARGB(102, 203, 246, 255)`.
  static const Color newsletterTabUnselectedBackground =
      AppPalette.surfaceSunken;

  /// Attachment tile fill in the preview grid.
  /// Was `Color.fromRGBO(244, 247, 254, 1)`.
  static const Color newsletterAttachmentTileBackground =
      AppPalette.surfaceSunken;

  /// Document (non-image) thumbnail fill on a list card, when the asset
  /// resolved. Was `Color(0xFFEAF2FF)`.
  static const Color newsletterDocumentThumbnailBackground =
      AppPalette.statusInfoSoft;

  /// Document thumbnail fill when no asset resolved, and the fallback behind a
  /// failed placeholder image. Was `Colors.grey.shade200`.
  static const Color newsletterThumbnailPlaceholderBackground =
      AppPalette.surfaceField;

  /// Letterbox behind a component image while it loads.
  /// Was `Colors.grey.shade100`.
  ///
  /// Same hex as [shimmerHighlight] but a different meaning, so it is its own
  /// token rather than a reuse (§4: a colour that encodes meaning gets a named
  /// semantic token).
  static const Color newsletterImageLoadingBackground = AppPalette.surfaceMuted;

  /// Background of the "loaded from cache, refresh failed" banner on the
  /// preview screen. A SEMANTIC state colour, not a palette entry — it is the
  /// only thing distinguishing a stale newsletter from a fresh one, and it
  /// pairs with the banner's own text. Was `Colors.orange.shade50`.
  static const Color newsletterStaleBannerBackground =
      AppPalette.statusWarningSoft;

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
  // Communication / messaging (Mandate 4) — see
  // lib/presentation/features/communication/. Semantic names; light-mode hex
  // preserved exactly.
  /// Hairline row divider between conversation-list tiles.
  static const Color messagingDividerLight = AppPalette.divider;

  /// Secondary text: message preview, the private-mode lock icon.
  static const Color messagingTextSecondary = AppPalette.textSecondary;

  /// Conversation-list timestamp (muted grey).
  static const Color messagingTimestamp = AppPalette.textMuted;

  /// Unread-count badge fill (also its own drop-shadow at reduced alpha).
  static const Color messagingUnreadBadge = AppPalette.brand;

  /// Text/icon drawn ON a coloured messaging accent (e.g. the unread badge).
  static const Color messagingOnAccent = AppPalette.textOnDark;

  /// Subtle InkWell splash on a conversation tile.
  static const Color messagingTileSplash = AppPalette.brandSoft;

  // Participant role colour-coding (Mandate 4 — semantic). Chips tint by role;
  // every chip also carries its role label text, so it stays distinguishable
  // without colour.
  /// ADMIN.
  static const Color messagingRoleAdmin = AppPalette.dataPurple;

  /// GUARDIAN / PARENT.
  static const Color messagingRoleGuardian = AppPalette.dataTeal;

  /// STAFF / TEACHER / LEAD_TEACHER.
  static const Color messagingRoleStaff = AppPalette.dataSun;

  /// DIRECTOR / PRINCIPAL.
  static const Color messagingRoleDirector = AppPalette.dataPink;

  /// ASSISTANT_DIRECTOR.
  static const Color messagingRoleAssistant = AppPalette.dataOrange;

  /// Placeholder / empty-state text in messaging sheets (e.g. "No tags
  /// available") — a cool muted grey.
  static const Color messagingTextPlaceholder = AppPalette.textMuted;

  /// Field / chip outline in filter sheets (was Colors.grey[300]).
  static const Color messagingBorderColor = AppPalette.borderStrong;

  /// Input hint text in filter fields (was Colors.grey[400]).
  static const Color messagingHintText = AppPalette.textMuted;

  /// Unselected filter-chip label (was Colors.grey[700]).
  static const Color messagingChipTextUnselected = AppPalette.textSecondary;

  /// Composer TextField outline (slate-200).
  static const Color messagingInputBorder = AppPalette.border;

  /// Composer TextField hint text.
  static const Color messagingComposerHint = AppPalette.textMuted;

  // Participant-info dialog (Mandate 4).
  /// Dialog surface behind the participant cards.
  static const Color messagingDialogBackground = AppPalette.surfaceSunken;

  /// Dialog title / student name (dark navy).
  static const Color messagingTitleColor = AppPalette.textPrimary;

  /// Strong body text (slate-800) — participant names, etc.
  static const Color messagingTextStrong = AppPalette.textPrimary;

  /// Dialog close-button outline (slate-300).
  static const Color messagingCloseBorder = AppPalette.borderStrong;

  /// Dialog close-button glyph (slate-500).
  static const Color messagingCloseIcon = AppPalette.textSecondary;
  // Role badges (semantic bg/fg pairs) — the label text also names the role,
  // so they stay distinguishable without colour.
  static const Color messagingBadgeAdminBg = AppPalette.brandSoft;
  static const Color messagingBadgeAdminFg = AppPalette.brandDark;
  static const Color messagingBadgeStaffBg = AppPalette.domainStaffSoft;
  static const Color messagingBadgeStaffFg = AppPalette.domainStaffInk;
  static const Color messagingBadgeGuardianBg = AppPalette.domainStudentSoft;
  static const Color messagingBadgeGuardianFg = AppPalette.domainStudentInk;

  /// Message-info dialog: quoted-message preview box background.
  static const Color messagingMessageBoxBg = AppPalette.surfaceSunken;

  /// Read-receipt "read by" tick (semantic — read state); paired with a
  /// done-all icon so it reads as "read" without relying on colour.
  static const Color messagingReadCheckColor = AppPalette.statusSuccess;

  // Attachment viewer.
  /// Muted surface behind an image placeholder / a card outline (grey-200).
  static const Color messagingSurfaceMuted = AppPalette.surfaceField;

  /// Muted glyph (broken/unsupported image icon) (grey-500).
  static const Color messagingIconMuted = AppPalette.textMuted;

  /// Secondary metadata text (file size/type, empty note) (grey-600).
  static const Color messagingTextMeta = AppPalette.textSecondary;
  // Document type-badge tints (semantic — the file-type icon shape also
  // conveys the type, so these are not colour-only signals).
  static const Color messagingFilePdf = AppPalette.statusError;
  static const Color messagingFileExcel = AppPalette.statusSuccess;
  static const Color messagingFilePowerpoint = AppPalette.statusWarningStrong;
  static const Color messagingFileWord = AppPalette.statusInfo;

  // Attachment bottom sheet.
  /// Drag handle at the top of the sheet.
  static const Color messagingSheetHandle = AppPalette.borderStrong;
  // Attachment-source accent tints (Camera / Gallery / Document) — each option
  // also carries an icon + label, so the colour is not the only signal.
  static const Color messagingAttachmentCamera = AppPalette.dataPurple;
  static const Color messagingAttachmentGallery = AppPalette.dataGreen;
  static const Color messagingAttachmentDocument = AppPalette.dataSun;

  // Full-screen media viewer (dark surface overlay whites).
  /// 54% white — hint text / broken-media icons over the black viewer.
  static const Color messagingMediaHint = AppPalette.onMediaHint;

  /// 70% white — loaders over the black viewer.
  static const Color messagingMediaSubtle = AppPalette.onMediaHint;

  /// 24% white — video scrubber track background.
  static const Color messagingMediaTrackBg = AppPalette.onMediaTrack;

  // Link / contact preview cards.
  /// Email/phone contact-preview chip background (receiver scheme).
  static const Color messagingContactChipBg = AppPalette.surfaceSunken;

  /// Composer link-preview dismiss (×) glyph (slate-400).
  static const Color messagingDismissIcon = AppPalette.textMuted;

  // Composer (chat input bar).
  /// Reply/edit preview body text (slate-700).
  static const Color messagingPreviewBody = AppPalette.textSecondary;

  /// Left-border accent on the "editing" preview strip (amber-600).
  static const Color messagingEditAccent = AppPalette.statusWarning;

  /// Pending-attachment "remove" badge fill (red-500).
  static const Color messagingRemoveBadge = AppPalette.statusError;

  /// Dark scrim over an attachment thumbnail (video play chip / filename strip)
  /// — const-usable equivalent of the old Colors.black54.
  static const Color messagingScrimDark = AppPalette.mediaScrim;

  // ── Message bubble — semantic fills (Mandate 4) ────────────────────────────
  // Bubble background encodes WHO sent the message, but never on its own: a
  // sent bubble is right-aligned and carries delivery ticks, a received one
  // is left-aligned, a private message shows a lock and a failed one an error
  // icon with "Failed · Retry". These named tokens exist so that distinction
  // is never re-encoded as a raw hex in a view.
  //
  // Three flat faces, no gradients. Pink is my own voice, navy is the
  // guardian's when staff read it, and the card face is everyone else. Two
  // saturated fills is the most a thread can carry and still be read quickly.

  /// My own message — the pink action face, right-aligned.
  static const Color messagingBubbleMine = AppPalette.brand;

  /// A guardian's message as staff or an admin read it — the navy impact
  /// face. Was deep pink, which put two pinks in one thread.
  static const Color messagingBubbleGuardian = AppPalette.surfaceInverse;

  /// Every other message — the plain card face, left-aligned.
  static const Color messagingBubbleReceived = AppPalette.surfaceCard;

  /// Dialog title / sender-name / deleted-text plum. Used at full strength and
  /// at 0.6/0.7 alpha (deleted body, confirm-sheet body, sender label).
  static const Color messagingHeadingPlum = AppPalette.textPrimary;

  /// Private-message lock icon (a message only the opposite role can see).
  static const Color messagingPrivateLock = AppPalette.statusError;

  /// Failed-send retry affordance (icon + "Failed · Retry" label). Same hex as
  /// [messagingPrivateLock] but a distinct semantic — a delivery failure, not a
  /// privacy marker.
  static const Color messagingFailed = AppPalette.statusError;

  /// Link colour inside a message rendered on a dark/gradient bubble.
  static const Color messagingLinkOnAccent = AppPalette.statusInfoSoft;

  /// Link colour inside a message rendered on a light bubble.
  static const Color messagingLink = AppPalette.textLink;

  /// Document-attachment file-type icon (PDF/doc/xls in the file card).
  static const Color messagingDocumentIcon = AppPalette.statusError;

  /// Image-attachment placeholder background while a thumbnail loads/fails.
  static const Color messagingThumbPlaceholderBg = AppPalette.surfaceField;

  /// Stronger meta grey — file-size caption + "Processing…" label (grey700).
  static const Color messagingMetaStrong = AppPalette.textSecondary;

  // ── Conversation list (Mandate 4) ──────────────────────────────────────────

  /// Shared accent purple — staff-directory "Message" chip and the
  /// Staff-Direct conversation-type indicator.
  static const Color messagingAccentPurple = AppPalette.actionSecondary;

  // Conversation-type indicator chip accents (each type also carries its own
  // text LABEL, so the type is legible without relying on colour).
  static const Color messagingTypeRoomChat = AppPalette.dataTeal;
  static const Color messagingTypeAdminChat = AppPalette.dataPurple;
  static const Color messagingTypeClassroom = AppPalette.dataOrange;

  /// Search-field container tint (translucent lavender).
  static const Color messagingSearchFieldBg = AppPalette.surfaceField;

  /// Staff-directory tile background (near-white lavender).
  static const Color messagingTileBg = AppPalette.surfaceCard;

  /// Presence "online" dot on a conversation avatar.
  static const Color messagingOnlineDot = AppPalette.statusSuccess;

  // Inline error banner (staff-search failure) + its retry button.
  static const Color messagingErrorBannerBg = AppPalette.statusErrorSoft;
  static const Color messagingErrorBannerBorder = AppPalette.statusError;
  static const Color messagingErrorBannerText = AppPalette.statusErrorStrong;

  // Soft warning banner (stale/cached data notice).
  static const Color messagingWarningBannerBg = AppPalette.statusWarningSoft;
  static const Color messagingWarningBannerBorder = AppPalette.statusWarning;
  static const Color messagingWarningBannerText =
      AppPalette.statusWarningStrong;

  // ── Admin chat host (Mandate 4) ────────────────────────────────────────────

  /// Muted purple-grey — "START NEW CHAT" section header.
  static const Color messagingMutedPurple = AppPalette.textMuted;

  /// Active-filter indicator dot on the filter button.
  static const Color messagingNotificationDot = AppPalette.statusError;

  /// Admin-chat conversation-tile ink splash (blue, matches the admin accent).
  static const Color messagingAdminChatSplash = AppPalette.brandSoft;

  // ── Parent messaging thread (Mandate 4) ────────────────────────────────────

  /// Transient flash when auto-scrolling to a quoted/target message.
  static const Color messagingScrollHighlight = AppPalette.statusSuccess;

  /// Thread header bottom divider (slightly cooler than [messagingDividerLight]).
  static const Color messagingBorderSubtle = AppPalette.divider;

  /// Error/"unable to load" icon (distinct meaning from the document-icon red).
  static const Color messagingErrorIcon = AppPalette.statusError;

  /// Read-only participant name-badge chip background (translucent plum).
  static const Color messagingChipBgPlum = AppPalette.surfaceSunken;

  // "Private mode" notice pill (amber).
  static const Color messagingNoticeBg = AppPalette.statusWarningSoft;
  static const Color messagingNoticeBorder = AppPalette.statusWarning;
  static const Color messagingNoticeText = AppPalette.statusWarningStrong;

  // ── Staff messaging thread (Mandate 4) ─────────────────────────────────────

  /// Staff-info dialog field label (Designation/Email) — near-black (black87).
  static const Color messagingMenuText = AppPalette.textPrimary;

  /// Staff-info dialog field value — mid-grey (black54).
  static const Color messagingMenuSubtext = AppPalette.textSecondary;

  // ── Conversation thread — participant role badges (Mandate 4) ──────────────
  // A distinct scheme from the messagingRoleXxx set: this screen's participant
  // name badges carry the role word ("Guardian"/"Staff"/"Admin") alongside the
  // colour, so the role is legible without it.
  static const Color messagingRoleBadgeGuardian = AppPalette.domainStudent;
  static const Color messagingRoleBadgeStaff = AppPalette.domainStaff;
  static const Color messagingRoleBadgeAdmin = AppPalette.brand;

  // ── Parent direct messaging (Mandate 4) ────────────────────────────────────
  // Strong error banner (load-failure notice) — deeper red than the soft
  // staff-search banner.
  static const Color messagingErrorSoftBg = AppPalette.statusErrorSoft;
  static const Color messagingErrorSoftBorder = AppPalette.statusError;
  static const Color messagingErrorRed = AppPalette.statusError;
  static const Color messagingErrorDarkText = AppPalette.statusErrorStrong;

  /// Character-counter colour once the message exceeds the limit.
  static const Color messagingCounterExceeded = AppPalette.statusError;

  // ── Shimmer placeholders (Mandate 4) ───────────────────────────────────────
  // Two shimmer palettes are in use across the messaging placeholders: a warm
  // grey pair (list/selection shimmers) and a cooler slate pair (thread shimmer).
  static const Color messagingShimmerBase = AppPalette.surfaceField;
  static const Color messagingShimmerHighlight = AppPalette.surfaceMuted;
  static const Color messagingShimmerBaseCool = AppPalette.surfaceField;
  static const Color messagingShimmerHighlightCool = AppPalette.surfaceMuted;

  /// Messaging tab bar selected-label colour (near-black plum).
  static const Color messagingTabLabel = AppPalette.textPrimary;
}
