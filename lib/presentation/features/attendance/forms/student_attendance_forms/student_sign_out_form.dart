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
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';

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
    this.popOnSuccess = false,
    this.isQrScan = false,
    this.qrToken = '',
    this.isKiosk = false,
    this.guardianCode,
    this.pin,
    super.key,
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;
  // When true, pops back to the caller after a successful submission instead of
  // pushAndRemoveUntil → StudentAttendanceTabbedView. Set by callers that live
  // outside the Attendance tab (e.g. the Classroom Students card).
  final bool popOnSuccess;

  /// True when triggered from a QR code scan.
  /// Sets method=QR and withinGeofence=true in the API payload.
  final bool isQrScan;

  /// QR token from the scanned code (only set when isQrScan=true).
  /// Included in the API payload when method=QR.
  final String qrToken;

  /// True when called from kiosk flow (guardian persona).
  /// When true, skips staff code resolution.
  final bool isKiosk;

  /// Guardian code from kiosk PIN verification.
  /// Only set when isKiosk=true.
  final String? guardianCode;

  /// PIN from kiosk access. Included in API payload for kiosk sign-out.
  final String? pin;

  static const String routeName = '/student-sign-out-form';

  @override
  State<StudentSignOutForm> createState() => _StudentSignOutFormState();
}

class _StudentSignOutFormState extends State<StudentSignOutForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String? _schoolIana;
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
      String? iana;
      try {
        iana = await SchoolTimezoneResolver.resolveForCurrentSchool(
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
        _schoolIana = iana;
        _isStaffAdminPersona = isAdmin;
        if (iana != null && iana.isNotEmpty) {
          final dt = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(iana);
          selectedDate = dt.$1;
          selectedTime = dt.$2;
        } else {
          final now = DateTime.now();
          selectedDate = now;
          selectedTime = TimeOfDay.fromDateTime(now);
        }
      });
    } catch (_) {}
  }

  Future<bool> _resolveIsParentSession() async {
    if (context.read<RoleCubit>().isParent) return true;

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

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (currentStudents.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No students selected to sign out'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final isParent = await _resolveIsParentSession();

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );

    final isAdmin = _isStaffAdminPersona ?? false;
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
            content: Text('Parents cannot sign out for future dates.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
    } else if (isAdmin) {
      if (occurredAt.isAfter(nowUtc)) {
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

    GeofenceState? geofenceState;
    try {
      geofenceState = context.read<GeofenceCubit>().state;
    } catch (_) {
      geofenceState = null;
    }
    // QR and GPS sign-outs are physical-presence methods — withinGeofence is
    // always true. APP (staff/admin manual) derives it from the geofence state.
    final String signOutMethod;
    final bool withinGeofence;
    if (isParent) {
      signOutMethod = widget.isQrScan ? 'QR' : 'GPS';
      withinGeofence = true; // physical presence proven by QR scan or GPS
    } else {
      signOutMethod = 'APP';
      withinGeofence = geofenceState?.isWithinGeofence ?? false;
    }

    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    final payload = <String, dynamic>{
      'studentCodes': studentCodes,
      'method': signOutMethod,
      'latitude': position?.latitude ?? 0,
      'longitude': position?.longitude ?? 0,
      'withinGeofence': withinGeofence,
      'timeZone': schoolTimeZone,
    };
    // Include QR token if this is a QR scan
    if (widget.isQrScan && widget.qrToken.isNotEmpty) {
      payload['qrToken'] = widget.qrToken;
    }
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
      // For kiosk flow (guardian), skip staff code resolution
      if (!widget.isKiosk) {
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
      } else {
        // KIOSK MODE: Use guardian code directly, no staff code needed
        payload['method'] = 'PIN';
        payload.addAll(<String, dynamic>{
          'guardianCode': widget.guardianCode,
          'pin': widget.pin,
          'isExpected': true,
        });
      }
    }

    try {
      final result = await serviceLocator<AttendanceRepository>()
          .submitStudentSignOut(payload: payload, isParent: isParent || widget.isKiosk);
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
        serviceLocator<ParentChildCubit>().forceRefresh();
        if (widget.popOnSuccess) {
          widget.refreshCallback?.call();
          Navigator.of(context).pop();
        } else if (widget.isKiosk) {
          context.go('/kiosk');
        } else if (isParent) {
          final s = currentStudents.first;
          if (context.mounted) {
            context.read<ParentChildCubit>().selectByCode(s.studentCode);
          }
          context.go(
            StudentAttendanceProfile.routeName,
            extra: <String, dynamic>{
              'studentCode': s.studentCode,
              'studentId': s.id,
              'studentName': s.fullName,
              'studentPhotoUuid': s.photoUuid,
              'roomName': s.roomName,
              'isSignedIn': false,
              'syncWithParentChildSelection': true,
            },
          );
        } else {
          context.go(StudentAttendanceTabbedView.routeName);
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
    if (!AttendancePermissionService.hasPermissionToManageStudentAttendance(context)) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Access Denied: You must be inside geofence and signed in to manage student attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    if (currentStudents.isEmpty && widget.students.isNotEmpty) {
      currentStudents = List.from(widget.students);
    }

    return StaffFormLayout(
      isKiosk: widget.isKiosk,
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
            child: SvgPicture.asset(
              MediaRes.delete_icon,
              height: 18,
              width: 18,
            ),
          ),
        ],
      ),
    );
  }
}
