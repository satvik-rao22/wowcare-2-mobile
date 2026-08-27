import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_events.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_in_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/widgets/unexpected_sign_in_attention_dialog.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_redirect.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

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
    this.isQrScan = false,
    this.qrToken = '',
    this.isKiosk = false,
    this.guardianCode,
    this.pin,
  });

  final VoidCallback refreshCallback;
  final List<StudentEntity> students;
  // When true, pops back to the caller after a successful submission instead of
  // pushAndRemoveUntil → StudentAttendanceTabbedView. Set by callers that live
  // outside the Attendance tab (e.g. the Classroom Students card) so the user
  // stays on the screen they started from.
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

  /// PIN from kiosk access. Included in API payload for kiosk sign-in.
  final String? pin;

  static const String routeName = '/student-sign-in-form';

  @override
  State<StudentSignInForm> createState() => _StudentSignInFormState();
}

class _StudentSignInFormState extends State<StudentSignInForm> {
  DateTime selectedDate = ServerTimeService.instance.now();
  TimeOfDay selectedTime = ServerTimeService.instance.timeOfDayNow();

  /// School IANA id from API; when set, date/time defaults and [occurredAt] use this zone.
  String? _schoolIana;
  List<StudentEntity> currentStudents = [];
  bool _isSubmitting = false;

  /// Owns the sign-in submit call (View -> Cubit -> UseCase -> Repository).
  /// Eagerly resolved so [dispose] can always close it.
  final StudentSignInSubmitCubit _submitCubit =
      serviceLocator<StudentSignInSubmitCubit>();
  bool? _isStaffPersona;
  Map<String, bool> _expectedTodayFromApi = {};
  bool _unexpectedGateLoading = true;
  bool _unexpectedSignInAcknowledged = false;
  String _notExpectedComment = '';
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

  @override
  void dispose() {
    _submitCubit.close();
    super.dispose();
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
        _notExpectedComment = result?.comment ?? '';
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadPersonaFlags() async {
    final isStaff = await _resolveIsStaffPersona();
    if (!mounted) return;
    setState(() {
      _isStaffPersona = isStaff;
      if (!_isStaffPersona!) {
        setCurrentDateTime();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runUnexpectedSignInGate();
    });
  }

  /// True for any staff-side login (school/org admin or regular staff);
  /// false for guardian/parent and kiosk-PIN access. Gates date/time editing.
  Future<bool> _resolveIsStaffPersona() async {
    try {
      final storage = serviceLocator<StorageService>();
      final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
          .trim();
      if (staffType.isNotEmpty) return true;

      final rolesJson = await storage.getString(StorageKeys.roles);
      if (rolesJson == null || rolesJson.trim().isEmpty) return false;
      final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
      for (final r in roles) {
        final roleCode = ((r as Map<String, dynamic>)['role'] ?? '')
            .toString()
            .toUpperCase();
        if (roleCode.contains('GUARDIAN') ||
            roleCode.contains('PARENT') ||
            roleCode.contains('KIOSK')) {
          continue;
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  void setCurrentDateTime() {
    final dateTime = ServerTimeService.instance.now();
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
        _notExpectedComment = '';
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

    // The absent-form-list lookup is a best-effort PRE-step: it exists only to
    // clear a same-day absence record before signing the student in. If it
    // fails (e.g. the backend 500s on this endpoint), do NOT abort the whole
    // sign-in — skip the deletion and let the sign-in POST run. Worst case the
    // backend rejects the sign-in for a still-present absence record, which is a
    // clear, actionable error; being unable to sign anyone in is worse.
    try {
      var page = 0;
      const pageSize = 200;
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
    } catch (e) {
      AppLogger.d(
        '[StudentSignIn] absent-form-list lookup failed ($e); '
        'proceeding to sign-in without clearing absence records',
      );
      return; // skip deletion, caller continues to the sign-in POST
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
          'Cannot sign in ${s.fullName}: marked absent for '
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
    final roleCubit = context.read<RoleCubit>();
    // Once RoleCubit has resolved the ACTIVE persona, it is authoritative —
    // trust it even when false. A dual-role account (e.g. SCHOOL_ADMIN +
    // GUARDIAN) has 'GUARDIAN' somewhere in its full roles list regardless of
    // which persona is currently active, so scanning that list below would
    // wrongly flip an admin who switched profiles back to a guardian sign-in.
    // Only fall through to the best-effort scan while RoleCubit is still
    // bootstrapping (no active persona resolved yet).
    if (roleCubit.hasResolvedAccess) return roleCubit.isParent;
    if (roleCubit.isParent) return true;

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

    final isParent = await _resolveIsParentSession();

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );

    // Staff (admin or regular) pick school-local date/time; parents/kiosk use "now" in the school's zone.
    final isStaffPersona = _isStaffPersona ?? await _resolveIsStaffPersona();

    final DateTime occurredAt = isStaffPersona
        ? SchoolZoneDateTime.resolvePickedInstantUtc(
            schoolTimeZone,
            selectedDate: selectedDate,
            selectedTime: selectedTime,
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
    }
    // Staff future-date/time was previously blocked here client-side, but
    // `occurredAt` and `nowUtc` come from two separately-captured "now"
    // reads a few statements apart — clock drift between them (or just the
    // wall clock ticking forward between the reads) could make an
    // unmodified, still-defaulted-to-now pick register as "after now" and
    // false-positive this warning even though nothing was actually set to
    // the future. The backend is the source of truth for this and already
    // rejects an actually-future sign-in; no need to duplicate (and
    // potentially misfire) that check here.

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
    // QR and GPS sign-ins are physical-presence methods — withinGeofence is
    // always true. APP (staff/admin manual) derives it from the geofence state.
    final String signInMethod;
    final bool withinGeofence;
    if (isParent) {
      signInMethod = widget.isQrScan ? 'QR' : 'GPS';
      withinGeofence = true; // physical presence proven by QR scan or GPS
    } else {
      signInMethod = 'APP';
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
      'method': signInMethod,
      'latitude': position?.latitude ?? 0,
      'longitude': position?.longitude ?? 0,
      'withinGeofence': withinGeofence,
      'timeZone': schoolTimeZone,
    };
    // Include QR token if this is a QR scan
    if (widget.isQrScan && widget.qrToken.isNotEmpty) {
      payload['qrToken'] = widget.qrToken;
    }
    if (_notExpectedComment.trim().isNotEmpty) {
      payload['notExpectedComment'] = _notExpectedComment.trim();
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
      payload['pin'] = widget.pin ?? '';
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
        // Never log the PIN itself (secret credential) — length only.
        AppLogger.d(
          '[KIOSK] Building kiosk payload: pinLength=${widget.pin?.length ?? 0}, guardianCode=${widget.guardianCode}',
        );
        payload['method'] = 'PIN';
        payload.addAll(<String, dynamic>{
          'guardianCode': widget.guardianCode,
          'pin': widget.pin,
          'isExpected': true,
        });
      }
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

      final result = await _submitCubit.submit(
        payload: payload,
        isParent: isParent || widget.isKiosk || widget.isQrScan,
      );
      final success = result.success;
      var message = result.message;

      if (!mounted) return;

      // Normalize success messages for better UX
      if (success &&
          (message.toLowerCase().contains('sign in') ||
              message.toLowerCase().contains('sign-in') ||
              message.toLowerCase().contains('signed in'))) {
        message = 'Sign in successfully';
      }

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
        AttendanceEvents.notifyChanged();
        serviceLocator<ParentChildCubit>().forceRefresh();
        if (widget.popOnSuccess) {
          widget.refreshCallback();
          if (context.canPop()) {
            context.pop();
          } else {
            Navigator.of(context).pop();
          }
        } else if (widget.isKiosk) {
          // Reload QR code before returning to dashboard
          AppLogger.d('[Kiosk] Student sign-in success - reloading QR code');
          unawaited(context.read<KioskDashboardCubit>().loadQrCode());
          context.go('/kiosk');
        } else if (widget.isQrScan || widget.qrToken.isNotEmpty) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          context.go('/dashboard');
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
              'isSignedIn': true,
              'syncWithParentChildSelection': true,
            },
          );
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
      // GPS parent sign-in disabled: show a warning and close the form so the
      // parent returns to the dashboard where the button will now be disabled.
      final isGpsParentDisabled = errorMessage.toLowerCase().contains(
        'gps parent sign-in is disabled',
      );
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(
            isGpsParentDisabled
                ? 'GPS sign-in for parents is disabled by the school admin.'
                : errorMessage,
          ),
          backgroundColor: isGpsParentDisabled
              ? AppColors.warningColor
              : AppColors.errorColor,
        ),
      );
      if (isGpsParentDisabled && mounted) Navigator.of(context).pop();
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
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    if (currentStudents.isEmpty) {
      // Fallback if students list is empty
      currentStudents = List.from(widget.students);
    }

    return StaffFormLayout(
      title: 'Sign-In',
      isKiosk: widget.isKiosk,
      showKioskBackButton: widget.isKiosk,
      showKioskLogoutMenu: widget.isKiosk,
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
                        initialDate: selectedDate,
                        isDisabled: !(_isStaffPersona ?? false),
                        onDateSelected: (date) {
                          setState(() {
                            // Prevent future dates (school calendar), not device calendar.
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
                            selectedDate = pickedDay.isAfter(today)
                                ? today
                                : date;
                          });
                          unawaited(_runUnexpectedSignInGate());
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
        showCancelButton: widget.isKiosk,
        onPressedCancel: widget.isKiosk
            ? () {
                context.go('/kiosk');
              }
            : null,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
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
                  fileUuid: student.photoUuid ?? '',
                  name: student.fullName,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: AppSpacing.s6),
                Flexible(
                  child: AppText.value(
                    student.fullName,
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
