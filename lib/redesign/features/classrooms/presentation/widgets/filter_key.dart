import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';

/// The chip at the end of a tab's toolbar that opens the filter sheet (7c).
///
/// A chip rather than an icon key, because it sits in the chip row and reads
/// as one more switch on it. It goes navy when something is filtered, the way
/// every selected chip in the app does.
class FilterKey extends StatelessWidget {
  const FilterKey({required this.onTap, this.isActive = false, super.key});

  final VoidCallback onTap;

  /// Something is filtered, so the chip is on.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = isActive ? c.onImpact : c.ink;

    return Semantics(
      button: true,
      selected: isActive,
      label: ClassroomsStrings.filter,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isActive ? AppSurfaces.chipSelected(c) : AppSurfaces.chip(c),
          padding: AppSizes.chipPad,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: ClassroomsSizes.agePillGap,
            children: <Widget>[
              Icon(AppIcons.filter, size: AppSizes.chipRemoveGlyph, color: ink),
              Text(
                ClassroomsStrings.filter,
                style: AppTextStyles.chipLabel.copyWith(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
