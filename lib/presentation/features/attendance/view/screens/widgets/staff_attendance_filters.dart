import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

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
        LayoutBuilder(
          builder: (context, constraints) {
            // For smaller screens, stack vertically if needed
            if (constraints.maxWidth < 400) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterButton(context, responsive),
                      SizedBox(width: spacing),
                      if (hasActiveFilters && onClearAll != null)
                        Flexible(
                          child: CustomClearAllChip(
                            onTap: onClearAll,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  CustomToggle(
                    label: 'Show Absent',
                    isToggled: showAbsentOnly,
                    onToggle: onToggleChanged,
                  ),
                ],
              );
            }
            
            // For larger screens, use horizontal layout
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterButton(context, responsive),
                      SizedBox(width: spacing),
                      if (hasActiveFilters && onClearAll != null)
                        Flexible(
                          child: CustomClearAllChip(
                            onTap: onClearAll,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: spacing),
                Flexible(
                  child: CustomToggle(
                    label: 'Show Absent',
                    isToggled: showAbsentOnly,
                    onToggle: onToggleChanged,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterButton(BuildContext context, ResponsiveHelper responsive) {
    return Container(
      height: responsive.inputFieldHeight * 0.83,
      constraints: BoxConstraints(
        minWidth: responsive.inputFieldHeight * 0.83,
        maxWidth: responsive.inputFieldHeight * 0.83,
      ),
      decoration: BoxDecoration(
        color: hasActiveFilters
            ? AppColors.themeColor.withOpacity(0.15)
            : AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasActiveFilters
              ? AppColors.themeColor
              : AppColors.cardBorderColor,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onFilterTap,
          child: Padding(
            padding: EdgeInsets.all(responsive.isTablet ? 10 : 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  MediaRes.filterIcon,
                  width: responsive.isTablet ? 26 : 24,
                  height: responsive.isTablet ? 26 : 24,
                  colorFilter: ColorFilter.mode(
                    hasActiveFilters
                        ? AppColors.themeColor
                        : AppColors.secondaryColor.withOpacity(0.6),
                    BlendMode.srcIn,
                  ),
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.themeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
