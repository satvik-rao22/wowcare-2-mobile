import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_transfer_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_mark_absent_form.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';

typedef StudentAttendanceActionTap = void Function(String actionLabel);

class StudentAttendanceVerticalPopUp extends StatelessWidget {
  final List<dynamic> students;
  final VoidCallback refreshCallback;
  final StudentAttendanceActionTap? onActionTap;
  final Set<String> disabledActions;
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
    this.topPosition,
    this.leftPosition,
    this.rightPosition,
    this.bottomPosition,
  });

  @override
  Widget build(BuildContext context) {
    // Use the shared GradientAddButton for consistent FAB styling.
    // Mirror the responsive sizing used in StaffScreen by deriving
    // tablet breakpoints from the current screen width.
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;
    final bool isLargeTablet = screenWidth >= 900;

    return GradientAddButton(
      onTap: () => _showActionMenu(context),
      isTablet: isTablet,
      isLargeTablet: isLargeTablet,
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
          child: Container(
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
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, String svgPath, String label) {
    final isDisabled = disabledActions.contains(label);
    return InkWell(
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
