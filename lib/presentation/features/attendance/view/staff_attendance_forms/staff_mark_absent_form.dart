import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_remove_tile.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/view_model/staff_mark_absent_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import '../../model/staff_entity.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_redirect.dart';

class StaffMarkAbsentForm extends StatefulWidget {
  const StaffMarkAbsentForm({
    super.key,
    this.staff,
    this.staffList,
    this.popOnSuccess = false,
  });

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;

  /// When true, pops back to the caller after a successful submission instead
  /// of redirecting to the Attendance daily tab. Set by callers that live
  /// outside the Attendance tab (e.g. the Staff attendance profile) so the
  /// user stays on the screen they started from.
  final bool popOnSuccess;

  static const String routeName = '/staff-mark-absent-form';

  @override
  State<StaffMarkAbsentForm> createState() => _StaffMarkAbsentFormState();
}

class _StaffMarkAbsentFormState extends State<StaffMarkAbsentForm> {
  late final StaffMarkAbsentFormCubit _cubit;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // RoleCubit's active persona is the canonical, persona-switch-aware
    // signal for admin-vs-staff — passed in here since the cubit itself has
    // no BuildContext (see cubit's init() doc).
    final isStaffAdminPersona = !context.read<RoleCubit>().isStaff;
    _cubit = serviceLocator<StaffMarkAbsentFormCubit>()
      ..init(
        staff: widget.staff,
        staffList: widget.staffList,
        isStaffAdminPersona: isStaffAdminPersona,
      );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _typeController.dispose();
    // ignore: discarded_futures
    _cubit.close();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final outcome = await _cubit.submit(
      reason: '',
      type: _typeController.text,
      notes: _notesController.text,
    );
    if (!mounted) return;
    if (outcome.success) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(outcome.message ?? 'Marked Absent successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
      if (outcome.returnToTabbedView && !widget.popOnSuccess) {
        redirectToAttendanceDaily(context, StaffAttendanceTabbedView.routeName);
      } else if (mounted) {
        // Teacher/staff persona, or a caller that owns its own screen: no
        // forced navigation — stay on whatever screen this action was
        // started from.
        Navigator.of(context).maybePop();
      }
    } else {
      final message = outcome.error != null
          ? ApiErrorHandler.extractErrorMessage(outcome.error)
          : outcome.message;
      // `noop` (already submitting / empty selection) carries no message.
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
    return BlocProvider<StaffMarkAbsentFormCubit>.value(
      value: _cubit,
      child: BlocListener<StaffMarkAbsentFormCubit, StaffMarkAbsentState>(
        // Pop the form once the last staff member has been removed.
        listenWhen: (prev, curr) =>
            prev.selectedStaff.isNotEmpty && curr.selectedStaff.isEmpty,
        listener: (context, _) => Navigator.pop(context),
        child: BlocBuilder<StaffMarkAbsentFormCubit, StaffMarkAbsentState>(
          builder: (context, state) {
            return StaffFormLayout(
              title: 'Mark Absent',
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
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
                                    state.isStaffAdminPersona != true ||
                                    state.isSelfTarget,
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
                                    state.isStaffAdminPersona != true ||
                                    state.isSelfTarget,
                                onDateSelected: _cubit.selectEndDate,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (state.selectedStaff.isNotEmpty) ...[
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 3.5,
                            ),
                        itemCount: state.selectedStaff.length,
                        itemBuilder: (context, index) => AttendanceRemoveTile(
                          name: state.selectedStaff[index].name,
                          photoUuid: state.selectedStaff[index].photoUuid ?? '',
                          staffCode: state.selectedStaff[index].staffCode,
                          canRemove: state.selectedStaff.length > 1,
                          onRemove: () =>
                              _cubit.removeStaff(state.selectedStaff[index]),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          hintText: 'Enter Absent Notes',
                          hintStyle: AppTextStyles.body.copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 15,
                          ),
                          border: AppSurfaces.fieldBorder(radius: AppRadius.r10),
                          enabledBorder: AppSurfaces.fieldBorder(radius: AppRadius.r10),
                          focusedBorder: AppSurfaces.fieldBorder(radius: AppRadius.r10),
                          errorBorder: AppSurfaces.fieldBorder(radius: AppRadius.r10, colour: AppPalette.statusError),
                          focusedErrorBorder: AppSurfaces.fieldBorder(radius: AppRadius.r10, colour: AppPalette.statusError),
                          filled: true,
                          fillColor: AppSurfaces.fieldFill,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
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
