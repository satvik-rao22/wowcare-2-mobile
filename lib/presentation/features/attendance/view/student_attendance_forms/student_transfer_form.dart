import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_remove_tile.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/attendance/entities/student_transfer_request.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_transfer_submit_cubit.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/classroom_visibility.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_redirect.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
export '../../model/tag_entity.dart';
import '../../model/student_entity.dart';
export '../../model/student_entity.dart';

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
        schoolIana = await _submitCubit.resolveFreshSchoolTimeZone();
      } catch (e) {
        AppLogger.d(
          'StudentTransferForm: resolveFreshSchoolTimeZone failed: $e',
        );
      }

      final isStaff = await _submitCubit.resolveIsStaffPersona();
      if (!mounted) return;
      setState(() {
        _schoolIana = schoolIana;
        _isStaffPersona = isStaff;
        final now = ServerTimeService.instance.now();
        _selectedTransferDate = now;
        _selectedTransferTime = TimeOfDay(hour: now.hour, minute: now.minute);
      });
    } catch (e) {
      AppLogger.d('StudentTransferForm: _loadPersonaFlags failed: $e');
    }
  }

  List<String> _filteredClassroomNames(
    Map<String, String> classroomNameToCode,
  ) {
    // The room the user is VIEWING the student in is authoritative when the
    // caller supplies one — it reflects where the student actually is right
    // now, including same-day transfers. The student entity's classroomCode
    // is their static ENROLLED room and does NOT change on a transfer, so
    // unioning it in here (as a previous version did) permanently excluded
    // that classroom as a transfer target even after the student had since
    // left it — e.g. transfer A -> B, then B -> A was blocked because A kept
    // getting re-added to the exclusion set from the stale entity field.
    // Only fall back to deriving from the entity when no viewing room is
    // known at all (a caller outside the single-classroom tab context).
    final viewing = _viewingClassroomName();
    final Set<String> currentRoomNames;
    if (viewing.isNotEmpty) {
      currentRoomNames = {viewing};
    } else {
      final codeToName = _codeToNameMap();
      currentRoomNames = currentStudents
          .map((s) {
            final code = s.classroomCode.trim();
            final resolved = code.isNotEmpty ? (codeToName[code] ?? '') : '';
            final fallback = s.roomName.trim();
            return (resolved.isNotEmpty ? resolved : fallback);
          })
          .where((name) => name.isNotEmpty)
          .toSet();
    }

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
      final options = await _submitCubit.resolveTransferClassroomOptions();
      if (options.schoolCode.isEmpty) return;

      final apiMap = <String, String>{
        for (final classroom in options.classrooms)
          if (classroom.name.trim().isNotEmpty &&
              classroom.code.trim().isNotEmpty &&
              (!options.isScopedStaff ||
                  options.allowedClassroomCodes.contains(
                    classroom.code.trim(),
                  )) &&
              isSelectableClassroomName(classroom.name))
            classroom.name: classroom.code,
      };

      if (!mounted || apiMap.isEmpty) return;
      setState(() {
        _classroomNameToCode = apiMap;
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

    final schoolTimeZone = await _submitCubit.resolveFreshSchoolTimeZone();
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
      return Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Access Denied: You must be inside geofence and signed in to manage student attendance.',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(color: AppColors.errorColor),
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
              itemBuilder: (context, index) => AttendanceRemoveTile(
                name: currentStudents[index].fullName,
                photoUuid: currentStudents[index].photoUuid ?? '',
                studentCode: currentStudents[index].studentCode,
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
                        child: CustomDateTimeField(
                          isTime: true,
                          initialTime: _selectedTransferTime,
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
            const AppText.label('Transfer to Classroom'),
            const SizedBox(height: AppSpacing.xs),
            CustomDropdown(
              hintText: _hasTransferTargets
                  ? 'Select classroom'
                  : 'No classroom available',
              items: availableClassrooms,
              selectedItem: selectedClassroom,
              isEnabled: _hasTransferTargets,
              onSelect: (value) {
                setState(() {
                  selectedClassroom = value;
                });
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        isForm: false,
        confirmButtonLabel: 'Submit',
        onPressedConfirm: _isSubmitting ? null : _handleSubmit,
        showCancelButton: false,
      ),
    );
  }
}
