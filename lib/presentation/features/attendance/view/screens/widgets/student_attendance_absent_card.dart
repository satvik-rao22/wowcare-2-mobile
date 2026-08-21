import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
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
  // Shared text tokens mirrored from StaffCard so attendance cards read with
  // the same Manrope/plum visual identity.
  static const Color _plum = Color(0xff573353);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTablet;
    final student = widget.student;

    final avatarSize = isTablet ? 52.0 : 50.0;
    final headerPadding = EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16);
    final spacing = isTablet ? 16.0 : 9.0;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: headerPadding.copyWith(top: 12, bottom: 12),
              child: Row(
                children: [
                  DocumentImageWidget(
                    fileUuid: student.photoUuid ?? '',
                    name: student.name,
                    studentCode: (student.studentCode ?? '').trim().isNotEmpty
                        ? student.studentCode
                        : student.id,
                    size: avatarSize,
                    fontSize: isTablet ? 18 : 16,
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Text(
                      student.name,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                        color: _plum,
                        height: 19 / 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      student.roomName,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                        color: _plum,
                        height: 19 / 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isExpanded) ...[
              const Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xFFE9ECEF),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(context, 'Room', student.roomName),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'Absent Time',
                      student.absentTime,
                      method: student.markAbsentMethod,
                    ),
                    if (student.absentBy.isNotEmpty &&
                        student.absentBy != 'Unknown') ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(context, 'Marked by', student.absentBy),
                    ],
                    if (student.note != null && student.note!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(context, 'Note', student.note!),
                    ],
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'Start Date',
                      student.startDate.isNotEmpty
                          ? student.startDate.split('T')[0]
                          : 'N/A',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      context,
                      'End Date',
                      student.endDate.isNotEmpty
                          ? student.endDate.split('T')[0]
                          : 'N/A',
                    ),
                    if (widget.onView != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: _outlinedButton('View', widget.onView),
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

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    AbsentMarkMethod? method,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _plum,
              height: 16 / 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (method != null) ...[
                _buildMethodIcon(method),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _plum,
                    height: 19 / 14,
                  ),
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

  Widget _outlinedButton(String label, VoidCallback? onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF6C7FD8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.white,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6C7FD8),
          height: 16 / 16,
        ),
      ),
    );
  }

  Widget _buildMethodIcon(AbsentMarkMethod method) {
    const size = 18.0;
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
        return Icon(
          Icons.point_of_sale_outlined,
          size: size,
          color: AppColors.themeColor,
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
