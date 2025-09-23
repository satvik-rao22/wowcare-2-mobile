import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

enum StaffPanelType { attendance, activities, none }

class StaffActionPanel extends StatelessWidget {
  const StaffActionPanel({
    super.key,
    required this.currentPanel,
    this.onAttendanceTap,
    this.onActivitiesTap,
    this.onMessageTap,
    this.onProfileTap,
    this.onClearSelections,
    this.isProfileEnabled = false,
    this.activitiesEnabled = true,
  });

  final StaffPanelType currentPanel;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onActivitiesTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onClearSelections;
  final bool isProfileEnabled;
  final bool activitiesEnabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Material(
          borderRadius: BorderRadius.circular(10),
          elevation: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              gradient: AppColors.buildPrimaryGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  svgPath: MediaRes.attendance_panel_icon,
                  label: 'Attendance',
                  onTap: onAttendanceTap,
                  isSelected: currentPanel == StaffPanelType.attendance,
                ),
                // const SizedBox(height: 20),
                // _ActionButton(
                //   svgPath: MediaRes.activity_panel_icon,
                //   label: 'Activities',
                //   onTap: activitiesEnabled ? onActivitiesTap : null,
                //   isSelected: currentPanel == StaffPanelType.activities,
                //   isEnabled: activitiesEnabled,
                //   disabledTooltip: 'Select applicable items to mark an activity',
                // ),
                const SizedBox(height: 20),
                _ActionButton(
                  svgPath: MediaRes.message_panel_icon,
                  label: 'Message',
                  onTap: onMessageTap,
                ),
                const SizedBox(height: 20),
                _ActionButton(
                  svgPath: MediaRes.profile_panel_icon,
                  label: 'Profile',
                  onTap: isProfileEnabled ? onProfileTap : null,
                  isEnabled: isProfileEnabled,
                  disabledTooltip: 'Select only one to view profile',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, 15),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color.fromRGBO(156, 132, 255, 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onClearSelections,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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
    return Tooltip(
      message: !isEnabled ? disabledTooltip : '',
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      showDuration: const Duration(seconds: 5),
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
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
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


