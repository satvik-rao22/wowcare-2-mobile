import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/add_shift_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/no_schedule_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/shift_override_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_absent_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_no_availability_bottom_sheet.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_responsive.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

/// Add Shift form. All form state, validation and the create flow live in
/// [AddShiftCubit]; this widget is a pure view over that state. It stays a
/// `StatefulWidget` only to own the note `TextEditingController` and to drive
/// the one-shot build-time prefill — there is no `setState` here.
class AddShiftScreen extends StatelessWidget {
  const AddShiftScreen({
    super.key,
    this.initialDate,
    this.initialClassroomCode,
    this.initialStaffCode,
    this.initialShiftStart,
    this.initialShiftEnd,
    this.initialPublish = false,
    this.prefillStaff = true,
  });

  static const String routeName = '/add-shift-screen';

  final DateTime? initialDate;
  final String? initialClassroomCode;
  final String? initialStaffCode;
  final TimeOfDay? initialShiftStart;
  final TimeOfDay? initialShiftEnd;

  /// When true, the "Publish shift" checkbox starts checked.
  final bool initialPublish;

  /// When false, staff is not pre-selected and work/break times are not
  /// auto-filled until the user picks a staff member (staff scheduling flow).
  final bool prefillStaff;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddShiftCubit>(
      create: (_) => serviceLocator<AddShiftCubit>()
        ..init(
          initialDate: initialDate,
          initialClassroomCode: initialClassroomCode,
          initialStaffCode: initialStaffCode,
          initialShiftStart: initialShiftStart,
          initialShiftEnd: initialShiftEnd,
          initialPublish: initialPublish,
          prefillStaff: prefillStaff,
        ),
      child: _AddShiftView(prefillStaff: prefillStaff),
    );
  }
}

class _AddShiftView extends StatefulWidget {
  const _AddShiftView({required this.prefillStaff});

  final bool prefillStaff;

  @override
  State<_AddShiftView> createState() => _AddShiftViewState();
}

class _AddShiftViewState extends State<_AddShiftView> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _onConfirm() async {
    final cubit = context.read<AddShiftCubit>();
    final staff = context.read<SchedulingStaffListCubit>().state.staff;

    if (!cubit.validate()) {
      final err = cubit.state.schoolHoursError;
      if (err != null) {
        CoreUtils.showTopSnackBar(context: context, message: err, isError: true);
      }
      return;
    }

    final outcome = await cubit.submit(
      staff: staff,
      notes: _noteController.text,
      onAbsentBlock: (absentDate) async {
        if (!mounted) return;
        await StaffAbsentBottomSheet.show(context, absentDate);
      },
      onNoScheduleConfirm: () async {
        if (!mounted) return false;
        return NoScheduleBottomSheet.show(context);
      },
      onNoAvailability: () async {
        if (!mounted) return;
        await StaffNoAvailabilityBottomSheet.show(context);
      },
      onConflictConfirm: (conflicts) async {
        if (!mounted) return false;
        return ShiftOverrideBottomSheet.show(context, conflictDates: conflicts);
      },
    );

    if (!mounted) return;
    if (outcome.errorMessage != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: outcome.errorMessage!,
        isError: true,
      );
    } else if (outcome.success) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: outcome.created
            ? 'Shift saved successfully'
            : 'No new shifts were created',
        isSuccess: true,
      );
      Navigator.of(context).pop(true);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final responsive = SchedulingResponsive(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;

    return BlocBuilder<AddShiftCubit, AddShiftState>(
      builder: (context, state) {
        return BlocBuilder<SchedulingStaffListCubit, SchedulingStaffListState>(
          builder: (context, staffState) {
            return BlocBuilder<ClassroomCubit, ClassroomState>(
              builder: (context, classroomState) {
                final cubit = context.read<AddShiftCubit>();
                final staff = staffState.staff;
                final selectedStaff =
                    cubit.findStaff(state.selectedStaffCode, staff);

                // Initial prefill for the case where `initialStaffCode` was
                // supplied via the constructor but the staff cubit hadn't
                // loaded its data yet at init time. Fires once per
                // (staffCode + date) combo.
                if (widget.prefillStaff &&
                    selectedStaff != null &&
                    cubit.shouldPrefillFor(selectedStaff)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    cubit.prefillTimesFromSchedule(selectedStaff);
                  });
                }

                final staffCodeToName = <String, String>{
                  for (final s in staff) s.code: s.name,
                };
                final staffNames =
                    staffCodeToName.values.toList(growable: false);
                final selectedStaffName =
                    staffCodeToName[state.selectedStaffCode];

                final classroomCodeToName = cubit.classroomOptions(
                  classrooms: classroomState.classrooms,
                  selectedStaff: selectedStaff,
                );
                final classroomNames =
                    classroomCodeToName.values.toList(growable: false);
                final selectedClassroomName =
                    classroomCodeToName[state.selectedClassroomCode];

                final staffAvailabilityError =
                    cubit.staffAvailabilityError(staff);

                return StaffFormLayout(
                  title: 'Add Shift',
                  bottomBar: Container(
                    padding: EdgeInsets.only(
                      bottom: bottomPadding,
                      left: 16,
                      right: 16,
                      top: 8,
                    ),
                    decoration: AppSurfaces.card(borderRadius: BorderRadius.only( topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0), topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0), )),
                    child: CustomButtonLayout(
                      confirmButtonLabel: state.saving ? 'Saving…' : 'Confirm',
                      onPressedConfirm:
                          (state.isFormValid && !state.saving) ? _onConfirm : null,
                      showCancelButton: false,
                      isForm: false,
                    ),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // PRD: Date on the left, Staff on the right; classroom below.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDateField(
                              responsive,
                              label: 'Date',
                              date: state.date,
                              onDateSelected: (d) =>
                                  cubit.setDate(d, selectedStaff: selectedStaff),
                            ),
                          ),
                          SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                          Expanded(
                            child: CustomDropdown(
                              label: 'Staff',
                              hintText: 'Select',
                              items: staffNames,
                              selectedItem: selectedStaffName,
                              labelStyle: TextStyle(
                                fontSize: responsive.labelFontSize,
                                fontWeight: FontWeight.w400,
                                color: AppColors.primaryColor,
                              ),
                              showAsterisk: true,
                              labelBottomSpacing:
                                  responsive.isTablet ? 8.0 : 6.0,
                              onSelect: (name) {
                                final code = staffCodeToName.entries
                                    .firstWhere(
                                      (e) => e.value == name,
                                      orElse: () =>
                                          const MapEntry<String, String>('', ''),
                                    )
                                    .key;
                                cubit.onStaffSelected(
                                  code.isEmpty ? null : code,
                                  staff,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.verticalSpacing),
                      CustomDropdown(
                        label: 'Classroom',
                        hintText: 'Select',
                        items: classroomNames,
                        selectedItem: selectedClassroomName,
                        labelStyle: TextStyle(
                          fontSize: responsive.labelFontSize,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primaryColor,
                        ),
                        showAsterisk: true,
                        labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                        onSelect: (name) {
                          final code = classroomCodeToName.entries
                              .firstWhere(
                                (e) => e.value == name,
                                orElse: () =>
                                    const MapEntry<String, String>('', ''),
                              )
                              .key;
                          cubit.setClassroom(code.isEmpty ? null : code);
                        },
                      ),
                      SizedBox(height: responsive.verticalSpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomDateTimeField(
                              isTime: true,
                              label: 'Shift Start',
                              isRequired: true,
                              initialTime: state.shiftStart,
                              errorText: state.shiftStartError,
                              onTimeSelected: cubit.setShiftStart,
                            ),
                          ),
                          SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                          Expanded(
                            child: CustomDateTimeField(
                              isTime: true,
                              label: 'Shift End',
                              isRequired: true,
                              initialTime: state.shiftEnd,
                              errorText: state.shiftEndError,
                              onTimeSelected: cubit.setShiftEnd,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.verticalSpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomDateTimeField(
                              isTime: true,
                              label: 'Break Start',
                              initialTime: state.breakStart,
                              errorText: state.breakStartError,
                              onTimeSelected: cubit.setBreakStart,
                              onClear: () => cubit.setBreakStart(null),
                            ),
                          ),
                          SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                          Expanded(
                            child: CustomDateTimeField(
                              isTime: true,
                              label: 'Break End',
                              initialTime: state.breakEnd,
                              errorText: state.breakEndError,
                              onTimeSelected: cubit.setBreakEnd,
                              onClear: () => cubit.setBreakEnd(null),
                            ),
                          ),
                        ],
                      ),
                      if (state.noScheduleForSelectedDate)
                        CoreUtils.buildInlineFieldError(
                          'No schedule available for the selected date.',
                        ),
                      if (state.schoolHoursError != null)
                        CoreUtils.buildInlineFieldError(state.schoolHoursError),
                      if (staffAvailabilityError != null)
                        CoreUtils.buildInlineFieldError(staffAvailabilityError),
                      SizedBox(height: responsive.verticalSpacing),
                      _buildRepeatHeader(responsive, state),
                      SizedBox(height: responsive.isTablet ? 16.0 : 12.0),
                      if (state.repeatOn) ...[
                        _buildDaysGrid(responsive, state),
                        if (state.daysError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            state.daysError!,
                            style: const TextStyle(
                              color: MaterialHues.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        SizedBox(height: responsive.verticalSpacing),
                        _buildDateField(
                          responsive,
                          label: 'Until Date',
                          date: state.untilDate,
                          errorText: state.untilDateError,
                          firstDate: state.date,
                          onDateSelected: cubit.setUntilDate,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _buildPublishCheckbox(responsive, state),
                      ),
                      SizedBox(height: responsive.verticalSpacing),
                      _buildNoteField(responsive),
                      const SizedBox(height: 12),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDateField(
    SchedulingResponsive responsive, {
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onDateSelected,
    String? errorText,
    DateTime? firstDate,
  }) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: MaterialHues.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        CustomDateTimeField(
          key: ValueKey('$label-${date?.toIso8601String() ?? 'empty'}'),
          hasLabel: false,
          fetchInitialTime: false,
          initialDate: date,
          firstDate: firstDate,
          onDateSelected: onDateSelected,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: MaterialHues.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRepeatHeader(SchedulingResponsive responsive, AddShiftState state) {
    final cubit = context.read<AddShiftCubit>();
    return Row(
      children: [
        CustomToggle(
          label: 'Repeat On',
          isToggled: state.repeatOn,
          onToggle: cubit.toggleRepeat,
          labelOnLeftSide: true,
          labelStyle: TextStyle(
            fontSize: responsive.labelFontSize,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
        const Spacer(),
        if (state.repeatOn)
          GestureDetector(
            onTap: cubit.toggleSelectAll,
            child: Text(
                state.selectedDays.length == state.availableWeekDays.length
                    ? 'Clear All'
                    : 'Select All',
                style: TextStyle(
                  fontSize: responsive.labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.themeColor,
                ),
              ),
          ),
      ],
    );
  }

  Widget _buildDaysGrid(SchedulingResponsive responsive, AddShiftState state) {
    final cubit = context.read<AddShiftCubit>();
    final days = state.availableWeekDays;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: responsive.isTablet ? 16.0 : 8.0,
        mainAxisSpacing: responsive.isTablet ? 16.0 : 10.0,
        childAspectRatio: responsive.isTablet ? 4.0 : 3.2,
      ),
      itemBuilder: (context, index) {
        final day = days[index];
        final isSelected = state.selectedDays.contains(day);
        return Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.themeColor.withValues(alpha: 0.12)
                : AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomCheckbox(
            value: isSelected,
            label: day,
            scale: 1.0,
            labelStyle: TextStyle(
              fontSize: responsive.isTablet ? 14.0 : 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
            onChanged: (val) => cubit.toggleDay(day, val ?? false),
          ),
        );
      },
    );
  }

  Widget _buildPublishCheckbox(SchedulingResponsive responsive, AddShiftState state) {
    final cubit = context.read<AddShiftCubit>();
    return CustomCheckbox(
      value: state.publish,
      label: 'Publish shift',
      scale: 1.0,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryColor,
      ),
      onChanged: (val) => cubit.setPublish(val ?? false),
    );
  }

  Widget _buildNoteField(SchedulingResponsive responsive) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Note', style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: responsive.inputFieldHeight,
          ),
          decoration: AppSurfaces.field(radius: responsive.isTablet ? 12.0 : 8.0),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: 'Write a note',
              hintStyle: labelStyle.copyWith(color: MaterialHues.grey500),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
