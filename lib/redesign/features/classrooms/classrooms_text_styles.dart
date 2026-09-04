import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Type the M07 frames draw that is not on the core ladder.
///
/// Sizes are the frame's own rem value times 16, exactly as `AppTextStyles`
/// writes them, and letter spacing is the em value times the size, so the
/// number in a frame is the number here. No colour: colour is a `Colourway`
/// decision the call site makes out loud.
abstract final class ClassroomsTextStyles {
  static const double _px = 16;
  static const String _font = AppTextStyles.fontFamily;

  // --- 7a --------------------------------------------------------------------

  /// "47 students in" on the navy card.
  static const TextStyle impactHeadline = TextStyle(
    fontFamily: _font,
    fontSize: 1.35 * _px,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  /// "12 staff on duty across 5 classrooms".
  static const TextStyle impactSub = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );

  /// "78 enrolled of 96 places · 81% full", under the trough.
  static const TextStyle impactFoot = TextStyle(
    fontFamily: _font,
    fontSize: .69 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A classroom card's name.
  static const TextStyle classroomName = TextStyle(
    fontFamily: _font,
    fontSize: 1 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The initial in a classroom's round tile.
  static const TextStyle classroomInitial = TextStyle(
    fontFamily: _font,
    fontSize: 1.02 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The age band pill, and any small tag beside it.
  static const TextStyle smallPill = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w700,
  );

  /// "23 of 26 places", beside the age pill.
  static const TextStyle capacityLine = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The ratio pill on a classroom card.
  static const TextStyle ratioPill = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The lead line, the present count and the staff count under a card.
  static const TextStyle footLine = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle footCount = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials in a lead's small bubble.
  static const TextStyle leadInitials = TextStyle(
    fontFamily: _font,
    fontSize: .62 * _px,
    fontWeight: FontWeight.w700,
  );

  /// "Needs 1 more staff member".
  static const TextStyle alertLine = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The dashed panel's title and body.
  static const TextStyle panelTitle = TextStyle(
    fontFamily: _font,
    fontSize: .9 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle panelBody = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The extended FAB's label.
  static const TextStyle extendedFab = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 7b · 7j · the big states ---------------------------------------------

  static const TextStyle stateTitleLarge = TextStyle(
    fontFamily: _font,
    fontSize: 1.15 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle stateTitle = TextStyle(
    fontFamily: _font,
    fontSize: 1.05 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle stateBody = TextStyle(
    fontFamily: _font,
    fontSize: .84 * _px,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );
  static const TextStyle stateHint = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle stateKey = TextStyle(
    fontFamily: _font,
    fontSize: .92 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 7c --------------------------------------------------------------------

  /// The Select key in the header bar, the Edit classroom key on 7f.
  static const TextStyle headerKey = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initial in the 52px header bubble.
  static const TextStyle headInitial = TextStyle(
    fontFamily: _font,
    fontSize: 1.15 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headLeadInitials = TextStyle(
    fontFamily: _font,
    fontSize: .58 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle headLead = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w600,
  );

  /// "Classroom profile ›" on the header card.
  static const TextStyle headLink = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A counting tile on the header card.
  static const TextStyle countValue = TextStyle(
    fontFamily: _font,
    fontSize: .98 * _px,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  static const TextStyle countLabel = TextStyle(
    fontFamily: _font,
    fontSize: .63 * _px,
    fontWeight: FontWeight.w700,
  );

  /// "Showing all 23" over the roster.
  static const TextStyle showingLine = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A roster row's trailing flag, and a staff row's duty pill.
  static const TextStyle flagPill = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials inside a roster avatar.
  static const TextStyle rosterInitials = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w700,
  );

  /// An expanded row's left-hand label, and its right-hand value.
  static const TextStyle factLabel = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle factValue = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A care-need tag, and a weekday square.
  static const TextStyle tag = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The hours line under the weekday squares.
  static const TextStyle hours = TextStyle(
    fontFamily: _font,
    fontSize: .69 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The two keys at the foot of an expanded row.
  static const TextStyle rowActionKey = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A dashed inline panel's title and line.
  static const TextStyle inlineEmptyTitle = TextStyle(
    fontFamily: _font,
    fontSize: .88 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The sun-tinted ratio note over the Staff tab.
  static const TextStyle notice = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w700,
    height: 1.45,
  );

  /// A staff row's designation, and the quiet lines under it.
  static const TextStyle staffRole = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle staffMeta = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w600,
  );

  // --- 7c · Notes ------------------------------------------------------------

  static const TextStyle dayPill = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle noteAuthor = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle noteTime = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle noteText = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle noteInitials = TextStyle(
    fontFamily: _font,
    fontSize: .6 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle newRule = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .1 * .66 * _px,
  );
  static const TextStyle composer = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w500,
  );

  // --- 7c · select mode ------------------------------------------------------

  static const TextStyle selectKey = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle bulkKey = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 7d --------------------------------------------------------------------

  /// The two-up Active / Upcoming keys in the filter sheet.
  static const TextStyle statusKey = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 7e --------------------------------------------------------------------

  static const TextStyle clockTitle = TextStyle(
    fontFamily: _font,
    fontSize: 1 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle clockSub = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle clockKey = TextStyle(
    fontFamily: _font,
    fontSize: .95 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle clockWhy = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle clockInitials = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// An alert's headline, and the line under it.
  static const TextStyle alertTitle = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle alertBody = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// The small classroom card a teacher taps to reach the profile.
  static const TextStyle miniTitle = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle miniSub = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle miniInitial = TextStyle(
    fontFamily: _font,
    fontSize: .95 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 7f --------------------------------------------------------------------

  static const TextStyle profileInitial = TextStyle(
    fontFamily: _font,
    fontSize: 1.4 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle uploadTitle = TextStyle(
    fontFamily: _font,
    fontSize: .83 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle uploadHint = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle uploadFile = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle uploadPercent = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle uploadAction = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle retryKey = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w700,
  );

  /// "23" over "of 26" on the Places card.
  static const TextStyle placesNumber = TextStyle(
    fontFamily: _font,
    fontSize: 1.5 * _px,
    fontWeight: FontWeight.w700,
    height: 1.05,
  );
  static const TextStyle placesOf = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle placesPill = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A stat tile in the profile's grids, and the meta beside a card eyebrow.
  static const TextStyle statValue = TextStyle(
    fontFamily: _font,
    fontSize: 1.1 * _px,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );
  static const TextStyle statLabel = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle cardMeta = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle movementTitle = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle movementSub = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The centre table's column headings, its rows and its pills.
  static const TextStyle tableHeading = TextStyle(
    fontFamily: _font,
    fontSize: .64 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .08 * .64 * _px,
  );
  static const TextStyle tableName = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle tableValue = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle tablePill = TextStyle(
    fontFamily: _font,
    fontSize: .65 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 7g · 7h ---------------------------------------------------------------

  static const TextStyle railNumber = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle railLabel = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle candidateName = TextStyle(
    fontFamily: _font,
    fontSize: .92 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle candidateSub = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A "What this changes" row: the label, then the value it becomes.
  static const TextStyle changeLabel = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle changeValue = TextStyle(
    fontFamily: _font,
    fontSize: .84 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle infoWell = TextStyle(
    fontFamily: _font,
    fontSize: .73 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle footerBackKey = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 7i --------------------------------------------------------------------

  static const TextStyle refusalInitials = TextStyle(
    fontFamily: _font,
    fontSize: .84 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle refusalStatus = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle optionTitle = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle optionSub = TextStyle(
    fontFamily: _font,
    fontSize: .69 * _px,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle sheetBody = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w500,
    height: 1.55,
  );
  static const TextStyle costLine = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  static const TextStyle sheetKey = TextStyle(
    fontFamily: _font,
    fontSize: .9 * _px,
    fontWeight: FontWeight.w700,
  );

  // --- 7j --------------------------------------------------------------------

  static const TextStyle offlineWell = TextStyle(
    fontFamily: _font,
    fontSize: .75 * _px,
    fontWeight: FontWeight.w700,
    height: 1.45,
  );
  static const TextStyle deadKey = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle tryAgainKey = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w700,
  );
}
