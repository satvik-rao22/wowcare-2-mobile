import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';
import 'package:wowcare/shared/common/widgets/attendance_status_dot.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart';

export 'package:wowcare/presentation/features/attendance/view/screens/widgets/attendance_card_shared.dart'
    show SignMethod;

class StudentAttendanceCardData {
  final String id;
  final String? attendanceRecordCode;
  final String? studentCode;
  final String studentName;
  final String? studentPhotoUuid;
  final String roomName;
  final String? classroomCode;
  final bool expectedToday;
  final bool hasSignIn;
  final String? signInTime;
  final String? signOutTime;
  final String? signInBy;
  final String? signOutBy;
  final SignMethod? signInMethod;
  final SignMethod? signOutMethod;
  final List<String>? tags;
  final int studentId;
  final int roomId;
  final int schoolId;
  // Transfer sequence info for validation/display
  final int? sequenceNumber;
  final int? totalSequenceCount;
  // Flags to indicate the displayed times are transfer-derived
  final bool isTransferSignIn;
  final bool isTransferSignOut;

  /// When set, shown as "Attended Time" (computed on the client from sign-in/out).
  final String? attendedTimeDisplay;

  /// Comment captured from the "not expected today" warning at sign-in.
  final String? notExpectedComment;

  StudentAttendanceCardData({
    required this.id,
    this.attendanceRecordCode,
    this.studentCode,
    required this.studentName,
    this.studentPhotoUuid,
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
    this.tags,
    required this.studentId,
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

class StudentAttendanceCard extends StatefulWidget {
  final StudentAttendanceCardData student;
  final int index;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onView;

  const StudentAttendanceCard({
    super.key,
    required this.student,
    required this.index,
    this.isExpanded = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  @override
  State<StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<StudentAttendanceCard> {
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTablet;
    final student = widget.student;
    final signIn = student.signInTime != null
        ? '${student.signInTime} By ${student.signInBy ?? 'Unknown'}'
        : 'Not Yet Signed In';
    final signOut = student.signOutTime != null
        ? '${student.signOutTime} By ${student.signOutBy ?? 'Unknown'}'
        : 'Not Yet Signed Out';

    final duration = computeAttendedDurationLabel(
      attendedTimeDisplay: student.attendedTimeDisplay,
      signInTime: student.signInTime,
      signOutTime: student.signOutTime,
    );

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
                  ProfileAvatar(
                    name: student.studentName,
                    studentCode: student.studentCode,
                    size: avatarSize,
                    fontSize: isTablet ? 18 : 16,
                    statusDot: AttendanceStatusDot(
                      studentCode: student.studentCode,
                    ),
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            student.studentName,
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
                            student.roomName,
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
                      student.expectedToday ? 'Yes' : 'No',
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    buildAttendanceDetailRow(
                      context,
                      'Classroom',
                      student.roomName,
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    buildAttendanceSignInOutRow(
                      context,
                      'Signed-In Time & Staff',
                      signIn,
                      student.signInMethod,
                      showTransferIcon: student.isTransferSignIn,
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    buildAttendanceSignInOutRow(
                      context,
                      'Signed-Out Time & Staff',
                      signOut,
                      student.signOutMethod,
                      showTransferIcon: student.isTransferSignOut,
                    ),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s10),
                      buildAttendanceDetailRow(
                        context,
                        'Attended Time',
                        duration,
                      ),
                    ],
                    if ((student.notExpectedComment ?? '')
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s10),
                      buildAttendanceDetailRow(
                        context,
                        'Comment',
                        student.notExpectedComment!.trim(),
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
