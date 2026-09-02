import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../controllers/av2_day_filter.dart';

/// Horizontally scrollable segmented filter. Selected chip is filled with the
/// primary text colour; others are outlined.
class Av2FilterChips extends StatelessWidget {
  const Av2FilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Av2DayFilter selected;
  final ValueChanged<Av2DayFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in Av2DayFilter.values) ...[
            _chip(f),
            if (f != Av2DayFilter.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _chip(Av2DayFilter f) {
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
            gradient: isSel ? Av2Colors.primaryGradient : null,
            color: isSel ? null : Av2Colors.surface,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
            border: Border.all(
              color: isSel ? Colors.transparent : Av2Colors.borderStrong,
            ),
          ),
          child: Text(
            f.label,
            style: Av2Text.chip.copyWith(
              color: isSel ? Colors.white : Av2Colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
