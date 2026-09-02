import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/dimensions.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// The filter-icon button (with active-filter dot) shared by
/// [StaffAttendanceFilters] and [StudentAttendanceFilters] — was an
/// identical private `_buildFilterButton` method in both.
class AttendanceFilterButton extends StatelessWidget {
  const AttendanceFilterButton({
    super.key,
    required this.responsive,
    required this.hasActiveFilters,
    this.onFilterTap,
  });

  final ResponsiveHelper responsive;
  final bool hasActiveFilters;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.all(
              responsive.isTablet ? AppSpacing.s10 : AppSpacing.xs,
            ),
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
