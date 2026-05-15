import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/widgets/unexpected_sign_in_attention_dialog.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

// Student entity used for Sign-In UI & API payload
class StudentEntity {
  final int id;
  final String studentCode;
  final String fullName;
  final int roomId;
  final String roomName;
  final String classroomCode;
  final String? photoUuid;
  final bool isExpectedToday;

  StudentEntity({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    required this.classroomCode,
    this.photoUuid,
    this.isExpectedToday = true,
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

class StudentSignInForm extends StatefulWidget {
  const StudentSignInForm({
    super.key,
    required this.students,
    required this.refreshCallback,
    this.popOnSuccess = false,
  });

  final VoidCallback refreshCallback;
  final List<StudentEntity> students;
  // When true, pops back to the caller after a successful submission instead of
  // pushAndRemoveUntil → StudentAttendanceTabbedView. Set by callers that live
  // outside the Attendance tab (e.g. the Classroom Students card) so the user
  // stays on the screen they started from.
  final bool popOnSuccess;

  static const String routeName = '/student-sign-in-form';

  @override
  State<StudentSignInForm> createState() => _StudentSignInFormState();
}

class _StudentSignInFormState extends State<StudentSignInForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  /// School IANA id from API; when set, date/time defaults and [occurredAt] use this zone.
  String? _schoolIana;
  List<StudentEntity> currentStudents = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona;
  Map<String, bool> _expectedTodayFromApi = {};
  bool _unexpectedGateLoading = true;
  bool _unexpectedSignInAcknowledged = false;
  int _unexpectedGateToken = 0;

  @override
  void initState() {
    super.initState();
    currentStudents = List.from(widget.students);
    _loadPersonaFlags();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapSchoolZone();
    });
  }

  Future<void> _bootstrapSchoolZone() async {
    final z = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );
    if (!mounted) return;
    setState(() {
      _schoolIana = z;
    });
    setCurrentDateTime();
    await _runUnexpectedSignInGate();
  }

  /// Selected calendar day as yyyy-MM-dd (naive components — intended school business date).
  String _naiveCalendarYyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _hasUnexpectedAmongSelected() {
    for (final s in currentStudents) {
      final code = s.studentCode.trim();
      if (code.isEmpty) continue;
      final expected = _expectedTodayFromApi[code] ?? s.isExpectedToday;
      if (!expected) return true;
    }
    return false;
  }

  List<String> _unexpectedStudentFullNames() {
    final out = <String>[];
    for (final s in currentStudents) {
      final code = s.studentCode.trim();
      if (code.isEmpty) continue;
      final expected = _expectedTodayFromApi[code] ?? s.isExpectedToday;
      if (!expected) out.add(s.fullName);
    }
    return out;
  }

  Future<void> _runUnexpectedSignInGate() async {
    if (!mounted) return;
    if (currentStudents.isEmpty) {
      setState(() {
        _unexpectedGateLoading = false;
        _unexpectedSignInAcknowledged = true;
      });
      return;
    }
    final token = ++_unexpectedGateToken;
    setState(() {
      _unexpectedGateLoading = true;
    });

    final dateStr = _naiveCalendarYyyyMmDd(selectedDate);
    try {
      final useCase = serviceLocator<GetStudentSignInFormListUseCase>();
      final page = await useCase(
        fromAttendanceDate: dateStr,
        toAttendanceDate: dateStr,
        classroomCodes: null,
        tagCodes: null,
        search: null,
        page: 0,
        size: 500,
      );
      if (!mounted || token != _unexpectedGateToken) return;
      final m = <String, bool>{};
      for (final item in page.items) {
        m[item.studentCode.trim()] = item.isExpectedToday;
      }
      setState(() {
        _expectedTodayFromApi = m;
      });
    } catch (_) {
      if (!mounted || token != _unexpectedGateToken) return;
      setState(() {
        _expectedTodayFromApi = {};
      });
    }

    if (!mounted || token != _unexpectedGateToken) return;

    final hasUnexpected = _hasUnexpectedAmongSelected();
    if (!hasUnexpected) {
      setState(() {
        _unexpectedSignInAcknowledged = true;
        _unexpectedGateLoading = false;
      });
      return;
    }

    setState(() {
      _unexpectedSignInAcknowledged = false;
      _unexpectedGateLoading = false;
    });

    if (!mounted || token != _unexpectedGateToken) return;

    final result = await showUnexpectedSignInAttentionDialog(
      context,
      unexpectedFullNames: _unexpectedStudentFullNames(),
      forStaff: false,
    );

    if (!mounted || token != _unexpectedGateToken) return;

    if (result?.confirmed == true) {
      setState(() {
        _unexpectedSignInAcknowledged = true;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadPersonaFlags() async {
    final isAdmin = await _resolveIsStaffAdminPersona();
    if (!mounted) return;
    setState(() {
      _isStaffAdminPersona = isAdmin;
      if (!_isStaffAdminPersona!) {
        setCurrentDateTime();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runUnexpectedSignInGate();
    });
  }

  Future<bool> _resolveIsStaffAdminPersona() async {
    try {
      final storage = serviceLocator<StorageService>();
      final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
          .trim()
          .toUpperCase();
      if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
        return true;
      }
      final rolesJson = await storage.getString(StorageKeys.roles);
      if (rolesJson == null || rolesJson.trim().isEmpty) return false;
      final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
      for (final r in roles) {
        final roleCode = ((r as Map<String, dynamic>)['role'] ?? '')
            .toString()
            .toUpperCase();
        if (roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN') {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  void setCurrentDateTime() {
    final iana = _schoolIana;
    if (iana != null && iana.isNotEmpty) {
      final (d, t) = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(iana);
      setState(() {
        selectedDate = d;
        selectedTime = t;
      });
      return;
    }
    final dateTime = DateTime.now();
    setState(() {
      selectedDate = dateTime;
      selectedTime = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    });
  }

  void _removeStudent(StudentEntity student) {
    setState(() {
      currentStudents.remove(student);
    });
    if (currentStudents.isEmpty) {
      Navigator.pop(context);
      return;
    }
    if (!_hasUnexpectedAmongSelected()) {
      setState(() {
        _unexpectedSignInAcknowledged = true;
      });
    }
  }

  Future<String> _resolveStaffCode() => resolveStaffCodeForLoggedInUser();

  bool _absenceDateMatchesCalendarDay(
    String absenceDateRaw,
    String targetYyyyMmDd,
  ) {
    final trimmed = absenceDateRaw.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.length >= 10 && trimmed.substring(0, 10) == targetYyyyMmDd) {
      return true;
    }
    try {
      final dt = DateTime.parse(trimmed).toLocal();
      final norm =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      return norm == targetYyyyMmDd;
    } catch (_) {
      return false;
    }
  }

  /// Staff sign-in: for students marked absent on [attendanceDateYyyyMmDd],
  /// delete absence records first (override sign-in).
  Future<void> _deleteTodaysAbsenceRecordsBeforeStaffSignIn({
    required String attendanceDateYyyyMmDd,
    required String staffCode,
    required List<StudentEntity> students,
  }) async {
    final repo = serviceLocator<AttendanceRepository>();
    final allItems = <StudentAttendanceAbsentFormItem>[];

    var page = 0;
    const pageSize = 100;
    while (true) {
      final absentPage = await repo.getStudentAbsentFormList(
        fromAbsenceDate: attendanceDateYyyyMmDd,
        toAbsenceDate: attendanceDateYyyyMmDd,
        page: page,
        size: pageSize,
      );
      allItems.addAll(absentPage.items);
      if (!absentPage.hasMore) break;
      page++;
      if (page > 100) break;
    }

    final processedStudentCodes = <String>{};
    for (final s in students) {
      final sc = s.studentCode.trim();
      if (sc.isEmpty || processedStudentCodes.contains(sc)) continue;

      final matches = allItems.where((it) {
        if (it.studentCode.trim() != sc) return false;
        return _absenceDateMatchesCalendarDay(
          it.absenceDate,
          attendanceDateYyyyMmDd,
        );
      }).toList();

      if (matches.isEmpty) continue;

      final withCode = matches
          .where((it) => (it.absenceRecordCode ?? '').trim().isNotEmpty)
          .toList();
      if (withCode.isEmpty) {
        throw Exception(
          'Cannot sign in ${s.fullName.split(' ').first}: marked absent for '
          'this day but the absence record could not be resolved. Refresh and try again.',
        );
      }

      final room = s.classroomCode.trim();
      StudentAttendanceAbsentFormItem chosen = withCode.first;
      if (room.isNotEmpty) {
        final byRoom = withCode
            .where((it) => it.classroomCode.trim() == room)
            .toList();
        if (byRoom.isNotEmpty) {
          chosen = byRoom.first;
        }
      }

      await repo.deleteStudentAbsenceRecord(
        absenceRecordCode: chosen.absenceRecordCode!.trim(),
        staffCode: staffCode,
      );
      processedStudentCodes.add(sc);
    }
  }

  Future<bool> _resolveIsParentSession() async {
    if (context.read<RoleProvider>().isParent) return true;

    try {
      final storage = serviceLocator<StorageService>();
      final rolesJson = (await storage.getString(StorageKeys.roles) ?? '')
          .trim();
      if (rolesJson.isNotEmpty) {
        final decoded = jsonDecode(rolesJson);
        if (decoded is List) {
          for (final role in decoded) {
            if (role is! Map) continue;
            final roleName = (role['role'] ?? '')
                .toString()
                .toUpperCase()
                .trim();
            if (roleName.contains('PARENT') || roleName.contains('GUARDIAN')) {
              return true;
            }
          }
        }
      }

      final loginContext = await storage.getJson(StorageKeys.loginContext);
      final contextRaw = jsonEncode(
        loginContext ?? const <String, dynamic>{},
      ).toUpperCase();
      if (contextRaw.contains('PARENT') || contextRaw.contains('GUARDIAN')) {
        return true;
      }
    } catch (_) {
      // Ignore parse/storage issues and keep non-parent fallback.
    }

    return false;
  }

  Future<void> _submitSignIn() async {
    if (_isSubmitting) return;
    if (currentStudents.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No students selected to sign in'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final client = serviceLocator<ApiClient>().client;
    final isParent = await _resolveIsParentSession();
    final endpoint = ApiPaths.urlWithBase(
      isParent
          ? ApiPaths.studentAttendanceRecordsParentSignIn
          : ApiPaths.studentAttendanceRecordsSignIn,
      ApiConstants.attendanceBaseUrl,
    );

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );

    // Admins pick school-local date/time; everyone else uses "now" in the school's zone.
    final isAdmin = _isStaffAdminPersona ?? await _resolveIsStaffAdminPersona();
    final nowUtc = DateTime.now().toUtc();

    final DateTime occurredAt = isAdmin
        ? SchoolZoneDateTime.utcFromSchoolWallClock(
            schoolTimeZone,
            year: selectedDate.year,
            month: selectedDate.month,
            day: selectedDate.day,
            hour: selectedTime.hour,
            minute: selectedTime.minute,
          )
        : SchoolZoneDateTime.utcNowInSchool(schoolTimeZone);

    final attendanceDate = SchoolZoneDateTime.yyyyMmDdFromUtcInstant(
      occurredAt,
      schoolTimeZone,
    );

    if (isParent) {
      final selectedDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final schoolToday = SchoolZoneDateTime.schoolCalendarTodayOnly(
        schoolTimeZone,
      );
      if (selectedDay.isAfter(schoolToday)) {
        if (!mounted) return;
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('Parents cannot sign in for future dates.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
    } else if (isAdmin) {
      // Admin cannot sign in for a future date/time
      if (occurredAt.isAfter(nowUtc)) {
        if (!mounted) return;
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('You cannot sign in for future date/time.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
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

    final classroomCodeByStudentCode = <String, String>{
      for (final s in currentStudents)
        if (s.studentCode.trim().isNotEmpty &&
            s.classroomCode.trim().isNotEmpty)
          s.studentCode.trim(): s.classroomCode.trim(),
    };
    final defaultClassroomCode = classroomCodeByStudentCode.values.isNotEmpty
        ? classroomCodeByStudentCode.values.first
        : '';

    final payload = <String, dynamic>{
      'studentCodes': studentCodes,
      'method': isParent ? 'GPS' : 'APP',
      'latitude': 0,
      'longitude': 0,
      'withinGeofence': true,
      'isGeofence': true,
      'timeZone': schoolTimeZone,
    };
    if (isParent) {
      final guardianCode = (await resolveGuardianCodeForLoggedInUser()).trim();
      if (!mounted) return;
      if (guardianCode.isEmpty) {
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('Unable to resolve guardian code. Please re-login.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
      payload['guardianCode'] = guardianCode;
    } else {
      if (defaultClassroomCode.isEmpty) {
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('Classroom code missing for selected students'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
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
      payload.addAll(<String, dynamic>{
        'attendanceDate': attendanceDate,
        'staffCode': staffCode,
        'classroomCode': defaultClassroomCode,
        'classroomCodeByStudentCode': classroomCodeByStudentCode,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
      });
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (!isParent) {
        final staffCode = (payload['staffCode'] ?? '').toString().trim();
        if (staffCode.isNotEmpty) {
          await _deleteTodaysAbsenceRecordsBeforeStaffSignIn(
            attendanceDateYyyyMmDd: attendanceDate,
            staffCode: staffCode,
            students: List<StudentEntity>.from(currentStudents),
          );
        }
      }

      final body = Map<String, dynamic>.from(payload);
      Map<String, dynamic>? queryParameters;
      if (isParent) {
        final g = body.remove('guardianCode');
        if (g != null && g.toString().trim().isNotEmpty) {
          queryParameters = {'guardianCode': g.toString().trim()};
        }
      }
      await applyAllowedClassroomCodesToAttendanceBody(
        body,
        serviceLocator<StorageService>(),
      );
      final response = await client.post<dynamic>(
        endpoint,
        queryParameters: queryParameters,
        data: body,
      );

      final data = response.data;
      bool success = false;
      String message = 'Signed-In successfully';

      if (data is Map<String, dynamic>) {
        success = data['success'] as bool? ?? false;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

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
          widget.refreshCallback();
          Navigator.of(context).pop();
        } else if (isParent) {
          final s = currentStudents.first;
          if (context.mounted) {
            context.read<ParentChildProvider>().selectByCode(s.studentCode);
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              settings: const RouteSettings(
                name: StudentAttendanceProfile.routeName,
              ),
              builder: (_) => StudentAttendanceProfile(
                studentCode: s.studentCode,
                studentId: s.id,
                studentName: s.fullName,
                studentPhotoUuid: s.photoUuid,
                roomName: s.roomName,
                isSignedIn: true,
                syncWithParentChildSelection: true,
              ),
            ),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const StudentAttendanceTabbedView(),
            ),
            (route) => false,
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
    if (currentStudents.isEmpty) {
      // Fallback if students list is empty
      currentStudents = List.from(widget.students);
    }

    return StaffFormLayout(
      title: 'Sign-In',
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
                        initialDate: selectedDate,
                        isDisabled: !(_isStaffAdminPersona ?? false),
                        onDateSelected: (date) {
                          setState(() {
                            // Prevent future dates (school calendar), not device calendar.
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
                            selectedDate = pickedDay.isAfter(today)
                                ? today
                                : date;
                          });
                          _runUnexpectedSignInGate();
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
                          time: selectedTime,
                          onTimeSelected: (t) {
                            setState(() {
                              selectedTime = t;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Sign-In',
        onPressedConfirm:
            (_isSubmitting ||
                _unexpectedGateLoading ||
                (_hasUnexpectedAmongSelected() &&
                    !_unexpectedSignInAcknowledged))
            ? null
            : _submitSignIn,
      ),
    );
  }
}

// Simplified RemoveStudentTile widget for UI-only implementation
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  fileUuid: student.photoUuid ?? '',
                  name: student.fullName,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: AppText.value(
                    student.fullName.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
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
