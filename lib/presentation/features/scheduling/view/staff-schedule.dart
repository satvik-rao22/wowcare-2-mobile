import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/presentation/features/scheduling/view/publish-shift-schedule.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../cubit/Single-Staff-Shift/staff_schedule_cubit.dart';
import '../cubit/Single-Staff-Shift/staff_schedule_state.dart';
import '../widgets/add-shiftform/copy-shift.dart';
import '../widgets/expandable_schedule_card_shimmer/staff-card-shimmer.dart';
import 'add-schedule.dart';

class StaffSchedulingScreen extends StatefulWidget {
  const StaffSchedulingScreen({super.key});

  static const String routeName = '/single-staff-schudle';

  @override
  State<StaffSchedulingScreen> createState() => _StaffSchedulingScreenState();
}

class _StaffSchedulingScreenState extends State<StaffSchedulingScreen> {
  DateTime _selectedDate = DateTime.now();
  List<StaffMember> _staffList = const [];
  Map<String, String> _classroomNamesByCode = const {};
  StaffMember? _selectedStaff;
  StaffProfile? _selectedProfile;
  List<StaffShiftEntity> _selectedStaffShifts = const [];
  String? _selectedPublishStatus;
  bool _isLoadingStaff = false;
  bool _isLoadingProfileAndSchedule = false;

  DateTime get _weekStart {
    final daysToSubtract = _selectedDate.weekday - DateTime.monday;

    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).subtract(Duration(days: daysToSubtract));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 5));

  // in this only add current date now
  // String get _weekTitle {
  //   final start = DateFormat('EEE MMM d').format(_weekStart);
  //   final end = DateFormat('EEE MMM d').format(_weekEnd);
  //   return '$start - $end';
  // }

  String get _weekTitle {
    return DateFormat('EEE, MMM d yyyy').format(_selectedDate);
  }

  @override
  void initState() {
    super.initState();

    _selectedDate = DateTime.now();
  }

  String _classroomNameForCode(String code) {
    if (code.trim().isEmpty || code == '-') return '-';
    return _classroomNamesByCode[code] ?? code;
  }

  double _sumScheduledHours() => _selectedStaffShifts.fold(
    0.0,
    (sum, shift) => sum + shift.scheduledHours,
  );

  double _sumUnscheduledHours() => _selectedStaffShifts.fold(
    0.0,
    (sum, shift) => sum + shift.unscheduledHours,
  );

  double _sumAvailableHours() => _selectedStaffShifts.fold(
    0.0,
    (sum, shift) => sum + shift.availableHours,
  );

  String _formatHours(double value) =>
      value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

  String _formatTime(String hhmmss) {
    try {
      final parts = hhmmss.split(':');
      if (parts.length < 2) return hhmmss;
      final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return hhmmss;
    }
  }

  int _toMinutes(String hhmmss) {
    try {
      final parts = hhmmss.split(':');
      if (parts.length < 2) return 0;
      return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _onRefresh() async {
    final selected = _selectedStaff;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StaffScheduleCubit, StaffScheduleState>(
      builder: (context, state) {
        final staffList = state.staffList;

        final selectedStaff = state.selectedStaff;

        final selectedProfile = state.selectedProfile;

        final selectedStaffShifts = state.shifts;

        final classroomMap = state.classroomMap;

        return GlobalScaffold(
          body: CustomRefreshIndicator(
            onRefresh: () async {
              await context.read<StaffScheduleCubit>().refresh(
                selectedDate: _selectedDate,
                publishStatus: _selectedPublishStatus,
              );
            },

            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    /// =======================================================
                    /// HEADER
                    /// =======================================================
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),

                          color: AppColors.colorBox3,

                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.subtract(
                                const Duration(days: 1),
                              );
                            });

                            if (selectedStaff != null) {
                              context
                                  .read<StaffScheduleCubit>()
                                  .loadStaffSchedule(
                                    selectedStaff,
                                    selectedDate: _selectedDate,
                                    publishStatus: _selectedPublishStatus,
                                  );
                            }
                          },
                        ),

                        Text(
                          _weekTitle,

                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.chevron_right),

                          color: AppColors.colorBox3,

                          onPressed: () {
                            setState(() {
                              _selectedDate = _selectedDate.add(
                                const Duration(days: 1),
                              );
                            });

                            if (selectedStaff != null) {
                              context
                                  .read<StaffScheduleCubit>()
                                  .loadStaffSchedule(
                                    selectedStaff,
                                    selectedDate: _selectedDate,
                                    publishStatus: _selectedPublishStatus,
                                  );
                            }
                          },
                        ),

                        const Spacer(),

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

                    /// =======================================================
                    /// ACTION BUTTONS
                    /// =======================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,

                      children: [
                        /// COPY SHIFT
                        InkWell(
                          borderRadius: BorderRadius.circular(14),

                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              CopyShiftForm.routeName,
                            );
                          },

                          child: Container(
                            height: 46,

                            padding: const EdgeInsets.symmetric(horizontal: 24),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(14),

                              border: Border.all(
                                color: AppColors.themeColor,

                                width: 1.5,
                              ),
                            ),

                            child: Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Icon(
                                  Icons.copy_rounded,

                                  color: AppColors.themeColor,

                                  size: 20,
                                ),

                                const SizedBox(width: 10),

                                Text(
                                  'Copy Shift',

                                  style: TextStyle(
                                    color: AppColors.themeColor,

                                    fontSize: 16,

                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        /// PUBLISH SHIFT
                        InkWell(
                          borderRadius: BorderRadius.circular(14),

                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              PublishShiftScheduleScreen.routeName,

                              arguments: {
                                'staffCode': selectedStaff?.code,

                                'staffName': selectedStaff?.name,
                              },
                            );
                          },

                          child: Container(
                            height: 46,

                            padding: const EdgeInsets.symmetric(horizontal: 25),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),

                              gradient: AppColors.buildPrimaryGradient(),
                            ),

                            child: const Row(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Icon(
                                  Icons.telegram_rounded,

                                  color: Colors.white,

                                  size: 20,
                                ),

                                SizedBox(width: 10),

                                Text(
                                  'Publish Shift',

                                  style: TextStyle(
                                    color: Colors.white,

                                    fontSize: 16,

                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    /// =======================================================
                    /// FILTERS
                    /// =======================================================
                    Row(
                      children: [
                        Expanded(
                          child: CustomDropdown(
                            items: staffList.map((s) => s.name).toList(),

                            selectedItem: selectedStaff?.name,

                            hintText: 'Select Staff',

                            onSelect: state.isLoadingStaff
                                ? null
                                : (value) {
                                    if (value == null || staffList.isEmpty) {
                                      return;
                                    }

                                    final staff = staffList.firstWhere(
                                      (s) => s.name == value,

                                      orElse: () =>
                                          selectedStaff ?? staffList[0],
                                    );

                                    context
                                        .read<StaffScheduleCubit>()
                                        .loadStaffSchedule(
                                          staff,

                                          selectedDate: _selectedDate,

                                          publishStatus: _selectedPublishStatus,
                                        );
                                  },
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: CustomDropdown(
                            items: const ['Published', 'Unpublished'],

                            selectedItem: _selectedPublishStatus,

                            hintText: 'Publish',

                            onSelect: (value) {
                              setState(() {
                                _selectedPublishStatus = value;
                              });

                              if (selectedStaff != null) {
                                context
                                    .read<StaffScheduleCubit>()
                                    .loadStaffSchedule(
                                      selectedStaff,

                                      selectedDate: _selectedDate,

                                      publishStatus: _selectedPublishStatus,
                                    );
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// =======================================================
                    /// STAFF CARD
                    /// =======================================================
                    if (state.isLoadingSchedule ||
                        state.scheduleError != null ||
                        state.shifts.isEmpty)
                      const StaffCardShimmer()
                    else
                      _staffCard(
                        selectedProfile,
                        selectedStaff,
                        selectedStaffShifts,
                        classroomMap,
                      ),

                    const SizedBox(height: 20),

                    /// =======================================================
                    /// SCHEDULE CARD
                    /// =======================================================
                    if (state.isLoadingSchedule ||
                        state.scheduleError != null ||
                        state.shifts.isEmpty)
                      const ScheduleCardShimmer()
                    else
                      _scheduleCard(selectedStaffShifts, classroomMap),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _staffCard(
    StaffProfile? selectedProfile,
    StaffMember? selectedStaff,
    List<StaffShiftEntity> selectedStaffShifts,
    Map<String, String> classroomMap,
  ) {
    /// SHOW SHIMMER
    if (_isLoadingProfileAndSchedule) {
      return const StaffCardShimmer();
    }

    final name = _selectedProfile?.fullName.isNotEmpty == true
        ? _selectedProfile!.fullName
        : (_selectedStaff?.name ?? 'Select staff to view details');
    final designation = _selectedProfile?.designation.isNotEmpty == true
        ? _selectedProfile!.designation
        : (_selectedStaff?.designation ?? '-');
    final classroom = _selectedProfile?.primaryClassroomCode.isNotEmpty == true
        ? _selectedProfile!.primaryClassroomCode
        : (_selectedStaff?.primaryClassroomOrFirstAllowed.isNotEmpty == true
              ? _selectedStaff!.primaryClassroomOrFirstAllowed
              : '-');
    final profileImage = _selectedProfile?.profilePhotoUrl.isNotEmpty == true
        ? _selectedProfile!.profilePhotoUrl
        : _selectedStaff?.profileImage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  DocumentImageWidget(
                    fileUuid: profileImage ?? '',
                    name: name,
                    size: 48,
                    fontSize: 16,
                  ),

                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 14,
                      width: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(designation),
                ],
              ),
              const Spacer(),
              Text(_classroomNameForCode(classroom)),
            ],
          ),
          const SizedBox(height: 16),
          _infoTile(
            MediaRes.availableHoursIcon,
            'Available Hours',
            _formatHours(_sumAvailableHours()),
            AppColors.availableHours,
          ),
          const SizedBox(height: 10),
          _infoTile(
            MediaRes.scheduledHoursIcon,
            'Scheduled Hours',
            _formatHours(_sumScheduledHours()),
            AppColors.scheduledHours,
          ),
          const SizedBox(height: 10),
          _infoTile(
            MediaRes.unScheduledHoursIcon,
            'Unscheduled Hours',
            _formatHours(_sumUnscheduledHours()),
            AppColors.unscheduledHours,
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String image, String title, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          /// Left side (icon + title)
          Row(children: [SvgPicture.asset(image, height: 20, width: 20)]),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _scheduleCard(
    List<StaffShiftEntity> selectedStaffShifts,
    Map<String, String> classroomMap,
  ) {
    /// SHOW SHIMMER
    if (_isLoadingProfileAndSchedule) {
      return const ScheduleCardShimmer();
    }
    final times = List.generate(13, (index) {
      final hour = index + 6;

      final dt = DateTime(2000, 1, 1, hour);

      return DateFormat('hh:00 a').format(dt);
    });

    final shift = _selectedStaffShifts.isNotEmpty
        ? _selectedStaffShifts.first
        : null;

    final scheduleDate = DateFormat('EEE, MMM d yyyy').format(_selectedDate);

    final shiftRange = shift != null
        ? '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}'
        : '';

    final breakRange =
        (shift?.breakStartTime ?? '').isNotEmpty &&
            (shift?.breakEndTime ?? '').isNotEmpty
        ? '${_formatTime(shift!.breakStartTime!)} - ${_formatTime(shift.breakEndTime!)}'
        : null;

    const slotHeight = 38.0;
    final timelineHeight = slotHeight * times.length;

    final startRefMin = 6 * 60;
    final endRefMin = 18 * 60;
    final totalRefMin = endRefMin - startRefMin;

    double shiftTop = 16;
    double shiftHeight = 180;
    double? breakTop;

    if (shift != null) {
      final start = _toMinutes(shift.startTime);
      final end = _toMinutes(shift.endTime);

      final duration = (end - start).clamp(60, totalRefMin);

      shiftTop = (((start - startRefMin) / totalRefMin) * timelineHeight).clamp(
        8,
        timelineHeight - 80,
      );

      shiftHeight = ((duration / totalRefMin) * timelineHeight).clamp(
        90,
        timelineHeight - shiftTop,
      );

      if ((shift.breakStartTime ?? '').isNotEmpty) {
        final bStart = _toMinutes(shift.breakStartTime!);

        breakTop = (((bStart - startRefMin) / totalRefMin) * timelineHeight)
            .clamp(8, timelineHeight - 30);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final timeColumnWidth = constraints.maxWidth * 0.39;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              /// Header
              Container(
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF8FC),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFC7D4FF), width: 1.5),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: timeColumnWidth,
                      child: const Center(
                        child: Text(
                          'Time',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 32,
                      child: VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: Color(0xFFDADFEA),
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: Text(
                          scheduleDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// Timeline
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Time Column
                  SizedBox(
                    width: timeColumnWidth,
                    child: Column(
                      children: times.map((t) {
                        return Container(
                          height: slotHeight,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFDADFEA),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(
                    height: 494,
                    child: VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFDADFEA),
                    ),
                  ),

                  /// Schedule Area
                  Expanded(
                    child: SizedBox(
                      height: timelineHeight,
                      child: shift == null
                          ? const Center(
                              child: Text(
                                'No schedule available',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            )
                          : Stack(
                              children: [
                                /// Shift Block
                                Positioned(
                                  left: 10,
                                  right: 6,
                                  top: shiftTop,
                                  child: Container(
                                    height: shiftHeight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC4D4F0),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _classroomNameForCode(
                                            shift.classroomCode,
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                            color: Color(0xFF3B5BA9),
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        Text(
                                          shiftRange,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                /// Break Block
                                if (breakRange != null && breakTop != null)
                                  Positioned(
                                    left: 10,
                                    right: 6,
                                    top: breakTop,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3CD),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Lunch Break $breakRange',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
