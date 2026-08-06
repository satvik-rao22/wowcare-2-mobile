import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';

/// Flashes a [HolidayCard] when it is the target of a holiday notification
/// deep link.
///
/// Every other module matches its deep-link target by entity code, but holiday
/// push payloads carry **no `holidayCode`** (see PUSH_CONTRACT_HOLIDAYS —
/// backend has only `holidayName`), so the name is the only identity available.
/// This widget therefore feeds the name into [HighlightableCard] in place of a
/// code, which matches trimmed and case-insensitively. Names are not guaranteed
/// unique, so two same-named holidays in one year would both flash — harmless,
/// and the only alternative is not highlighting at all.
///
/// Passing a null / non-matching [highlightName] renders [child] untouched.
class HolidayHighlight extends StatelessWidget {
  const HolidayHighlight({
    required this.holiday,
    required this.highlightName,
    required this.child,
    super.key,
  });

  final Holiday holiday;

  /// `highlightHoliday` query param from the notification deep link.
  final String? highlightName;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HighlightableCard(
      code: holiday.name,
      highlightCode: highlightName,
      // HolidayCard paints an opaque, full-bleed white background, which hides
      // a flash drawn behind it.
      foreground: true,
      // The target card can sit inside a collapsed-height section far down the
      // list, so let it scroll itself into view.
      scrollOnHighlight: true,
      child: child,
    );
  }
}
