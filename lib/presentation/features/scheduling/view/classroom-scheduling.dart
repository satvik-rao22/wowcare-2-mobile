import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import '../../../../app/theme/colors.dart';
import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../cubit/staff_scheduling_cubit.dart';
import '../cubit/staff_scheduling_state.dart';
import '../model/classroom-schudle-model.dart';
import '../model/staff_model.dart';
import '../widgets/schedule_card.dart';
import '../widgets/expandable_schedule_card.dart';
import 'add-schedule.dart';
import 'classroom/classroom-view.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../app/di/di.dart';
import '../../classroom/cubit/classroom_cubit.dart';
import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import 'package:intl/intl.dart';

class SchedulingScreen extends StatefulWidget {
  const SchedulingScreen({super.key});

  static const String routeName = '/scheduling';

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  String _classroomNameForCode(
    String code,
    StaffSchedulingLoaded state,
    ClassroomState classroomState,
  ) {
    if (code.trim().isEmpty || code == '-') return '-';

    final fromAllClassrooms = state.allClassrooms
        .where((c) => (c['classroomCode'] ?? c['code']) == code)
        .firstOrNull;

    final nameFromAllClassrooms =
        (fromAllClassrooms?['classroomName'] ?? fromAllClassrooms?['name'])
            ?.toString();
    if (nameFromAllClassrooms != null &&
        nameFromAllClassrooms.trim().isNotEmpty) {
      return nameFromAllClassrooms;
    }

    final fromCubit = classroomState.classrooms
        .where((c) => c.code == code)
        .firstOrNull;
    final cubitName = fromCubit?.name;
    if (cubitName != null && cubitName.trim().isNotEmpty) {
      return cubitName;
    }

    return code;
  }

  void _openFirstClassroomForDailyView(
    BuildContext context,
    StaffSchedulingLoaded state,
    ClassroomState classroomState,
  ) {
    if (state.staffShifts.isEmpty) return;

    final selectedDate = DateFormat(
      'yyyy-MM-dd',
    ).format(state.selectedDate ?? DateTime.now());

    final targetShift =
        state.staffShifts
            .where((s) => s.shiftDate == selectedDate)
            .firstOrNull ??
        state.staffShifts.first;

    final classroomName = _classroomNameForCode(
      targetShift.classroomCode,
      state,
      classroomState,
    );

    Navigator.pushNamed(
      context,
      ClassroomViewScreen.routeName,
      arguments: ClassroomViewArgs(
        classroomCode: targetShift.classroomCode,
        classroomName: classroomName,
        date: targetShift.shiftDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => StaffSchedulingCubit(
            serviceLocator<StaffSchedulingRepository>(),
            serviceLocator<StorageService>(),
          ),
        ),
        BlocProvider(
          create: (context) =>
              serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
        ),
      ],
      child: GlobalScaffold(
        // hasBackButton: true,
        body: BlocBuilder<StaffSchedulingCubit, StaffSchedulingState>(
          builder: (context, state) {
            if (state is StaffSchedulingLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 Header Row
                    Row(
                      children: [
                        // Date Navigator
                        Expanded(
                          child: Container(
                            height: 48,

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  color: AppColors.colorBox3,
                                  onPressed: () {
                                    final current =
                                        state.selectedDate ?? DateTime.now();
                                    final newDate = state.isDailyView
                                        ? current.subtract(
                                            const Duration(days: 1),
                                          )
                                        : current.subtract(
                                            const Duration(days: 7),
                                          );
                                    context
                                        .read<StaffSchedulingCubit>()
                                        .changeDateAndMode(
                                          date: newDate,
                                          isDaily: state.isDailyView,
                                        );
                                  },
                                ),
                                Expanded(
                                  child: state.isDailyView
                                      ? Text(
                                          DateFormat('EEE, MMM dd').format(
                                            state.selectedDate ??
                                                DateTime.now(),
                                          ),
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            "${DateFormat('MMM dd').format((state.selectedDate ?? DateTime.now()).subtract(Duration(days: (state.selectedDate ?? DateTime.now()).weekday - 1)))}"
                                            " - "
                                            "${DateFormat('MMM dd').format((state.selectedDate ?? DateTime.now()).add(Duration(days: 7 - (state.selectedDate ?? DateTime.now()).weekday)))}",
                                            maxLines: 1,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  color: AppColors.colorBox3,
                                  onPressed: () {
                                    final current =
                                        state.selectedDate ?? DateTime.now();
                                    final newDate = state.isDailyView
                                        ? current.add(const Duration(days: 1))
                                        : current.add(const Duration(days: 7));
                                    context
                                        .read<StaffSchedulingCubit>()
                                        .changeDateAndMode(
                                          date: newDate,
                                          isDaily: state.isDailyView,
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // View mode toggle
                        Container(
                          // padding: const EdgeInsets.symmetric(horizontal: 8),
                          width: MediaQuery.sizeOf(context).width * 0.24,
                          child: CustomDropdown(
                            hintText: 'Select View',
                            prependHintAsSelectableItem: false,
                            selectedItem: state.isDailyView
                                ? 'Daily'
                                : 'Weekly',
                            items: const ['Daily', 'Weekly'],
                            fieldHeight: 36,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            selectedTextStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                            popupItemTextStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            onSelect: (value) {
                              if (value == null) return;

                              final bool isDaily = value == 'Daily View';

                              context
                                  .read<StaffSchedulingCubit>()
                                  .changeDateAndMode(
                                    date: state.selectedDate ?? DateTime.now(),
                                    isDaily: isDaily,
                                  );

                              final classroomState = context
                                  .read<ClassroomCubit>()
                                  .state;

                              if (isDaily && !state.isDailyView) {
                                _openFirstClassroomForDailyView(
                                  context,
                                  state,
                                  classroomState,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        GradientAddButton(
                          onTap: () async {
                            Navigator.pushNamed(
                              context,
                              AddShiftScreen.routeName,
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// 🔹 Filters
                    const ScheduleCard(),

                    const SizedBox(height: 16),

                    BlocBuilder<ClassroomCubit, ClassroomState>(
                      builder: (context, classroomState) {
                        if (state.staffShifts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                "No shifts found for this date range.",
                              ),
                            ),
                          );
                        }

                        // Determine Date Range for Card Title
                        String dateRangeTitle = "Weekly Schedule";
                        if (state.isDailyView) {
                          dateRangeTitle = DateFormat(
                            'EE, MMM dd',
                          ).format(state.selectedDate ?? DateTime.now());
                        } else if (state.staffShifts.isNotEmpty) {
                          final sortedDates =
                              state.staffShifts
                                  .map((s) => s.shiftDate)
                                  .toSet()
                                  .toList()
                                ..sort();
                          try {
                            final firstDt = DateTime.parse(sortedDates.first);
                            final lastDt = DateTime.parse(sortedDates.last);
                            final format = DateFormat('MMM dd');
                            dateRangeTitle =
                                '${format.format(firstDt)} - ${format.format(lastDt)}';
                          } catch (_) {}
                        }

                        // Map to handle missing class
                        final Map<String, List<StaffShiftEntity>>
                        shiftsByClassroom = {};
                        for (var shift in state.staffShifts) {
                          shiftsByClassroom
                              .putIfAbsent(shift.classroomCode, () => [])
                              .add(shift);
                        }

                        final classroomsWithShifts = shiftsByClassroom.keys.map((
                          code,
                        ) {
                          final classroomName = _classroomNameForCode(
                            code,
                            state,
                            classroomState,
                          );

                          final classroomShifts = shiftsByClassroom[code]!;

                          // Sort shifts by date and time
                          classroomShifts.sort((a, b) {
                            int cmp = a.shiftDate.compareTo(b.shiftDate);
                            if (cmp == 0)
                              return a.startTime.compareTo(b.startTime);
                            return cmp;
                          });

                          final mappedStaff = classroomShifts.map((shift) {
                            String formatTime(String timeStr) {
                              try {
                                final parts = timeStr.split(':');
                                if (parts.length >= 2) {
                                  final dt = DateTime(
                                    2026,
                                    1,
                                    1,
                                    int.parse(parts[0]),
                                    int.parse(parts[1]),
                                  );
                                  return DateFormat('hh:mm a').format(dt);
                                }
                              } catch (_) {}
                              return timeStr;
                            }

                            // --- STATUS COLOR LOGIC ---
                            Color? statusColor;
                            if (state.isDailyView) {
                              try {
                                final now = DateTime.now();
                                final shiftDt = DateTime.parse(shift.shiftDate);

                                if (shiftDt.year == now.year &&
                                    shiftDt.month == now.month &&
                                    shiftDt.day == now.day) {
                                  DateTime? parseTime(String t) {
                                    final p = t.split(':');
                                    if (p.length >= 2) {
                                      return DateTime(
                                        now.year,
                                        now.month,
                                        now.day,
                                        int.parse(p[0]),
                                        int.parse(p[1]),
                                      );
                                    }
                                    return null;
                                  }

                                  final st = parseTime(shift.startTime);
                                  final et = parseTime(shift.endTime);
                                  final bst = shift.breakStartTime!.isNotEmpty
                                      ? parseTime(shift.breakStartTime!)
                                      : null;
                                  final bet = shift.breakEndTime!.isNotEmpty
                                      ? parseTime(shift.breakEndTime!)
                                      : null;

                                  if (st != null &&
                                      et != null &&
                                      now.isAfter(st) &&
                                      now.isBefore(et)) {
                                    if (bst != null &&
                                        bet != null &&
                                        now.isAfter(bst) &&
                                        now.isBefore(bet)) {
                                      statusColor = Colors.red; // Break
                                    } else {
                                      statusColor = Colors.green; // Working
                                    }
                                  } else {
                                    statusColor = Colors.blue; // Scheduled
                                  }
                                } else {
                                  statusColor = Colors.blue;
                                }
                              } catch (_) {
                                statusColor = Colors.blue;
                              }
                            }
                            // --------------------------

                            return StaffModel(
                              name:
                                  '${shift.staffFirstName} ${shift.staffLastName}'
                                      .trim(),
                              image: DocumentImageWidget(fileUuid: shift.image),
                              workedHours: shift.scheduledHours.toInt(),
                              totalHours:
                                  (shift.scheduledHours +
                                          shift.unscheduledHours)
                                      .toInt(),
                              shift:
                                  '${formatTime(shift.startTime)} - ${formatTime(shift.endTime)}',
                              statusColor: statusColor,
                              shiftDate: shift.shiftDate,
                            );
                          }).toList();

                          return ClassroomSchedule(
                            title: classroomName,
                            classroomCode: code,
                            staffList: mappedStaff,
                            showWarning: false,
                            isExpanded: state.isDailyView || state.expandAll,
                            classroomName: classroomName,
                          );
                        }).toList();

                        if (classroomsWithShifts.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        // Single Card for the whole week
                        return ExpandableScheduleCard(
                          title: dateRangeTitle,
                          isInitiallyExpanded:
                              state.isDailyView || state.expandAll,
                          classrooms: classroomsWithShifts,
                          classroomNameMap: context
                              .read<ClassroomCubit>()
                              .codeNameMap,
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
