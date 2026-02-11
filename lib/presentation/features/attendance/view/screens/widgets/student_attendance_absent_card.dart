import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentAbsentCardData {
  final String id;
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

  StudentAbsentCardData({
    required this.id,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 18 : 16),
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
                      size: avatarSize,
                      fontSize: responsive.isTablet ? 18 : 16,
                    ),
                    // Status dot for absent list
                    if (student.hasSignIn &&
                        (student.signOutTime == null ||
                            student.signOutTime!.isEmpty))
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: responsive.isTablet ? 14 : 12,
                          height: responsive.isTablet ? 14 : 12,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 177, 21, 1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: responsive.isTablet ? 2.5 : 2,
                            ),
                          ),
                        ),
                      )
                    else if (student.expectedToday &&
                        !student.hasSignIn &&
                        (student.signOutTime == null ||
                            student.signOutTime!.isEmpty) &&
                        (student.signInTime == null ||
                            student.signInTime!.isEmpty))
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: responsive.isTablet ? 14 : 12,
                          height: responsive.isTablet ? 14 : 12,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(200, 32, 32, 1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: responsive.isTablet ? 2.5 : 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Text(
                    student.name,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: responsive.labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF573353),
                      height: 19 / responsive.labelFontSize,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: spacing / 2),
                Flexible(
                  child: Text(
                    student.roomName,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: responsive.isTablet ? 16 : 15,
                      color: const Color(0xFF6C7FD8),
                      fontWeight: FontWeight.w500,
                      height: 19 / (responsive.isTablet ? 16 : 15),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (widget.isExpanded) ...[
              SizedBox(height: responsive.verticalSpacing / 2),
              const Divider(height: 1, color: Color(0xFFE5E9F2)),
              SizedBox(height: responsive.verticalSpacing / 2),
              _buildDetailRow(context, responsive, 'Room', student.roomName),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(context, responsive, 'Absent Time', student.absentTime),
              if (student.absentBy.isNotEmpty && student.absentBy != 'Unknown') ...[
                SizedBox(height: responsive.isTablet ? 8 : 6),
                _buildDetailRow(context, responsive, 'Marked by', student.absentBy),
              ],
              if (student.note != null && student.note!.isNotEmpty) ...[
                SizedBox(height: responsive.isTablet ? 8 : 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: responsive.isTablet ? 2 : 1,
                      child: Text(
                        'Note',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.isTablet ? 14 : 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF8F9BB3),
                          height: responsive.isTablet ? 18 / 14 : 16 / 12,
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.horizontalSpacing / 2),
                    Expanded(
                      flex: responsive.isTablet ? 3 : 2,
                      child: Text(
                        student.note!,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: responsive.isTablet ? 16 : 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF573353),
                          height: responsive.isTablet ? 21 / 16 : 19 / 14,
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
                  child: OutlinedButton(
                    onPressed: widget.onView,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.themeColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: AppColors.cardColor,
                    ),
                    child: Text(
                      "View",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: responsive.isTablet ? 16 : 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.themeColor,
                        height: 19 / (responsive.isTablet ? 16 : 15),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, ResponsiveHelper responsive, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: responsive.isTablet ? 2 : 1,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.isTablet ? 14 : 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8F9BB3),
              height: responsive.isTablet ? 18 / 14 : 16 / 12,
            ),
          ),
        ),
        SizedBox(width: responsive.horizontalSpacing / 2),
        Expanded(
          flex: responsive.isTablet ? 3 : 2,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.isTablet ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF573353),
              height: responsive.isTablet ? 21 / 16 : 19 / 14,
            ),
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
