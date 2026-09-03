import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// Which of a guardian's students the dashboard is showing (3P1).
///
/// The control changes shape with the family: one student is a label rather
/// than a switch, because there is nothing to switch to; two are a pair of
/// segments; three or more scroll as chips with faces on them.
class ChildSwitcher extends StatelessWidget {
  const ChildSwitcher({
    required this.children,
    required this.selectedId,
    required this.onSelect,
    super.key,
  });

  final List<ChildDay> children;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// Above this many students the switcher scrolls instead of splitting.
  static const int _segmentsUpTo = 2;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return _Single(child: children.first);
    if (children.length <= _segmentsUpTo) return _segments(context);
    return _chips(context);
  }

  Widget _segments(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.track(c, radius: AppRadii.innerR),
      padding: AppSizes.segmentedPad,
      child: Row(
        spacing: AppSizes.segmentGap,
        children: <Widget>[
          for (final child in children)
            Expanded(
              child: Semantics(
                button: true,
                selected: child.id == selectedId,
                label: child.firstName,
                child: Pressable.surface(
                  onTap: () => onSelect(child.id),
                  child: SurfaceBox(
                    surface: child.id == selectedId
                        ? AppSurfaces.segmentSelected(c)
                        : AppSurfaces.track(c, radius: AppRadii.innerR),
                    padding: DashboardSizes.switcherPillPad,
                    alignment: Alignment.center,
                    child: Text(
                      DashboardStrings.childAndRoom(
                        child.firstName,
                        child.classroomName,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DashboardTextStyles.switcherPillText.copyWith(
                        color: child.id == selectedId ? c.ink : c.ink3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chips(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: Row(
      spacing: DashboardSizes.childChipRowGap,
      children: <Widget>[
        for (final child in children)
          _Chip(
            child: child,
            selected: child.id == selectedId,
            onTap: () => onSelect(child.id),
          ),
      ],
    ),
  );
}

/// A family of one. A label, not a control.
class _Single extends StatelessWidget {
  const _Single({required this.child});

  final ChildDay child;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: DashboardSizes.singleChildPillPad,
        decoration: BoxDecoration(
          color: c.studentBg,
          borderRadius: AppRadii.pillR,
        ),
        child: Text(
          DashboardStrings.childAndRoom(
            child.firstName,
            child.classroomName,
          ),
          style: DashboardTextStyles.singleChildPillText.copyWith(
            color: c.student,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  final ChildDay child;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      selected: selected,
      label: child.firstName,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: selected
              ? AppSurfaces.radioCard(c, selected: true)
              : AppSurfaces.chip(c),
          padding: DashboardSizes.childChipPad,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: DashboardSizes.childChipGap,
            children: <Widget>[
              AppAvatar(
                initials: child.initials,
                size: DashboardSizes.chipAvatar,
                attendance: child.attendance,
                ringColor: selected ? c.studentBg : c.card,
                textStyle: DashboardTextStyles.chipAvatarText,
              ),
              Text(
                child.firstName,
                style: DashboardTextStyles.childChipText.copyWith(
                  color: selected ? c.ink : c.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
