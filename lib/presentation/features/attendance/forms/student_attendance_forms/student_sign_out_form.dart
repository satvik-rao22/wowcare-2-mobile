import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_remove_tile.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/attendance_events.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_out_request.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_out_submit_cubit.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_redirect.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_permission_service.dart';
import 'package:wowcare/domain/features/attendance/usecases/validate_qr_code_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view_model/qr_code_validation_cubit.dart';
import 'student_entity.dart';

export 'student_entity.dart';

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
  DateTime selectedDate = ServerTimeService.instance.now();
  TimeOfDay selectedTime = ServerTimeService.instance.timeOfDayNow();
  String? _schoolIana;
  List<StudentEntity> currentStudents = [];
  bool _isSubmitting = false;
  bool? _isStaffPersona;

  /// Owns the sign-out submit call (View -> Cubit -> UseCase -> Repository).
  /// Eagerly resolved so [dispose] can always close it.
  final StudentSignOutSubmitCubit _submitCubit =
      serviceLocator<StudentSignOutSubmitCubit>();
  final QrCodeValidationCubit _qrCubit =
      serviceLocator<QrCodeValidationCubit>();

  @override
  void initState() {
    super.initState();
    if (widget.students.isNotEmpty) {
      currentStudents = List.from(widget.students);
    }
    _loadPersonaFlags();
  }

  @override
  void dispose() {
    _submitCubit.close();
    super.dispose();
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
        iana = await _submitCubit.resolveFreshSchoolTimeZone();
      } catch (_) {}

      final isStaff = await _submitCubit.resolveIsStaffPersona();
      if (!mounted) return;
      setState(() {
        _schoolIana = iana;
        _isStaffPersona = isStaff;
        final now = ServerTimeService.instance.now();
        selectedDate = now;
        selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      });
    } catch (_) {}
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

    final isParent = await AttendancePermissionService.resolveIsParentSession(
      context,
    );

    final schoolTimeZone = await _submitCubit.resolveFreshSchoolTimeZone();

    final isStaffPersona = _isStaffPersona ?? false;

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
            content: Text('Parents cannot sign out for future dates.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
    }
    // Staff future-date/time was previously blocked here client-side by
    // comparing `occurredAt` against a separately-captured `nowUtc` a few
    // statements earlier — clock drift (or just the wall clock ticking
    // forward) between those two reads could false-positive this warning
    // even for an unmodified, still-defaulted-to-now pick. The backend
    // already rejects an actually-future sign-out; no need to duplicate
    // (and potentially misfire) that check here.

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

    // QR pre-check: validate token with GUARDIAN_SIGN_OUT before calling write API
    if (widget.isQrScan && widget.qrToken.isNotEmpty) {
      try {
        final result = await _qrCubit.validate(
          qrToken: widget.qrToken,
          useCase: QrAttendanceUseCase.guardianSignOut,
        );
        if (!mounted) return;
        if (!result.valid) {
          CoreUtils.showTopSnackBarFromSnackBar(
            context: context,
            snackBar: SnackBar(
              content: Text(result.reason ?? 'QR code is not valid'),
              backgroundColor: AppColors.warningColor,
            ),
          );
          return;
        }
      } catch (_) {
        if (!mounted) return;
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('Failed to validate QR code'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
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

    // Resolve persona-specific values (with the same guards as before), then
    // assemble a typed StudentSignOutRequest whose toPayload() reproduces the
    // exact payload map this form used to build.
    final StudentSignOutMode mode;
    String? resolvedGuardianCode;
    String? resolvedPin;
    String? resolvedStaffCode;
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
      mode = StudentSignOutMode.parent;
      resolvedGuardianCode = guardianCode;
      resolvedPin = widget.pin ?? '';
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
        mode = StudentSignOutMode.staff;
        resolvedStaffCode = staffCode;
      } else {
        // KIOSK MODE: Use guardian code directly, no staff code needed.
        mode = StudentSignOutMode.kiosk;
        resolvedGuardianCode = widget.guardianCode;
        resolvedPin = widget.pin;
      }
    }

    final request = StudentSignOutRequest(
      mode: mode,
      studentCodes: studentCodes,
      signOutMethod: signOutMethod,
      latitude: position?.latitude ?? 0,
      longitude: position?.longitude ?? 0,
      withinGeofence: withinGeofence,
      timeZone: schoolTimeZone,
      qrToken: (widget.isQrScan && widget.qrToken.isNotEmpty)
          ? widget.qrToken
          : null,
      guardianCode: resolvedGuardianCode,
      pin: resolvedPin,
      attendanceDate: mode == StudentSignOutMode.staff ? attendanceDate : null,
      staffCode: resolvedStaffCode,
      classroomCode: mode == StudentSignOutMode.staff
          ? defaultClassroomCode
          : null,
      classroomCodeByStudentCode: mode == StudentSignOutMode.staff
          ? classroomCodeByStudentCode
          : null,
      occurredAtIso: mode == StudentSignOutMode.staff
          ? occurredAt.toUtc().toIso8601String()
          : null,
    );

    try {
      final result = await _submitCubit.submit(
        request: request,
        isParent: isParent || widget.isKiosk || widget.isQrScan,
      );
      final success = result.success;
      var message = result.message;

      if (!mounted) return;

      // Normalize success messages for better UX
      if (success &&
          (message.toLowerCase().contains('sign out') ||
              message.toLowerCase().contains('sign-out') ||
              message.toLowerCase().contains('signed out'))) {
        message = 'Sign out successfully';
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
        context.read<ParentChildCubit>().forceRefresh();
        if (widget.popOnSuccess) {
          widget.refreshCallback?.call();
          Navigator.of(context).pop();
        } else if (widget.isKiosk) {
          // Reload QR code before returning to dashboard
          AppLogger.d('[Kiosk] Student sign-out success - reloading QR code');
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
              'isSignedIn': false,
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

    if (currentStudents.isEmpty && widget.students.isNotEmpty) {
      currentStudents = List.from(widget.students);
    }

    return StaffFormLayout(
      isKiosk: widget.isKiosk,
      showKioskBackButton: widget.isKiosk,
      showKioskLogoutMenu: widget.isKiosk,
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
              itemBuilder: (context, index) => AttendanceRemoveTile(
                name: currentStudents[index].fullName,
                photoUuid: currentStudents[index].photoUuid ?? '',
                onRemove: () => _removeStudent(currentStudents[index]),
                horizontalPadding: AppSpacing.sm,
                deleteIconSize: 18,
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
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Sign-Out',
        onPressedConfirm: _isSubmitting ? null : _handleSubmit,
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
