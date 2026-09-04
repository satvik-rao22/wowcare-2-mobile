import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// A pill that says what the roster is narrowed to (5a) or offers a value to
/// narrow it by (5b).
///
/// Picked, it takes the student tint, because everything this module filters
/// is a student. [onRemove] adds the small cross an applied filter carries.
class StudentsFilterChip extends StatelessWidget {
  const StudentsFilterChip({
    required this.label,
    this.selected = false,
    this.onTap,
    this.onRemove,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = selected ? c.student : c.ink2;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: selected
              ? AppSurfaces.pill(fill: c.studentBg, line: c.studentRim)
              : AppSurfaces.pill(fill: c.card, line: c.keyBorder),
          padding: StudentsSizes.filterChipPad,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSizes.chipInnerGap,
            children: <Widget>[
              Text(
                label,
                style: StudentsTextStyles.filterChip.copyWith(color: ink),
              ),
              if (onRemove != null)
                Pressable.surface(
                  onTap: onRemove,
                  child: Icon(
                    AppIcons.close,
                    size: AppSizes.chipRemoveGlyph,
                    color: ink,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
