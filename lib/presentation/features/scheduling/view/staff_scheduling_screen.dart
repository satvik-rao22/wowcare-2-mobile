import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/staff/entities/staff_shift.dart';
import 'package:wowcare/presentation/features/classrooom/views/filters/designation_display_utils.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/staff_scheduling_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_day_schedule_calendar.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Staff Scheduling — single-day view with staff picker, profile summary,
/// hour totals, and day timeline backed by staff list + staff-shifts APIs.
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

  List<Shift> _shiftsFromSummary(StaffShiftDaySummary summary) {
    return summary.blocks
        .map(
          (b) => Shift(
            start: b.start,
            end: b.end,
            room: b.room,
            isBreakShift: b.isBreak,
          ),
        )
        .toList();
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
                    onPreviousDay: () => cubit.shiftSelectedDay(-1),
                    onNextDay: () => cubit.shiftSelectedDay(1),
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
                    child: state.isLoadingStaff
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: PrimaryCircularLoader()),
                          )
                        : CustomDropdown(
                            hintText: 'Select Staff',
                            items: state.staffDropdownNames,
                            selectedItem: state.selectedStaffDropdownLabel,
                            fieldHeight: 44,
                            prependHintAsSelectableItem: false,
                            onSelect: cubit.selectStaffByName,
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (staff != null)
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
                            classroom: staff.displayClassroomName,
                            profilePhotoAssetCode: staff.profilePhotoAssetCode,
                          ),
                          const SizedBox(height: 16),
                          if (state.isLoadingShifts)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: PrimaryCircularLoader()),
                            )
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
                            if (state.isLoadingSchoolHours)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: PrimaryCircularLoader(),
                                ),
                              )
                            else if (!state.hasSchoolHoursForDay)
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
                                  '${state.schoolStartTime}_${state.schoolEndTime}',
                                ),
                                dayColumnLabel: dayColumnLabel,
                                schoolStartTime: state.schoolStartTime!,
                                schoolEndTime: state.schoolEndTime!,
                                dailyRoomSchedule:
                                    DailyShifts(shifts: calendarShifts),
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
    required this.onPreviousDay,
    required this.onNextDay,
  });

  final DateTime selectedDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;

  static const Color _chevronColor = Color(0xFF9C84FF);

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE, MMM d').format(selectedDay);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onPreviousDay,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                Icons.chevron_left,
                color: _chevronColor,
                size: 24,
              ),
            ),
            Text(
              formattedDate,
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.primaryColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: onNextDay,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                Icons.chevron_right,
                color: _chevronColor,
                size: 24,
              ),
            ),
          ],
        ),
        const Spacer(),
        GradientAddButton(onTap: () {}),
        const SizedBox(width: 8),
        _GradientPublishButton(onTap: () {}),
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
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      designation,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      classroom,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
