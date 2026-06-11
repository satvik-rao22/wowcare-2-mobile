import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'dart:convert';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/classroom_visibility.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_redirect.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';

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
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;
  final Map<String, String> classroomNameToCode;
  // When true, pops back to the caller after a successful submission instead of
  // pushAndRemoveUntil → StudentAttendanceTabbedView. Set by callers that live
  // outside the Attendance tab (e.g. the Classroom Students card).
  final bool popOnSuccess;

  static const String routeName = '/student-transfer-form';

  @override
  State<StudentTransferForm> createState() => _StudentTransferFormState();
}

class _StudentTransferFormState extends State<StudentTransferForm> {
  DateTime _selectedTransferDate = DateTime.now();
  TimeOfDay _selectedTransferTime = TimeOfDay.now();
  String? _schoolIana;
  bool? _isStaffAdminPersona;
  String? selectedClassroom;
  String currentClassroom = '';
  List<String> availableClassrooms = [];
  List<StudentEntity> currentStudents = [];
  bool _isSubmitting = false;
  Map<String, String> _classroomNameToCode = <String, String>{};
  bool _hasTransferTargets = true;

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
      final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
          .trim()
          .toUpperCase();
      bool isAdmin =
          staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN';
      if (!isAdmin) {
        final rolesJson = await storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.trim().isNotEmpty) {
          final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
          for (final r in roles) {
            final roleCode = ((r as Map<String, dynamic>)['role'] ?? '')
                .toString()
                .toUpperCase();
            if (roleCode == 'SCHOOL_ADMIN' ||
                roleCode == 'ORGANIZATION_ADMIN') {
              isAdmin = true;
              break;
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _schoolIana = schoolIana;
        _isStaffAdminPersona = isAdmin;
        if (schoolIana != null && schoolIana.isNotEmpty) {
          final dt = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(
            schoolIana,
          );
          _selectedTransferDate = dt.$1;
          _selectedTransferTime = dt.$2;
        } else {
          _selectedTransferDate = DateTime.now();
          _selectedTransferTime = TimeOfDay.now();
        }
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

    return classroomNameToCode.entries
        .where((entry) => entry.key.trim().isNotEmpty)
        .where((entry) => isSelectableClassroomName(entry.key))
        .where((entry) => !currentRoomNames.contains(entry.key))
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  Future<void> _loadAvailableClassroomsFromApi() async {
    try {
      final storageService = serviceLocator<StorageService>();
      final schoolCode =
          (await storageService.getString(StorageKeys.schoolCode) ?? '').trim();
      if (schoolCode.isEmpty) return;
      final isScopedStaff = await isAttendanceScopedStaffPersona(
        storage: storageService,
      );
      final allowedCodes = isScopedStaff
          ? (await resolveAttendanceAllowedClassroomCodes(
              storage: storageService,
            )).map((e) => e.trim()).where((e) => e.isNotEmpty).toSet()
          : const <String>{};

      final getActiveClassroomsUseCase =
          serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getActiveClassroomsUseCase(
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
    final isAdmin = _isStaffAdminPersona ?? false;

    final DateTime transferredAt;
    if (isAdmin) {
      final pickedDay = DateTime(
        _selectedTransferDate.year,
        _selectedTransferDate.month,
        _selectedTransferDate.day,
      );
      final safeDay = pickedDay.isAfter(schoolToday) ? schoolToday : pickedDay;
      transferredAt = SchoolZoneDateTime.utcFromSchoolWallClock(
        schoolTimeZone,
        year: safeDay.year,
        month: safeDay.month,
        day: safeDay.day,
        hour: _selectedTransferTime.hour,
        minute: _selectedTransferTime.minute,
      );
    } else {
      transferredAt = SchoolZoneDateTime.utcNowInSchool(schoolTimeZone);
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

    final payload = <String, dynamic>{
      'transferDate': transferDate,
      'staffCode': staffCode,
      'studentCodes': studentCodes,
      'toClassroomCode': toClassroomCode,
      'toClassroomCodeByStudentCode': toClassroomCodeByStudentCode,
      // No dedicated reason field in UI yet, so send a generic placeholder.
      'transferReason': 'Transferred via mobile app',
      'timeZone': schoolTimeZone,
      'transferredAt': transferredAt.toUtc().toIso8601String(),
    };

    try {
      final result = await serviceLocator<AttendanceRepository>()
          .submitStudentTransfer(payload: payload);
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
              context, StudentAttendanceTabbedView.routeName);
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
            const SizedBox(height: 20),
            // Date + Time (50/50 split) - align with StaffTransferForm
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Date'),
                      const SizedBox(height: 8),
                      CustomDateTimeField(
                        hasLabel: false,
                        isRangePicker: false,
                        isTime: false,
                        fetchInitialTime: false,
                        initialDate: _selectedTransferDate,
                        isDisabled: !(_isStaffAdminPersona ?? false),
                        onDateSelected: (date) {
                          setState(() {
                            final iana = _schoolIana;
                            final today = iana != null && iana.isNotEmpty
                                ? SchoolZoneDateTime.schoolCalendarTodayOnly(
                                    iana,
                                  )
                                : DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
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
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Time'),
                      const SizedBox(height: 8),
                      IgnorePointer(
                        ignoring: !(_isStaffAdminPersona ?? false),
                        child: SimpleTimePickerField(
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
            const SizedBox(height: 20),
            // Below: Current classroom and Transfer to classroom
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Current Classroom'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: const Color.fromRGBO(177, 175, 233, 0.1),
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
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Transfer to Classroom'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color.fromRGBO(177, 175, 233, 0.1),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
        borderRadius: BorderRadius.circular(10),
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
                const SizedBox(width: 6),
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
