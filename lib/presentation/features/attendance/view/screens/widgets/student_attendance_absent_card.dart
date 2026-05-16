import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AbsentMarkMethod { gps, qr, kiosk, app, web }

class StudentAbsentCardData {
  final String id;
  final String? studentCode;
  final String name;
  final String? photoUuid;
  final String roomName;
  final String absentTime;
  final String absentBy;
  final String? note;
  final int studentId;
  final int roomId;
  final int schoolId;
  final String startDate;
  final String endDate;
  final bool hasSignIn;
  final bool expectedToday;
  final String? signInTime;
  final String? signOutTime;
  final AbsentMarkMethod? markAbsentMethod;

  StudentAbsentCardData({
    required this.id,
    this.studentCode,
    required this.name,
    this.photoUuid,
    required this.roomName,
    required this.absentTime,
    required this.absentBy,
    this.note,
    required this.studentId,
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

class StudentAbsentCard extends StatefulWidget {
  final StudentAbsentCardData student;
  final int index;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onView;

  const StudentAbsentCard({
    super.key,
    required this.student,
    required this.index,
    this.isExpanded = false,
    this.onTap,
    this.onView,
  });

  @override
  State<StudentAbsentCard> createState() => _StudentAbsentCardState();
}

class _StudentAbsentCardState extends State<StudentAbsentCard> {
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final student = widget.student;

    final avatarSize = responsive.isTablet ? 52.0 : 44.0;
    final cardPadding = responsive.isTablet
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    final spacing = responsive.isTablet ? 16.0 : 14.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 18 : 16),
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    DocumentImageWidget(
                      fileUuid: student.photoUuid ?? '',
                      name: student.name,
                      studentCode: (student.studentCode ?? '').trim().isNotEmpty
                          ? student.studentCode
                          : student.id,
                      size: avatarSize,
                      fontSize: responsive.isTablet ? 18 : 16,
                    ),
                  ],
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: AppText.body(
                    student.name,
                    style: TextStyle(
                      fontSize: responsive.labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing / 2),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AppText.body(
                      student.roomName,
                      style: TextStyle(
                        fontSize: responsive.isTablet ? 16 : 15,
                        color: AppColors.themeColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ),
              ],
            ),
            if (widget.isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              Divider(height: 1, color: AppColors.cardBorderColor),
              SizedBox(height: responsive.verticalSpacing / 2),
              _buildDetailRow(context, responsive, 'Room', student.roomName),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                context,
                responsive,
                'Absent Time',
                student.absentTime,
                method: student.markAbsentMethod,
              ),
              if (student.absentBy.isNotEmpty &&
                  student.absentBy != 'Unknown') ...[
                SizedBox(height: responsive.isTablet ? 8 : 6),
                _buildDetailRow(
                  context,
                  responsive,
                  'Marked by',
                  student.absentBy,
                ),
              ],
              if (student.note != null && student.note!.isNotEmpty) ...[
                SizedBox(height: responsive.isTablet ? 8 : 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: responsive.isTablet ? 2 : 1,
                      child: AppText.small(
                        'Note',
                        style: TextStyle(
                          fontSize: responsive.isTablet ? 14 : 12,
                          color: AppColors.secondaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.horizontalSpacing / 2),
                    Expanded(
                      flex: responsive.isTablet ? 3 : 2,
                      child: AppText.value(
                        student.note!,
                        style: TextStyle(
                          fontSize: responsive.isTablet ? 16 : 14,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                context,
                responsive,
                'Start Date',
                student.startDate.isNotEmpty
                    ? student.startDate.split('T')[0]
                    : 'N/A',
              ),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(
                context,
                responsive,
                'End Date',
                student.endDate.isNotEmpty
                    ? student.endDate.split('T')[0]
                    : 'N/A',
              ),
              SizedBox(height: responsive.verticalSpacing / 2),
              if (widget.onView != null)
                SizedBox(
                  width: double.infinity,
                  height: responsive.buttonHeight * 0.8,
                  child: CustomCancelButton(
                    cancelButtonLabel: 'View',
                    onPressedCancel: widget.onView,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    ResponsiveHelper responsive,
    String label,
    String value, {
    AbsentMarkMethod? method,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: responsive.isTablet ? 2 : 1,
          child: AppText.small(
            label,
            style: TextStyle(
              fontSize: responsive.isTablet ? 14 : 12,
              color: AppColors.secondaryColor.withOpacity(0.6),
            ),
          ),
        ),
        SizedBox(width: responsive.horizontalSpacing / 2),
        Expanded(
          flex: responsive.isTablet ? 3 : 2,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (method != null) ...[
                _buildMethodIcon(method, responsive),
                SizedBox(width: responsive.horizontalSpacing / 4),
              ],
              Flexible(
                child: AppText.value(
                  value,
                  style: TextStyle(fontSize: responsive.isTablet ? 16 : 14),
                  textAlign: TextAlign.end,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodIcon(
    AbsentMarkMethod method,
    ResponsiveHelper responsive,
  ) {
    final size = responsive.isTablet ? 20.0 : 18.0;
    switch (method) {
      case AbsentMarkMethod.gps:
        return SvgPicture.asset(
          MediaRes.gpsMethodIcon,
          width: size,
          height: size,
        );
      case AbsentMarkMethod.qr:
        return SvgPicture.asset(
          MediaRes.qrAttendanceIcon,
          width: size,
          height: size,
        );
      case AbsentMarkMethod.kiosk:
        return SvgPicture.asset(
          MediaRes.pinMethodIcon,
          width: size,
          height: size,
        );
      case AbsentMarkMethod.app:
        return SvgPicture.asset(
          MediaRes.appMethodIcon,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.themeColor,
            BlendMode.srcIn,
          ),
        );
      case AbsentMarkMethod.web:
        return SvgPicture.asset(
          MediaRes.webMethodIcon,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(
            AppColors.themeColor,
            BlendMode.srcIn,
          ),
        );
    }
  }
}
