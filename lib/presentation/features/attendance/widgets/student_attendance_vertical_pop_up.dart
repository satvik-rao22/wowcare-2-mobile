import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/app_tooltip.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';

typedef StudentAttendanceActionTap = void Function(String actionLabel);

class StudentAttendanceVerticalPopUp extends StatelessWidget {
  final List<dynamic> students;
  final VoidCallback refreshCallback;
  final StudentAttendanceActionTap? onActionTap;
  final Set<String> disabledActions;

  /// Optional per-action tooltip messages explaining why an action is
  /// disabled, keyed by action label ('Sign-in', 'Sign-Out', 'Transfer',
  /// 'Absent'). Shown when the user taps a disabled action.
  final Map<String, String> disabledReasons;
  final double? topPosition;
  final double? leftPosition;
  final double? rightPosition;
  final double? bottomPosition;

  const StudentAttendanceVerticalPopUp({
    super.key,
    required this.students,
    required this.refreshCallback,
    this.onActionTap,
    this.disabledActions = const <String>{},
    this.disabledReasons = const <String, String>{},
    this.topPosition,
    this.leftPosition,
    this.rightPosition,
    this.bottomPosition,
  });

  @override
  Widget build(BuildContext context) {
    // Check permission using the shared service
    final isStudentAttendanceAllowed =
        AttendancePermissionService.hasPermissionToManageStudentAttendance(context);
    final activeDisabledActions = Set<String>.from(disabledActions);
    final activeReasons = Map<String, String>.from(disabledReasons);
    if (!isStudentAttendanceAllowed) {
      // STAFF persona that has not completed self sign-in: block every action
      // and explain why. This reason takes precedence over status-based ones.
      for (final action in const ['Sign-in', 'Sign-Out', 'Transfer', 'Absent']) {
        activeDisabledActions.add(action);
        activeReasons[action] =
            AttendancePermissionService.staffSelfSignInRequiredMessage;
      }
    }

    // Use the shared GradientAddButton for consistent FAB styling.
    // Mirror the responsive sizing used in StaffScreen by deriving
    // tablet breakpoints from the current screen width.
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;
    final bool isLargeTablet = screenWidth >= 900;

    return GradientAddButton(
      onTap: () => _showActionMenu(context, activeDisabledActions, activeReasons),
      isTablet: isTablet,
      isLargeTablet: isLargeTablet,
    );
  }

  void _showActionMenu(
    BuildContext context,
    Set<String> activeDisabledActions,
    Map<String, String> activeReasons,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;
    final bool isLargeTablet = screenWidth >= 900;
    final double buttonSize = isLargeTablet ? 72.0 : (isTablet ? 56.0 : 40.0);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Pin to the top-right so the menu sits flush below the + button
          // instead of being vertically centered in the inset band.
          alignment: Alignment.topRight,
          insetPadding: EdgeInsets.only(
            top: (topPosition ?? 100) + buttonSize,
            left: leftPosition ?? MediaQuery.of(context).size.width * 0.75,
            right: rightPosition ?? 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: AppColors.buildPrimaryGradient(),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Container(
              width: 50,
              constraints: const BoxConstraints(maxHeight: 400),
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItem(context, MediaRes.Sign_in, 'Sign-in', activeDisabledActions, activeReasons),
                  const SizedBox(height: 5),
                  _buildMenuItem(context, MediaRes.Sign_out, 'Sign-Out', activeDisabledActions, activeReasons),
                  const SizedBox(height: 5),
                  _buildMenuItem(context, MediaRes.transfer, 'Transfer', activeDisabledActions, activeReasons),
                  const SizedBox(height: 5),
                  _buildMenuItem(context, MediaRes.Mark_absent, 'Absent', activeDisabledActions, activeReasons),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, String svgPath, String label, Set<String> activeDisabledActions, Map<String, String> activeReasons) {
    final isDisabled = activeDisabledActions.contains(label);
    final Widget item = InkWell(
      onTap: isDisabled
          ? null
          : () {
        Navigator.pop(context);
        if (onActionTap != null) {
          onActionTap!(label);
          return;
        }
        _navigateToForm(context, label);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Opacity(
            opacity: isDisabled ? 0.45 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
              child: SvgPicture.asset(svgPath, height: 24, width: 24),
            ),
          ),
          const SizedBox(height: 5),
          Opacity(
            opacity: isDisabled ? 0.5 : 1,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Manrope', color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );

    final reason = activeReasons[label];
    if (!isDisabled || reason == null || reason.isEmpty) {
      return item;
    }
    // Disabled action: tapping the greyed-out item reveals why it is blocked.
    return AppTooltip(message: reason, child: item);
  }

  void _navigateToForm(BuildContext context, String label) {
    Widget? form;
    
    switch (label) {
      case 'Sign-in':
        form = const StudentSelectionSignInForm();
        break;
      case 'Sign-Out':
        form = const StudentSelectionSignOutForm();
        break;
      case 'Transfer':
        form = const StudentSelectionTransferForm();
        break;
      case 'Absent':
        form = const StudentSelectionMarkAbsentForm();
        break;
    }

    if (form != null) {
      Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => form!),
      ).then((_) {
        refreshCallback();
      });
    }
  }
}
