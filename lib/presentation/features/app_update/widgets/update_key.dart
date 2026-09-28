import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_haptics.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// A key on the update banners: the pink store key, or the quiet Not now.
/// Same press as every other key in the app ([SkeuKeyBox]).
class UpdateKey extends StatelessWidget {
  const UpdateKey({
    required this.label,
    required this.onTap,
    this.variant = KeyVariant.primary,
    this.radius = AppRadius.lg,
    this.padding = const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
    this.style = AppTextStyles.appUpdateKey,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final KeyVariant variant;
  final double radius;
  final EdgeInsetsGeometry padding;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // The design sets Not now in secondary ink, a step quieter than the
    // navy a secondary key normally carries.
    final Color ink = variant == KeyVariant.secondary
        ? AppPalette.textSecondary
        : AppSurfaces.keyInk(variant);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: SkeuKeyBox(
          variant: variant,
          radius: radius,
          padding: padding,
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: style.copyWith(color: ink),
          ),
        ),
      ),
    );
  }
}
