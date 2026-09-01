import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/theme/dimensions.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart';

export 'package:wowcare/presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart'
    show AbsentMarkMethod;

class StaffAbsentCardData {
  final String id;
  final String? staffCode;
  final String name;
  final String? photoUuid;
  final String roomName;
  final String absentTime;
  final String absentBy;
  final String? note;
  final int staffId;
  final int roomId;
  final int schoolId;
  final String startDate;
  final String endDate;
  final bool hasSignIn;
  final bool expectedToday;
  final String? signInTime;
  final String? signOutTime;
  final AbsentMarkMethod? markAbsentMethod;

  StaffAbsentCardData({
    required this.id,
    this.staffCode,
    required this.name,
    this.photoUuid,
    required this.roomName,
    required this.absentTime,
    required this.absentBy,
    this.note,
    required this.staffId,
    required this.roomId,
    required this.schoolId,
    required this.startDate,
    required this.endDate,
    this.hasSignIn = false,
    this.expectedToday = true,
    this.signInTime,
    this.signOutTime,
    this.markAbsentMethod,
  });
}

class StaffAbsentCard extends StatefulWidget {
  final StaffAbsentCardData staff;
  final int index;
  final bool isExpanded;
  final bool disableAttendanceStatusLookup;
  final VoidCallback? onTap;
  final VoidCallback? onView;

  const StaffAbsentCard({
    super.key,
    required this.staff,
    required this.index,
    this.isExpanded = false,
    this.disableAttendanceStatusLookup = false,
    this.onTap,
    this.onView,
  });

  @override
  State<StaffAbsentCard> createState() => _StaffAbsentCardState();
}

class _StaffAbsentCardState extends State<StaffAbsentCard> {
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTablet;
    final staff = widget.staff;

    final avatarSize = isTablet ? 52.0 : 50.0;
    final headerPadding = EdgeInsets.symmetric(
      horizontal: isTablet ? AppSpacing.xl : AppSpacing.md,
    );
    final spacing = isTablet ? 16.0 : 9.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: AppRadius.allMd,
          border: Border.all(
            color: AppColors.cardBorderColor,
            width: AppDimensions.hairline,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: headerPadding.copyWith(top: 12, bottom: 12),
              child: Row(
                children: [
                  DocumentImageWidget(
                    fileUuid: staff.photoUuid ?? '',
                    name: staff.name,
                    staffCode: (staff.staffCode ?? '').trim().isNotEmpty
                        ? staff.staffCode
                        : staff.id,
                    size: avatarSize,
                    fontSize: isTablet ? 18 : 16,
                    disableAttendanceStatusLookup:
                        widget.disableAttendanceStatusLookup,
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            staff.name,
                            style: AppTextStyles.value.copyWith(
                              fontSize: isTablet ? 16 : 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            staff.roomName,
                            style: AppTextStyles.value.copyWith(
                              fontSize: isTablet ? 16 : 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isExpanded) ...[
              const Divider(
                height: 1,
                thickness: AppDimensions.hairline,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: AppColors.attendanceCardDividerColor,
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildAbsentDetailRow(context, 'Room', staff.roomName),
                    const SizedBox(height: AppSpacing.s10),
                    buildAbsentDetailRow(
                      context,
                      'Absent Time',
                      staff.absentTime,
                      method: staff.markAbsentMethod,
                    ),
                    if (staff.absentBy.isNotEmpty &&
                        staff.absentBy != 'Unknown') ...[
                      const SizedBox(height: AppSpacing.s10),
                      buildAbsentDetailRow(
                        context,
                        'Marked by',
                        staff.absentBy,
                      ),
                    ],
                    if (staff.note != null && staff.note!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s10),
                      buildAbsentDetailRow(context, 'Absent Note', staff.note!),
                    ],
                    const SizedBox(height: AppSpacing.s10),
                    buildAbsentDetailRow(
                      context,
                      'Start Date',
                      staff.startDate.isNotEmpty
                          ? staff.startDate.split('T')[0]
                          : 'N/A',
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    buildAbsentDetailRow(
                      context,
                      'End Date',
                      staff.endDate.isNotEmpty
                          ? staff.endDate.split('T')[0]
                          : 'N/A',
                    ),
                    if (widget.onView != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        height: AppSpacing.xxxl,
                        child: attendanceOutlinedButton('View', widget.onView),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
