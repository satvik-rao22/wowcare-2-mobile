import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/core/util/server_time_service.dart';

enum SignMethod { gps, qr, pin, kiosk, direct, web, system }

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
  // Shared text tokens mirrored from StaffCard so attendance cards read with
  // the same Manrope/plum visual identity.
  static const Color _plum = Color(0xff573353);

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

    // Attended time: prefer client-computed label from parent; else derive locally.
    String duration = (student.attendedTimeDisplay ?? '').trim();
    if (duration.isEmpty &&
        student.signInTime != null &&
        student.signOutTime != null) {
      try {
        final signInTime = _parseTimeString(student.signInTime!);
        final signOutTime = _parseTimeString(student.signOutTime!);
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
                    fileUuid: student.studentPhotoUuid ?? '',
                    name: student.studentName,
                    studentCode: student.studentCode,
                    size: avatarSize,
                    fontSize: isTablet ? 18 : 16,
                  ),
                  SizedBox(width: spacing),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            student.studentName,
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
                    _buildDetailRow(
                      context,
                      'Expected Today?',
                      student.expectedToday ? 'Yes' : 'No',
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(context, 'Classroom', student.roomName),
                    const SizedBox(height: 10),
                    _buildSignInOutRow(
                      context,
                      'Signed-In Time & Staff',
                      signIn,
                      student.signInMethod,
                      showTransferIcon: student.isTransferSignIn,
                    ),
                    const SizedBox(height: 10),
                    _buildSignInOutRow(
                      context,
                      'Signed-Out Time & Staff',
                      signOut,
                      student.signOutMethod,
                      showTransferIcon: student.isTransferSignOut,
                    ),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(context, 'Attended Time', duration),
                    ],
                    if ((student.notExpectedComment ?? '')
                        .trim()
                        .isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        context,
                        'Comment',
                        student.notExpectedComment!.trim(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildActionButtons(context),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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
    );
  }

  Widget _buildSignInOutRow(
    BuildContext context,
    String label,
    String value,
    SignMethod? method, {
    bool showTransferIcon = false,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (method != null) ...[
                _buildMethodIcon(method),
                const SizedBox(width: 4),
              ],
              if (showTransferIcon) ...[
                Tooltip(
                  message: 'Transfer',
                  child: SvgPicture.asset(
                    MediaRes.transfer,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      AppColors.themeColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
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

  Widget _buildMethodIcon(SignMethod method) {
    const double size = 18;

    switch (method) {
      case SignMethod.gps:
        return Tooltip(
          message: 'GPS',
          child: SvgPicture.asset(
            MediaRes.gpsMethodIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case SignMethod.qr:
        return Tooltip(
          message: 'QR',
          child: SvgPicture.asset(
            MediaRes.qrAttendanceIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case SignMethod.kiosk:
        return Tooltip(
          message: 'Kiosk',
          child: SvgPicture.asset(
            MediaRes.kioskAttendenceIcons,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case SignMethod.pin:
        return Tooltip(
          message: 'PIN',
          child: SvgPicture.asset(
            MediaRes.kioskAttendenceIcons,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case SignMethod.direct:
        return Tooltip(
          message: 'APP',
          child: SvgPicture.asset(
            MediaRes.appMethodIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case SignMethod.web:
        return Tooltip(
          message: 'WEB',
          child: SvgPicture.asset(
            MediaRes.webMethodIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
      case SignMethod.system:
        // Auto sign-out performed by the system (no person). Matches web's
        // gear/"System" indicator.
        return Tooltip(
          message: 'System',
          child: SvgPicture.asset(
            MediaRes.systemMethodIcon,
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(
              AppColors.themeColor,
              BlendMode.srcIn,
            ),
          ),
        );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // For very small screens, stack buttons vertically
        if (constraints.maxWidth < 300) {
          return Column(
            children: [
              if (widget.onDelete != null)
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: _outlinedButton('Delete', widget.onDelete),
                ),
              if (widget.onDelete != null && widget.onEdit != null)
                const SizedBox(height: 12),
              if (widget.onEdit != null)
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: _gradientButton('Edit', widget.onEdit),
                ),
              if (widget.onView != null) ...[
                if (widget.onEdit != null || widget.onDelete != null)
                  const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: _outlinedButton('View', widget.onView),
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
                  height: 40,
                  child: _outlinedButton('Delete', widget.onDelete),
                ),
              ),
            if (widget.onDelete != null && widget.onEdit != null)
              const SizedBox(width: 16),
            if (widget.onEdit != null)
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: _gradientButton('Edit', widget.onEdit),
                ),
              ),
            if (widget.onView != null) ...[
              if (widget.onEdit != null || widget.onDelete != null)
                const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: _outlinedButton('View', widget.onView),
                ),
              ),
            ],
          ],
        );
      },
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

  Widget _gradientButton(String label, VoidCallback? onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: AppColors.buildPrimaryGradient(),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: AppColors.transparent,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            height: 16 / 16,
          ),
        ),
      ),
    );
  }

  DateTime _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(' ');
      if (parts.length < 2) {
        return ServerTimeService.instance.now();
      }

      final timePart = parts[0];
      final period = parts[1];

      final timeComponents = timePart.split(':');
      if (timeComponents.length < 2) {
        return ServerTimeService.instance.now();
      }

      int hour = int.parse(timeComponents[0]);
      int minute = int.parse(timeComponents[1]);

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return ServerTimeService.instance.now().copyWith(
        hour: hour,
        minute: minute,
      );
    } catch (e) {
      return ServerTimeService.instance.now();
    }
  }
}
