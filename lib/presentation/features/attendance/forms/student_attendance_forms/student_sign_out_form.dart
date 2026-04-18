import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

// Student entity for Sign-Out UI & API payload
class StudentEntity {
  final int id;
  final String studentCode;
  final String fullName;
  final int roomId;
  final String roomName;
  final String photoUuid;
  final String classroomCode;

  StudentEntity({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    this.photoUuid = '',
    required this.classroomCode,
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

class StudentSignOutForm extends StatefulWidget {
  const StudentSignOutForm({
    required this.students,
    this.refreshCallback,
    super.key,
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;

  static const String routeName = '/student-sign-out-form';

  @override
  State<StudentSignOutForm> createState() => _StudentSignOutFormState();
}

class _StudentSignOutFormState extends State<StudentSignOutForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<StudentEntity> currentStudents = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona;

  @override
  void initState() {
    super.initState();
    if (widget.students.isNotEmpty) {
      currentStudents = List.from(widget.students);
    }
    _loadPersonaFlags();
  }

  void _removeStudent(StudentEntity student) {
    setState(() {
      currentStudents.remove(student);

      if (currentStudents.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  Future<String> _resolveStaffCode() => resolveStaffCodeForLoggedInUser();

  Future<void> _loadPersonaFlags() async {
    try {
      final storage = serviceLocator<StorageService>();
      final staffType =
          (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();
      bool isAdmin = staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN';
      if (!isAdmin) {
        final rolesJson = await storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.trim().isNotEmpty) {
          final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
          for (final r in roles) {
            final roleCode =
                ((r as Map<String, dynamic>)['role'] ?? '').toString().toUpperCase();
            if (roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN') {
              isAdmin = true;
              break;
            }
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _isStaffAdminPersona = isAdmin;
        if (!isAdmin) {
          final now = DateTime.now();
          selectedDate = now;
          selectedTime = TimeOfDay.fromDateTime(now);
        }
      });
    } catch (_) {}
  }

  Future<bool> _resolveIsParentSession() async {
    if (context.read<RoleProvider>().isParent) return true;

    try {
      final storage = serviceLocator<StorageService>();
      final rolesJson = (await storage.getString(StorageKeys.roles) ?? '').trim();
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
      final contextRaw = jsonEncode(loginContext ?? const <String, dynamic>{})
          .toUpperCase();
      if (contextRaw.contains('PARENT') || contextRaw.contains('GUARDIAN')) {
        return true;
      }
    } catch (_) {
      // Ignore parse/storage issues and keep non-parent fallback.
    }

    return false;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (currentStudents.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('No students selected to sign out'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final client = serviceLocator<ApiClient>().client;
    final isParent = await _resolveIsParentSession();
    final endpoint = ApiPaths.urlWithBase(
      isParent
          ? ApiPaths.studentAttendanceRecordsParentSignOut
          : ApiPaths.studentAttendanceRecordsSignOut,
      ApiConstants.attendanceBaseUrl,
    );

    final now = DateTime.now();
    final isAdmin = _isStaffAdminPersona ?? false;
    final DateTime effectiveDate = isAdmin ? selectedDate : now;
    final TimeOfDay effectiveTime =
        isAdmin ? selectedTime : TimeOfDay.fromDateTime(now);

    final occurredAt = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
      effectiveTime.hour,
      effectiveTime.minute,
    ).toUtc();
    final attendanceDate =
        '${occurredAt.year.toString().padLeft(4, '0')}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';

    if (isParent) {
      final selectedDay =
          DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
      final today = DateTime(now.year, now.month, now.day);
      if (selectedDay.isAfter(today)) {
        if (!mounted) return;
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('Parents cannot sign out for future dates.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
    } else if (isAdmin) {
      if (occurredAt.isAfter(now.toUtc())) {
        if (!mounted) return;
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('You cannot sign out for future date/time.'),
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
        snackBar: 
        const SnackBar(
          content: Text('Student code missing for selected students'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final classroomCodeByStudentCode = <String, String>{
      for (final s in currentStudents)
        if (s.studentCode.trim().isNotEmpty && s.classroomCode.trim().isNotEmpty)
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
      'timeZone': 'UTC',
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
        'occurredAt': occurredAt.toIso8601String(),
      });
    }

    try {
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
      String message = 'Signed-Out successfully';

      if (data is Map<String, dynamic>) {
        success = data['success'] as bool? ?? false;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

      if (!mounted) return;

      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? AppColors.successColor : AppColors.errorColor,
        ),
      );

      if (success) {
        if (isParent) {
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
                isSignedIn: false,
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
        snackBar: 
        SnackBar(
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
    if (currentStudents.isEmpty && widget.students.isNotEmpty) {
      currentStudents = List.from(widget.students);
    }

    return StaffFormLayout(
      title: 'Sign-Out',
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
                onRemove: () => _removeStudent(
                  currentStudents[index],
                ),
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
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final pickedDay = DateTime(date.year, date.month, date.day);
                            selectedDate = pickedDay.isAfter(today) ? today : date;
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
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Sign-Out',
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
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.themeColor,
        ),
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
                    student.fullName.split(' ').first,
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
            child: SvgPicture.asset(
              MediaRes.delete_icon,
              height: 18,
              width: 18,
            ),
          )
        ],
      ),
    );
  }
}
