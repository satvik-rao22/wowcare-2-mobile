import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/domain/features/attendance/entities/student_transfer_request.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_transfer_submit_cubit.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/classroom_visibility.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_redirect.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';

// Student entity for Transfer UI & API payload
class StudentEntity {
  final int id;
  final String studentCode;
  final String fullName;
  final int roomId;
  final String roomName;
  final String photoUuid;
  final List<TagEntity> tags;
  final String classroomCode;

  StudentEntity({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    this.photoUuid = '',
    this.tags = const [],
    this.classroomCode = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentEntity &&
          runtimeType == other.runtimeType &&
          studentCode == other.studentCode;

  @override
  int get hashCode => studentCode.hashCode;
}

// Mock tag entity for UI-only implementation
class TagEntity {
  final String name;

  TagEntity({required this.name});
}

class StudentTransferForm extends StatefulWidget {
  const StudentTransferForm({
    super.key,
    required this.students,
    this.refreshCallback,
    this.classroomNameToCode = const <String, String>{},
    this.popOnSuccess = false,
    this.currentClassroomCode,
    this.currentClassroomName,
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;
  final Map<String, String> classroomNameToCode;

  /// The classroom the user is currently VIEWING the student in, when the caller
  /// knows it (e.g. the Classroom → Students tab).
  ///
  /// This is authoritative for "where is the student right now" and must win
  /// over [StudentEntity.classroomCode]: a transfer moves the student for
  /// attendance purposes, but the student record keeps pointing at their
  /// enrolled room. Without it, transferring A→B and then opening Transfer from
  /// classroom B excluded A (the stale value) and left B — the student's actual
  /// current room — selectable as a destination.
  final String? currentClassroomCode;
  final String? currentClassroomName;
  // When true, pops back to the caller after a successful submission instead of
  // pushAndRemoveUntil → StudentAttendanceTabbedView. Set by callers that live
  // outside the Attendance tab (e.g. the Classroom Students card).
  final bool popOnSuccess;

  static const String routeName = '/student-transfer-form';

  @override
  State<StudentTransferForm> createState() => _StudentTransferFormState();
}

class _StudentTransferFormState extends State<StudentTransferForm> {
  DateTime _selectedTransferDate = ServerTimeService.instance.now();
  TimeOfDay _selectedTransferTime = ServerTimeService.instance.timeOfDayNow();
  String? _schoolIana;
  bool? _isStaffPersona;
  String? selectedClassroom;
  String currentClassroom = '';
  List<String> availableClassrooms = [];
  List<StudentEntity> currentStudents = [];
  bool _isSubmitting = false;
  Map<String, String> _classroomNameToCode = <String, String>{};
  bool _hasTransferTargets = true;

  /// Owns the transfer submit call (View -> Cubit -> UseCase -> Repository).
  /// Eagerly resolved so [dispose] can always close it.
  final StudentTransferSubmitCubit _submitCubit =
      serviceLocator<StudentTransferSubmitCubit>();

  @override
  void initState() {
    super.initState();
    currentStudents = List.from(widget.students);
    _classroomNameToCode = Map<String, String>.from(widget.classroomNameToCode);
    if (widget.students.isNotEmpty) {
      currentClassroom = _deriveCurrentClassroomName();
      availableClassrooms = _filteredClassroomNames(_classroomNameToCode);
      _hasTransferTargets = availableClassrooms.isNotEmpty;
    }
    _loadAvailableClassroomsFromApi();
    _loadPersonaFlags();
  }

  @override
  void dispose() {
    _submitCubit.close();
    super.dispose();
  }

  Future<void> _loadPersonaFlags() async {
    try {
      String? schoolIana;
      try {
        schoolIana = await SchoolTimezoneResolver.resolveForCurrentSchool(
          storage: serviceLocator<StorageService>(),
          apiClient: serviceLocator<ApiClient>(),
        );
      } catch (_) {}

      final storage = serviceLocator<StorageService>();
      // True for any staff-side login (school/org admin or regular staff);
      // false for guardian/parent and kiosk-PIN access. Gates date/time editing.
      final isStaff = await resolveIsStaffPersonaFromStorage(storage);
      if (!mounted) return;
      setState(() {
        _schoolIana = schoolIana;
        _isStaffPersona = isStaff;
        final now = ServerTimeService.instance.now();
        _selectedTransferDate = now;
        _selectedTransferTime = TimeOfDay(hour: now.hour, minute: now.minute);
      });
    } catch (_) {}
  }

  List<String> _filteredClassroomNames(
    Map<String, String> classroomNameToCode,
  ) {
    // Determine names of classrooms currently occupied by selected students
    final codeToName = _codeToNameMap();
    final currentRoomNames = currentStudents
        .map((s) {
          final code = s.classroomCode.trim();
          final resolved = code.isNotEmpty ? (codeToName[code] ?? '') : '';
          final fallback = s.roomName.trim();
          return (resolved.isNotEmpty ? resolved : fallback);
        })
        .where((name) => name.isNotEmpty)
        .toSet();

    // Also exclude the room the user is VIEWING the student in. The student
    // record above can be stale after a transfer (it still points at their
    // enrolled room), which is what left the current classroom selectable.
    final viewing = _viewingClassroomName();
    if (viewing.isNotEmpty) currentRoomNames.add(viewing);

    return classroomNameToCode.entries
        .where((entry) => entry.key.trim().isNotEmpty)
        .where((entry) => isSelectableClassroomName(entry.key))
        .where((entry) => !currentRoomNames.contains(entry.key))
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  /// Name of the classroom the caller says we're viewing, resolved from its code
  /// where possible. Empty when the caller didn't supply one.
  String _viewingClassroomName() {
    final code = (widget.currentClassroomCode ?? '').trim();
    if (code.isNotEmpty) {
      final resolved = (_codeToNameMap()[code] ?? '').trim();
      if (resolved.isNotEmpty) return resolved;
    }
    final name = (widget.currentClassroomName ?? '').trim();
    // Guard against a code being passed as the name (matches the daily-view rule).
    if (name.isNotEmpty && !name.startsWith('CLS_')) return name;
    return '';
  }

  Future<void> _loadAvailableClassroomsFromApi() async {
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          (await storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isEmpty) return;
      final isScopedStaff = await isStudentAttendanceScopedStaffPersona(
        storage: storageService,
      );
      final allowedCodes = isScopedStaff
          ? (await resolveStudentAttendanceAllowedClassroomCodes(
              storage: storageService,
            )).map((e) => e.trim()).where((e) => e.isNotEmpty).toSet()
          : const <String>{};

      final classrooms = await _submitCubit.fetchActiveClassrooms(
        schoolCode: schoolCode,
        onlyTypeClassroom: true,
      );

      final apiMap = <String, String>{
        for (final classroom in classrooms)
          if (classroom.name.trim().isNotEmpty &&
              classroom.code.trim().isNotEmpty &&
              (!isScopedStaff ||
                  allowedCodes.contains(classroom.code.trim())) &&
              isSelectableClassroomName(classroom.name))
            classroom.name: classroom.code,
      };

      if (!mounted || apiMap.isEmpty) return;
      setState(() {
        _classroomNameToCode = apiMap;
        // Re-derive current classroom once we have a reliable map
        currentClassroom = _deriveCurrentClassroomName();
        availableClassrooms = _filteredClassroomNames(_classroomNameToCode);
        _hasTransferTargets = availableClassrooms.isNotEmpty;
        if (selectedClassroom != null &&
            !availableClassrooms.contains(selectedClassroom)) {
          selectedClassroom = null;
        }
      });
    } catch (_) {
      // Keep fallback map from widget.classroomNameToCode if API load fails.
    }
  }

  Map<String, String> _codeToNameMap() {
    if (_classroomNameToCode.isEmpty) return const <String, String>{};
    // Reverse map name->code to code->name
    final map = <String, String>{};
    _classroomNameToCode.forEach((name, code) {
      if (code.trim().isNotEmpty && name.trim().isNotEmpty) {
        map[code.trim()] = name.trim();
      }
    });
    return map;
  }

  String _deriveCurrentClassroomName() {
    // The viewing room wins: after a transfer the student record still points at
    // their enrolled room, so trusting it would both mislabel this field and
    // leave the real current room selectable as a destination.
    final viewing = _viewingClassroomName();
    if (viewing.isNotEmpty) return viewing;
    if (currentStudents.isEmpty) return 'N/A';
    final first = currentStudents.firstWhere(
      (s) => s.classroomCode.trim().isNotEmpty || s.roomName.trim().isNotEmpty,
      orElse: () => currentStudents.first,
    );
    final code = first.classroomCode.trim();
    final roomName = first.roomName.trim();
    // Match daily-view logic: treat API name that equals code / looks like CLS_* as missing label.
    final apiNameLooksLikeCode =
        roomName.isNotEmpty &&
        (roomName == code || roomName.startsWith('CLS_'));
    if (roomName.isNotEmpty && !apiNameLooksLikeCode) return roomName;
    if (code.isNotEmpty) {
      final resolved = _codeToNameMap()[code] ?? '';
      if (resolved.isNotEmpty) return resolved;
    }
    if (roomName.isNotEmpty) return roomName;
    if (code.isNotEmpty) return code;
    return 'N/A';
  }

  void _removeStudent(StudentEntity student) {
    setState(() {
      currentStudents.remove(student);

      if (currentStudents.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  void _handleSubmit() {
    if (!_hasTransferTargets) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No other classroom available for transfer.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }
    if (selectedClassroom == null) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Please select a classroom to transfer to'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    _submitTransfer();
  }

  Future<String> _resolveStaffCode() async {
    return resolveStaffCodeForLoggedInUser();
  }

  Future<void> _submitTransfer() async {
    if (_isSubmitting) return;
    if (currentStudents.isEmpty || selectedClassroom == null) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No students selected to transfer'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );
    final schoolToday = SchoolZoneDateTime.schoolCalendarTodayOnly(
      schoolTimeZone,
    );
    final isStaffPersona = _isStaffPersona ?? false;

    final DateTime transferredAt;
    if (isStaffPersona) {
      final pickedDay = DateTime(
        _selectedTransferDate.year,
        _selectedTransferDate.month,
        _selectedTransferDate.day,
      );
      final safeDay = pickedDay.isAfter(schoolToday) ? schoolToday : pickedDay;
      transferredAt = SchoolZoneDateTime.resolvePickedInstantUtc(
        schoolTimeZone,
        selectedDate: safeDay,
        selectedTime: _selectedTransferTime,
      );
    } else {
      transferredAt = SchoolZoneDateTime.utcNowInSchool(schoolTimeZone);
    }

    if (isStaffPersona &&
        transferredAt.isAfter(ServerTimeService.instance.nowUtc())) {
      if (!mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('You cannot transfer for a future date/time.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final transferDate = SchoolZoneDateTime.yyyyMmDdFromUtcInstant(
      transferredAt,
      schoolTimeZone,
    );

    final staffCode = await _resolveStaffCode();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Unable to resolve staffCode. Please re-login.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final studentCodes = currentStudents
        .map((s) => s.studentCode.trim())
        .where((code) => code.isNotEmpty)
        .toList();
    if (studentCodes.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Student code missing for selected students'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final toClassroomCode = selectedClassroom == null
        ? ''
        : (_classroomNameToCode[selectedClassroom!] ?? '').trim();
    if (toClassroomCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text(
            'Selected classroom is not linked to a classroom code yet.',
          ),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final toClassroomCodeByStudentCode = <String, String>{
      for (final s in currentStudents) s.studentCode: toClassroomCode,
    };

    // No dedicated reason field in UI yet, so the request defaults
    // transferReason to the generic placeholder the payload always carried.
    final request = StudentTransferRequest(
      transferDate: transferDate,
      staffCode: staffCode,
      studentCodes: studentCodes,
      toClassroomCode: toClassroomCode,
      toClassroomCodeByStudentCode: toClassroomCodeByStudentCode,
      timeZone: schoolTimeZone,
      transferredAt: transferredAt.toUtc().toIso8601String(),
    );

    try {
      final result = await _submitCubit.submit(request: request);
      final success = result.success;
      final message = result.message;

      if (!mounted) return;

      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(message),
          backgroundColor: success
              ? AppColors.successColor
              : AppColors.errorColor,
        ),
      );

      if (success) {
        if (widget.popOnSuccess) {
          widget.refreshCallback?.call();
          Navigator.of(context).pop();
        } else {
          redirectToAttendanceDaily(
            context,
            StudentAttendanceTabbedView.routeName,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(
      context,
    )) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Access Denied: You must be inside geofence and signed in to manage student attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return StaffFormLayout(
      title: 'Transfer',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 3.5,
              ),
              itemCount: currentStudents.length,
              itemBuilder: (context, index) => RemoveStudentTile(
                student: currentStudents[index],
                onRemove: () => _removeStudent(currentStudents[index]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Date + Time (50/50 split) - align with StaffTransferForm
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Date'),
                      const SizedBox(height: AppSpacing.xs),
                      CustomDateTimeField(
                        hasLabel: false,
                        isRangePicker: false,
                        isTime: false,
                        fetchInitialTime: false,
                        initialDate: _selectedTransferDate,
                        isDisabled: !(_isStaffPersona ?? false),
                        onDateSelected: (date) {
                          setState(() {
                            final iana = _schoolIana;
                            final today = iana != null && iana.isNotEmpty
                                ? SchoolZoneDateTime.schoolCalendarTodayOnly(
                                    iana,
                                  )
                                : DateTime(
                                    ServerTimeService.instance.now().year,
                                    ServerTimeService.instance.now().month,
                                    ServerTimeService.instance.now().day,
                                  );
                            final pickedDay = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );
                            _selectedTransferDate = pickedDay.isAfter(today)
                                ? today
                                : date;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Time'),
                      const SizedBox(height: AppSpacing.xs),
                      IgnorePointer(
                        ignoring: !(_isStaffPersona ?? false),
                        child: GradientTimePickerField(
                          time: _selectedTransferTime,
                          onTimeSelected: (t) {
                            setState(() {
                              _selectedTransferTime = t;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Below: Current classroom and Transfer to classroom
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Current Classroom'),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.s14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.attendanceBorderLightColor,
                                ),
                                borderRadius: AppRadius.allSm,
                                color: AppColors.fieldBackgroundColor,
                              ),
                              child: AppText.value(
                                currentClassroom,
                                style: TextStyle(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Transfer to Classroom'),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.none,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.attendanceBorderLightColor,
                          ),
                          borderRadius: AppRadius.allSm,
                          color: AppColors.fieldBackgroundColor,
                        ),
                        child: DropdownButton<String>(
                          value: selectedClassroom,
                          hint: Text(
                            _hasTransferTargets
                                ? 'Select classroom'
                                : 'No classroom available',
                          ),
                          style: TextStyle(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 15,
                          ),
                          isExpanded: true,
                          icon: SvgPicture.asset(MediaRes.arrow_drop_down),
                          underline: Container(),
                          onChanged: !_hasTransferTargets
                              ? null
                              : (String? newValue) {
                                  setState(() {
                                    selectedClassroom = newValue!;
                                  });
                                },
                          items: availableClassrooms.map((String classroom) {
                            return DropdownMenuItem<String>(
                              value: classroom,
                              child: Text(classroom),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Submit',
        onPressedConfirm: _isSubmitting ? null : _handleSubmit,
        showCancelButton: false,
      ),
    );
  }
}

class RemoveStudentTile extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onRemove;

  const RemoveStudentTile({
    super.key,
    required this.student,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
        borderRadius: BorderRadius.circular(AppRadius.r10),
        color: const Color.fromRGBO(249, 245, 250, 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                DocumentImageWidget(
                  fileUuid: student.photoUuid,
                  name: student.fullName,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: AppSpacing.s6),
                Flexible(
                  child: Text(
                    student.fullName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: SvgPicture.asset(MediaRes.delete_icon),
          ),
        ],
      ),
    );
  }
}
