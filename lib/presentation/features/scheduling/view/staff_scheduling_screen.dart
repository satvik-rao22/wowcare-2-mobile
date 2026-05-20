import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/scheduling/usecases/get_staff_shift_by_code_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_shift.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/views/filters/designation_display_utils.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/staff_scheduling_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/view/add_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/edit_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/publish_shifts_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_day_schedule_calendar.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_scheduling_staff_dropdown.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Staff Scheduling — single-day view with staff picker, profile summary,
/// hour totals, and day timeline. Staff dropdown is fed by [StaffCubit] (with
/// disk cache); pull-to-refresh re-pulls staff + classroom data. Shift list
/// remains placeholder until the shift-API cubit is wired in.
class StaffSchedulingScreen extends StatelessWidget {
  const StaffSchedulingScreen({super.key});

  static const String routeName = '/dashboard/staff-scheduling';

  @override
  Widget build(BuildContext context) {
    return const _StaffSchedulingView();
  }
}

class _StaffSchedulingView extends StatelessWidget {
  const _StaffSchedulingView();

  void _openAddShiftScreen(
    BuildContext context,
    StaffSchedulingState state,
  ) {
    final staffCubit = context.read<StaffCubit>();
    final classroomCubit = context.read<ClassroomCubit>();
    final selectedCode = state.selectedStaff?.code;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<StaffCubit>.value(value: staffCubit),
            BlocProvider<ClassroomCubit>.value(value: classroomCubit),
          ],
          child: AddShiftScreen(
            initialDate: state.selectedDay,
            initialStaffCode: selectedCode,
          ),
        ),
      ),
    );
  }

  List<Shift> _shiftsFromSummary(StaffShiftDaySummary summary) {
    return summary.blocks
        .map(
          (b) => Shift(
            start: b.start,
            end: b.end,
            room: b.room,
            isBreakShift: b.isBreak,
            shiftCode: b.shiftCode,
          ),
        )
        .toList();
  }

  /// Parses `"hh:mm:ss a"` (the format used by `StaffShiftTimelineBlock`) into
  /// `TimeOfDay`. Returns null on any parse failure.
  TimeOfDay? _parseClockTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(' ');
    if (parts.length < 2) return null;
    final timePart = parts[0];
    final marker = parts[1].toUpperCase();
    final segments = timePart.split(':');
    if (segments.length < 2) return null;
    var hour = int.tryParse(segments[0]);
    final minute = int.tryParse(segments[1]);
    if (hour == null || minute == null) return null;
    final isPm = marker == 'PM';
    final isAm = marker == 'AM';
    if (!isAm && !isPm) return null;
    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _openViewShiftScreen(
    BuildContext context,
    StaffSchedulingState state,
    Shift tappedShift,
  ) async {
    final navigator = Navigator.of(context);
    final shiftCode = tappedShift.shiftCode.trim();
    if (shiftCode.isEmpty) {
      // Fallback for legacy/mocked blocks that don't carry a shiftCode —
      // open the view screen with whatever the timeline block had.
      _pushViewShiftFromBlock(navigator, state, tappedShift);
      return;
    }

    try {
      final shift =
          await serviceLocator<GetStaffShiftByCodeUseCase>()(shiftCode);
      if (!context.mounted) return;
      final classroomName = shift.classroomName.trim().isNotEmpty
          ? shift.classroomName
          : (state.classroomNamesByCode[shift.classroomCode] ??
              shift.classroomCode);
      final staffName = shift.staffName.trim().isNotEmpty
          ? shift.staffName
          : (state.selectedStaff?.name ?? '');
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => ViewShiftScreen(
            date: shift.shiftDate,
            staff: staffName,
            classroom: classroomName,
            shiftStart: shift.startTime,
            shiftEnd: shift.endTime,
            breakStart: shift.breakStartTime,
            breakEnd: shift.breakEndTime,
            note: shift.notes,
            status: shift.isPublished
                ? ShiftStatus.published
                : ShiftStatus.draft,
            isRecurring: shift.isRecurring,
            onEditThis: () => _openEditShiftScreen(
              context,
              state,
              shiftCode,
              EditShiftMode.thisShift,
            ),
            onEditSeries: () => _openEditShiftScreen(
              context,
              state,
              shiftCode,
              EditShiftMode.entireSeries,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  /// Same prefetch pattern as [_openViewShiftScreen] — fires
  /// `GET /api/v1/staff-shifts/{shiftCode}` so the Edit form lands with the
  /// freshest server-side data and not whatever was on screen in View.
  Future<void> _openEditShiftScreen(
    BuildContext context,
    StaffSchedulingState state,
    String shiftCode,
    EditShiftMode mode,
  ) async {
    final navigator = Navigator.of(context);
    try {
      final shift =
          await serviceLocator<GetStaffShiftByCodeUseCase>()(shiftCode);
      if (!context.mounted) return;
      final classroomName = shift.classroomName.trim().isNotEmpty
          ? shift.classroomName
          : (state.classroomNamesByCode[shift.classroomCode] ??
              shift.classroomCode);
      final staffName = shift.staffName.trim().isNotEmpty
          ? shift.staffName
          : (state.selectedStaff?.name ?? '');
      const dayNameByIndex = <int, String>{
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      };
      final selectedDays = <String>{
        for (final d in shift.seriesRecurrenceDays)
          if (dayNameByIndex[d] != null) dayNameByIndex[d]!,
      };
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => EditShiftScreen(
            mode: mode,
            initialDate: shift.shiftDate,
            staff: staffName,
            classroom: classroomName,
            shiftStart: shift.startTime,
            shiftEnd: shift.endTime,
            breakStart: shift.breakStartTime,
            breakEnd: shift.breakEndTime,
            note: shift.notes,
            status: shift.isPublished
                ? ShiftStatus.published
                : ShiftStatus.draft,
            isPublished: shift.isPublished,
            selectedDays: selectedDays,
            untilDate: shift.seriesEndDate,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    }
  }

  void _pushViewShiftFromBlock(
    NavigatorState navigator,
    StaffSchedulingState state,
    Shift tappedShift,
  ) {
    final start = _parseClockTime(tappedShift.start);
    final end = _parseClockTime(tappedShift.end);
    if (start == null || end == null) return;

    TimeOfDay? breakStart;
    TimeOfDay? breakEnd;
    final shiftStartMin = start.hour * 60 + start.minute;
    final shiftEndMin = end.hour * 60 + end.minute;
    for (final block in state.shiftSummary.blocks) {
      if (!block.isBreak) continue;
      final bs = _parseClockTime(block.start);
      final be = _parseClockTime(block.end);
      if (bs == null || be == null) continue;
      final bsMin = bs.hour * 60 + bs.minute;
      final beMin = be.hour * 60 + be.minute;
      if (bsMin >= shiftStartMin && beMin <= shiftEndMin) {
        breakStart = bs;
        breakEnd = be;
        break;
      }
    }

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ViewShiftScreen(
          date: state.selectedDay,
          staff: state.selectedStaff?.name ?? '',
          classroom: tappedShift.room,
          shiftStart: start,
          shiftEnd: end,
          breakStart: breakStart,
          breakEnd: breakEnd,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffSchedulingCubit, StaffSchedulingState>(
      builder: (context, state) {
        final cubit = context.read<StaffSchedulingCubit>();
        final staff = state.selectedStaff;
        final dayColumnLabel =
            DateFormat('EEE, MMM d').format(state.selectedDay);
        final calendarShifts = _shiftsFromSummary(state.shiftSummary);
        // Keep the shimmer up until the very first load attempt has settled,
        // OR while the staff list is being (re)loaded with nothing to show.
        // This avoids briefly flashing the "Select a staff" empty state before
        // `loadInitial()` flips the loading flag on.
        final isInitialLoad = !state.hasAttemptedInitialLoad ||
            (state.isLoadingStaff && state.staffList.isEmpty);
        final isProfileLoading = state.isLoadingStaff ||
            state.isLoadingShifts ||
            state.isLoadingSchoolHours;

        return GlobalScaffold(
          hasBackButton: true,
          body: CustomRefreshIndicator(
            onRefresh: cubit.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateHeaderRow(
                    selectedDay: state.selectedDay,
                    staffNames: state.staffDropdownNames,
                    initialPublishStaff: state.selectedStaffDropdownLabel,
                    onDatePicked: cubit.selectDay,
                    onAddTap: () => _openAddShiftScreen(context, state),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: AppColors.errorColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0x19162831)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: StaffSchedulingStaffDropdown(
                      staffNames: state.staffDropdownNames,
                      selectedStaffName: state.selectedStaffDropdownLabel,
                      isLoading: state.isLoadingStaff,
                      onSelected: cubit.selectStaffByName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isInitialLoad)
                    const StaffSchedulingShimmer()
                  else if (staff != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StaffProfileHeader(
                            staffCode: staff.code,
                            staffName: staff.name,
                            designation: formatDesignationForDisplay(
                              staff.designation,
                            ),
                            classroom:
                                state.classroomResolver.resolveForStaff(staff),
                            profilePhotoAssetCode: staff.profilePhotoAssetCode,
                          ),
                          const SizedBox(height: 16),
                          if (isProfileLoading)
                            const StaffShiftsBodyShimmer()
                          else ...[
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(255, 250, 234, 1),
                              label: 'Available Hours',
                              hours: '${state.shiftSummary.availableHours}',
                              icon: MediaRes.availableHoursIcon,
                            ),
                            const SizedBox(height: 16),
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(234, 255, 250, 1),
                              label: 'Scheduled Hours',
                              hours: '${state.shiftSummary.scheduledHours}',
                              icon: MediaRes.scheduledHoursIcon,
                            ),
                            const SizedBox(height: 16),
                            ShiftHoursTile(
                              bgColor: const Color.fromRGBO(22, 40, 49, 0.01),
                              label: 'Unscheduled Hours',
                              hours: '${state.shiftSummary.unscheduledHours}',
                              icon: MediaRes.unScheduledHoursIcon,
                            ),
                            const SizedBox(height: 20),
                            if (!state.hasSchoolHoursForDay)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No school hours configured for this day.',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: AppColors.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              StaffDayScheduleCalendar(
                                key: ValueKey(
                                  '${staff.code}_${dayColumnLabel}_'
                                  '${state.schoolStartTime}_${state.schoolEndTime}_'
                                  '${state.classroomNamesByCode.length}',
                                ),
                                dayColumnLabel: dayColumnLabel,
                                schoolStartTime: state.schoolStartTime!,
                                schoolEndTime: state.schoolEndTime!,
                                classroomResolver: state.classroomResolver,
                                dailyRoomSchedule:
                                    DailyShifts(shifts: calendarShifts),
                                onShiftTap: (shift) => _openViewShiftScreen(
                                  context,
                                  state,
                                  shift,
                                ),
                              ),
                          ],
                        ],
                      ),
                    )
                  else if (!state.isLoadingStaff)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Select a staff member to view their schedule.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.primaryColor,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DateHeaderRow extends StatelessWidget {
  const _DateHeaderRow({
    required this.selectedDay,
    required this.onDatePicked,
    required this.onAddTap,
    this.staffNames = const <String>[],
    this.initialPublishStaff,
  });

  final DateTime selectedDay;
  final ValueChanged<DateTime> onDatePicked;
  final VoidCallback onAddTap;
  final List<String> staffNames;
  final String? initialPublishStaff;

  Future<void> _openPublishScreen(BuildContext context) async {
    await Navigator.of(context).push<PublishShiftsResult>(
      MaterialPageRoute<PublishShiftsResult>(
        builder: (_) => PublishShiftsScreen(
          staff: staffNames,
          initialStaff: initialPublishStaff,
          initialUntilDate: selectedDay,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CustomDateTimeField(
            key: ValueKey(selectedDay.toIso8601String()),
            hasLabel: false,
            fetchInitialTime: false,
            initialDate: selectedDay,
            onDateSelected: onDatePicked,
          ),
        ),
        const SizedBox(width: 8),
        GradientAddButton(onTap: onAddTap),
        const SizedBox(width: 8),
        _GradientPublishButton(onTap: () => _openPublishScreen(context)),
      ],
    );
  }
}

class _GradientPublishButton extends StatelessWidget {
  const _GradientPublishButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const height = 40.0;
    const borderRadius = 8.0;

    final child = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: AppColors.buildPrimaryGradient(),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'Publish',
        style: TextStyle(
          fontFamily: 'Manrope',
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onTap == null) return child;

    return GestureDetector(onTap: onTap, child: child);
  }
}

class _StaffProfileHeader extends StatelessWidget {
  const _StaffProfileHeader({
    required this.staffCode,
    required this.staffName,
    required this.designation,
    required this.classroom,
    this.profilePhotoAssetCode,
  });

  final String staffCode;
  final String staffName;
  final String designation;
  final String classroom;
  final String? profilePhotoAssetCode;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            DocumentImageWidget(
              fileUuid: staffCode,
              name: staffName,
              mediaAssetCode: profilePhotoAssetCode,
              staffCode: staffCode,
              size: 80,
              fontSize: 28,
              disableProfileLookupFallback: profilePhotoAssetCode != null &&
                  profilePhotoAssetCode!.isNotEmpty,
              disableAttendanceStatusLookup: true,
            ),
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 177, 21, 1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staffName,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.primaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (designation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  designation,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
              ],
              if (classroom.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  classroom,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
