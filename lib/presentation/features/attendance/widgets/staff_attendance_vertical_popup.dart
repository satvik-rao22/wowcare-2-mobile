import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

typedef StaffAttendanceActionTap = void Function(String actionLabel);

class StaffAttendanceVerticalPopUp extends StatelessWidget {
  final List<dynamic> students;
  final VoidCallback refreshCallback;
  final StaffAttendanceActionTap? onActionTap;
  final Set<String> disabledActions;
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showActionMenu(context),
          child: const Icon(Icons.more_vert, color: Colors.white),
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.only(
            top: topPosition ?? 100,
            bottom: bottomPosition ?? MediaQuery.of(context).size.height * 0.45,
            left: leftPosition ?? MediaQuery.of(context).size.width * 0.75,
            right: rightPosition ?? 16,
          ),
          child: StaffAttendanceVerticalPopupOnly(
            students: students,
            refreshCallback: refreshCallback,
            onActionTap: onActionTap,
            disabledActions: disabledActions,
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
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: SvgPicture.asset(svgPath, height: 24, width: 24),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Manrope', color: AppColors.primaryColor),
          ),
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
    this.topPosition,
    this.leftPosition,
    this.rightPosition,
    this.bottomPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      constraints: const BoxConstraints(maxHeight: 400),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.classroomStudentTabColor, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(context, MediaRes.Sign_in, 'Sign-in'),
          const SizedBox(height: 5),
          _buildMenuItem(context, MediaRes.Sign_out, 'Sign-Out'),
          const SizedBox(height: 5),
          _buildMenuItem(context, MediaRes.transfer, 'Transfer'),
          const SizedBox(height: 5),
          _buildMenuItem(context, MediaRes.Mark_absent, 'Absent'),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String svgPath, String label) {
    final isDisabled = disabledActions.contains(label);
    return InkWell(
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
  }
}


