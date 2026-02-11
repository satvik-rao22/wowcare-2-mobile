import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:intl/intl.dart';

enum SignMethod {
  gps,
  qr,
  kiosk,
  direct,
}

class StudentAttendanceCardData {
  final String id;
  final String studentName;
  final String? studentPhotoUuid;
  final String roomName;
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

  StudentAttendanceCardData({
    required this.id,
    required this.studentName,
    this.studentPhotoUuid,
    required this.roomName,
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
    final student = widget.student;
    final signIn = student.signInTime != null
        ? '${student.signInTime} By ${student.signInBy ?? 'Unknown'}'
        : 'Not Yet Signed In';
    final signOut = student.signOutTime != null
        ? '${student.signOutTime} By ${student.signOutBy ?? 'Unknown'}'
        : 'Not Yet Signed Out';

    // Calculate duration
    String duration = '';
    if (student.signInTime != null && student.signOutTime != null) {
      try {
        final signInTime = _parseTimeString(student.signInTime!);
        final signOutTime = _parseTimeString(student.signOutTime!);
        final difference = signOutTime.difference(signInTime);
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;
        duration = '$hours hours $minutes minutes';
      } catch (e) {
        duration = '';
      }
    }

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
                      fileUuid: student.studentPhotoUuid ?? '',
                      name: student.studentName,
                      size: avatarSize,
                      fontSize: responsive.isTablet ? 18 : 16,
                    ),
                    // Status dot logic
                    if (student.hasSignIn && student.signOutTime == null)
                      // Green dot for signed in (present)
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
                    else if (student.expectedToday == true &&
                        !student.hasSignIn &&
                        (student.signOutTime == null ||
                            student.signOutTime!.isEmpty) &&
                        (student.signInTime == null ||
                            student.signInTime!.isEmpty))
                      // Red dot for absent
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
                    student.studentName,
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
              _buildDetailRow(context, responsive, 'Expected Today?', student.expectedToday ? 'Yes' : 'No'),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildDetailRow(context, responsive, 'Classroom', student.roomName),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildSignInOutRow(context, responsive, 'Signed-In Time & Staff', signIn, student.signInMethod),
              SizedBox(height: responsive.isTablet ? 8 : 6),
              _buildSignInOutRow(context, responsive, 'Signed-Out Time & Staff', signOut, student.signOutMethod),
              if (duration.isNotEmpty) ...[
                SizedBox(height: responsive.isTablet ? 8 : 6),
                _buildDetailRow(context, responsive, 'Attended Time', duration),
              ],
              SizedBox(height: responsive.verticalSpacing / 2),
              _buildActionButtons(context, responsive),
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

  Widget _buildSignInOutRow(BuildContext context, ResponsiveHelper responsive, String label, String value, SignMethod? method) {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
              if (method != null) ...[
                SizedBox(width: responsive.horizontalSpacing / 4),
                _buildMethodIcon(method, responsive),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodIcon(SignMethod method, ResponsiveHelper responsive) {
    IconData icon;
    String tooltip;
    Color color;

    switch (method) {
      case SignMethod.gps:
        icon = Icons.location_on;
        tooltip = 'GPS';
        color = const Color(0xFF4285F4);
        break;
      case SignMethod.qr:
        icon = Icons.qr_code;
        tooltip = 'QR Code';
        color = const Color(0xFF34A853);
        break;
      case SignMethod.kiosk:
        icon = Icons.desktop_mac;
        tooltip = 'Kiosk';
        color = const Color(0xFFEA4335);
        break;
      case SignMethod.direct:
        icon = Icons.phone_android;
        tooltip = 'Direct from App';
        color = const Color(0xFFFBBC04);
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        size: responsive.isTablet ? 20 : 18,
        color: color,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ResponsiveHelper responsive) {
    final buttonSpacing = responsive.horizontalSpacing / 2;
    final buttonHeight = responsive.buttonHeight * 0.8;
    final buttonFontSize = responsive.isTablet ? 16.0 : 15.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // For very small screens, stack buttons vertically
        if (constraints.maxWidth < 300) {
          return Column(
            children: [
              if (widget.onDelete != null)
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: OutlinedButton(
                    onPressed: widget.onDelete,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.themeColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: AppColors.cardColor,
                    ),
                    child: Text(
                      "Delete",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.themeColor,
                      ),
                    ),
                  ),
                ),
              if (widget.onDelete != null && widget.onEdit != null)
                SizedBox(height: buttonSpacing),
              if (widget.onEdit != null)
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: AppColors.buildPrimaryGradient(),
                    ),
                    child: TextButton(
                      onPressed: widget.onEdit,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        "Edit",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.onView != null) ...[
                if (widget.onEdit != null || widget.onDelete != null)
                  SizedBox(height: buttonSpacing),
                SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
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
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.themeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        }

        // For larger screens, use horizontal layout
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.onDelete != null)
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: OutlinedButton(
                    onPressed: widget.onDelete,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.themeColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.cardColor,
                    ),
                    child: Text(
                      "Delete",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.themeColor,
                        height: 19 / buttonFontSize,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.onDelete != null && widget.onEdit != null)
              SizedBox(width: buttonSpacing),
            if (widget.onEdit != null)
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: AppColors.buildPrimaryGradient(),
                    ),
                    child: TextButton(
                      onPressed: widget.onEdit,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        "Edit",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 19 / buttonFontSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.onView != null) ...[
              if (widget.onEdit != null || widget.onDelete != null)
                SizedBox(width: buttonSpacing),
              Expanded(
                child: SizedBox(
                  height: buttonHeight,
                  child: OutlinedButton(
                    onPressed: widget.onView,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.themeColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.cardColor,
                    ),
                    child: Text(
                      "View",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: buttonFontSize,
                        fontWeight: FontWeight.w600,
                        color: AppColors.themeColor,
                        height: 19 / buttonFontSize,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  DateTime _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(' ');
      if (parts.length < 2) {
        return DateTime.now();
      }

      final timePart = parts[0];
      final period = parts[1];

      final timeComponents = timePart.split(':');
      if (timeComponents.length < 2) {
        return DateTime.now();
      }

      int hour = int.parse(timeComponents[0]);
      int minute = int.parse(timeComponents[1]);

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return DateTime.now().copyWith(hour: hour, minute: minute);
    } catch (e) {
      return DateTime.now();
    }
  }
}
