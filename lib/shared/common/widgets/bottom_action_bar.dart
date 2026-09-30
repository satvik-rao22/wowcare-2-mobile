import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// The docked bar under a form or list that holds its primary action.
///
/// One place owns the card face, the rounded top corners, the breathing room
/// around the keys and the bottom system inset (with a floor on devices that
/// report none), so no screen pins a key to the edge of the display.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Radius radius = Radius.circular(
      ResponsiveHelper(context).isTablet ? 40 : 24,
    );
    return Container(
      decoration: AppSurfaces.card(
        borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: child,
        ),
      ),
    );
  }
}
