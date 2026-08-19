import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu_tokens.dart';

/// The app's legacy colour tokens, remapped onto the ChildcareWow brand
/// palette in [SkeuColors].
///
/// Screens that have not yet been rebuilt in the skeuomorphic language still
/// reference these names, so pointing them at the brand ramps brings the whole
/// app onto one palette without touching every call site: the old violet /
/// aubergine scheme is gone, and teal now carries structure, navy carries text,
/// and pink is reserved for the recommended action. Prefer [SkeuColors]
/// directly in new code.
class AppColors {
  const AppColors._();

  /// Was violet #5978F7. Teal is the brand's structural / interactive colour.
  static const themeColor = SkeuColors.teal600;

  /// Was aubergine #573353. Navy ink carries every heading and body text.
  static const primaryColor = SkeuColors.ink;
  static const secondaryColor = SkeuColors.navy700;

  static const cardColor = SkeuColors.white;
  static final cardBorderColor = SkeuColors.borderHairline;

  static const fieldBackgroundColor = SkeuColors.cream100;

  static const accentColor = SkeuColors.sun400;

  /// Form-error red, deliberately NOT brand pink: pink means "recommended
  /// action" and must never double as a warning.
  static const errorColor = SkeuColors.danger500;
  static const warningColor = SkeuColors.sun400;
  static const successColor = SkeuColors.green500;

  static const dividerColor = SkeuColors.cream200;

  static const classroomStudentTabColor = SkeuColors.teal50;
  static const classroomStaffTabColor = SkeuColors.teal100;
  static const classroomNotesTabColor = SkeuColors.green100;

  // Bar bands are the design's mid-light ramp steps: saturated enough to read
  // inside a recessed trough, light enough that four of them side by side stay
  // calm. The status dots elsewhere use the -400/-500 steps instead.
  static const Color lightBlueProgressBar = SkeuColors.teal300;
  static const Color mustardProgressBar = SkeuColors.sun300;
  static const Color lightGreenProgressBar = SkeuColors.green300;
  static const Color redProgressBar = SkeuColors.danger100;
  static const Color refundLegendColor = SkeuColors.teal200;
  static const Color paidLegendColor = SkeuColors.green500;
  static const Color colorBox = SkeuColors.green300;
  static const Color colorBox2 = SkeuColors.danger500;
  static const Color colorBox3 = SkeuColors.teal500;

  static const List<Color> scaffoldGradientColors = [
    Color(0xFFFFFFFF),
    Color(0xFFEFF1F9),
  ];

  /// The primary object face: teal, the brand's structural colour.
  static const List<Color> primaryGradientColors = [
    SkeuColors.teal400,
    SkeuColors.teal600,
  ];

  static const List<Color> secondaryGradientColors = [
    SkeuColors.teal500,
    SkeuColors.teal700,
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
    SkeuColors.pink400,
    SkeuColors.pink600,
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
  /// Monogram beads cycle the brand's own tinted surfaces, so a wall of
  /// avatars reads as one family rather than six unrelated pastels.
  static const List<Color> profileAvatarColors = <Color>[
    SkeuColors.pink200,
    SkeuColors.sun200,
    SkeuColors.teal200,
    SkeuColors.orange200,
    SkeuColors.green200,
    SkeuColors.purple200,
  ];

  /// Tag washes, drawn from the brand's soft surface tints.
  static const List<Color> tagColors = [
    SkeuColors.sun100,
    SkeuColors.teal50,
    SkeuColors.teal100,
    SkeuColors.green100,
    SkeuColors.pink100,
    SkeuColors.purple100,
    SkeuColors.orange100,
  ];

  static const List<Color> tagTextColors = [SkeuColors.ink];

  // Billing specific colors
  static const Color billingTextColor = SkeuColors.ink;
  static const Color billingTextSecondary = SkeuColors.inkSoft;

  // Transaction badge colors
  static const Color billingInvoiceBadgeColor = SkeuColors.teal100;
  static const Color billingPaymentBadgeColor = SkeuColors.green100;
  static const Color billingRefundBadgeColor = SkeuColors.cream200;
  static const Color billingDefaultBadgeColor = SkeuColors.cream200;

  // Transaction status colors
  static const Color billingStatusInProgressColor = SkeuColors.sun200;
  static const Color billingStatusCancelledColor = SkeuColors.danger100;

  // Card and container colors
  static const Color billingCardColor = SkeuColors.white;
  static final Color billingCardBorderColor = primaryColor.withValues(
    alpha: 0.2,
  );
  static final Color billingCardShadowColor = SkeuColors.navy.withValues(
    alpha: 0.06,
  );

  // Divider colors
  static final Color billingDividerColor = primaryColor.withValues(alpha: 0.1);

  // Button colors
  static const Color billingButtonTextColor = SkeuColors.white;

  // Error/Alert colors for billing
  static const Color billingErrorBackgroundColor = SkeuColors.danger50;
  static const Color billingErrorBorderColor = SkeuColors.danger100;
  static const Color billingErrorIconColor = SkeuColors.danger600;
  static const Color billingErrorTextColor = SkeuColors.danger600;

  // Grey shades for billing
  static const Color billingGrey = Colors.grey;
  static final Color billingGreyLight = Colors.grey.shade100;
  static final Color billingGreyMedium = Colors.grey.shade500;
  static final Color billingGreyDark = Colors.grey.shade700;
  static final Color billingGreyTransparent = Colors.grey.withValues(
    alpha: 0.3,
  );

  // Success color
  static const Color billingSuccessColor = SkeuColors.green500;

  // Background colors
  static const Color billingBackgroundColor = SkeuColors.white;
  static const Color billingTransparentColor = Colors.transparent;

  // Shadow colors
  // Every shadow in the design system is navy-tinted, never pure black.
  static final Color billingShadowColor = SkeuColors.navy.withValues(
    alpha: 0.05,
  );
  static final Color billingShadowColorLight = SkeuColors.navy.withValues(
    alpha: 0.06,
  );
  static final Color billingShadowColorMedium = SkeuColors.navy.withValues(
    alpha: 0.1,
  );

  // Border colors with opacity
  static const Color billingBorderLight = SkeuColors.borderHairline;
  static final Color billingBorderMedium = primaryColor.withValues(alpha: 0.2);
  static final Color billingBorderHeavy = primaryColor.withValues(alpha: 0.4);
  static const Color billingDividerLight = SkeuColors.cream200;

  // Button and input colors
  static final Color billingButtonDisabled = Colors.grey[300]!;
  static final Color billingInputBorderDefault = Colors.grey.shade200;
  static const Color billingInputBorderFocused = SkeuColors.teal500;
  static final Color billingInputBackgroundDisabled = Colors.grey[200]!;

  // Status indicator colors (for success/error states)
  static const Color billingStatusSuccess = SkeuColors.green500;
  static const Color billingStatusError = SkeuColors.danger500;
}
