import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The "Clear All" filter action.
///
/// A small rimmed pink key: clearing the filters is the recommended action
/// while any are applied, and the 2px rim keeps it pressable-looking beside the
/// read-only status chip it sits next to.
class CustomClearAllChip extends StatelessWidget {
  const CustomClearAllChip({
    required this.onTap,
    this.label = 'Clear All',
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    super.key,
  });

  final void Function()? onTap;
  final String label;
  final double? fontSize;
  final FontWeight? fontWeight;

  /// Retained for call-site compatibility — the key is always a pill.
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: SkeuSurfaces.facePink,
          borderRadius: BorderRadius.circular(SkeuRadius.pill),
          boxShadow: const [
            BoxShadow(color: SkeuElevation.rimPink, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          softWrap: true,
          style: TextStyle(
            fontFamily: SkeuText.family,
            color: SkeuColors.white,
            fontSize: fontSize ?? 12,
            fontWeight: fontWeight ?? SkeuText.weightBold,
          ),
        ),
      ),
    );
  }
}
