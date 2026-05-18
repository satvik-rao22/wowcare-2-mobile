import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/classroom/repositories/classroom_repository.dart';
import '../../../../domain/features/staff/entities/staff_member.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';
import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import '../../../../shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../../../../shared/common/widgets/gradient_add_button.dart';
import '../../../../core/util/school_timezone_resolver.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/util/school_zone_datetime.dart';
import '../widgets/add-shiftform/copy-shift.dart';
import 'publish-shift-schedule.dart';
import 'add-schedule.dart';

class StaffSchedulingScreen extends StatefulWidget {
  const StaffSchedulingScreen({super.key});

  static const String routeName = '/staff-shift';

  @override
  State<StaffSchedulingScreen> createState() => _StaffSchedulingScreenState();
}

class _StaffSchedulingScreenState extends State<StaffSchedulingScreen> {
  final ClassroomRepository _classroomRepository =
      serviceLocator<ClassroomRepository>();
  final StaffRepository _staffRepository = serviceLocator<StaffRepository>();
  final StaffSchedulingRepository _staffSchedulingRepository =
      serviceLocator<StaffSchedulingRepository>();
  final StorageService _storage = serviceLocator<StorageService>();
  DateTime _selectedDate = DateTime.now();
  String _schoolTimeZone = SchoolTimezoneResolver.fallbackTimeZone;
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
    return DateFormat('MMM d yyyy').format(_selectedDate);
  }

  @override
  void initState() {
    super.initState();

    _selectedDate = DateTime.now();
    _loadSchoolTimeZone();
    _loadStaffList();
  }

  Future<void> _loadSchoolTimeZone() async {
    try {
      final tz = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: serviceLocator<ApiClient>(),
      );
      if (!mounted) return;
      setState(() => _schoolTimeZone = tz);
    } catch (_) {}
  }

  Future<void> _onRefresh() async {
    final selected = _selectedStaff;
    if (selected != null) {
      await _loadStaffProfileAndSchedule(selected);
    } else {
      await _loadStaffList();
    }
  }

  Future<void> _loadStaffList() async {
    setState(() => _isLoadingStaff = true);
    try {
      final schoolCode = await _storage.getString(StorageKeys.schoolCode) ?? '';
      final results = await Future.wait([
        _staffRepository.getStaffListBySchool(schoolCode: schoolCode),
        _classroomRepository.getActiveClassrooms(
          schoolCode: schoolCode,
          onlyTypeClassroom: true,
        ),
      ]);

      final staff = results[0] as List<StaffMember>;
      final classrooms = results[1] as List<Classroom>;

      if (!mounted) return;
      setState(() {
        _staffList = staff;
        _classroomNamesByCode = {
          for (final c in classrooms)
            if (c.code.isNotEmpty) c.code: c.name,
        };
        _isLoadingStaff = false;
      });
      if (staff.isNotEmpty) {
        final first = staff.first;
        setState(() {
          _selectedStaff = first;
        });
        _loadStaffProfileAndSchedule(first);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStaff = false);
      CoreUtils.logApiError(e.toString());
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to load staff list',
        isWarning: true,
      );
    }
  }

  String _classroomNameForCode(String code) {
    if (code.trim().isEmpty || code == '-') return '-';
    return _classroomNamesByCode[code] ?? code;
  }

  Future<void> _loadStaffProfileAndSchedule(StaffMember staff) async {
    setState(() {
      _isLoadingProfileAndSchedule = true;
      _selectedProfile = null;
      _selectedStaffShifts = const [];
    });

    try {
      final dateFrom = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final dateTo = dateFrom;

      final shiftStatus = _selectedPublishStatus == null
          ? null
          : (_selectedPublishStatus == 'Published'
                ? 'PUBLISHED'
                : 'UNPUBLISHED');

      final schoolCode = await _storage.getString(StorageKeys.schoolCode) ?? '';
      final organizationCode =
          await _storage.getString(StorageKeys.organizationCode) ?? '';

      final profile = await _staffRepository.getStaffProfile(
        staffCode: staff.code,
        forEditStaff: true,
      );

      final classroomCode = profile.primaryClassroomCode.isNotEmpty
          ? profile.primaryClassroomCode
          : (staff.primaryClassroomOrFirstAllowed.isNotEmpty
                ? staff.primaryClassroomOrFirstAllowed
                : null);

      final allShifts = await _staffSchedulingRepository.getStaffShifts(
        classroomCode: classroomCode,
        dateFrom: dateFrom,
        dateTo: dateTo,
        shiftStatus: shiftStatus,
        schoolCode: schoolCode,
        organizationCode: organizationCode,
      );

      final staffShifts =
          allShifts
              .where((s) => s.staffCode == staff.code)
              .toList(growable: false)
            ..sort((a, b) {
              final dateCompare = a.shiftDate.compareTo(b.shiftDate);
              if (dateCompare != 0) return dateCompare;
              return a.startTime.compareTo(b.startTime);
            });

      if (!mounted) return;
      setState(() {
        _selectedProfile = profile;
        _selectedStaffShifts = staffShifts;
        _isLoadingProfileAndSchedule = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfileAndSchedule = false);
      CoreUtils.logApiError(e.toString());
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to load staff profile/schedule',
        isWarning: true,
      );
    }
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

  String _formatDesignation(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '-';
    // Normalize API formats like "ASSISTANT_TEACHER" / "assistant_teacher"
    final normalized = trimmed.replaceAll(RegExp(r'[_\\-]+'), ' ');
    final collapsed = normalized.replaceAll(RegExp(r'\\s+'), ' ').trim();
    return collapsed
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

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

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      body: CustomRefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

                      final selected = _selectedStaff;

                      if (selected != null) {
                        _loadStaffProfileAndSchedule(selected);
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

                      final selected = _selectedStaff;

                      if (selected != null) {
                        _loadStaffProfileAndSchedule(selected);
                      }
                    },
                  ),
                  const Spacer(),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      if (_selectedStaffShifts.isEmpty) {
                        CoreUtils.showTopSnackBar(
                          context: context,
                          message:
                              'No shift found for this date to publish. Add a shift first.',
                          isWarning: true,
                        );
                        return;
                      }

                      final schoolCode = await _storage.getString(
                        StorageKeys.schoolCode,
                      );
                      final organizationCode = await _storage.getString(
                        StorageKeys.organizationCode,
                      );

                      if (schoolCode == null ||
                          schoolCode.isEmpty ||
                          organizationCode == null ||
                          organizationCode.isEmpty) {
                        CoreUtils.showTopSnackBar(
                          context: context,
                          message: 'Missing school/organization info.',
                          isWarning: true,
                        );
                        return;
                      }

                      final shift = _selectedStaffShifts.first;
                      final payload = <String, dynamic>{
                        'staffCode': shift.staffCode,
                        'classroomCode': shift.classroomCode,
                        'schoolCode': schoolCode,
                        'organizationCode': organizationCode,
                        'shiftDate': shift.shiftDate,
                        'startTime': shift.startTime,
                        'endTime': shift.endTime,
                        if ((shift.breakStartTime ?? '').isNotEmpty)
                          'breakStartTime': shift.breakStartTime,
                        if ((shift.breakEndTime ?? '').isNotEmpty)
                          'breakEndTime': shift.breakEndTime,
                        'publish': true,
                        'repeat': false,
                        'overrideConflicts': true,
                        'forceAdd': true,
                        if ((shift.notes ?? '').isNotEmpty)
                          'notes': shift.notes,
                      };

                      Navigator.pushNamed(
                        context,
                        PublishShiftScheduleScreen.routeName,
                        arguments: payload,
                      );
                    },
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: AppColors.buildPrimaryGradient(),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Publish',
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
                  SizedBox(width: 10),
                  GradientAddButton(
                    onTap: () async {
                      Navigator.pushNamed(context, AddShiftScreen.routeName);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// ACTION BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // InkWell(
                  //   borderRadius: BorderRadius.circular(14),
                  //   onTap: () {
                  //     Navigator.pushNamed(context, CopyShiftForm.routeName);
                  //   },
                  //   child: Container(
                  //     height: 46,
                  //     padding: const EdgeInsets.symmetric(horizontal: 18),
                  //     decoration: BoxDecoration(
                  //       color: Colors.white,
                  //       borderRadius: BorderRadius.circular(14),
                  //       border: Border.all(
                  //         color: AppColors.themeColor,
                  //         width: 1.5,
                  //       ),
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Icon(
                  //           Icons.copy_rounded,
                  //           color: AppColors.themeColor,
                  //           size: 20,
                  //         ),
                  //         const SizedBox(width: 10),
                  //         Text(
                  //           'Copy Shift',
                  //           style: TextStyle(
                  //             color: AppColors.themeColor,
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.w600,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(width: 12),
                ],
              ),

              const SizedBox(height: 14),

              /// FILTERS
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown(
                      items: _staffList.map((s) => s.name).toList(),
                      selectedItem: _selectedStaff?.name,
                      hintText: 'Select Staff',
                      onSelect: _isLoadingStaff
                          ? null
                          : (value) {
                              if (value == null || _staffList.isEmpty) return;
                              final staff = _staffList.firstWhere(
                                (s) => s.name == value,
                                orElse: () => _selectedStaff ?? _staffList[0],
                              );
                              setState(() {
                                _selectedStaff = staff;
                              });
                              _loadStaffProfileAndSchedule(staff);
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
                        final selected = _selectedStaff;
                        if (selected != null) {
                          _loadStaffProfileAndSchedule(selected);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _staffCard(),

              const SizedBox(height: 20),

              _scheduleCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staffCard() {
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
                  Text(_formatDesignation(designation)),
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

  Widget _scheduleCard() {
    final times = List.generate(13, (index) {
      final hour = index + 6;

      final dt = DateTime(2000, 1, 1, hour);

      return DateFormat('hh:00 a').format(dt);
    });

    final shift = _selectedStaffShifts.isNotEmpty
        ? _selectedStaffShifts.first
        : null;

    final scheduleDate = DateFormat('EEE, MMM d yyyy').format(
      SchoolZoneDateTime.dateTimeFromInstantInSchool(
        _selectedDate,
        _schoolTimeZone,
      ),
    );

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
