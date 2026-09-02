import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_remove_tile.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_mark_absent_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_redirect.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

// StudentEntity / TagEntity now live in the form's cubit library; re-export
// them so existing callers that import this form keep resolving the types.
export 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_mark_absent_cubit.dart'
    show StudentEntity, TagEntity;

class StudentMarkAbsentForm extends StatefulWidget {
  const StudentMarkAbsentForm({
    super.key,
    required this.students,
    this.refreshCallback,
    this.popOnSuccess = false,
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;
  // When true, pops back to the caller after a successful submission instead of
  // pushAndRemoveUntil → StudentAttendanceTabbedView. Set by callers that live
  // outside the Attendance tab (e.g. the Classroom Students card).
  final bool popOnSuccess;

  @override
  State<StudentMarkAbsentForm> createState() => _StudentMarkAbsentFormState();
}

class _StudentMarkAbsentFormState extends State<StudentMarkAbsentForm> {
  late final StudentMarkAbsentFormCubit _cubit;
  final TextEditingController _reasonController = TextEditingController();
  final Map<String, TextEditingController> notesControllers = {};

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<StudentMarkAbsentFormCubit>();
    for (var student in widget.students) {
      notesControllers[student.studentCode] = TextEditingController();
    }
    _cubit.init(widget.students);
  }

  void _removeStudent(StudentEntity student) {
    notesControllers[student.studentCode]?.dispose();
    notesControllers.remove(student.studentCode);
    _cubit.removeStudent(student);
  }

  @override
  void dispose() {
    for (var controller in notesControllers.values) {
      controller.dispose();
    }
    _reasonController.dispose();
    // ignore: discarded_futures
    _cubit.close();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final notes = <String, String>{
      for (final entry in notesControllers.entries) entry.key: entry.value.text,
    };
    final outcome = await _cubit.submit(
      reason: _reasonController.text,
      notes: notes,
    );
    if (!mounted) return;
    switch (outcome.success) {
      case true:
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: SnackBar(
            content: Text(outcome.message ?? 'Marked Absent successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
        if (widget.popOnSuccess) {
          widget.refreshCallback?.call();
          Navigator.of(context).pop();
        } else {
          redirectToAttendanceDaily(
            context,
            StudentAttendanceTabbedView.routeName,
          );
        }
      case false:
        final message = outcome.error != null
            ? ApiErrorHandler.extractErrorMessage(outcome.error)
            : outcome.message;
        // `noop` (submit already in flight) carries no message — stay silent.
        if (message == null) return;
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: SnackBar(
            content: Text(message),
            backgroundColor: AppColors.warningColor,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentMarkAbsentFormCubit>.value(
      value: _cubit,
      child: BlocListener<StudentMarkAbsentFormCubit, StudentMarkAbsentState>(
        // Pop the form once the last student has been removed.
        listenWhen: (prev, curr) =>
            prev.students.isNotEmpty && curr.students.isEmpty,
        listener: (context, _) => Navigator.pop(context),
        child: BlocBuilder<StudentMarkAbsentFormCubit, StudentMarkAbsentState>(
          builder: (context, state) {
            if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
              context,
            )) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Access Denied: You must be inside geofence and signed in to manage student attendance.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.errorColor,
                      ),
                    ),
                  ),
                ),
              );
            }

            final currentStudents = state.students;
            return StaffFormLayout(
              title: 'Mark Absent',
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText.label('Start Date'),
                              const SizedBox(height: AppSpacing.xs),
                              CustomDateTimeField(
                                hasLabel: false,
                                isRangePicker: false,
                                isTime: false,
                                fetchInitialTime: false,
                                initialDate: state.startDate,
                                isDisabled:
                                    !(state.isStaffAdminPersona ?? false),
                                onDateSelected: _cubit.selectStartDate,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText.label('End Date'),
                              const SizedBox(height: AppSpacing.xs),
                              CustomDateTimeField(
                                hasLabel: false,
                                isRangePicker: false,
                                isTime: false,
                                fetchInitialTime: false,
                                initialDate: state.endDate,
                                isDisabled:
                                    !(state.isStaffAdminPersona ?? false),
                                onDateSelected: _cubit.selectEndDate,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: currentStudents.length,
                      itemBuilder: (context, index) {
                        final student = currentStudents[index];

                        return Column(
                          children: [
                            AttendanceRemoveTile(
                              name: student.fullName,
                              photoUuid: student.photoUuid ?? '',
                              onRemove: () => _removeStudent(student),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextField(
                              controller: notesControllers[student.studentCode],
                              decoration: InputDecoration(
                                hintText: 'Enter Absent Notes',
                                hintStyle: AppTextStyles.body.copyWith(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 15,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.r10,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorderColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.r10,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorderColor,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.r10,
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.inputBorderColor,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.r10,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.errorColor,
                                    width: 1,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.r10,
                                  ),
                                  borderSide: const BorderSide(
                                    color: AppColors.errorColor,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.cardColor,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              bottomBar: CustomButtonLayout(
                confirmButtonLabel: 'Submit',
                onPressedConfirm: _handleSubmit,
                showCancelButton: false,
                isLoading: state.isSubmitting,
              ),
            );
          },
        ),
      ),
    );
  }
}
