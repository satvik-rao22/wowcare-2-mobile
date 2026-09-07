import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/fonts.dart';

/// Reusable text style widgets following the design patterns from staff_card.dart
class AppTextStyles {
  AppTextStyles._();

  /// Label text style - used for field labels
  /// fontSize: 13, fontWeight: w400, color: primaryColor, height: 16/13
  static const TextStyle label = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
    height: 16 / 13,
  );

  /// Value text style - used for displaying values/content
  /// fontSize: 14, fontWeight: w500, color: primaryColor, height: 19/14
  static const TextStyle value = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
    height: 19 / 14,
  );

  /// Title text style - used for section titles
  /// fontSize: 16, fontWeight: w700, color: primaryColor
  static const TextStyle title = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
    height: 16 / 16,
  );

  /// Subtitle text style - used for subtitles
  /// fontSize: 14, fontWeight: w700, color: primaryColor
  static const TextStyle subtitle = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  /// Body text style - used for regular body text
  /// fontSize: 14, fontWeight: w500, color: primaryColor, height: 19/14
  static const TextStyle body = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
    height: 19 / 14,
  );

  /// Small text style - used for smaller text
  /// fontSize: 12, fontWeight: w400, color: primaryColor
  static const TextStyle small = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
    height: 15 / 12,
  );

  /// Button text style - used for button labels
  /// fontSize: 16, fontWeight: w700, color: varies
  static TextStyle button({Color? color}) => TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.primaryColor,
    height: 16 / 16,
  );

  /// Section header text style - used for section headers
  /// fontSize: 13, fontWeight: w600, color: primaryColor
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// Medium-weight override with no size/color of its own — for text that
  /// inherits its size and color from an ambient style (e.g. `AppText.body`)
  /// and only needs a heavier weight.
  static const TextStyle mediumWeight = TextStyle(fontWeight: FontWeight.w500);

  /// fontSize: 16, fontWeight: w500, no color of its own (inherits ambient).
  /// A larger sibling of [value]/[body] used where those two are locked to
  /// 14 — kept as its own entry rather than `.copyWith` so it doesn't also
  /// pull in their color/height.
  static const TextStyle valueLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// fontSize: 16, no weight/color of its own (inherits ambient).
  static const TextStyle size16 = TextStyle(fontSize: 16);

  /// fontSize: 14, no weight/color of its own (inherits ambient).
  static const TextStyle size14 = TextStyle(fontSize: 14);

  /// fontSize: 18, fontWeight: w600, no color of its own (inherits ambient).
  static const TextStyle heading18 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  /// Attendance tab bar selected-label style (responsive size).
  static TextStyle attendanceTabLabelSelected({required bool isTablet}) =>
      TextStyle(
        fontFamily: Fonts.manrope,
        color: AppColors.attendanceIconColor,
        fontSize: isTablet ? 18 : 16,
        fontWeight: FontWeight.w600,
      );

  /// Attendance tab bar unselected-label style (responsive size).
  static TextStyle attendanceTabLabelUnselected({required bool isTablet}) =>
      TextStyle(
        fontFamily: Fonts.manrope,
        color: AppColors.primaryColor.withValues(alpha: 0.5),
        fontSize: isTablet ? 18 : 16,
        fontWeight: FontWeight.w400,
      );

  /// Attendance screen header title ("Student/Staff Attendance"), responsive size.
  static TextStyle attendanceScreenTitle({required bool isTablet}) => TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: isTablet ? 22 : 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// Attendance profile header name, responsive size. No color/fontFamily of
  /// its own — composed as an override on top of [AppText.title].
  static TextStyle attendanceProfileName({required bool isTablet}) => TextStyle(
    fontSize: isTablet ? 23 : 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
  );

  /// Attendance popup tab bar selected-label style (weight 500, distinct
  /// from [attendanceTabLabelSelected]'s 600 — the popup's own visual spec).
  static TextStyle attendancePopupTabLabelSelected({required bool isTablet}) =>
      TextStyle(
        color: AppColors.attendanceIconColor,
        fontFamily: Fonts.manrope,
        fontSize: isTablet ? 18 : 16,
        fontWeight: FontWeight.w500,
      );

  /// Attendance popup tab bar unselected-label style — no explicit weight,
  /// matching the original (inherits ambient/ TabBar default).
  static TextStyle attendancePopupTabLabelUnselected({
    required bool isTablet,
  }) => TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.5),
    fontFamily: Fonts.manrope,
    fontSize: isTablet ? 18 : 16,
  );

  /// Attendance popup action-button label (icon+label grid buttons).
  static TextStyle attendancePopupActionButton({required double fontSize}) =>
      TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: fontSize,
        color: AppColors.primaryColor,
      );

  /// Attendance popup "View Attendance" gradient button label. No color of
  /// its own — painted via ShaderMask, which overrides paint regardless.
  static TextStyle attendancePopupViewButton({required bool isTablet}) =>
      TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: isTablet ? 18 : 16,
        fontWeight: FontWeight.w700,
        letterSpacing: (isTablet ? 18 : 16) * (-3 / 100),
      );

  /// Attendance custom-view segmented-tab label (selected vs unselected).
  /// No fontFamily of its own — composed as an override on [AppText.body].
  static TextStyle attendanceCustomTabLabel({required bool isSelected}) =>
      TextStyle(
        fontSize: 16,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
        color: isSelected
            ? AppColors.attendanceTabSelectedLabelColor
            : AppColors.attendanceTabUnselectedLabelColor,
      );

  /// Attendance transfer-form classroom dropdown value style. No fontFamily
  /// of its own, matching the original (inherits the DropdownButton's
  /// ambient default).
  static TextStyle attendanceDropdownValue({required Color color}) =>
      TextStyle(color: color, fontSize: 15);

  /// Staff attendance card's designation label. 13/12·w400 with NO
  /// line-height — deliberately left off this base (unlike most entries
  /// above) because no existing height matched this exact metric and every
  /// candidate base would have injected one via `.copyWith()`, changing this
  /// row's layout. Color varies per call site via `.copyWith(color: ...)`.
  static TextStyle attendanceDesignationLabel({required bool isTablet}) =>
      TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: isTablet ? 13 : 12,
        fontWeight: FontWeight.w400,
      );

  // ---------------------------------------------------------------------
  // Activity module (Mandate 4, final slice) — see
  // lib/presentation/features/activities/**. Named per the same
  // `activity<Purpose>` convention as the `attendanceXxx` entries above.
  // Several entries here are reused across more than one visual purpose
  // (e.g. a chip label and a status caption sharing identical metrics) —
  // that's intentional per Mandate 6 ("reuse what exists"): the doc comment
  // lists every call-site purpose it covers.
  // ---------------------------------------------------------------------

  /// Small circular badge text — filter-count badges and avatar-initials
  /// circles.
  /// fontSize: 10, fontWeight: w700, color: cardColor
  static const TextStyle activitySmallBadgeText = TextStyle(
    color: AppColors.cardColor,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );

  /// Small caption/chip text with no weight of its own (activity-name chip,
  /// "Checking sign-in status…" caption).
  /// fontSize: 12, color: primaryColor
  static const TextStyle activitySmallText = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 12,
  );

  /// Small metadata text — approval-status badges, "Created By" captions.
  /// fontSize: 12, fontWeight: w500, color: primaryColor
  static const TextStyle activityMetaText = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  /// Activity feed "No Activities found" / range-feed error message.
  /// fontSize: 16, fontWeight: w500, color: primaryColor @ 55% opacity
  static TextStyle get activityEmptyFeedText => TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.55),
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// Activity date/dropdown selected-value text — placeholder color while
  /// empty, body color once a value is chosen.
  /// fontSize: 15, fontWeight: w400
  static TextStyle activityDropdownValueText({required bool hasValue}) =>
      TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: hasValue
            ? AppColors.activityBodyTextColor
            : AppColors.activityPlaceholderTextColor,
      );

  /// Activity tab custom-dropdown popup item text.
  /// fontSize: 14, fontWeight: w400, color: activityBodyTextColor
  static const TextStyle activityDropdownPopupItem = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.activityBodyTextColor,
  );

  /// Same metrics as [value] (14/w500/primaryColor) but without the explicit
  /// height — used where callers rely on the ambient/font default line
  /// height instead of value's 19/14 (activity time/name text, "Select All"
  /// labels, student-scope checkbox rows).
  /// fontSize: 14, fontWeight: w500, color: primaryColor
  static const TextStyle activityBodyValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  /// Activity feed popup-menu item title (View/Edit/Delete).
  /// fontSize: 14, fontWeight: w500, color: blackColor
  static const TextStyle activityPopupItemTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.blackColor,
  );

  /// Compact bold name text — single-student avatar row, student grid tile.
  /// fontSize: 13, fontWeight: w600, color: primaryColor
  static const TextStyle activityCompactBoldName = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// List-row value text — student-list-sheet name row, [ViewWidget] content.
  /// fontSize: 15, fontWeight: w600, color: primaryColor
  static const TextStyle activityRowValueText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// Button label with no color of its own — used where the surrounding
  /// button (e.g. `ElevatedButton.styleFrom(foregroundColor: ...)`) supplies
  /// the color.
  /// fontSize: 16, fontWeight: w700
  static const TextStyle activityPlainButtonLabel = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
  );

  /// Modal/bottom-sheet dialog title ("Student" list sheet, "Image Uploader").
  /// fontSize: 18, fontWeight: w700, color: primaryColor
  static const TextStyle activityDialogTitle = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  /// [ActivityStudentDisplayTile] name text.
  /// fontSize: 12, fontWeight: w600, color: primaryColor, height: 1.15
  static const TextStyle activityStudentTileName = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.15,
  );

  /// "Processing..." label on the media-preview processing card.
  /// fontSize: 12, fontWeight: w700, color: activityProcessingText
  static const TextStyle activityProcessingCardText = TextStyle(
    color: AppColors.activityProcessingText,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  /// "PROCESSING" corner-badge label on media thumbnails.
  /// fontSize: 9.5, fontWeight: w700, color: activityProcessingBadgeText
  static const TextStyle activityProcessingBadgeLabel = TextStyle(
    color: AppColors.activityProcessingBadgeText,
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
  );

  /// Emphasized 13px label text — toggle option labels ("Yes"/"No"),
  /// checkbox labels, media-upload status lines.
  /// fontSize: 13, fontWeight: w500, color: primaryColor
  static const TextStyle activityStrongLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  /// Media-upload success line ("Uploaded X/Y").
  /// fontSize: 13, fontWeight: w600, color: activityUploadSuccessColor
  static const TextStyle activityUploadSuccessText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.activityUploadSuccessColor,
  );

  /// Media-upload warning/partial-failure line.
  /// fontSize: 13, fontWeight: w500, color: activityUploadWarningColor
  static const TextStyle activityUploadWarningText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.activityUploadWarningColor,
  );

  /// Muted field label with no size of its own (inherits ambient) — "Students
  /// involved"/"First Aid Administered" style captions.
  /// fontWeight: w500, color: primaryColor @ 60% opacity
  static TextStyle get activityMutedFieldLabel => TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.6),
    fontWeight: FontWeight.w500,
  );

  /// Field label text — matches [label]'s metrics minus the explicit height.
  /// fontSize: 13, fontWeight: w400, color: primaryColor
  static const TextStyle activityFieldLabel = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Required-field asterisk marker — color only, inherits ambient
  /// size/weight.
  static const TextStyle activityRequiredMarker = TextStyle(
    color: AppColors.activityRequiredFieldMarkerColor,
  );

  /// Responsive input-field label (RichText label + required marker).
  /// fontWeight: w400, color: primaryColor
  static TextStyle activityInputFieldLabel({required double fontSize}) =>
      TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryColor,
      );

  /// Responsive input-field value text.
  /// fontWeight: w600, color: primaryColor, height: 19/14
  static TextStyle activityInputValueText({required double fontSize}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
        height: 19 / 14,
      );

  /// Responsive dropdown popup-item text (no height of its own).
  /// fontWeight: w400, color: primaryColor
  static TextStyle activityInputPopupItemText({required double fontSize}) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryColor,
      );

  /// Date-field selected-value text — dimmed while unselected.
  /// fontSize: 14, fontWeight: w500
  static TextStyle activityDateValueText({required bool hasValue}) => TextStyle(
    color: hasValue
        ? AppColors.primaryColor
        : AppColors.primaryColor.withValues(alpha: 0.6),
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// "Video preview unavailable" placeholder text — color only.
  static const TextStyle activityMediaUnavailableText = TextStyle(
    color: AppColors.activityMediaPlaceholderIconColor,
  );

  /// "Video processing..." caption under the processing placeholder.
  /// fontSize: 13, fontWeight: w600, color: activityProcessingText
  static const TextStyle activityProcessingCaption = TextStyle(
    color: AppColors.activityProcessingText,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Bold 14px field value / section-title text ("Select Students" heading,
  /// selected-staff display).
  /// fontSize: 14, fontWeight: w600, color: primaryColor
  static const TextStyle activityFieldValueBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// Search-field hint text.
  /// fontSize: 14, fontWeight: w400, color: activitySearchHintColor
  static const TextStyle activitySearchHintText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.activitySearchHintColor,
  );

  /// Empty-list placeholder text.
  /// fontSize: 14, color: activityPlaceholderTextColor
  static const TextStyle activityEmptyListText = TextStyle(
    color: AppColors.activityPlaceholderTextColor,
    fontSize: 14,
  );

  /// Muted checkbox label text (nap-reminder checkbox).
  /// fontSize: 14, fontWeight: w400, color: activityPlaceholderTextColor
  static const TextStyle activityCheckboxLabelMuted = TextStyle(
    color: AppColors.activityPlaceholderTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Small inline error text (12px).
  /// fontSize: 12, fontWeight: w500, color: activityErrorTextColor
  static const TextStyle activityErrorTextSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.activityErrorTextColor,
  );

  /// Scripted signature text — deliberately not [Fonts.manrope] (a distinct
  /// cursive font used only for the incident-activity signature band).
  /// fontFamily: 'MervaleScript', fontSize: 24, fontWeight: w400,
  /// color: primaryColor
  static const TextStyle activitySignatureScriptText = TextStyle(
    fontFamily: 'MervaleScript',
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
  );

  /// "Signature-ID" caption under a scripted signature.
  /// fontSize: 10, fontWeight: w500, color: activityTextColorMuted50
  static const TextStyle activitySignatureIdCaption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.activityTextColorMuted50,
  );

  /// "Upload" section label in the school-cloud image uploader dialog.
  /// fontSize: 14, fontWeight: w700, color: primaryColor
  static const TextStyle activityUploadSectionLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  /// Uploader helper text ("Only image files are supported...").
  /// fontSize: 12, color: primaryColor @ 50% opacity
  static TextStyle get activityUploaderHintText => TextStyle(
    fontSize: 12,
    color: AppColors.primaryColor.withValues(alpha: 0.5),
  );

  /// "Selected Images (N)" section label.
  /// fontSize: 13, fontWeight: w700, color: primaryColor
  static const TextStyle activitySelectedImagesLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  /// "Uploading… N%" progress caption.
  /// fontSize: 12, color: primaryColor @ 60% opacity
  static TextStyle get activityUploadProgressText => TextStyle(
    fontSize: 12,
    color: AppColors.primaryColor.withValues(alpha: 0.6),
  );

  /// "N file(s) selected" caption.
  /// fontSize: 13, color: primaryColor @ 60% opacity
  static TextStyle get activitySelectedFilesCaption => TextStyle(
    fontSize: 13,
    color: AppColors.primaryColor.withValues(alpha: 0.6),
  );

  /// "Choose Media" gradient-button label — dims when disabled.
  /// fontWeight: w600
  static TextStyle activityGradientButtonLabel({required bool enabled}) =>
      TextStyle(
        fontWeight: FontWeight.w600,
        color: enabled
            ? AppColors.cardColor
            : AppColors.activityPlaceholderTextColor,
      );

  /// Destructive inline action text ("Replace") — color only.
  static const TextStyle activityDestructiveActionText = TextStyle(
    color: AppColors.activityErrorTextColor,
  );

  /// "Select Media Source" picker-dialog title.
  /// fontSize: 20, fontWeight: w700, color: primaryColor
  static const TextStyle activityPickerDialogTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  /// Media-source picker option label ("Take Photo", "Record Video", ...).
  /// fontSize: 16, fontWeight: w600, color: primaryColor
  static const TextStyle activityPickerOptionLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// "Take/Upload Photo or Video" hint inside the picture-box uploader.
  /// fontSize: 14, color: primaryColor
  static const TextStyle activityUploadBoxHint = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 14,
  );

  /// Responsive media-uploader label text (no weight of its own).
  /// color: primaryColor
  static TextStyle activityMediaLabelText({required double fontSize}) =>
      TextStyle(fontSize: fontSize, color: AppColors.primaryColor);

  /// Responsive body text with no weight/color of its own (inherits
  /// ambient).
  static TextStyle activityResponsiveBodyText({required double fontSize}) =>
      TextStyle(fontSize: fontSize);

  /// Inline validation-error text (13px, no weight of its own).
  /// fontSize: 13, color: activityErrorTextColor
  static const TextStyle activityValidationErrorText = TextStyle(
    color: AppColors.activityErrorTextColor,
    fontSize: 13,
  );

  /// Media-upload progress line without a weight override — the photo/video
  /// activity screen's own variant, kept distinct from
  /// [activityStrongLabel]'s w500 since the source doesn't set a weight here.
  /// fontSize: 13, color: primaryColor
  static const TextStyle activityUploadProgressPlain = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 13,
  );

  /// "Photo/Video processing in background..." label.
  /// fontSize: 12.5, fontWeight: w600, color: activityProcessingText
  static const TextStyle activityMediaProcessingLabel = TextStyle(
    color: AppColors.activityProcessingText,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
  );

  /// Small dark-background tooltip text (disabled-tile / sign-in-required
  /// tooltips).
  /// fontSize: 12, color: cardColor
  static const TextStyle activityTooltipText = TextStyle(
    color: AppColors.cardColor,
    fontSize: 12,
  );

  /// Choose-Activity grid tile label — dims when the activity is disabled.
  /// fontSize: 14, fontWeight: w500
  static TextStyle activityGridTileLabel({required bool isDisabled}) =>
      TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDisabled
            ? AppColors.activityMutedGreyColor
            : AppColors.primaryColor,
      );

  /// Daily/Custom tab toggle label — themed when selected.
  /// fontWeight: bold
  static TextStyle activityTabToggleLabel({required bool isSelected}) =>
      TextStyle(
        color: isSelected
            ? AppColors.themeColor
            : AppColors.activityMutedGreyColor,
        fontWeight: FontWeight.bold,
      );

  /// Filter-screen shimmer-loading label.
  /// fontSize: 13, fontWeight: w400, color: primaryColor @ 50% opacity
  static TextStyle get activityFilterShimmerLabel => TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.5),
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  /// Filter-screen load-error text.
  /// fontSize: 14, color: primaryColor @ 70% opacity
  static TextStyle get activityFilterErrorText => TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.7),
    fontSize: 14,
  );

  // ── Reports (Mandate M4) ────────────────────────────────────────────────

  /// Reports hub page title. Size and line height are responsive, so they are
  /// parameters rather than baked in.
  /// fontWeight: w600, color: primaryColor
  static TextStyle reportsScreenTitle({
    required double fontSize,
    required double height,
  }) => TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
    height: height,
  );

  /// Reports hub tab label. Deliberately has NO color of its own: the TabBar
  /// supplies it through `labelColor` / `unselectedLabelColor`, and baking a
  /// color in here would flatten the selected/unselected distinction.
  /// fontSize: 16, fontWeight: w600
  static const TextStyle reportsTabLabel = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// "No reports available yet." placeholder. No explicit height — the text it
  /// replaced had none, and adding one would change the line box.
  /// fontSize: 14, fontWeight: w500, color: primaryColor @ 60% opacity
  static TextStyle get reportsEmptyListText => TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor.withValues(alpha: 0.6),
  );

  /// Base report form field label. fontWeight w400, color primaryColor.
  /// Local variation (opacity, height) goes through `.copyWith(...)`.
  static TextStyle reportsFieldLabel({required double fontSize}) => TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
  );

  /// Base report field VALUE. fontWeight w500, color primaryColor.
  static TextStyle reportsFieldValue({required double fontSize}) => TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: fontSize,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  /// Base report heading. fontWeight w600, color primaryColor.
  static TextStyle reportsHeading({required double fontSize}) => TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// "Note: All Classrooms will be selected by Default." fontSize 12, w400.
  static const TextStyle reportsNote = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.reportsAccentColor,
  );

  /// Small uppercase section heading above a group of filter fields.
  static const TextStyle reportsSectionLabel = TextStyle(
    fontFamily: Fonts.manrope,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.reportsAccentColor,
  );

  /// Required-field "*" marker inside a RichText label. Colour only, so the
  /// surrounding TextSpan supplies size, weight and family.
  static const TextStyle reportsRequiredMarker = TextStyle(
    color: AppColors.reportsRequiredFieldMarkerColor,
  );

  /// Multi-select row label. Deliberately has NO colour of its own — these
  /// rows sit inside a popup that supplies the ambient colour, and baking one
  /// in would override it.
  /// fontSize: 14, fontWeight: w500
  static const TextStyle reportsSelectionRowLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// "No <items> found" empty text inside a multi-select popup. Colour only.
  static const TextStyle reportsSelectionEmptyLabel = TextStyle(
    color: AppColors.reportsDisabledForegroundColor,
  );

  /// Label on the filled Download button. Colour + weight only; the button
  /// supplies the size.
  static const TextStyle reportsDownloadButtonLabel = TextStyle(
    color: AppColors.cardColor,
    fontWeight: FontWeight.w600,
  );

  // ---------------------------------------------------------------------
  // Individual Movements (Mandate 4) — see
  // lib/presentation/features/availability/**. Named per the same
  // `movement<Purpose>` convention as the `activityXxx`/`attendanceXxx`
  // entries above.
  // ---------------------------------------------------------------------

  /// Board screen "Overview" heading.
  /// fontSize: 18, fontWeight: w500, color: primaryColor
  static const TextStyle movementSectionHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  /// Load-error message and "No movements available" empty state.
  /// fontSize: 14, color: primaryColor
  static const TextStyle movementErrorText = TextStyle(
    fontSize: 14,
    color: AppColors.primaryColor,
  );

  /// Pager's current-bucket title, under the prev/next arrows.
  /// fontSize: 14, fontWeight: w600, color: primaryColor
  static const TextStyle movementPagerSectionTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );
  /// Board column card title (Overdue/Upcoming/Confirmed/Rejected).
  /// fontSize: 18, fontWeight: w600, color: primaryColor
  static const TextStyle movementColumnTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// "Start School"/"Leave School" type chip label.
  /// fontSize: 12, fontWeight: w600, color: primaryColor
  static const TextStyle movementTypeChipLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// Row classroom name and movement-date text.
  /// fontSize: 14, fontWeight: w500, color: primaryColor
  static const TextStyle movementClassroomLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  /// Row student-name link.
  /// fontSize: 15, fontWeight: w500, color: primaryColor
  static const TextStyle movementStudentNameLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor,
  );

  /// Row comment preview text.
  /// fontSize: 13, fontWeight: w500, color: primaryColor @ 85% opacity
  static TextStyle get movementCommentText => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor.withValues(alpha: 0.85),
  );

  /// "More Options" bottom-sheet title.
  /// fontSize: 18, fontWeight: w700, color: primaryColor
  static const TextStyle movementBottomSheetTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryColor,
  );

  /// Bottom-sheet action row label — destructive (delete) rows pass
  /// [AppColors.errorColor].
  /// fontSize: 15, fontWeight: w600
  static TextStyle movementActionTileLabel({required Color color}) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: color,
  );

  /// Confirm-movement screen field label.
  /// fontSize: 13, fontWeight: w500, color: primaryColor @ 55% opacity
  static TextStyle get movementConfirmLabel => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor.withValues(alpha: 0.55),
  );

  /// Confirm-movement screen field value.
  /// fontSize: 14, fontWeight: w600, color: primaryColor
  static const TextStyle movementConfirmValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// Add/edit-movement form field label (responsive size).
  /// fontWeight: w400, color: primaryColor
  static TextStyle movementFormLabel({required double fontSize}) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryColor,
  );

  /// Add/edit-movement form field value / dropdown selection (responsive size).
  /// fontWeight: w600, color: primaryColor, height: 19/14
  static TextStyle movementFormValue({required double fontSize}) => TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
    height: 19 / 14,
  );

  // ---------------------------------------------------------------------
  // Future Availability (Mandate 4) — see
  // lib/presentation/features/availability/view/future_availability_screen.dart.
  // ---------------------------------------------------------------------

  /// Date navigator's formatted-date label.
  /// fontSize: 15, fontWeight: w600, color: primaryColor
  static const TextStyle futureAvailabilityDateNavLabel = TextStyle(
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w600,
    fontSize: 15,
  );

  /// "Availability" screen title.
  /// fontSize: 18, fontWeight: w500, color: primaryColor
  static const TextStyle futureAvailabilityTitle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  /// "Full Day"/"2 Shifts" toggle label — bold+full colour when selected.
  /// fontSize: 15
  static TextStyle futureAvailabilityShiftToggleLabel({required bool isSelected}) =>
      TextStyle(
        fontSize: 15,
        color: isSelected
            ? AppColors.primaryColor
            : AppColors.primaryColor.withValues(alpha: 0.55),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      );

  /// Empty/error state message under the grid.
  /// fontSize: 13, fontWeight: w500, color: primaryColor @ 80% opacity
  static TextStyle get futureAvailabilityEmptyMessage => TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.8),
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// Grid header cell text (Classroom/Morning/Afternoon).
  /// fontSize: 15, fontWeight: w700, color: primaryColor @ 80% opacity
  static TextStyle get futureAvailabilityHeaderCellText => TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 15,
    color: AppColors.primaryColor.withValues(alpha: 0.8),
  );

  /// Grid classroom-name cell text.
  /// fontSize: 13, fontWeight: w600, color: primaryColor @ 90% opacity
  static TextStyle get futureAvailabilityClassroomName => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: AppColors.primaryColor.withValues(alpha: 0.9),
  );

  /// Grid available-spot count — colour signals negative vs non-negative.
  /// fontSize: 18, fontWeight: w700
  static TextStyle futureAvailabilityCountValue({required Color color}) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: color,
  );

  // ── Dashboard: My Day card ────────────────────────────────────────────────
  // Mandate 4 §4.4. Exact values lifted from my_day_card.dart's inline styles;
  // rendered output is unchanged. Named for the role they play, not the size.

  /// The countdown's hour/minute/second digits.
  static const TextStyle myDayCountdownDigits = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 44,
    fontWeight: FontWeight.w600,
  );

  /// The ':' between countdown units. Deliberately a different size from the
  /// digits — that is the existing rendering, not a mistake.
  static const TextStyle myDayCountdownSeparator = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 48,
    fontWeight: FontWeight.w600,
  );

  /// The 'HH' / 'MM' / 'SS' caption under each countdown unit.
  static TextStyle myDayCountdownUnitLabel = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.5),
    fontSize: 12,
    height: 0.1,
  );

  /// Day name shown above the countdown for an upcoming shift.
  static const TextStyle myDayUpcomingDayName = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  /// The card's one-line schedule status sentence.
  static const TextStyle myDayStatusLine = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// Work Time / Break Time chip label.
  static const TextStyle myDayChipLabel = TextStyle(
    color: AppColors.secondaryColor,
  );

  /// The clock-in PIN, rendered on the primary gradient.
  static const TextStyle myDayClockInPin = TextStyle(
    color: AppColors.cardColor,
    fontSize: 17,
    fontWeight: FontWeight.bold,
    letterSpacing: 17 * (-3 / 100),
  );

  /// Self-attendance action button label (Sign In / Sign Out / Transfer /
  /// Mark Absent).
  static const TextStyle myDayActionButtonLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Geofence status line under the card body.
  static const TextStyle myDayGeofenceStatus = TextStyle(
    fontSize: 12,
    height: 1.4,
  );

  // ── Dashboard: chat-preview row ───────────────────────────────────────────

  /// "No recent chat" placeholder.
  static TextStyle chatPreviewEmpty = TextStyle(
    fontSize: 13,
    color: AppColors.primaryColor.withValues(alpha: 0.5),
  );

  /// Conversation title on a preview row.
  static const TextStyle chatPreviewTitle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// Relative timestamp on a preview row.
  static TextStyle chatPreviewTime = TextStyle(
    fontSize: 11,
    color: AppColors.primaryColor.withValues(alpha: 0.5),
  );

  /// Last-message snippet on a preview row.
  static TextStyle chatPreviewSnippet = TextStyle(
    fontSize: 12,
    color: AppColors.primaryColor.withValues(alpha: 0.5),
  );

  /// Unread-count text inside the badge.
  static const TextStyle chatPreviewUnreadBadge = TextStyle(
    color: AppColors.cardColor,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  // ── Newsletter (Mandate 4) ────────────────────────────────────────────────
  // Feature-prefixed, matching the `activity*` convention above.
  //
  // None of these set `fontFamily`. `ThemeData.fontFamily` is 'Manrope' on
  // both the light and dark themes, and a `Text`'s style merges onto the
  // ambient DefaultTextStyle, so the family resolves to Manrope without being
  // restated (§4: "these lines are a find-and-delete").
  //
  // Styles whose colour comes from the newsletter's AUTHOR-CHOSEN palette are
  // NOT here — see [newsletterTitleBar] / [newsletterRichBody], which carry
  // chrome only and take their colour via `.copyWith()`.

  /// Tab label in the newsletter tab bars. Colour varies by selection, so
  /// callers apply `.copyWith(color: …)`.
  static const TextStyle newsletterTabLabel = TextStyle(fontSize: 15);

  /// "Newsletter" header above the parent tab bar.
  static const TextStyle newsletterScreenTitle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  /// Centred "No Newsletters" / "No Sent Newsletters" / error text in a list.
  static const TextStyle newsletterEmptyState = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  /// Centred failure text on the preview screen.
  static const TextStyle newsletterPreviewError = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Text inside the stale-content banner on the preview screen.
  static final TextStyle newsletterStaleBanner = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.9),
    fontSize: 13,
  );

  /// The large recipient count in the recipients sheet header.
  static const TextStyle newsletterRecipientCount = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  /// "Recipients" caption under the count.
  static final TextStyle newsletterRecipientCountCaption = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.66),
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// One recipient's name in the sheet list.
  static const TextStyle newsletterRecipientName = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// The recipient-count badge on a list card.
  static const TextStyle newsletterRecipientBadge = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  /// Title row of the recipients sheet.
  static const TextStyle newsletterSheetTitle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  /// "+N" extra-attachment count over a card thumbnail.
  static const TextStyle newsletterAttachmentCountBadge = TextStyle(
    color: AppColors.whiteColor,
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );

  /// "Attachments" heading above the preview grid.
  static final TextStyle newsletterAttachmentsHeading = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.85),
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// File name under one attachment tile.
  static final TextStyle newsletterAttachmentFileName = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.85),
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  /// "No newsletter content available." in the preview body.
  static final TextStyle newsletterEmptyContent = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.65),
    fontSize: 14,
  );

  /// Newsletter title on a list card.
  static const TextStyle newsletterCardTitle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  /// Meta label ("Date", "Created by") on a list card.
  static final TextStyle newsletterCardMetaLabel = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.58),
    fontSize: 13,
  );

  /// Meta value beside a [newsletterCardMetaLabel].
  static final TextStyle newsletterCardMetaValue = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.82),
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  /// Caption under the full-screen image preview overlay.
  static final TextStyle newsletterOverlayCaption = TextStyle(
    color: AppColors.primaryColor.withValues(alpha: 0.7),
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// Newsletter title inside the themed gradient title bar.
  ///
  /// CHROME ONLY — no colour. The bar paints its text in
  /// `NewsletterThemeColors.titleTextColor`, which is author data, so the
  /// caller applies `.copyWith(color: theme.titleTextColor)`.
  static const TextStyle newsletterTitleBar = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  /// Base style for rendered newsletter body HTML. CHROME ONLY — the colour is
  /// `NewsletterThemeColors.body`, chosen by the newsletter's author.
  static const TextStyle newsletterRichBody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  /// Base style for a rendered newsletter heading part. CHROME ONLY — the
  /// colour is `NewsletterThemeColors.heading`.
  static const TextStyle newsletterRichHeading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

}

/// Reusable text widgets with predefined styles
class AppText extends StatelessWidget {
  const AppText.label(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.label;

  const AppText.value(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.value;

  const AppText.title(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.title;

  const AppText.subtitle(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.subtitle;

  const AppText.body(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.body;

  const AppText.small(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.small;

  const AppText.sectionHeader(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  }) : _variant = _TextVariant.sectionHeader;

  final String text;
  final _TextVariant _variant;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  TextStyle get _baseStyle {
    switch (_variant) {
      case _TextVariant.label:
        return AppTextStyles.label;
      case _TextVariant.value:
        return AppTextStyles.value;
      case _TextVariant.title:
        return AppTextStyles.title;
      case _TextVariant.subtitle:
        return AppTextStyles.subtitle;
      case _TextVariant.body:
        return AppTextStyles.body;
      case _TextVariant.small:
        return AppTextStyles.small;
      case _TextVariant.sectionHeader:
        return AppTextStyles.sectionHeader;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _baseStyle.merge(style),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}

enum _TextVariant { label, value, title, subtitle, body, small, sectionHeader }
