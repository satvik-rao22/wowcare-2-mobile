import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/dimensions.dart';
import 'package:wowcare/shared/common/widgets/app_tooltip.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

typedef StaffAttendanceActionTap = void Function(String actionLabel);

class StaffAttendanceVerticalPopUp extends StatelessWidget {
  final List<dynamic> students;
  final VoidCallback refreshCallback;
  final StaffAttendanceActionTap? onActionTap;
  final Set<String> disabledActions;

  /// Optional per-action tooltip messages explaining why an action is
  /// disabled, keyed by action label ('Sign-in', 'Sign-Out', 'Transfer',
  /// 'Absent'). Shown when the user taps a disabled action.
  final Map<String, String> disabledReasons;
  final double? topPosition;
  final double? leftPosition;
  final double? rightPosition;
  final double? bottomPosition;

  const StaffAttendanceVerticalPopUp({
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
    return SizedBox(
      height: 45,
      width: 45,
      child: Material(
        color: AppColors.primaryColor,
        borderRadius: AppRadius.allMd,
        child: InkWell(
          borderRadius: AppRadius.allMd,
          onTap: () => _showActionMenu(context),
          child: const Icon(Icons.more_vert, color: AppColors.cardColor),
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.transparentColor,
          elevation: 0,
          insetPadding: EdgeInsets.only(
            top: topPosition ?? 100,
            bottom:
                bottomPosition ?? ResponsiveHelper(context).screenHeight * 0.45,
            left: leftPosition ?? ResponsiveHelper(context).screenWidth * 0.75,
            right: rightPosition ?? 16,
          ),
          child: StaffAttendanceVerticalPopupOnly(
            students: students,
            refreshCallback: refreshCallback,
            onActionTap: onActionTap,
            disabledActions: disabledActions,
            disabledReasons: disabledReasons,
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, String svgPath, String label) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
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
          const SizedBox(height: AppSpacing.s5),
          Text(label, maxLines: 1, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class StaffAttendanceVerticalPopupOnly extends StatelessWidget {
  final List<dynamic> students;
  final VoidCallback refreshCallback;
  final StaffAttendanceActionTap? onActionTap;
  final Set<String> disabledActions;

  /// Optional per-action tooltip messages explaining why an action is
  /// disabled, keyed by action label ('Sign-in', 'Sign-Out', 'Transfer',
  /// 'Absent'). Shown when the user taps a disabled action.
  final Map<String, String> disabledReasons;
  final double? topPosition;
  final double? leftPosition;
  final double? rightPosition;
  final double? bottomPosition;

  const StaffAttendanceVerticalPopupOnly({
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
    return Container(
      width: 50,
      constraints: BoxConstraints(
        // Upper bound only. The Column (mainAxisSize.min) sizes to its content,
        // so this must stay ABOVE the 4 items' height or the last action
        // ("Absent") gets cropped. The scroll view guards tiny screens.
        maxHeight: ResponsiveHelper(context).screenHeight * 0.9,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: AppColors.classroomStudentTabColor,
          width: AppDimensions.borderThick,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.attendanceCardShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuItem(context, MediaRes.Sign_in, 'Sign-in'),
            const SizedBox(height: AppSpacing.s5),
            _buildMenuItem(context, MediaRes.Sign_out, 'Sign-Out'),
            const SizedBox(height: AppSpacing.s5),
            _buildMenuItem(context, MediaRes.transfer, 'Transfer'),
            const SizedBox(height: AppSpacing.s5),
            _buildMenuItem(context, MediaRes.Mark_absent, 'Absent'),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String svgPath, String label) {
    final isDisabled = disabledActions.contains(label);
    final Widget item = InkWell(
      onTap: isDisabled
          ? null
          : () {
              Navigator.pop(context);
              onActionTap?.call(label);
            },
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

    final reason = disabledReasons[label];
    if (!isDisabled || reason == null || reason.isEmpty) {
      return item;
    }
    // Disabled action: tapping the greyed-out item reveals why it is blocked.
    return AppTooltip(message: reason, child: item);
  }
}
