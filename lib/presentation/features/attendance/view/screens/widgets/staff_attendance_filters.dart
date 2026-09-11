import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'attendance_filter_button.dart';

class StaffAttendanceFilters extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime selectedDate;
  final bool showAbsentOnly;
  final bool hasActiveFilters;
  final Function(DateTime) onDateSelected;
  final Function(bool) onToggleChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClearAll;

  const StaffAttendanceFilters({
    super.key,
    required this.searchController,
    required this.selectedDate,
    required this.showAbsentOnly,
    required this.hasActiveFilters,
    required this.onDateSelected,
    required this.onToggleChanged,
    this.onFilterTap,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final spacing = responsive.horizontalSpacing / 2;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: responsive.isTablet ? 3 : 2,
              child: CustomSearchBar(
                controller: searchController,
                hintText: 'Search Staff',
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              flex: responsive.isTablet ? 2 : 1,
              child: CustomDateTimeField(
                hasLabel: false,
                isRangePicker: false,
                isTime: false,
                fetchInitialTime: false,
                initialDate: selectedDate,
                onDateSelected: onDateSelected,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.verticalSpacing / 2),
        // Filter button, clear-all chip, and "Show Absent" toggle on one row.
        Row(
          children: [
            AttendanceFilterButton(
              responsive: responsive,
              hasActiveFilters: hasActiveFilters,
              onFilterTap: onFilterTap,
            ),
            SizedBox(width: spacing),
            if (hasActiveFilters && onClearAll != null)
              Flexible(child: CustomClearAllChip(onTap: onClearAll)),
            const Spacer(),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: CustomToggle(
                  label: 'Show Absent',
                  isToggled: showAbsentOnly,
                  onToggle: onToggleChanged,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
