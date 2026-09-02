import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/theme/dimensions.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart';

export 'package:wowcare/presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart'
    show SignMethod;

class StaffAttendanceCardData {
  final String? attendanceRecordCode;
  final String id;
  final String staffName;
  final String? staffPhotoUuid;
  final String? designationName;
  final String roomName;

  /// Backend classroom code for this row (for attendance mutations).
  final String? classroomCode;
  final bool expectedToday;
  final bool hasSignIn;
  final String? signInTime;
  final String? signOutTime;
  final String? signInBy;
  final String? signOutBy;
  final SignMethod? signInMethod;
  final SignMethod? signOutMethod;
  final int staffId;
  final int roomId;
  final int schoolId;
  final int? sequenceNumber;
  final int? totalSequenceCount;
  final bool isTransferSignIn;
  final bool isTransferSignOut;

  /// When set, shown as "Attended Time" (computed on the client from sign-in/out).
  final String? attendedTimeDisplay;

  /// Comment captured from the "not expected today" warning at sign-in.
  final String? notExpectedComment;

  StaffAttendanceCardData({
    this.attendanceRecordCode,
    required this.id,
    required this.staffName,
    this.staffPhotoUuid,
    this.designationName,
    required this.roomName,
    this.classroomCode,
    required this.expectedToday,
    required this.hasSignIn,
    this.signInTime,
    this.signOutTime,
    this.signInBy,
    this.signOutBy,
    this.signInMethod,
    this.signOutMethod,
    required this.staffId,
    required this.roomId,
    required this.schoolId,
    this.sequenceNumber,
    this.totalSequenceCount,
    this.isTransferSignIn = false,
    this.isTransferSignOut = false,
    this.attendedTimeDisplay,
    this.notExpectedComment,
  });
}

class StaffAttendanceCard extends StatefulWidget {
  final StaffAttendanceCardData staff;
  final int index;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;

  const StaffAttendanceCard({
    super.key,
    required this.staff,
    required this.index,
    this.isExpanded = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  @override
  State<StaffAttendanceCard> createState() => _StaffAttendanceCardState();
}

class _StaffAttendanceCardState extends State<StaffAttendanceCard> {
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTablet;
    final staff = widget.staff;
    final signIn = staff.signInTime != null
        ? '${staff.signInTime} By ${staff.signInBy ?? 'Unknown'}'
        : 'Not Yet Signed In';
    final signOut = staff.signOutTime != null
        ? '${staff.signOutTime} By ${staff.signOutBy ?? 'Unknown'}'
        : 'Not Yet Signed Out';

    String duration = (staff.attendedTimeDisplay ?? '').trim();
    if (duration.isEmpty &&
        staff.signInTime != null &&
        staff.signOutTime != null) {
      try {
        final signInTime = parseAttendanceTimeString(staff.signInTime!);
        final signOutTime = parseAttendanceTimeString(staff.signOutTime!);
        var end = signOutTime;
        if (end.isBefore(signInTime)) {
          end = end.add(const Duration(days: 1));
        }
        final difference = end.difference(signInTime);
        if (difference.inSeconds == 0) {
          duration = '0 hours 0 minutes';
        } else if (difference.inSeconds > 0) {
          final hours = difference.inHours;
          final minutes = difference.inMinutes % 60;
          duration = '$hours hours $minutes minutes';
        }
      } catch (e) {
        duration = '';
      }
    }

    final avatarSize = isTablet ? 52.0 : 50.0;
    final headerPadding = EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16);
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
                    fileUuid: staff.staffPhotoUuid ?? '',
                    name: staff.staffName,
                    staffCode: staff.id,
                    size: avatarSize,
                    fontSize: isTablet ? 18 : 16,
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff.staffName,
                                style: AppTextStyles.value.copyWith(
                                  fontSize: isTablet ? 16 : 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (staff.designationName != null &&
                                  staff.designationName!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  staff.designationName!,
                                  // Survivor: 13/12·w400·primary@0.6 with NO
                                  // line-height. No AppTextStyles base is w400
                                  // without a height, so a base+copyWith would
                                  // inject height and change layout — left inline.
                                  style: TextStyle(
                                    fontFamily: Fonts.manrope,
                                    fontSize: isTablet ? 13 : 12,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
                    buildAttendanceDetailRow(
                      context,
                      'Expected Today?',
                      staff.expectedToday ? 'Yes' : 'No',
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    buildAttendanceDetailRow(
                      context,
                      'Classroom',
                      staff.roomName,
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    buildAttendanceSignInOutRow(
                      context,
                      'Sign In time & by',
                      signIn,
                      staff.signInMethod,
                      showTransferIcon: staff.isTransferSignIn,
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    buildAttendanceSignInOutRow(
                      context,
                      'Sign Out time & by',
                      signOut,
                      staff.signOutMethod,
                      showTransferIcon: staff.isTransferSignOut,
                    ),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s10),
                      buildAttendanceDetailRow(
                        context,
                        'Attended Time',
                        duration,
                      ),
                    ],
                    if ((staff.notExpectedComment ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s10),
                      buildAttendanceDetailRow(
                        context,
                        'Comment',
                        staff.notExpectedComment!.trim(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    buildAttendanceActionButtons(
                      context,
                      onDelete: widget.onDelete,
                      onEdit: widget.onEdit,
                      onView: widget.onView,
                    ),
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
