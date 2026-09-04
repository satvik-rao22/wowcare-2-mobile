import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// The row of tabs across a student's record (5c).
///
/// The chosen tab is a raised key and the rest are wells: the one you are on
/// is the one that has come up to meet you. It scrolls past the gutters,
/// because five tabs do not fit a phone and shrinking them to fit would make
/// them unreadable.
class ProfileTabPills extends StatelessWidget {
  const ProfileTabPills({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenGutter),
    clipBehavior: Clip.none,
    child: Row(
      spacing: StudentsSizes.tabPillGap,
      children: <Widget>[
        for (final (i, label) in labels.indexed)
          _TabPill(
            label: label,
            isSelected: i == index,
            onTap: () => onChanged(i),
          ),
      ],
    ),
  );
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: isSelected
              ? AppSurfaces.keySecondary(c)
              : AppSurfaces.well(c),
          padding: StudentsSizes.tabPillPad,
          child: Text(
            label,
            style: StudentsTextStyles.tabPill.copyWith(
              color: isSelected ? c.ink : c.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
