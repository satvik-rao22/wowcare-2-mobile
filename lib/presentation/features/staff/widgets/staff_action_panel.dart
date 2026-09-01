import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_attendance_action_availability.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_action_panel_options.dart';

enum StaffPanelType { attendance, activities, none }

class StaffActionPanel extends StatefulWidget {
  const StaffActionPanel({
    super.key,
    required this.currentPanel,
    this.onAttendanceTap,
    this.onActivitiesTap,
    this.onMessageTap,
    this.onProfileTap,
    this.onClearSelections,
    this.onSignIn,
    this.onSignOut,
    this.onTransfer,
    this.onAbsent,
    this.showMessage = true,
    this.isProfileEnabled = false,
    this.activitiesEnabled = true,
    this.attendanceAvailability = StaffAttendanceActionAvailability.allEnabled,
  });

  final StaffPanelType currentPanel;
  final VoidCallback? onAttendanceTap;
  final VoidCallback? onActivitiesTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onClearSelections;
  final VoidCallback? onSignIn;
  final VoidCallback? onSignOut;
  final VoidCallback? onTransfer;
  final VoidCallback? onAbsent;
  final bool showMessage;
  final bool isProfileEnabled;
  final bool activitiesEnabled;

  /// Enables/disables attendance sub-actions (Sign-In, Sign-Out, Transfer, Absent)
  /// from the current selection's attendance state.
  final StaffAttendanceActionAvailability attendanceAvailability;

  @override
  State<StaffActionPanel> createState() => _StaffActionPanelState();
}

class _StaffActionPanelState extends State<StaffActionPanel> {
  final ValueNotifier<StaffPanelType> _current = ValueNotifier(
    StaffPanelType.none,
  );

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }

  final Map<String, String> _activityIcons = const {
    'NAP START': MediaRes.napActivityIcon,
    'NAP END': MediaRes.napActivityIcon,
    'BATHROOM': MediaRes.bathroomActivityIcon,
    'BOTTLE': MediaRes.bottleActivityIcon,
    'MEAL': MediaRes.mealActivityIcon,
    'INCIDENT': MediaRes.incidentActivityIcon,
    'PHOTO': MediaRes.photoVideoActivityIcon,
    'MEDICATION': MediaRes.medicationActivityIcon,
    'NOTES': MediaRes.notesActivityIcon,
    'OUTDOOR': MediaRes.outdoorActivityIcon,
    'LEARNING': MediaRes.learningActivityIcon,
  };

  void _toggleAttendancePanel() {
    _current.value = _current.value == StaffPanelType.attendance
        ? StaffPanelType.none
        : StaffPanelType.attendance;
    widget.onAttendanceTap?.call();
  }

  void _toggleActivitiesPanel() {
    if (!widget.activitiesEnabled) return;
    _current.value = _current.value == StaffPanelType.activities
        ? StaffPanelType.none
        : StaffPanelType.activities;
    widget.onActivitiesTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StaffPanelType>(
      valueListenable: _current,
      builder: (context, current, _) {
        final bool showActivitiesPanel =
            widget.activitiesEnabled && current == StaffPanelType.activities;
        final bool showExpandedPanel =
            current == StaffPanelType.attendance || showActivitiesPanel;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showExpandedPanel)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: current == StaffPanelType.attendance
                    ? AttendanceOptionsPanel(
                        onSignIn: widget.onSignIn,
                        onSignOut: widget.onSignOut,
                        onTransfer: widget.onTransfer,
                        onAbsent: widget.onAbsent,
                        availability: widget.attendanceAvailability,
                      )
                    : ActivitiesOptionsPanel(
                        activityIcons: _activityIcons,
                        onAnyActivityTap: widget.onActivitiesTap,
                      ),
              ),
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Material(
                  borderRadius: BorderRadius.circular(10),
                  elevation: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
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
                        ActionButton(
                          svgPath: MediaRes.attendance_panel_icon,
                          label: 'Attendance',
                          onTap: _toggleAttendancePanel,
                          isSelected: current == StaffPanelType.attendance,
                        ),
                        if (widget.activitiesEnabled) ...[
                          const SizedBox(height: 20),
                          ActionButton(
                            svgPath: MediaRes.activity_panel_icon,
                            label: 'Activities',
                            onTap: _toggleActivitiesPanel,
                            isSelected: current == StaffPanelType.activities,
                          ),
                        ],
                        if (widget.showMessage) ...[
                          const SizedBox(height: 20),
                          ActionButton(
                            svgPath: MediaRes.message_panel_icon,
                            label: 'Message',
                            onTap: widget.onMessageTap,
                          ),
                        ],
                        const SizedBox(height: 20),
                        ActionButton(
                          svgPath: MediaRes.profile_panel_icon,
                          label: 'Profile',
                          onTap: widget.isProfileEnabled
                              ? widget.onProfileTap
                              : null,
                          isEnabled: widget.isProfileEnabled,
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
                          color: AppColors.blackColor.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: AppColors.transparentColor,
                      child: InkWell(
                        onTap: () {
                          _current.value = StaffPanelType.none;
                          widget.onClearSelections?.call();
                        },
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.close,
                            color: AppColors.cardColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
