import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/shared/common/widgets/app_tooltip.dart';

/// The attendance sub-action fan-out (Sign-In/Sign-Out/Transfer/Absent) shown
/// when [StaffActionPanel]'s Attendance button is expanded.
class AttendanceOptionsPanel extends StatelessWidget {
  const AttendanceOptionsPanel({
    super.key,
    this.onSignIn,
    this.onSignOut,
    this.onTransfer,
    this.onAbsent,
    required this.availability,
  });

  final VoidCallback? onSignIn;
  final VoidCallback? onSignOut;
  final VoidCallback? onTransfer;
  final VoidCallback? onAbsent;
  final StaffAttendanceActionAvailability availability;

  /// Per-action message explaining why an attendance action is disabled —
  /// mirrors the attendance pop-up. Empty string means "no tooltip".
  static String _disabledReason(String action) {
    switch (action) {
      case 'Sign-In':
        return 'Sign-In can only be done for Students/Staff not signed in.';
      case 'Sign-Out':
        return 'Sign-Out can only be done for Students/Staff already signed in.';
      case 'Transfer':
        return 'Transfer can only be done for Students/Staff already signed in.';
      case 'Absent':
        return 'Absent can only be marked for Students/Staff not yet signed in';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(111, 140, 255, 1)),
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.attendanceCardShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AttendanceActionItem(
            svgPath: MediaRes.Sign_in,
            label: 'Sign-In',
            onTap: availability.signInEnabled ? onSignIn : null,
            isEnabled: availability.signInEnabled,
            disabledTooltip: _disabledReason('Sign-In'),
          ),
          const SizedBox(height: 5),
          AttendanceActionItem(
            svgPath: MediaRes.Sign_out,
            label: 'Sign-Out',
            onTap: availability.signOutEnabled ? onSignOut : null,
            isEnabled: availability.signOutEnabled,
            disabledTooltip: _disabledReason('Sign-Out'),
          ),
          const SizedBox(height: 5),
          AttendanceActionItem(
            svgPath: MediaRes.transfer,
            label: 'Transfer',
            onTap: availability.transferEnabled ? onTransfer : null,
            isEnabled: availability.transferEnabled,
            disabledTooltip: _disabledReason('Transfer'),
          ),
          const SizedBox(height: 5),
          AttendanceActionItem(
            svgPath: MediaRes.Mark_absent,
            label: 'Absent',
            onTap: availability.absentEnabled ? onAbsent : null,
            isEnabled: availability.absentEnabled,
            disabledTooltip: _disabledReason('Absent'),
          ),
        ],
      ),
    );
  }
}

/// The activity-type fan-out shown when [StaffActionPanel]'s Activities
/// button is expanded.
class ActivitiesOptionsPanel extends StatelessWidget {
  const ActivitiesOptionsPanel({
    super.key,
    required this.activityIcons,
    this.onAnyActivityTap,
  });

  final Map<String, String> activityIcons;
  final VoidCallback? onAnyActivityTap;

  @override
  Widget build(BuildContext context) {
    final items = activityIcons.entries.toList();
    return Container(
      width: 70,
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromRGBO(111, 140, 255, 1)),
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.attendanceCardShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: ScrollController(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              ActivityPngItem(
                pngPath: items[i].value,
                label: _format(items[i].key),
                onTap: onAnyActivityTap,
              ),
              if (i < items.length - 1) const SizedBox(height: 5),
            ],
          ],
        ),
      ),
    );
  }

  String _format(String upper) =>
      upper.substring(0, 1) + upper.substring(1).toLowerCase();
}

class AttendanceActionItem extends StatelessWidget {
  const AttendanceActionItem({
    super.key,
    required this.svgPath,
    required this.label,
    this.onTap,
    this.isEnabled = true,
    this.disabledTooltip = '',
  });

  final String svgPath;
  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;
  final String disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final double opacity = isEnabled ? 1.0 : 0.45;
    return AppTooltip(
      message: !isEnabled ? disabledTooltip : '',
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.attendanceInfoHighlightColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(svgPath, height: 24, width: 24),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFonts.body,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.svgPath,
    required this.label,
    this.onTap,
    this.isSelected = false,
    this.isEnabled = true,
    this.disabledTooltip = '',
  });

  final String svgPath;
  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isEnabled;
  final String disabledTooltip;

  @override
  Widget build(BuildContext context) {
    final double opacity = isEnabled ? 1.0 : 0.5;
    return AppTooltip(
      message: !isEnabled ? disabledTooltip : '',
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: opacity,
          child: Column(
            children: [
              SvgPicture.asset(
                svgPath,
                height: 24,
                width: 24,
                colorFilter: const ColorFilter.mode(
                  AppColors.cardColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.cardColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityPngItem extends StatelessWidget {
  const ActivityPngItem({
    super.key,
    required this.pngPath,
    required this.label,
    this.onTap,
  });
  final String pngPath;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(pngPath, scale: 3.5),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: AppFonts.body,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
