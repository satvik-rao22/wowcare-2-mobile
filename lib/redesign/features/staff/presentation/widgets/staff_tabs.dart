import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/cubit/staff_profile_cubit.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6c's tab strip: five raised keys on a well ground, scrolling past the
/// gutter because five of them do not fit a phone.
///
/// Not a `SegmentedControl`, which has one track and a sliding segment: the
/// frame draws separate keys that can run off the edge, and a control that
/// slides cannot.
class StaffTabs extends StatelessWidget {
  const StaffTabs({
    required this.tabs,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<StaffProfileTab> tabs;
  final StaffProfileTab selected;
  final ValueChanged<StaffProfileTab> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: StaffSizes.tabStripPad,
    child: Row(
      spacing: StaffSizes.tabGap,
      children: <Widget>[
        for (final tab in tabs)
          _Tab(
            label: label(tab),
            isSelected: tab == selected,
            onTap: () => onChanged(tab),
          ),
      ],
    ),
  );

  static String label(StaffProfileTab tab) => switch (tab) {
    StaffProfileTab.profile => StaffStrings.tabProfile,
    StaffProfileTab.schedule => StaffStrings.tabSchedule,
    StaffProfileTab.attendance => AppStrings.attendance,
    StaffProfileTab.dates => StaffStrings.tabDates,
    StaffProfileTab.documents => StaffStrings.tabDocuments,
  };
}

class _Tab extends StatelessWidget {
  const _Tab({
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
          surface: isSelected ? AppSurfaces.cardRaised(c) : AppSurfaces.well(c),
          padding: StaffSizes.tabPad,
          child: Text(
            label,
            style: StaffTextStyles.tabLabel.copyWith(
              color: isSelected ? c.ink : c.ink3,
            ),
          ),
        ),
      ),
    );
  }
}
