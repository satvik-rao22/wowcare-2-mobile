import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_spacing.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';

import '../controllers/reg_inbox_filter.dart';

/// Segmented filter for the admin list: Pending / Approved / All.
///
/// Visually identical to `Av2FilterChips`, but not a reuse of it: that widget
/// is typed to `Av2DayFilter.values`. Generifying it would create a shared
/// widget with two callers and a type parameter for the sake of ~40 lines —
/// coupling the two modules more tightly than the duplication costs.
class RegFilterChips extends StatelessWidget {
  const RegFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final RegInboxFilter selected;
  final ValueChanged<RegInboxFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in RegInboxFilter.values) ...[
            _chip(f),
            if (f != RegInboxFilter.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _chip(RegInboxFilter f) {
    final isSel = f == selected;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
      child: InkWell(
        onTap: () => onSelected(f),
        borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? Av2Colors.primaryFill : Av2Colors.surface,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
            border: Border.all(
              color: isSel ? Colors.transparent : Av2Colors.borderStrong,
            ),
          ),
          child: Text(
            f.label,
            style: Av2Text.chip.copyWith(
              color: isSel ? Av2Colors.onPrimary : Av2Colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
