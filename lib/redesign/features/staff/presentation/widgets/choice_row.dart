import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// A row of pick-one keys, each as wide as the next: 6b's Status and Order
/// groups, and 6d's Status, Role and "Same shift every day".
///
/// The picked key takes the staff tint, which is the one place in this module
/// colour is doing anything but saying "staff". It is not a segmented control:
/// there is no track to slide inside, and the frames draw separate keys.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    spacing: StaffSizes.filterOptionGap,
    children: <Widget>[
      for (var index = 0; index < labels.length; index++)
        Expanded(
          child: _Choice(
            label: labels[index],
            isSelected: index == selectedIndex,
            onTap: () => onSelect(index),
          ),
        ),
    ],
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
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
              ? AppSurfaces.tile(c, fill: c.staffBg, line: c.staffLine)
              : AppSurfaces.keySecondary(c),
          padding: StaffSizes.choiceOptionPad,
          alignment: Alignment.center,
          child: Text(
            label,
            style: StaffTextStyles.choiceKey.copyWith(
              color: isSelected ? c.staffFg : c.ink2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
