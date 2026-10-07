import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

/// Shared by [StaffAttendanceCard] and [StudentAttendanceCard] — the two
/// mirror each other's sign-in/sign-out display exactly.
enum SignMethod { gps, qr, pin, kiosk, direct, web, system }

/// Shared by [StaffAbsentCard] and [StudentAbsentCard] — was independently
/// declared as `StaffAbsentMarkMethod`/`AbsentMarkMethod` with identical
/// values in each file.
enum AbsentMarkMethod { gps, qr, kiosk, app, web }

/// Formats a backend date string (`2024-10-01` or `2024-10-01T00:00:00`) as
/// `Oct 01, 2024`. Returns [raw] unchanged if it can't be parsed.
String formatAbsentCardDate(String raw) {
  final date = DateTime.tryParse(raw.split('T')[0]);
  return date == null ? raw : DateFormat('MMM dd, yyyy').format(date);
}

Widget buildAttendanceDetailRow(
  BuildContext context,
  String label,
  String value,
) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: AppTextStyles.label)),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Text(
          value,
          style: AppTextStyles.value,
          textAlign: TextAlign.end,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

Widget buildAttendanceSignInOutRow(
  BuildContext context,
  String label,
  String value,
  SignMethod? method, {
  bool showTransferIcon = false,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: AppTextStyles.label)),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Web shows exactly one indicator per sign-in/sign-out. On a
            // transfer row the transfer icon wins and the underlying method
            // icon is suppressed, instead of stacking both.
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
            ] else if (method != null) ...[
              buildAttendanceMethodIcon(method),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.value,
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

Widget buildAttendanceMethodIcon(SignMethod method) {
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

Widget buildAttendanceActionButtons(
  BuildContext context, {
  VoidCallback? onDelete,
  VoidCallback? onEdit,
  VoidCallback? onView,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // For very small screens, stack buttons vertically
      if (constraints.maxWidth < 300) {
        return Column(
          children: [
            if (onDelete != null)
              SizedBox(
                width: double.infinity,
                height: AppSpacing.xxxl,
                child: attendanceOutlinedButton('Delete', onDelete),
              ),
            if (onDelete != null && onEdit != null)
              const SizedBox(height: AppSpacing.sm),
            if (onEdit != null)
              SizedBox(
                width: double.infinity,
                height: AppSpacing.xxxl,
                child: attendanceGradientButton('Edit', onEdit),
              ),
            if (onView != null) ...[
              if (onEdit != null || onDelete != null)
                const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.xxxl,
                child: attendanceOutlinedButton('View', onView),
              ),
            ],
          ],
        );
      }

      // For larger screens, use horizontal layout
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onDelete != null)
            Expanded(
              child: SizedBox(
                height: AppSpacing.xxxl,
                child: attendanceOutlinedButton('Delete', onDelete),
              ),
            ),
          if (onDelete != null && onEdit != null)
            const SizedBox(width: AppSpacing.md),
          if (onEdit != null)
            Expanded(
              child: SizedBox(
                height: AppSpacing.xxxl,
                child: attendanceGradientButton('Edit', onEdit),
              ),
            ),
          if (onView != null) ...[
            if (onEdit != null || onDelete != null)
              const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: AppSpacing.xxxl,
                child: attendanceOutlinedButton('View', onView),
              ),
            ),
          ],
        ],
      );
    },
  );
}

Widget attendanceOutlinedButton(String label, VoidCallback? onPressed) {
  return OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.attendanceActionAccentColor),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.cardColor,
    ),
    child: Text(
      label,
      style: AppTextStyles.title.copyWith(
        color: AppColors.attendanceActionAccentColor,
      ),
    ),
  );
}

Widget attendanceGradientButton(String label, VoidCallback? onPressed) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: AppRadius.allSm,
      gradient: AppColors.buildPrimaryGradient(),
    ),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.transparentColor,
      ),
      child: Text(
        label,
        style: AppTextStyles.title.copyWith(color: AppColors.cardColor),
      ),
    ),
  );
}

Widget buildAbsentDetailRow(
  BuildContext context,
  String label,
  String value, {
  AbsentMarkMethod? method,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: AppTextStyles.label)),
      const SizedBox(width: AppSpacing.xs),
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (method != null) ...[
              buildAbsentMethodIcon(method),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.value,
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

Widget buildAbsentMethodIcon(AbsentMarkMethod method) {
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

DateTime parseAttendanceTimeString(String timeString) {
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

/// Attended time: prefers the client-computed label from [attendedTimeDisplay];
/// else derives it from [signInTime]/[signOutTime]. Shared by
/// [StaffAttendanceCard] and [StudentAttendanceCard] — was identical inline
/// math duplicated in both `build()` methods.
String computeAttendedDurationLabel({
  required String? attendedTimeDisplay,
  required String? signInTime,
  required String? signOutTime,
}) {
  String duration = (attendedTimeDisplay ?? '').trim();
  if (duration.isEmpty && signInTime != null && signOutTime != null) {
    try {
      final parsedSignIn = parseAttendanceTimeString(signInTime);
      final parsedSignOut = parseAttendanceTimeString(signOutTime);
      var end = parsedSignOut;
      if (end.isBefore(parsedSignIn)) {
        end = end.add(const Duration(days: 1));
      }
      final difference = end.difference(parsedSignIn);
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
  return duration;
}
