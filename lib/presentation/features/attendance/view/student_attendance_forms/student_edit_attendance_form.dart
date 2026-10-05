import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_edit_form_widgets.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_card.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_edit_attendance_cubit.dart';

class StudentEditAttendanceForm extends StatefulWidget {
  const StudentEditAttendanceForm({
    super.key,
    required this.studentAttendance,
    required this.attendanceDate,
  });

  final StudentAttendanceCardData studentAttendance;
  final DateTime attendanceDate;

  @override
  State<StudentEditAttendanceForm> createState() =>
      _StudentEditAttendanceFormState();
}

class _StudentEditAttendanceFormState extends State<StudentEditAttendanceForm> {
  late final StudentEditAttendanceFormCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<StudentEditAttendanceFormCubit>();
    // ignore: discarded_futures
    _cubit.init(
      signInRaw: widget.studentAttendance.signInTime,
      signOutRaw: widget.studentAttendance.signOutTime,
      attendanceRecordCode: widget.studentAttendance.attendanceRecordCode,
      attendanceDate: widget.attendanceDate,
    );
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    _cubit.close();
    super.dispose();
  }

  void _handleCancel() {
    context.pop();
  }

  Future<void> _handleSubmit() async {
    final outcome = await _cubit.submit();
    if (!mounted) return;
    if (outcome.success) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(outcome.message ?? 'Attendance updated successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
      context.pop(true);
    } else {
      final message = outcome.error != null
          ? ApiErrorHandler.extractErrorMessage(outcome.error)
          : outcome.message;
      if (message == null) return; // noop (already submitting)
      // A future sign-in/out time is a correctable user mistake, not a system
      // failure — surface it as a yellow warning rather than a red error.
      final isFutureTimeWarning = message.toLowerCase().contains(
        'cannot be in the future',
      );
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(message),
          backgroundColor: isFutureTimeWarning
              ? AppColors.warningColor
              : AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentEditAttendanceFormCubit>.value(
      value: _cubit,
      child:
          BlocBuilder<
            StudentEditAttendanceFormCubit,
            StudentEditAttendanceState
          >(
            builder: (context, state) {
              final isTablet = ResponsiveHelper(context).isTabletCompact;
              final student = widget.studentAttendance;
              final titleName = student.studentName.isNotEmpty
                  ? student.studentName
                  : 'Student';

              return StaffFormLayout(
                title: "Edit $titleName's Attendance",
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AttendanceEditHeaderCard(
                        photoUuid: student.studentPhotoUuid,
                        name: student.studentName,
                        subtitle: student.roomName,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AttendanceEditTimeSection(
                        label: 'Sign-In Time',
                        time: state.signInTime,
                        onTimeChanged: _cubit.setSignInTime,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AttendanceEditTimeSection(
                        label: 'Sign-Out Time',
                        time: state.signOutTime,
                        onTimeChanged: _cubit.setSignOutTime,
                      ),
                    ],
                  ),
                ),
                bottomBar: CustomButtonLayout(
                  isForm: false,
                  onPressedCancel: _handleCancel,
                  onPressedConfirm: state.isSubmitting ? null : _handleSubmit,
                  confirmButtonLabel: 'Submit',
                ),
              );
            },
          ),
    );
  }
}
