import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// The header key that puts the roster into select mode, and takes it out
/// again (5a).
///
/// On, it goes navy: the roster is in a mode, and the key that put it there
/// is the way back out. It is not pink, because picking students is not the
/// screen's one action.
class SelectModeKey extends StatelessWidget {
  const SelectModeKey({required this.isOn, required this.onTap, super.key});

  final bool isOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final label = isOn ? StudentsStrings.doneKey : StudentsStrings.selectKey;

    return Semantics(
      button: true,
      selected: isOn,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isOn
              ? AppSurfaces.glyphTile(c, fill: c.impact, radius: AppRadii.inner)
              : AppSurfaces.keySecondary(c),
          padding: StudentsSizes.selectKeyPad,
          child: Text(
            label,
            style: StudentsTextStyles.filterChip.copyWith(
              color: isOn ? c.onImpact : c.ink2,
            ),
          ),
        ),
      ),
    );
  }
}
