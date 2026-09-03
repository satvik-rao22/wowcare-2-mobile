import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';

/// The 22px checkbox from 5a's select mode: a 2px border that fills pink
/// with a warm-white tick when checked.
///
/// It is only the mark. `CheckRow` puts it in a row; a roster row in select
/// mode puts it before the avatar.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({required this.checked, super.key});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.ease,
      width: AppSizes.checkbox,
      height: AppSizes.checkbox,
      decoration: BoxDecoration(
        color: checked ? c.pink : null,
        borderRadius: AppRadii.checkR,
        border: Border.all(
          color: checked ? c.pink : c.ink3,
          width: AppSizes.checkboxBorder,
        ),
      ),
      child: checked
          ? Icon(AppIcons.check, size: AppSizes.checkGlyph, color: c.onPink)
          : null,
    );
  }
}
