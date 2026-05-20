import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import '../../../../app/theme/colors.dart';
import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../cubit/classroom-day-view/classroom_staff_scheduling_cubit.dart';
import '../cubit/classroom-day-view/classroom_staff_scheduling_state.dart';
import '../widgets/expandable_schedule_card_shimmer/expandable_schedule_card_shimmer.dart';
import '../widgets/schedule_card.dart';
import '../widgets/expandable_schedule_card.dart';
import 'add-schedule.dart';
import '../../../../app/di/di.dart';
import '../../classroom/cubit/classroom_cubit.dart';
import 'package:intl/intl.dart';
import 'classroom/classroom-view.dart';
import '../model/staff_schedule_staff_vm.dart';
import '../model/classroom_schedule_vm.dart';

class SchedulingScreen extends StatefulWidget {
  const SchedulingScreen({super.key});

  static const String routeName = '/scheduling';

  @override
  State<SchedulingScreen> createState() => _SchedulingScreenState();
}

class _SchedulingScreenState extends State<SchedulingScreen> {
  String _selectedView = 'Daily View';

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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<StaffSchedulingCubit>()),
        BlocProvider(
          create: (context) =>
              serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
        ),
      ],
      child: GlobalScaffold(
        // hasBackButton: true,
        body: BlocBuilder<StaffSchedulingCubit, StaffSchedulingState>(
          builder: (context, state) {
            if (state is StaffSchedulingInitial ||
                (state is StaffSchedulingLoaded && state.isLoadingShifts)) {
              final loaded = state is StaffSchedulingLoaded ? state : null;
              return CustomRefreshIndicator(
                onRefresh: () async {
                  context.read<StaffSchedulingCubit>().loadInitialData(
                    date: loaded?.selectedDate ?? DateTime.now(),
                    isDaily: true,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      /// HEADER SHIMMER
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            height: 40,
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            height: 40,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// FILTER SHIMMER
                      Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// SCHEDULE SHIMMER
                      ListView.builder(
                        itemCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (_, __) {
                          return const ExpandableScheduleCardShimmer();
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            /// ==============================
            /// LOADED
            /// ==============================

            if (state is StaffSchedulingLoaded) {
              return CustomRefreshIndicator(
                onRefresh: () async {
                  context.read<StaffSchedulingCubit>().loadInitialData(
                    date: state.selectedDate ?? DateTime.now(),
                    isDaily: true,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// 🔹 Header Row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    color: AppColors.colorBox3,
                                    onPressed: () {
                                      final current =
                                          state.selectedDate ?? DateTime.now();

                                      final newDate = current.subtract(
                                        const Duration(days: 1),
                                      );

                                      context
                                          .read<StaffSchedulingCubit>()
                                          .changeDateAndMode(
                                            date: newDate,
                                            isDaily: true,
                                          );
                                    },
                                  ),

                                  Expanded(
                                    child: Text(
                                      DateFormat('EEE, MMM dd').format(
                                        state.selectedDate ?? DateTime.now(),
                                      ),
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),

                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    color: AppColors.colorBox3,
                                    onPressed: () {
                                      final current =
                                          state.selectedDate ?? DateTime.now();

                                      final newDate = current.add(
                                        const Duration(days: 1),
                                      );

                                      context
                                          .read<StaffSchedulingCubit>()
                                          .changeDateAndMode(
                                            date: newDate,
                                            isDaily: true,
                                          );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(
                            width: MediaQuery.sizeOf(context).width * 0.32,
                            child: CustomDropdown(
                              hintText: 'Select View',
                              prependHintAsSelectableItem: false,
                              selectedItem: _selectedView,
                              items: const ['Daily View', 'Classroom View'],
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
                                setState(() => _selectedView = value);
                                if (value != 'Classroom View') return;

                                final selectedDate =
                                    state.selectedDate ?? DateTime.now();
                                final dateStr = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(selectedDate);

                                final selectedCode = state.selectedClassroom;
                                final classroomState = context
                                    .read<ClassroomCubit>()
                                    .state;

                                final code =
                                    (selectedCode != null &&
                                        selectedCode.trim().isNotEmpty)
                                    ? selectedCode
                                    : (classroomState.classrooms.isNotEmpty
                                          ? classroomState.classrooms.first.code
                                          : (state.allClassrooms.isNotEmpty
                                                ? (state
                                                              .allClassrooms
                                                              .first['classroomCode'] ??
                                                          state
                                                              .allClassrooms
                                                              .first['code'])
                                                      ?.toString()
                                                : null));

                                if (code == null || code.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No classroom selected'),
                                    ),
                                  );
                                  return;
                                }

                                final name = _classroomNameForCode(
                                  code,
                                  state,
                                  classroomState,
                                );

                                Navigator.pushNamed(
                                  context,
                                  ClassroomViewScreen.routeName,
                                  arguments: ClassroomViewArgs(
                                    classroomCode: code,
                                    classroomName: name,
                                    date: dateStr,
                                  ),
                                ).then((_) {
                                  if (mounted) {
                                    setState(
                                      () => _selectedView = 'Daily View',
                                    );
                                  }
                                });
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
                          final selectedDate =
                              state.selectedDate ?? DateTime.now();
                          final selectedDateStr = DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDate);

                          // Map to handle missing class
                          final Map<String, List<StaffShiftEntity>>
                          shiftsByClassroom = {};
                          for (var shift in state.staffShifts) {
                            // Ensure we only show the selected day's data
                            if (shift.shiftDate != selectedDateStr) continue;

                            // Publish filter (for now: only Published / Not Published)
                            final publishFilter = (state.selectedPublish ?? '')
                                .trim();
                            if (publishFilter.isNotEmpty) {
                              final isPublished =
                                  shift.shiftStatus.trim().toUpperCase() ==
                                  'PUBLISHED';
                              if (publishFilter == 'Published' &&
                                  !isPublished) {
                                continue;
                              }
                              if (publishFilter == 'Not Published' &&
                                  isPublished) {
                                continue;
                              }
                            }
                            shiftsByClassroom
                                .putIfAbsent(shift.classroomCode, () => [])
                                .add(shift);
                          }

                          // Build the full classroom list (even if no shifts)
                          final Map<String, String> classroomNameByCode = {};

                          for (final c in classroomState.classrooms) {
                            if (c.code.trim().isEmpty) continue;
                            if (c.name.trim().isEmpty) continue;
                            classroomNameByCode[c.code] = c.name;
                          }

                          for (final c in state.allClassrooms) {
                            final code = (c['classroomCode'] ?? c['code'])
                                ?.toString();
                            final name = (c['classroomName'] ?? c['name'])
                                ?.toString();
                            if (code == null || code.trim().isEmpty) continue;
                            if (name == null || name.trim().isEmpty) continue;
                            classroomNameByCode.putIfAbsent(code, () => name);
                          }

                          final allClassroomCodes =
                              classroomNameByCode.keys.toList(growable: false)
                                ..sort((a, b) {
                                  final an = classroomNameByCode[a] ?? a;
                                  final bn = classroomNameByCode[b] ?? b;
                                  return an.toLowerCase().compareTo(
                                    bn.toLowerCase(),
                                  );
                                });

                          final classrooms = allClassroomCodes.map((code) {
                            final classroomName =
                                classroomNameByCode[code] ??
                                _classroomNameForCode(
                                  code,
                                  state,
                                  classroomState,
                                );

                            final classroomShifts =
                                shiftsByClassroom[code] ??
                                const <StaffShiftEntity>[];

                            int statusRank(String status) {
                              final s = status.toUpperCase().trim();
                              if (s == 'PUBLISHED') return 3;
                              if (s == 'DRAFT') return 2;
                              if (s == 'CANCELLED') return 1;
                              return 0;
                            }

                            // API can return multiple shift rows per staff for the same day
                            // (e.g. cancelled history). Show only one "best" row per staff.
                            final Map<String, StaffShiftEntity> bestByStaff =
                                {};
                            for (final shift in classroomShifts) {
                              final key = shift.staffCode.trim();
                              if (key.isEmpty) continue;

                              final prev = bestByStaff[key];
                              if (prev == null) {
                                bestByStaff[key] = shift;
                                continue;
                              }

                              final r1 = statusRank(shift.shiftStatus);
                              final r0 = statusRank(prev.shiftStatus);
                              if (r1 != r0) {
                                if (r1 > r0) bestByStaff[key] = shift;
                                continue;
                              }

                              // Same status: pick the earlier start time
                              if (shift.startTime.compareTo(prev.startTime) <
                                  0) {
                                bestByStaff[key] = shift;
                              }
                            }

                            final sortedShifts = bestByStaff.values.toList()
                              ..sort(
                                (a, b) => a.startTime.compareTo(b.startTime),
                              );

                            final mappedStaff = sortedShifts
                                .map((shift) {
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
                                  try {
                                    final now = DateTime.now();
                                    final shiftDt = DateTime.parse(
                                      shift.shiftDate,
                                    );

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
                                      final bst =
                                          shift.breakStartTime!.isNotEmpty
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
                                  // --------------------------

                                  return StaffScheduleStaffVm(
                                    name:
                                        '${shift.staffFirstName} ${shift.staffLastName}'
                                            .trim(),

                                    image: DocumentImageWidget(
                                      fileUuid: shift.image,
                                    ),

                                    availableHours: shift.availableHours,

                                    scheduledHours: shift.scheduledHours,

                                    shift:
                                        '${formatTime(shift.startTime)} - ${formatTime(shift.endTime)}',

                                    statusColor: statusColor,

                                    shiftDate: shift.shiftDate,

                                    shiftCode: shift.shiftCode,

                                    shiftStatus: shift.shiftStatus,
                                  );
                                })
                                .toList(growable: false);

                            return ClassroomScheduleVm(
                              title: code,
                              classroomCode: code,
                              staffList: mappedStaff,
                              showWarning: mappedStaff.isEmpty,
                              isExpanded: state.expandAll,
                              classroomName: classroomName,
                            );
                          }).toList();

                          if (classrooms.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Text("No classrooms found."),
                              ),
                            );
                          }

                          // Single Card for the whole week
                          return ExpandableScheduleCard(
                            title: DateFormat(
                              'EEE, MMM dd',
                            ).format(state.selectedDate ?? DateTime.now()),
                            isInitiallyExpanded: state.expandAll,
                            classrooms: classrooms,
                            classroomNameMap: {
                              ...context.read<ClassroomCubit>().codeNameMap,
                              ...classroomNameByCode,
                            },
                            isLoading: state.isLoadingShifts,
                          );
                        },
                      ),
                    ],
                  ),
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

// (intentionally removed the old tab widget; view switching is now via dropdown)
