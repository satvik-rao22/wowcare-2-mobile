import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/core/util/server_time_service.dart';

enum SignMethod { gps, qr, pin, kiosk, direct, web, system }

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
  // Shared text tokens mirrored from StaffCard so attendance cards read with
  // the same Manrope/plum visual identity.
  static const Color _plum = AppColors.primaryColor;

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
        final signInTime = _parseTimeString(staff.signInTime!);
        final signOutTime = _parseTimeString(staff.signOutTime!);
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
          color: Colors.white,
          borderRadius: AppRadius.allMd,
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
                              if (staff.designationName != null &&
                                  staff.designationName!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.s2),
                                Text(
                                  staff.designationName!,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: isTablet ? 13 : 12,
                                    fontWeight: FontWeight.w400,
                                    color: _plum.withValues(alpha: 0.6),
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
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
                color: Color(0xFFE9ECEF),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                      context,
                      'Expected Today?',
                      staff.expectedToday ? 'Yes' : 'No',
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    _buildDetailRow(context, 'Classroom', staff.roomName),
                    const SizedBox(height: AppSpacing.s10),
                    _buildSignInOutRow(
                      context,
                      'Sign In time & by',
                      signIn,
                      staff.signInMethod,
                      showTransferIcon: staff.isTransferSignIn,
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    _buildSignInOutRow(
                      context,
                      'Sign Out time & by',
                      signOut,
                      staff.signOutMethod,
                      showTransferIcon: staff.isTransferSignOut,
                    ),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s10),
                      _buildDetailRow(context, 'Attended Time', duration),
                    ],
                    if ((staff.notExpectedComment ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s10),
                      _buildDetailRow(
                        context,
                        'Comment',
                        staff.notExpectedComment!.trim(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
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
        const SizedBox(width: AppSpacing.xs),
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
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (method != null) ...[
                _buildMethodIcon(method),
                const SizedBox(width: AppSpacing.xxs),
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
                const SizedBox(width: AppSpacing.xxs),
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
                  height: AppSpacing.xxxl,
                  child: _outlinedButton('Delete', widget.onDelete),
                ),
              if (widget.onDelete != null && widget.onEdit != null)
                const SizedBox(height: AppSpacing.sm),
              if (widget.onEdit != null)
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.xxxl,
                  child: _gradientButton('Edit', widget.onEdit),
                ),
              if (widget.onView != null) ...[
                if (widget.onEdit != null || widget.onDelete != null)
                  const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.xxxl,
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
                  height: AppSpacing.xxxl,
                  child: _outlinedButton('Delete', widget.onDelete),
                ),
              ),
            if (widget.onDelete != null && widget.onEdit != null)
              const SizedBox(width: AppSpacing.md),
            if (widget.onEdit != null)
              Expanded(
                child: SizedBox(
                  height: AppSpacing.xxxl,
                  child: _gradientButton('Edit', widget.onEdit),
                ),
              ),
            if (widget.onView != null) ...[
              if (widget.onEdit != null || widget.onDelete != null)
                const SizedBox(width: AppSpacing.md),
              Expanded(
                child: SizedBox(
                  height: AppSpacing.xxxl,
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
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
        borderRadius: AppRadius.allSm,
        gradient: AppColors.buildPrimaryGradient(),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
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
