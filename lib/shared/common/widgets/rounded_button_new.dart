import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// A pill-shaped primary key with an external [isLoading]/[enabled] state —
/// distinct from [RoundedButton] (rectangular, caller-coloured) and
/// [CustomButtonLayout] (rounded-rect, internally-managed loading state via
/// its async [onPressed]). Used where the pill shape and externally-driven
/// loading state (e.g. from a Cubit's `AuthLoading`) are both required, such
/// as the sign-in screen.
///
/// It used to take a `gradient`. There are none now: it paints the
/// recommended-action key, rim included.
class RoundedButtonNew extends StatelessWidget {
  const RoundedButtonNew({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    required this.lableColor,
    this.enabled = true,
    super.key,
  });

  final String label;
  final bool isLoading;
  final bool enabled;
  final VoidCallback onPressed;
  final Color lableColor;

  @override
  Widget build(BuildContext context) {
    final isInteractive = enabled && !isLoading;
    return GestureDetector(
      onTap: isInteractive ? onPressed : null,
      child: SkeuKeyBox(
        // The design's dead key: recessed and rimless, so it reads flat and
        // inert rather than as a live key behind a veil of opacity.
        variant: isInteractive ? KeyVariant.primary : KeyVariant.disabled,
        enabled: isInteractive,
        radius: 25,
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        child: isLoading
            ? const CircularProgressIndicator(color: AppPalette.onBrand)
            : Text(
                label,
                style: TextStyle(
                  color: isInteractive
                      ? lableColor
                      : AppSurfaces.keyInk(KeyVariant.disabled),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
