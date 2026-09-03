import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Type the M03 frames draw that is not on the core ladder.
///
/// Sizes are the frame's own rem value times 16, exactly as `AppTextStyles`
/// writes them, and letter spacing is written as its em value times the size
/// so the number in a frame is the number here. No colour: colour is a
/// `Colourway` decision the call site makes.
abstract final class DashboardTextStyles {
  static const double _px = 16;
  static const String _font = AppTextStyles.fontFamily;


  /// An attention card's kind: INCIDENTS, RATIO, SHIFTS.
  static const TextStyle attentionEyebrow = TextStyle(
    fontFamily: _font,
    fontSize: 0.68 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.1 * 0.68 * _px,
  );

  /// What the attention card is about, in one line.
  static const TextStyle attentionTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.95 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The word beside a headline count: "reports".
  static const TextStyle attentionHeadlineLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.76 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The pill key on an attention card: Review, Scheduling.
  static const TextStyle attentionAction = TextStyle(
    fontFamily: _font,
    fontSize: 0.74 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The outstanding figure on the billing card.
  static const TextStyle attentionMoney = TextStyle(
    fontFamily: _font,
    fontSize: 1.9 * _px,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  /// A count inside an attention card's tinted tile.
  static const TextStyle attentionTileValue = TextStyle(
    fontFamily: _font,
    fontSize: 1.0 * _px,
    fontWeight: FontWeight.w800,
  );

  /// A My day tile's caption: SINCE, WORK TIME, BREAK.
  static const TextStyle dayTileLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.6 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.08 * 0.6 * _px,
  );

  /// The time a My day tile names.
  static const TextStyle dayTileTime = TextStyle(
    fontFamily: _font,
    fontSize: 0.98 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A window inside a My day tile.
  static const TextStyle dayTileRange = TextStyle(
    fontFamily: _font,
    fontSize: 0.76 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The four digits of a Sign-In PIN, tracked wide.
  static const TextStyle pin = TextStyle(
    fontFamily: _font,
    fontSize: 0.96 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.14 * 0.96 * _px,
  );

  /// A key in My day's two-by-two grid.
  static const TextStyle dayKeyLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.83 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Who the dashboard's one conversation is with.
  static const TextStyle messageName = TextStyle(
    fontFamily: _font,
    fontSize: 0.79 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The last line of that conversation.
  static const TextStyle messagePreview = TextStyle(
    fontFamily: _font,
    fontSize: 0.71 * _px,
    fontWeight: FontWeight.w500,
  );

  /// Its unread count.
  static const TextStyle messageBadge = TextStyle(
    fontFamily: _font,
    fontSize: 0.61 * _px,
    fontWeight: FontWeight.w800,
  );

  /// A dotted status pill on a card's title row.
  static const TextStyle statusPillText = TextStyle(
    fontFamily: _font,
    fontSize: 0.64 * _px,
    fontWeight: FontWeight.w800,
  );

  /// A figure in the school-status well row.
  static const TextStyle statusNumber = TextStyle(
    fontFamily: _font,
    fontSize: 1.1 * _px,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  /// Its caption.
  static const TextStyle statusLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.6 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Students, or Staff, above a breakdown trough.
  static const TextStyle statusGroupTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The line beside it: "86 enrolled · 80 expected".
  static const TextStyle statusGroupMeta = TextStyle(
    fontFamily: _font,
    fontSize: 0.68 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A legend chip's state name.
  static const TextStyle legendLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.66 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its count.
  static const TextStyle legendCount = TextStyle(
    fontFamily: _font,
    fontSize: 0.72 * _px,
    fontWeight: FontWeight.w800,
  );

  /// A classroom on a ratio or shift row.
  static const TextStyle innerRowTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.82 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its counts or window.
  static const TextStyle innerRowSub = TextStyle(
    fontFamily: _font,
    fontSize: 0.69 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The flag at the end of that row: +1 staff, In Ratio.
  static const TextStyle innerRowFlag = TextStyle(
    fontFamily: _font,
    fontSize: 0.68 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The figure inside the staff ratio ring.
  static const TextStyle ratioRingNumber = TextStyle(
    fontFamily: _font,
    fontSize: 1.3 * _px,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  /// The caption under it: OF 14 IN.
  static const TextStyle ratioRingCaption = TextStyle(
    fontFamily: _font,
    fontSize: 0.54 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.06 * 0.54 * _px,
  );

  /// A figure on the two-up availability row.
  static const TextStyle summaryNumber = TextStyle(
    fontFamily: _font,
    fontSize: 1.3 * _px,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  /// Its caption.
  static const TextStyle summaryLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.72 * _px,
    fontWeight: FontWeight.w600,
  );

  /// One of the billing card's four figures.
  static const TextStyle billingAmount = TextStyle(
    fontFamily: _font,
    fontSize: 1.08 * _px,
    fontWeight: FontWeight.w700,
    height: 1.0,
  );

  /// Its caption: Invoiced, Net paid, In process.
  static const TextStyle billingLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.62 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The date range key on the billing card.
  static const TextStyle rangeKeyText = TextStyle(
    fontFamily: _font,
    fontSize: 0.66 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The all-unpaid row's title.
  static const TextStyle unpaidTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.78 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its explanation.
  static const TextStyle unpaidSub = TextStyle(
    fontFamily: _font,
    fontSize: 0.66 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its figure.
  static const TextStyle unpaidValue = TextStyle(
    fontFamily: _font,
    fontSize: 0.95 * _px,
    fontWeight: FontWeight.w800,
  );

  /// A week strip day: THU.
  static const TextStyle shiftDayLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.58 * _px,
    fontWeight: FontWeight.w800,
  );

  /// Its date.
  static const TextStyle shiftDayNumber = TextStyle(
    fontFamily: _font,
    fontSize: 1.02 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The classroom that day's shift is in.
  static const TextStyle shiftTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.83 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The Today pill on the week strip.
  static const TextStyle todayPillText = TextStyle(
    fontFamily: _font,
    fontSize: 0.6 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The date range inside an attendance well.
  static const TextStyle rangeWellText = TextStyle(
    fontFamily: _font,
    fontSize: 0.79 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The Change link beside it.
  static const TextStyle rangeWellLink = TextStyle(
    fontFamily: _font,
    fontSize: 0.69 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A figure on an attendance summary tile.
  static const TextStyle summaryTileNumber = TextStyle(
    fontFamily: _font,
    fontSize: 1.22 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Its caption.
  static const TextStyle summaryTileLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.63 * _px,
    fontWeight: FontWeight.w700,
  );

  /// One recorded day on an attendance list.
  static const TextStyle dayRowText = TextStyle(
    fontFamily: _font,
    fontSize: 0.79 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The student a guardian is looking at.
  static const TextStyle childName = TextStyle(
    fontFamily: _font,
    fontSize: 1.02 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Their classroom and age.
  static const TextStyle childMeta = TextStyle(
    fontFamily: _font,
    fontSize: 0.73 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Their initials, in the big avatar.
  static const TextStyle childAvatarText = TextStyle(
    fontFamily: _font,
    fontSize: 0.95 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A student's name on the switcher.
  static const TextStyle childChipText = TextStyle(
    fontFamily: _font,
    fontSize: 0.8 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Their initials, in the switcher's small avatar.
  static const TextStyle chipAvatarText = TextStyle(
    fontFamily: _font,
    fontSize: 0.66 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A two-student switcher's pill.
  static const TextStyle switcherPillText = TextStyle(
    fontFamily: _font,
    fontSize: 0.83 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The one-student switcher, which is a label.
  static const TextStyle singleChildPillText = TextStyle(
    fontFamily: _font,
    fontSize: 0.72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The end-of-day reminder row.
  static const TextStyle reminderTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.79 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its explanation.
  static const TextStyle reminderSub = TextStyle(
    fontFamily: _font,
    fontSize: 0.69 * _px,
    fontWeight: FontWeight.w600,
  );

  /// An activity tile's caption: Nap, Meals, Photos.
  static const TextStyle activityLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.66 * _px,
    fontWeight: FontWeight.w700,
  );

  /// What a guardian owes.
  static const TextStyle balanceAmount = TextStyle(
    fontFamily: _font,
    fontSize: 1.85 * _px,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 1.85 * _px,
  );

  /// The line under it.
  static const TextStyle balanceSub = TextStyle(
    fontFamily: _font,
    fontSize: 0.74 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The due-date pill.
  static const TextStyle duePillText = TextStyle(
    fontFamily: _font,
    fontSize: 0.63 * _px,
    fontWeight: FontWeight.w700,
  );

  /// An invoice's name.
  static const TextStyle invoiceTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.8 * _px,
    fontWeight: FontWeight.w600,
  );

  /// When and how it was paid.
  static const TextStyle invoiceSub = TextStyle(
    fontFamily: _font,
    fontSize: 0.68 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its amount.
  static const TextStyle invoiceAmount = TextStyle(
    fontFamily: _font,
    fontSize: 0.83 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A newsletter's name.
  static const TextStyle newsletterTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.88 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Who is signed in, on the More page.
  static const TextStyle moreName = TextStyle(
    fontFamily: _font,
    fontSize: 1.05 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Their role and school.
  static const TextStyle moreRole = TextStyle(
    fontFamily: _font,
    fontSize: 0.73 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A More tile's label.
  static const TextStyle moreTileLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.88 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its badge.
  static const TextStyle moreBadgeText = TextStyle(
    fontFamily: _font,
    fontSize: 0.66 * _px,
    fontWeight: FontWeight.w800,
  );

  /// A More group: STUDENTS, STAFF, CENTER.
  static const TextStyle moreEyebrow = TextStyle(
    fontFamily: _font,
    fontSize: 0.66 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.14 * 0.66 * _px,
  );

  /// Who is signed in, on the Account page.
  static const TextStyle accountName = TextStyle(
    fontFamily: _font,
    fontSize: 1.0 * _px,
    fontWeight: FontWeight.w600,
  );

  /// An account row's title.
  static const TextStyle accountRowTitle = TextStyle(
    fontFamily: _font,
    fontSize: 0.9 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its second line.
  static const TextStyle accountRowSub = TextStyle(
    fontFamily: _font,
    fontSize: 0.71 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The Sign-In PIN on the account row.
  static const TextStyle accountPin = TextStyle(
    fontFamily: _font,
    fontSize: 0.85 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.1 * 0.85 * _px,
  );

  /// The roles-here pill beside Switch Profile.
  static const TextStyle rolesPillText = TextStyle(
    fontFamily: _font,
    fontSize: 0.62 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The help center's address.
  static const TextStyle helpLink = TextStyle(
    fontFamily: _font,
    fontSize: 0.68 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The Logout key.
  static const TextStyle logoutText = TextStyle(
    fontFamily: _font,
    fontSize: 0.9 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A confirmation sheet's explanation.
  static const TextStyle sheetBody = TextStyle(
    fontFamily: _font,
    fontSize: 0.81 * _px,
    fontWeight: FontWeight.w500,
  );

  /// SIGN OUT TIME, above the figure.
  static const TextStyle timeEyebrow = TextStyle(
    fontFamily: _font,
    fontSize: 0.64 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.12 * 0.64 * _px,
  );

  /// The time being confirmed.
  static const TextStyle timeValue = TextStyle(
    fontFamily: _font,
    fontSize: 1.55 * _px,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 1.55 * _px,
  );

  /// The audit note under it.
  static const TextStyle timeNote = TextStyle(
    fontFamily: _font,
    fontSize: 0.72 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// The Now pill on a read-only time.
  static const TextStyle nowPillText = TextStyle(
    fontFamily: _font,
    fontSize: 0.65 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A label on a confirmation sheet's fact row.
  static const TextStyle factLabel = TextStyle(
    fontFamily: _font,
    fontSize: 0.78 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its value.
  static const TextStyle factValue = TextStyle(
    fontFamily: _font,
    fontSize: 0.81 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Who is being signed out.
  static const TextStyle personName = TextStyle(
    fontFamily: _font,
    fontSize: 0.87 * _px,
    fontWeight: FontWeight.w600,
  );

  /// What signing out costs the classroom.
  static const TextStyle warningText = TextStyle(
    fontFamily: _font,
    fontSize: 0.77 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// A confirmation sheet's key.
  static const TextStyle confirmKeyText = TextStyle(
    fontFamily: _font,
    fontSize: 0.97 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The student on a guardian's sign-out sheet.
  static const TextStyle sheetChildName = TextStyle(
    fontFamily: _font,
    fontSize: 0.92 * _px,
    fontWeight: FontWeight.w600,
  );
}
