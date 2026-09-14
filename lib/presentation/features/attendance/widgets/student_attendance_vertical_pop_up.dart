import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/student_selection_mark_absent_form.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/app_tooltip.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

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
    return BlocBuilder<GeofenceCubit, GeofenceState>(
      builder: (context, _) {
        return BlocBuilder<RoleCubit, RoleState>(
          builder: (context, _) {
            // Check permission using the shared service
            final isStudentAttendanceAllowed =
                AttendancePermissionService.hasPermissionToManageStudentAttendance(
                  context,
                );
            final activeDisabledActions = Set<String>.from(disabledActions);
            final activeReasons = Map<String, String>.from(disabledReasons);
            if (!isStudentAttendanceAllowed) {
              // STAFF persona that has not completed self sign-in: block
              // every action and explain why. This reason takes precedence
              // over status-based ones.
              for (final action in const [
                'Sign-in',
                'Sign-Out',
                'Transfer',
                'Absent',
              ]) {
                activeDisabledActions.add(action);
                activeReasons[action] =
                    AttendancePermissionService.staffSelfSignInRequiredMessage;
              }
            }

            // Use the shared GradientAddButton for consistent FAB styling.
            // Mirror the responsive sizing used in StaffScreen by deriving
            // tablet breakpoints from the current screen width.
            final bool isTablet = ResponsiveHelper(context).isTabletCompact;
            final bool isLargeTablet = ResponsiveHelper(context).isWide;

            return GradientAddButton(
              onTap: () => _showActionMenu(
                context,
                activeDisabledActions,
                activeReasons,
              ),
              isTablet: isTablet,
              isLargeTablet: isLargeTablet,
            );
          },
        );
      },
    );
  }

  void _showActionMenu(
    BuildContext context,
    Set<String> activeDisabledActions,
    Map<String, String> activeReasons,
  ) {
    final bool isTablet = ResponsiveHelper(context).isTabletCompact;
    final bool isLargeTablet = ResponsiveHelper(context).isWide;
    final double buttonSize = isLargeTablet ? 72.0 : (isTablet ? 56.0 : 40.0);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.transparentColor,
          elevation: 0,
          // Pin to the top-right so the menu sits flush below the + button
          // instead of being vertically centered in the inset band.
          alignment: Alignment.topRight,
          insetPadding: EdgeInsets.only(
            top: (topPosition ?? 100) + buttonSize,
            left: leftPosition ?? ResponsiveHelper(context).screenWidth * 0.75,
            right: rightPosition ?? 16,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s2),
            decoration: BoxDecoration(
              borderRadius: AppRadius.allMd,
              gradient: AppColors.buildPrimaryGradient(),
              boxShadow: [
                BoxShadow(
                  color: AppColors.attendanceCardShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              width: 50,
              constraints: BoxConstraints(
                // Upper bound only. The Column (mainAxisSize.min) sizes to its
                // content, so this must stay ABOVE the 4 items' height or the
                // last action ("Absent") gets cropped. The dialog's own bounds
                // (insetPadding.top) already handle the anchor offset, and the
                // scroll view below guards genuinely tiny screens.
                maxHeight: ResponsiveHelper(context).screenHeight * 0.9,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.r10),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StudentPopupMenuItem(
                      svgPath: MediaRes.Sign_in,
                      label: 'Sign-in',
                      isDisabled: activeDisabledActions.contains('Sign-in'),
                      disabledReason: activeReasons['Sign-in'],
                      onTap: () => _handleMenuItemTap(context, 'Sign-in'),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _StudentPopupMenuItem(
                      svgPath: MediaRes.Sign_out,
                      label: 'Sign-Out',
                      isDisabled: activeDisabledActions.contains('Sign-Out'),
                      disabledReason: activeReasons['Sign-Out'],
                      onTap: () => _handleMenuItemTap(context, 'Sign-Out'),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _StudentPopupMenuItem(
                      svgPath: MediaRes.transfer,
                      label: 'Transfer',
                      isDisabled: activeDisabledActions.contains('Transfer'),
                      disabledReason: activeReasons['Transfer'],
                      onTap: () => _handleMenuItemTap(context, 'Transfer'),
                    ),
                    const SizedBox(height: AppSpacing.s5),
                    _StudentPopupMenuItem(
                      svgPath: MediaRes.Mark_absent,
                      label: 'Absent',
                      isDisabled: activeDisabledActions.contains('Absent'),
                      disabledReason: activeReasons['Absent'],
                      onTap: () => _handleMenuItemTap(context, 'Absent'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleMenuItemTap(BuildContext context, String label) {
    Navigator.pop(context);
    if (onActionTap != null) {
      onActionTap!(label);
      return;
    }
    _navigateToForm(context, label);
  }

  void _navigateToForm(BuildContext context, String label) {
    if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
      context,
    )) {
      return;
    }

    String? path;

    switch (label) {
      case 'Sign-in':
        path = '/attendance/student-selection-sign-in';
        break;
      case 'Sign-Out':
        path = '/attendance/student-selection-sign-out';
        break;
      case 'Transfer':
        path = '/attendance/student-selection-transfer';
        break;
      case 'Absent':
        path = '/attendance/student-selection-mark-absent';
        break;
    }

    if (path != null) {
      context.push(path).then((_) {
        refreshCallback();
      });
    }
  }
}

class _StudentPopupMenuItem extends StatelessWidget {
  const _StudentPopupMenuItem({
    required this.svgPath,
    required this.label,
    required this.isDisabled,
    required this.disabledReason,
    required this.onTap,
  });

  final String svgPath;
  final String label;
  final bool isDisabled;
  final String? disabledReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget item = InkWell(
      onTap: isDisabled ? null : onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Opacity(
            opacity: isDisabled ? 0.45 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s5),
              decoration: BoxDecoration(
                color: AppColors.attendanceInfoHighlightColor,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                svgPath,
                height: AppDimensions.iconMd,
                width: AppDimensions.iconMd,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s5),
          Opacity(
            opacity: isDisabled ? 0.5 : 1,
            child: Text(label, maxLines: 1, style: AppTextStyles.body),
          ),
        ],
      ),
    );

    final reason = disabledReason;
    if (!isDisabled || reason == null || reason.isEmpty) {
      return item;
    }
    // Disabled action: tapping the greyed-out item reveals why it is blocked.
    return AppTooltip(message: reason, child: item);
  }
}
