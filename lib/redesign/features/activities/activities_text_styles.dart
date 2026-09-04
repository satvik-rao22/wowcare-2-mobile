import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Type sizes the M08 frames draw that are not on the core ladder. Sizes are
/// the frame's rem value times 16, like `AppTextStyles`. No colour here.
abstract final class ActivitiesTextStyles {
  static const double _px = 16;
  static const String _font = AppTextStyles.fontFamily;

  /// The date on the day rail: `.86rem 700`.
  static const TextStyle railDate = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The line under it: `.66rem 600`.
  static const TextStyle railScope = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The Day / Range key and the In now label: `.71rem 700`.
  static const TextStyle railKey = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The classroom inside the rail's well, and a range field: `.76rem 600`.
  static const TextStyle railWell = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The initial in the classroom tile: `.55rem 800`.
  static const TextStyle railTile = TextStyle(
    fontFamily: _font,
    fontSize: .55 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The pending banner's sentence, and any bold small line: `.78rem 700`.
  static const TextStyle bannerLine = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The count bubble on the banner: `.72rem 800`.
  static const TextStyle bannerCount = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w800,
  );

  /// The time on the rail: `.74rem 700`, with `.6rem 600` under it.
  static const TextStyle railTime = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle railMeridiem = TextStyle(
    fontFamily: _font,
    fontSize: .6 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A card's own title: `.92rem 600`.
  static const TextStyle cardName = TextStyle(
    fontFamily: _font,
    fontSize: .92 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The line under it: `.71rem 600`.
  static const TextStyle cardDetail = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A card's body paragraph: `.79rem 500`, line-height 1.5.
  static const TextStyle cardBody = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// A spec chip's key: `.65rem 700`, and its value `.74rem 700`.
  static const TextStyle specKey = TextStyle(
    fontFamily: _font,
    fontSize: .65 * _px,
    fontWeight: FontWeight.w700,
    letterSpacing: .02 * .65 * _px,
  );

  static const TextStyle specValue = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The additional-notes eyebrow: `.63rem 800`, tracked.
  static const TextStyle noteEyebrow = TextStyle(
    fontFamily: _font,
    fontSize: .63 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .11 * .63 * _px,
  );

  /// Its body: `.76rem 500`, line-height 1.5.
  static const TextStyle noteBody = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// A tag pill on a card, and a card's small badge: `.65rem 700`.
  static const TextStyle tagLabel = TextStyle(
    fontFamily: _font,
    fontSize: .65 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials in a 25px stacked avatar: `.58rem 700`.
  static const TextStyle kidInitials = TextStyle(
    fontFamily: _font,
    fontSize: .58 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials in a 28px or 30px summary avatar: `.62rem 700`.
  static const TextStyle summaryInitials = TextStyle(
    fontFamily: _font,
    fontSize: .62 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The initials in a 32px or 38px avatar: `.72rem 700`.
  static const TextStyle personInitials = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Who a card is for, at its foot: `.71rem 600`.
  static const TextStyle cardWho = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Who logged it, on the far right: `.68rem 600`.
  static const TextStyle cardBy = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A footnote or a recessed hint: `.71rem 600`, line-height 1.5.
  static const TextStyle footnote = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// A field's help line under it: `.67rem 600`, line-height 1.45.
  static const TextStyle helpLine = TextStyle(
    fontFamily: _font,
    fontSize: .67 * _px,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  /// The load-more key: `.78rem 700` over `.67rem 600`.
  static const TextStyle loadMoreTitle = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle loadMoreSub = TextStyle(
    fontFamily: _font,
    fontSize: .67 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A range day header: `.72rem 700` with `.68rem 600` beside it.
  static const TextStyle dayHeader = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle dayHeaderMeta = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A wizard's step line: `.68rem 700`, tracked and upper-cased.
  static const TextStyle stepLine = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w700,
    letterSpacing: .06 * .68 * _px,
  );

  /// A section eyebrow on a form: `.65rem 800`, tracked.
  static const TextStyle sectionRule = TextStyle(
    fontFamily: _font,
    fontSize: .65 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .12 * .65 * _px,
  );

  /// The summary line above a type grid or a form: `.8rem 600`.
  static const TextStyle summaryLine = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A small pink key beside it (Change, Select all): `.73rem 700`.
  static const TextStyle inlineKey = TextStyle(
    fontFamily: _font,
    fontSize: .73 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A type tile's label: `.86rem 600`.
  static const TextStyle tileLabel = TextStyle(
    fontFamily: _font,
    fontSize: .86 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The navy tip under the grid: `.76rem 600`, line-height 1.5.
  static const TextStyle tip = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// A form field's label: `.72rem 700`.
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: _font,
    fontSize: .72 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A field's value: `.84rem 600`.
  static const TextStyle fieldValue = TextStyle(
    fontFamily: _font,
    fontSize: .84 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A description box's text: `.82rem 500`, line-height 1.5.
  static const TextStyle fieldParagraph = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// The character counter: `.65rem 700`.
  static const TextStyle counter = TextStyle(
    fontFamily: _font,
    fontSize: .65 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A toggle card's title: `.82rem 700`.
  static const TextStyle toggleTitle = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A person row's name on a form: `.82rem 600` over `.67rem 600`.
  static const TextStyle personName = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle personSub = TextStyle(
    fontFamily: _font,
    fontSize: .67 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The small key on a person row: `.7rem 700`.
  static const TextStyle personKey = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The bottle stepper's reading: `1.15rem 700` with `.76rem 700` after it.
  static const TextStyle stepperValue = TextStyle(
    fontFamily: _font,
    fontSize: 1.15 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle stepperUnit = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A roster row's name on 8f: `.92rem 600`.
  static const TextStyle pickName = TextStyle(
    fontFamily: _font,
    fontSize: .92 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its sub-line: `.71rem 600`.
  static const TextStyle pickSub = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The In now block's title inside the picker: `.79rem 700`.
  static const TextStyle pickInNow = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A tag pill on a roster row: `.64rem 700`.
  static const TextStyle pickTag = TextStyle(
    fontFamily: _font,
    fontSize: .64 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The time on a detail's head card: `.98rem 600` over `.73rem 600`.
  static const TextStyle detailTime = TextStyle(
    fontFamily: _font,
    fontSize: .98 * _px,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle detailBy = TextStyle(
    fontFamily: _font,
    fontSize: .73 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A read-only field's value on 8d: `.85rem 600`, line-height 1.5.
  static const TextStyle detailValue = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  /// The acknowledgement block's eyebrow: `.66rem 800`, tracked.
  static const TextStyle ackEyebrow = TextStyle(
    fontFamily: _font,
    fontSize: .66 * _px,
    fontWeight: FontWeight.w800,
    letterSpacing: .13 * .66 * _px,
  );

  /// Its body, and the guardian's acknowledge key: `.79rem 600`, height 1.5.
  static const TextStyle ackBody = TextStyle(
    fontFamily: _font,
    fontSize: .79 * _px,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  static const TextStyle ackKey = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The queue's headline on 8e: `1.15rem 700`.
  static const TextStyle queueTitle = TextStyle(
    fontFamily: _font,
    fontSize: 1.15 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A queue row's name: `.95rem 600`.
  static const TextStyle queueName = TextStyle(
    fontFamily: _font,
    fontSize: .95 * _px,
    fontWeight: FontWeight.w600,
  );

  /// Its body: `.8rem 500`, line-height 1.5.
  static const TextStyle queueBody = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// A moderation key: `.82rem 700` in the queue, `.88rem 700` docked.
  static const TextStyle queueKey = TextStyle(
    fontFamily: _font,
    fontSize: .82 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle moderationKey = TextStyle(
    fontFamily: _font,
    fontSize: .88 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The navy gate card's headline on 8s: `.98rem 700`.
  static const TextStyle gateTitle = TextStyle(
    fontFamily: _font,
    fontSize: .98 * _px,
    fontWeight: FontWeight.w700,
  );

  /// Its shift line: `.71rem 600`, and the PIN line `.68rem 600`.
  static const TextStyle gateSub = TextStyle(
    fontFamily: _font,
    fontSize: .71 * _px,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle gatePin = TextStyle(
    fontFamily: _font,
    fontSize: .68 * _px,
    fontWeight: FontWeight.w600,
  );

  /// A key inside the navy card: `.8rem 700` and `.85rem 700`.
  static const TextStyle gateKeyQuiet = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle gateKeyLoud = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w700,
  );

  /// An edge state's title and body: `1.12rem 600` over `.85rem 500`.
  static const TextStyle edgeTitle = TextStyle(
    fontFamily: _font,
    fontSize: 1.12 * _px,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle edgeBody = TextStyle(
    fontFamily: _font,
    fontSize: .85 * _px,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  /// A filter option's label in the sheet: `.78rem 600`.
  static const TextStyle filterOption = TextStyle(
    fontFamily: _font,
    fontSize: .78 * _px,
    fontWeight: FontWeight.w600,
  );

  /// The uploader's tab and its section title: `.8rem 700` / `.74rem 700`.
  static const TextStyle uploaderTab = TextStyle(
    fontFamily: _font,
    fontSize: .8 * _px,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle uploaderSection = TextStyle(
    fontFamily: _font,
    fontSize: .74 * _px,
    fontWeight: FontWeight.w700,
  );

  /// A thumbnail's state strip: `.58rem 700`.
  static const TextStyle uploaderState = TextStyle(
    fontFamily: _font,
    fontSize: .58 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The progress reading under the bar: `.7rem 700`.
  static const TextStyle uploaderProgress = TextStyle(
    fontFamily: _font,
    fontSize: .7 * _px,
    fontWeight: FontWeight.w700,
  );

  /// The uploader's own footnote and hint: `.69rem 600` / `.76rem 600`.
  static const TextStyle uploaderHint = TextStyle(
    fontFamily: _font,
    fontSize: .69 * _px,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle uploaderEmpty = TextStyle(
    fontFamily: _font,
    fontSize: .76 * _px,
    fontWeight: FontWeight.w600,
  );
}
