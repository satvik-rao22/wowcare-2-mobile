import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/scheduling/view/add_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/edit_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/publish_shifts_screen.dart';
import 'package:wowcare/presentation/features/scheduling/view/view_shift_screen.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/staff_day_schedule_calendar.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Staff Scheduling — single-day view with staff picker, profile summary,
/// hour totals, and day timeline. Staff dropdown is fed by [StaffCubit] (with
/// disk cache); pull-to-refresh re-pulls staff + classroom data. Shift list
/// remains placeholder until the shift-API cubit is wired in.
class StaffSchedulingScreen extends StatefulWidget {
  const StaffSchedulingScreen({super.key});

  static const String routeName = '/dashboard/staff-scheduling';

  @override
  State<StaffSchedulingScreen> createState() => _StaffSchedulingScreenState();
}

class _StaffSchedulingScreenState extends State<StaffSchedulingScreen> {
  DateTime _selectedDay = DateTime.now();
  String? _selectedStaffCode;

  static const String _availableHours = '45';
  static const String _scheduledHours = '35';
  static const String _unscheduledHours = '10';

  /// Placeholder shifts until the staff-shifts list integration lands.
  static const List<Shift> _placeholderShifts = [
    Shift(start: '07:00:00 AM', end: '05:30:00 PM', room: '1-Blue-D'),
    Shift(
      start: '12:00:00 PM',
      end: '12:30:00 PM',
      room: 'Lunch Break',
      isBreakShift: true,
    ),
  ];

  TimeOfDay _toTimeOfDay(String input) {
    final dt = DateFormat('hh:mm:ss a').parse(input);
    return TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  Future<void> _onRefresh() async {
    final staffCubit = context.read<StaffCubit>();
    final classroomCubit = context.read<ClassroomCubit>();
    await Future.wait<void>([
      staffCubit.refresh(),
      classroomCubit.loadActiveClassrooms(
        force: true,
        onlyTypeClassroom: false,
      ),
    ]);
  }

  StaffMember? _resolveSelectedStaff(List<StaffMember> staff) {
    if (_selectedStaffCode == null && staff.isNotEmpty) {
      _selectedStaffCode = staff.first.code;
    }
    if (_selectedStaffCode == null) return null;
    for (final s in staff) {
      if (s.code == _selectedStaffCode) return s;
    }
    return staff.isNotEmpty ? staff.first : null;
  }

  void _pushWithProviders(BuildContext context, Widget page) {
    final staffCubit = context.read<StaffCubit>();
    final classroomCubit = context.read<ClassroomCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider<StaffCubit>.value(value: staffCubit),
            BlocProvider<ClassroomCubit>.value(value: classroomCubit),
          ],
          child: page,
        ),
      ),
    );
  }

  void _openViewShift(Shift shift, String classroom, String staffName) {
    final shiftStart = _toTimeOfDay(shift.start);
    final shiftEnd = _toTimeOfDay(shift.end);
    _pushWithProviders(
      context,
      ViewShiftScreen(
        date: _selectedDay,
        staff: staffName,
        classroom: classroom,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        isRecurring: true,
        onEditThis: () => _openEditShift(
          EditShiftMode.thisShift,
          classroom: classroom,
          staffName: staffName,
          shiftStart: shiftStart,
          shiftEnd: shiftEnd,
        ),
        onEditSeries: () => _openEditShift(
          EditShiftMode.entireSeries,
          classroom: classroom,
          staffName: staffName,
          shiftStart: shiftStart,
          shiftEnd: shiftEnd,
        ),
      ),
    );
  }

  void _openEditShift(
    EditShiftMode mode, {
    required String classroom,
    required String staffName,
    required TimeOfDay shiftStart,
    required TimeOfDay shiftEnd,
  }) {
    _pushWithProviders(
      context,
      EditShiftScreen(
        mode: mode,
        initialDate: _selectedDay,
        staff: staffName,
        classroom: classroom,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffCubit, StaffState>(
      builder: (context, staffState) {
        return BlocBuilder<ClassroomCubit, ClassroomState>(
          builder: (context, classroomState) {
            final staff = staffState.items;
            final selectedStaff = _resolveSelectedStaff(staff);
            final staffNames =
                staff.map((s) => s.name).toList(growable: false);
            final selectedName = selectedStaff?.name;

            final classroomCodeToName = <String, String>{
              for (final c in classroomState.classrooms) c.code: c.name,
            };
            final primaryClassroomName = selectedStaff != null
                ? (classroomCodeToName[selectedStaff.primaryClassroomCode] ??
                    selectedStaff.primaryClassroomName)
                : '';

            final dayColumnLabel =
                DateFormat('EEE, MMM d').format(_selectedDay);

            return GlobalScaffold(
              hasBackButton: true,
              body: CustomRefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateHeaderRow(
                        selectedDay: _selectedDay,
                        staffNames: staffNames,
                        initialPublishStaff: selectedName,
                        onPreviousDay: () => setState(
                          () => _selectedDay = _selectedDay.subtract(
                            const Duration(days: 1),
                          ),
                        ),
                        onNextDay: () => setState(
                          () => _selectedDay = _selectedDay.add(
                            const Duration(days: 1),
                          ),
                        ),
                        onAddTap: () => _pushWithProviders(
                          context,
                          AddShiftScreen(
                            initialDate: _selectedDay,
                            initialStaffCode: selectedStaff?.code,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0x19162831),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomDropdown(
                          hintText: staffNames.isEmpty
                              ? 'No staff available'
                              : 'Select Staff',
                          items: staffNames,
                          selectedItem: selectedName,
                          fieldHeight: 44,
                          onSelect: (name) {
                            final found = staff.firstWhere(
                              (s) => s.name == name,
                              orElse: () => const StaffMember(
                                code: '',
                                name: '',
                                primaryClassroomCode: '',
                                allowedClassroomCodes: <String>[],
                                designation: '',
                                phoneNumber: '',
                                status: '',
                                email: '',
                              ),
                            );
                            setState(() {
                              _selectedStaffCode =
                                  found.code.isEmpty ? null : found.code;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (selectedStaff != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.1),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StaffProfileHeader(
                                staffName: selectedStaff.name,
                                designation: selectedStaff.designation,
                                classroom: primaryClassroomName,
                              ),
                              const SizedBox(height: 16),
                              const ShiftHoursTile(
                                bgColor: Color.fromRGBO(255, 250, 234, 1),
                                label: 'Available Hours',
                                hours: _availableHours,
                                icon: MediaRes.availableHoursIcon,
                              ),
                              const SizedBox(height: 16),
                              const ShiftHoursTile(
                                bgColor: Color.fromRGBO(234, 255, 250, 1),
                                label: 'Scheduled Hours',
                                hours: _scheduledHours,
                                icon: MediaRes.scheduledHoursIcon,
                              ),
                              const SizedBox(height: 16),
                              const ShiftHoursTile(
                                bgColor: Color.fromRGBO(22, 40, 49, 0.01),
                                label: 'Unscheduled Hours',
                                hours: _unscheduledHours,
                                icon: MediaRes.unScheduledHoursIcon,
                              ),
                              const SizedBox(height: 20),
                              StaffDayScheduleCalendar(
                                key: ValueKey(
                                  '${selectedStaff.code}_${dayColumnLabel}_$_selectedDay',
                                ),
                                dayColumnLabel: dayColumnLabel,
                                dailyRoomSchedule: const DailyShifts(
                                  shifts: _placeholderShifts,
                                ),
                                onShiftTap: (shift) => _openViewShift(
                                  shift,
                                  primaryClassroomName,
                                  selectedStaff.name,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
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
    required this.onAddTap,
    this.staffNames = const <String>[],
    this.initialPublishStaff,
  });

  final DateTime selectedDay;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
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
    required this.staffName,
    required this.designation,
    required this.classroom,
  });

  final String staffName;
  final String designation;
  final String classroom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            DocumentImageWidget(
              fileUuid: staffName,
              name: staffName,
              size: 80,
              fontSize: 28,
              disableProfileLookupFallback: true,
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
