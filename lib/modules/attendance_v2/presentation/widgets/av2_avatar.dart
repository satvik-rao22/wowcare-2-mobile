import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_text_styles.dart';

/// Circular initials avatar. Sizes via [diameter] so it works in the header
/// (48) and the desktop roster rail (30).
class Av2Avatar extends StatelessWidget {
  const Av2Avatar({super.key, required this.initials, this.diameter = 48});

  final String initials;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Av2Colors.avatarBg,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: Av2Text.bodyMedium.copyWith(
          color: Av2Colors.avatarText,
          fontSize: diameter * 0.36,
        ),
      ),
    );
  }
}
