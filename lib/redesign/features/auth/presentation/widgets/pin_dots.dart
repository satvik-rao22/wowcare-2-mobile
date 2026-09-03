import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';

/// The four dots above the kiosk pad. A digit fills its dot navy; an empty
/// slot keeps the kiosk's own deep-well rim.
class PinDots extends StatelessWidget {
  const PinDots({required this.filled, required this.length, super.key});

  /// How many digits have been entered.
  final int filled;

  /// How long the PIN is. Four, everywhere in this app.
  final int length;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      label: '$filled of $length',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: AuthSizes.pinDotGap,
        children: <Widget>[
          for (int i = 0; i < length; i++)
            AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.ease,
              width: AuthSizes.pinDot,
              height: AuthSizes.pinDot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? c.ink : null,
                border: Border.all(
                  color: i < filled ? c.ink : c.deepWell,
                  width: AuthSizes.pinDotBorder,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
