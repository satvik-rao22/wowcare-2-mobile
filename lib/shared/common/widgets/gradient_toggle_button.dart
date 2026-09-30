import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// The compact switch used across the app.
///
/// The design's `.toggle`: the track is a well the knob slides along, and it
/// fills green when on. Named for the gradient it used to paint; there is no
/// gradient in it any more.
class GradientToggleButton extends StatelessWidget {
  const GradientToggleButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 44,
    this.height = 22,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final knobSize = height - 6;

    return IgnorePointer(
      ignoring: disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.easeOut,
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: value && !disabled
              ? SkeuDecoration(
                  color: AppPalette.statusSuccess,
                  borderRadius: AppRadius.allPill,
                )
              : AppSurfaces.trough(),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Opacity(
            opacity: disabled ? 0.5 : 1,
            child: Container(
              width: knobSize,
              height: knobSize,
              decoration: AppSurfaces.knob(),
            ),
          ),
        ),
      ),
    );
  }
}
