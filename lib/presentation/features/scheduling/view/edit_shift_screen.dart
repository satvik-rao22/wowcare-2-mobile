import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:wowcare/app/di/di.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/edit_shift_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/scheduling_staff_list_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/no_schedule_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/shift_override_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_absent_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_no_availability_bottom_sheet.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Whether the Edit screen affects a single occurrence or every occurrence in
/// a recurring series. Drives the screen title and which PUT API is hit on
/// Save (`/api/v1/staff-shifts/{shiftCode}` vs
/// `/api/v1/staff-shifts/series/{seriesCode}`).
enum EditShiftMode { thisShift, entireSeries }

/// Edit form for an existing shift. All form state, validation and the dual-
/// mode update flow live in [EditShiftCubit]; this widget is a pure view over
/// that state. Mirrors [AddShiftScreen]'s validation rules end-to-end:
///   * shift end > shift start, break end > break start, break ⊂ shift
///   * shift + break within school hours
///   * staff-absence pre-check (single-day → hard block, recurring → strip
///     absent dates after save via the absent-days POST)
///   * staff has a work schedule for every targeted weekday (recurring →
///     hard-block sheet, single → soft prompt with `forceAdd`)
///   * shift time fits inside the staff's work-schedule window for the day
///     (recurring → hard-block sheet, single → inline red hint)
///   * time-aware conflict detection vs existing shifts on the same day
///     (always sends `overrideConflicts: true` so the prompt is just UX)
class EditShiftScreen extends StatelessWidget {
  const EditShiftScreen({
    super.key,
    required this.mode,
    required this.shiftCode,
    required this.staffCode,
    required this.classroomCode,
    required this.initialDate,
    required this.staff,
    required this.classroom,
    required this.shiftStart,
    required this.shiftEnd,
    this.seriesCode,
    this.breakStart,
    this.breakEnd,
    this.note,
    this.status = ShiftStatus.published,
    this.isPublished = true,
    this.selectedDays = const <String>{},
    this.untilDate,
    this.classrooms = const <String>[],
    this.staffOptions = const <String>[],
    this.onSave,
  });

  static const String routeName = '/edit-shift-screen';

  final EditShiftMode mode;
  final String shiftCode;
  final String? seriesCode;
  final String staffCode;
  final String classroomCode;
  final DateTime initialDate;
  final String staff;
  final String classroom;
  final TimeOfDay shiftStart;
  final TimeOfDay shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;
  final String? note;
  final ShiftStatus status;
  final bool isPublished;
  final Set<String> selectedDays;
  final DateTime? untilDate;
  final List<String> classrooms;
  final List<String> staffOptions;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EditShiftCubit>(
      create: (_) => serviceLocator<EditShiftCubit>()
        ..init(
          mode: mode,
          shiftCode: shiftCode,
          seriesCode: seriesCode,
          staffCode: staffCode,
          classroomCode: classroomCode,
          initialDate: initialDate,
          shiftStart: shiftStart,
          shiftEnd: shiftEnd,
          breakStart: breakStart,
          breakEnd: breakEnd,
          selectedDays: selectedDays,
          untilDate: untilDate,
          isPublished: isPublished,
        ),
      child: _EditShiftView(
        mode: mode,
        staffCode: staffCode,
        staffName: staff,
        classroomFallbackName: classroom,
        initialDate: initialDate,
        status: status,
        note: note,
        onSave: onSave,
      ),
    );
  }
}

class _EditShiftView extends StatefulWidget {
  const _EditShiftView({
    required this.mode,
    required this.staffCode,
    required this.staffName,
    required this.classroomFallbackName,
    required this.initialDate,
    required this.status,
    required this.note,
    required this.onSave,
  });

  final EditShiftMode mode;
  final String staffCode;
  final String staffName;
  final String classroomFallbackName;
  final DateTime initialDate;
  final ShiftStatus status;
  final String? note;
  final VoidCallback? onSave;

  @override
  State<_EditShiftView> createState() => _EditShiftViewState();
}

class _EditShiftViewState extends State<_EditShiftView> {
  late final TextEditingController _noteController = TextEditingController(
    text: widget.note ?? '',
  );

  bool get _isSeriesMode => widget.mode == EditShiftMode.entireSeries;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    final cubit = context.read<EditShiftCubit>();
    final staff = context.read<SchedulingStaffListCubit>().state.staff;

    if (!cubit.validate()) {
      final err = cubit.state.schoolHoursError;
      if (err != null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: err,
          isError: true,
        );
      }
      return;
    }

    final outcome = await cubit.save(
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
        message: 'Shift updated successfully',
        isSuccess: true,
      );
      widget.onSave?.call();
      Navigator.of(context).pop(true);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;
    final title = _isSeriesMode ? 'Edit entire series' : 'Edit this shift';

    return BlocBuilder<EditShiftCubit, EditShiftState>(
      builder: (context, state) {
        return BlocBuilder<ClassroomCubit, ClassroomState>(
          builder: (context, classroomState) {
            final cubit = context.read<EditShiftCubit>();
            final staffList = context
                .watch<SchedulingStaffListCubit>()
                .state
                .staff;

            final classroomCodeToName = cubit.classroomOptions(
              classrooms: classroomState.classrooms,
              staff: staffList,
            );
            final classroomNames = classroomCodeToName.values.toList(
              growable: false,
            );
            final selectedClassroomName =
                classroomCodeToName[state.selectedClassroomCode] ??
                widget.classroomFallbackName;

            final staffAvailabilityError = cubit.staffAvailabilityError(
              staffList,
            );

            return StaffFormLayout(
              title: title,
              bottomBar: Container(
                padding: EdgeInsets.only(
                  bottom: bottomPadding,
                  left: 16,
                  right: 16,
                  top: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                    topRight: Radius.circular(
                      responsive.isTablet ? 40.0 : 24.0,
                    ),
                  ),
                ),
                child: CustomButtonLayout(
                  confirmButtonLabel: state.saving ? 'Saving…' : 'Save',
                  onPressedConfirm: (cubit.isFormValid && !state.saving)
                      ? _onSave
                      : null,
                  showCancelButton: false,
                  isForm: false,
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildStatusHeader(responsive),
                  SizedBox(height: responsive.verticalSpacing),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDateField(
                          responsive,
                          label: 'Date',
                          date: state.date,
                          onDateSelected: cubit.setDate,
                        ),
                      ),
                      SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                      Expanded(
                        child: CustomDropdown(
                          label: 'Staff',
                          hintText: 'Select',
                          items: <String>[widget.staffName],
                          selectedItem: widget.staffName,
                          labelStyle: TextStyle(
                            fontSize: responsive.labelFontSize,
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff573353),
                          ),
                          showAsterisk: true,
                          labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                          onSelect: (_) {},
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
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w400,
                      color: const Color(0xff573353),
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
                        child: GradientTimePickerField(
                          label: 'Shift Start',
                          isRequired: true,
                          time: state.shiftStart,
                          errorText: state.shiftStartError,
                          onTimeSelected: cubit.setShiftStart,
                        ),
                      ),
                      SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                      Expanded(
                        child: GradientTimePickerField(
                          label: 'Shift End',
                          isRequired: true,
                          time: state.shiftEnd,
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
                        child: GradientTimePickerField(
                          label: 'Break Start',
                          time: state.breakStart,
                          errorText: state.breakStartError,
                          onTimeSelected: cubit.setBreakStart,
                          onClear: () => cubit.setBreakStart(null),
                        ),
                      ),
                      SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                      Expanded(
                        child: GradientTimePickerField(
                          label: 'Break End',
                          time: state.breakEnd,
                          errorText: state.breakEndError,
                          onTimeSelected: cubit.setBreakEnd,
                          onClear: () => cubit.setBreakEnd(null),
                        ),
                      ),
                    ],
                  ),
                  if (state.schoolHoursError != null)
                    CoreUtils.buildInlineFieldError(state.schoolHoursError),
                  if (staffAvailabilityError != null)
                    CoreUtils.buildInlineFieldError(staffAvailabilityError),
                  SizedBox(height: responsive.verticalSpacing),
                  if (_isSeriesMode) ...[
                    _buildRepeatHeader(responsive, state),
                    SizedBox(height: responsive.isTablet ? 16.0 : 12.0),
                    _buildDaysGrid(responsive, state),
                    if (state.daysError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        state.daysError!,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Manrope',
                        ),
                      ),
                    ],
                    SizedBox(height: responsive.verticalSpacing),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildPublishCheckbox(responsive, state),
                    ),
                    SizedBox(height: responsive.verticalSpacing),
                    _buildDateField(
                      responsive,
                      label: 'Until Date',
                      date: state.untilDate,
                      firstDate: state.date,
                      errorText: state.untilDateError,
                      onDateSelected: cubit.setUntilDate,
                    ),
                    SizedBox(height: responsive.verticalSpacing),
                    _buildNoteField(responsive),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildPublishCheckbox(responsive, state),
                    ),
                    SizedBox(height: responsive.verticalSpacing),
                    _buildNoteField(responsive),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusHeader(ResponsiveHelper responsive) {
    final formatted = DateFormat('MMM d, yyyy').format(widget.initialDate);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 8.0 : 4.0,
      ),
      child: Text(
        'Shift on $formatted (${widget.status.label})',
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: responsive.titleFontSize * 0.85,
          fontWeight: FontWeight.w600,
          color: const Color(0xff573353),
        ),
      ),
    );
  }

  Widget _buildDateField(
    ResponsiveHelper responsive, {
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onDateSelected,
    String? errorText,
    DateTime? firstDate,
  }) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.red),
              ),
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
              color: AppColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRepeatHeader(ResponsiveHelper responsive, EditShiftState state) {
    final cubit = context.read<EditShiftCubit>();
    return Row(
      children: [
        Text(
          'Repeat On',
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w500,
            color: const Color(0xff573353),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: cubit.toggleSelectAll,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: AppColors.primaryGradientColors,
            ).createShader(bounds),
            child: Text(
              state.selectedDays.length == state.availableWeekDays.length
                  ? 'Clear All'
                  : 'Select All',
              style: TextStyle(
                fontSize: responsive.labelFontSize,
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDaysGrid(ResponsiveHelper responsive, EditShiftState state) {
    final cubit = context.read<EditShiftCubit>();
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
                : AppColors.fieldbackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomCheckbox(
            value: isSelected,
            label: day,
            scale: 1.0,
            labelStyle: TextStyle(
              fontSize: responsive.isTablet ? 14.0 : 12.5,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
            onChanged: (val) => cubit.toggleDay(day, val ?? false),
          ),
        );
      },
    );
  }

  Widget _buildPublishCheckbox(
    ResponsiveHelper responsive,
    EditShiftState state,
  ) {
    final cubit = context.read<EditShiftCubit>();
    return CustomCheckbox(
      value: state.publish,
      label: 'Publish shift',
      scale: 1.0,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w500,
        color: const Color(0xff573353),
      ),
      onChanged: (val) => cubit.setPublish(val ?? false),
    );
  }

  Widget _buildNoteField(ResponsiveHelper responsive) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add Note', style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            minLines: 1,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: 'Eg. Please note the change in classroom location',
              hintStyle: labelStyle.copyWith(color: AppColors.grey),
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
