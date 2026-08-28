import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/dimensions.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentAttendanceFilters extends StatelessWidget {
  final TextEditingController searchController;
  final DateTime selectedDate;
  final bool showAbsentOnly;
  final bool hasActiveFilters;
  final List<String> selectedClassrooms;
  final List<String> selectedTags;
  final List<String> availableClassrooms;
  final List<String> availableTags;
  final Function(DateTime) onDateSelected;
  final Function(bool) onToggleChanged;
  final Function(List<String>)? onClassroomsChanged;
  final Function(List<String>)? onTagsChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClearAll;

  const StudentAttendanceFilters({
    super.key,
    required this.searchController,
    required this.selectedDate,
    required this.showAbsentOnly,
    required this.hasActiveFilters,
    this.selectedClassrooms = const [],
    this.selectedTags = const [],
    this.availableClassrooms = const [],
    this.availableTags = const [],
    required this.onDateSelected,
    required this.onToggleChanged,
    this.onClassroomsChanged,
    this.onTagsChanged,
    this.onFilterTap,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTablet;
    final spacing = responsive.horizontalSpacing / 2;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: isTablet ? 3 : 2,
              child: CustomSearchBar(
                controller: searchController,
                hintText: 'Search Students',
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              flex: isTablet ? 2 : 1,
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
        if (availableClassrooms.isNotEmpty || availableTags.isNotEmpty) ...[
          SizedBox(height: responsive.verticalSpacing / 2),
          Row(
            children: [
              if (availableClassrooms.isNotEmpty)
                Expanded(
                  child: CustomMultiSelectDropdown(
                    hintText: 'Classroom',
                    items: availableClassrooms,
                    selectedItems: selectedClassrooms,
                    onChanged: onClassroomsChanged ?? (items) {},
                  ),
                ),
              if (availableClassrooms.isNotEmpty && availableTags.isNotEmpty)
                SizedBox(width: spacing),
              if (availableTags.isNotEmpty)
                Expanded(
                  child: CustomMultiSelectDropdown(
                    hintText: 'Tags',
                    items: availableTags,
                    selectedItems: selectedTags,
                    onChanged: onTagsChanged ?? (items) {},
                  ),
                ),
            ],
          ),
        ],
        SizedBox(height: responsive.verticalSpacing / 2),
        // Filter button, clear-all chip, and "Show Absent" toggle on one row.
        Row(
          children: [
            _buildFilterButton(context, responsive),
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

  Widget _buildFilterButton(BuildContext context, ResponsiveHelper responsive) {
    return Container(
      height: responsive.inputFieldHeight * 0.83,
      constraints: BoxConstraints(
        minWidth: responsive.inputFieldHeight * 0.83,
        maxWidth: responsive.inputFieldHeight * 0.83,
      ),
      decoration: BoxDecoration(
        color: hasActiveFilters
            ? AppColors.themeColor.withValues(alpha: 0.15)
            : AppColors.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.r10),
        border: Border.all(
          color: hasActiveFilters
              ? AppColors.themeColor
              : AppColors.cardBorderColor,
          width: AppDimensions.hairline,
        ),
      ),
      child: Material(
        color: AppColors.transparentColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r10),
          onTap: onFilterTap,
          child: Padding(
            padding: EdgeInsets.all(responsive.isTablet ? AppSpacing.s10 : AppSpacing.xs),
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
                        : AppColors.secondaryColor.withValues(alpha: 0.6),
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
