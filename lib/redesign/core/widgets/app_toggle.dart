import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/painters/inset_shadow_painter.dart';
import 'package:wowcare/redesign/core/theme/app_elevation.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A 46 by 27 switch. Components page `.toggle`: the track is a well, the
/// knob is raised, and on it turns the signed-in green.
///
/// The knob slides on `AppMotion.base`; the track's colour and its recess
/// cross-fade on `AppMotion.fast`.
class AppToggle extends StatelessWidget {
  const AppToggle({required this.value, required this.onChanged, super.key});

  final bool value;

  /// Null renders the toggle inert.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final track = value ? AppSurfaces.trackOn(c) : AppSurfaces.track(c);

    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.ease,
          width: AppSizes.toggleWidth,
          height: AppSizes.toggleHeight,
          decoration: track.decoration,
          child: Stack(
            children: <Widget>[
              // The well's recess, fading out as the track turns green.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: AppMotion.fast,
                    curve: AppMotion.ease,
                    opacity: value ? 0 : 1,
                    child: CustomPaint(
                      painter: InsetShadowPainter(
                        AppElevation.track(c),
                        AppRadii.pillR,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedAlign(
                duration: AppMotion.base,
                curve: AppMotion.ease,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.toggleInset,
                  ),
                  child: SurfaceBox(
                    surface: AppSurfaces.knob(c),
                    width: AppSizes.toggleKnob,
                    height: AppSizes.toggleKnob,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
