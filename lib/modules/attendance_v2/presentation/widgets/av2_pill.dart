import 'package:flutter/material.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';

/// A small rounded status/label pill with a fill + matching text colour.
/// Used for today-status, OT chips, and the absent badge.
class Av2Pill extends StatelessWidget {
  const Av2Pill({
    super.key,
    required this.text,
    required this.fill,
    required this.textColor,
  });

  final String text;
  final Color fill;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
      ),
      child: Text(
        text,
        style: Av2Text.caption.copyWith(color: textColor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
