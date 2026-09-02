import 'dart:async';
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
import 'package:wowcare/core/util/attendance_events.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_in_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_in_submit_state.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_in_gate_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_in_gate_state.dart';
import 'package:wowcare/presentation/features/attendance/widgets/unexpected_sign_in_attention_dialog.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/core/util/guardian_code_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
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
  /// Owns the sign-in submit call (View -> Cubit -> UseCase -> Repository).
  /// Eagerly resolved so [dispose] can always close it.
  final StudentSignInSubmitCubit _submitCubit =
      serviceLocator<StudentSignInSubmitCubit>();

  /// Owns ALL of the form's business state (date/time, school zone, persona,
  /// current students, unexpected-sign-in gate). The View is now stateless
  /// (no `setState`) and reads everything via `BlocBuilder`. Dialog + navigation
  /// stay here in the View — the cubit never touches [BuildContext].
  final StudentSignInGateCubit _gateCubit =
      serviceLocator<StudentSignInGateCubit>();

  /// Pure re-entrancy guard for the submit handler — NOT UI state (the button's
  /// disabled/spinner reads [_submitCubit]'s InProgress). This spans the whole
  /// operation (pre-submit steps included), so a double-tap during the pre-step
  /// window can't fire two submits — the guarantee the old local `_isSubmitting`
  /// gave, which the submit cubit's InProgress (which starts only at submit())
  /// does not cover.
  bool _submitInFlight = false;

  @override
  void initState() {
    super.initState();
    // Mirrors the original two-path bootstrap:
    //  - seed the working student list, then
    //  - _loadPersonaFlags(): resolve persona, then post-frame run the gate, and
    //  - post-frame _bootstrapSchoolZone(): resolve zone + setCurrentDateTime,
    //    then run the gate.
    _gateCubit.seedStudents(widget.students);
    _gateCubit.loadPersonaFlags().then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _runGate());
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _gateCubit.bootstrapSchoolZone();
      if (mounted) _runGate();
    });
  }

  @override
  void dispose() {
    _gateCubit.close();
    _submitCubit.close();
    super.dispose();
  }

  /// Runs the cubit's expected-today fetch (token cancellation lives in the
  /// cubit), then owns the dialog + navigation the cubit cannot: a superseded
  /// resolve does nothing; a current result that needs the dialog shows it and
  /// either acknowledges (confirm) or pops the screen (cancel).
  Future<void> _runGate() async {
    final outcome = await _gateCubit.resolveExpectedToday();
    if (!mounted || outcome.superseded) return;
    if (outcome.needsDialog) {
      final result = await showUnexpectedSignInAttentionDialog(
        context,
        unexpectedFullNames: outcome.unexpectedNames,
        forStaff: false,
      );
      if (!mounted) return;
      if (result?.confirmed == true) {
        _gateCubit.acknowledgeUnexpected(result?.comment ?? '');
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  void _removeStudent(StudentEntity s) {
    final nowEmpty = _gateCubit.removeStudent(s);
    if (nowEmpty) {
      Navigator.pop(context);
    }
  }

  Future<String> _resolveStaffCode() => resolveStaffCodeForLoggedInUser();

  Future<void> _submitSignIn() async {
    final gateState = _gateCubit.state;
    if (_submitInFlight) return;
    // Snapshot the business state the request is built from (unchanged logic).
    final currentStudents = gateState.currentStudents;
    final selectedDate = gateState.selectedDate;
    final selectedTime = gateState.selectedTime;
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

    final isParent = await AttendancePermissionService.resolveIsParentSession(
      context,
    );

    final schoolTimeZone = await _gateCubit.resolveFreshSchoolTimeZone();

    // Staff (admin or regular) pick school-local date/time; parents/kiosk use "now" in the school's zone.
    // Persona is resolved during initState (loadPersonaFlags) before any user
    // interaction, so it is non-null here in practice; default to non-staff.
    final isStaffPersona = gateState.isStaffPersona ?? false;

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

    // Resolve persona-specific values (with the same guards as before), then
    // assemble a typed StudentSignInRequest whose toPayload() reproduces the
    // exact payload map this form used to build.
    final StudentSignInMode mode;
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
      mode = StudentSignInMode.parent;
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
        mode = StudentSignInMode.staff;
        resolvedStaffCode = staffCode;
      } else {
        // KIOSK MODE: Use guardian code directly, no staff code needed.
        // Never log the PIN itself (secret credential) — length only.
        AppLogger.d(
          '[KIOSK] Building kiosk payload: pinLength=${widget.pin?.length ?? 0}, guardianCode=${widget.guardianCode}',
        );
        mode = StudentSignInMode.kiosk;
        resolvedGuardianCode = widget.guardianCode;
        resolvedPin = widget.pin;
      }
    }

    final request = StudentSignInRequest(
      mode: mode,
      studentCodes: studentCodes,
      signInMethod: signInMethod,
      latitude: position?.latitude ?? 0,
      longitude: position?.longitude ?? 0,
      withinGeofence: withinGeofence,
      timeZone: schoolTimeZone,
      qrToken: (widget.isQrScan && widget.qrToken.isNotEmpty)
          ? widget.qrToken
          : null,
      notExpectedComment: gateState.notExpectedComment.trim().isNotEmpty
          ? gateState.notExpectedComment.trim()
          : null,
      guardianCode: resolvedGuardianCode,
      pin: resolvedPin,
      attendanceDate: mode == StudentSignInMode.staff ? attendanceDate : null,
      staffCode: resolvedStaffCode,
      classroomCode: mode == StudentSignInMode.staff
          ? defaultClassroomCode
          : null,
      classroomCodeByStudentCode: mode == StudentSignInMode.staff
          ? classroomCodeByStudentCode
          : null,
      occurredAtIso: mode == StudentSignInMode.staff
          ? occurredAt.toUtc().toIso8601String()
          : null,
    );

    // Submit state (spinner / button-disable) is driven by [_submitCubit], which
    // emits InProgress at the start of submit() below and Success/Failure at the
    // end. [_submitInFlight] is only a re-entrancy guard (covers the pre-steps
    // too), never UI state.
    _submitInFlight = true;
    try {
      if (!isParent) {
        final staffCode = (request.staffCode ?? '').trim();
        if (staffCode.isNotEmpty) {
          await _submitCubit.clearTodaysAbsenceRecordsBeforeSignIn(
            attendanceDateYyyyMmDd: attendanceDate,
            staffCode: staffCode,
            students: currentStudents
                .map(
                  (s) => (
                    studentCode: s.studentCode,
                    classroomCode: s.classroomCode,
                    fullName: s.fullName,
                  ),
                )
                .toList(),
          );
        }
      }

      final result = await _submitCubit.submit(
        request: request,
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
      _submitInFlight = false;
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

    return BlocProvider<StudentSignInGateCubit>.value(
      value: _gateCubit,
      child: BlocBuilder<StudentSignInGateCubit, StudentSignInGateState>(
        builder: (context, gate) {
          final currentStudents = gate.currentStudents;
          final isStaffPersona = gate.isStaffPersona ?? false;
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                              initialDate: gate.selectedDate,
                              isDisabled: !isStaffPersona,
                              onDateSelected: (date) {
                                // Prevent future dates (school calendar), not
                                // device calendar.
                                final iana = gate.schoolIana;
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
                                final clamped = pickedDay.isAfter(today)
                                    ? today
                                    : date;
                                _gateCubit.setSelectedDate(clamped);
                                unawaited(_runGate());
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
                              ignoring: !isStaffPersona,
                              child: GradientTimePickerField(
                                time: gate.selectedTime,
                                onTimeSelected: (t) {
                                  _gateCubit.setSelectedTime(t);
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
            bottomBar:
                BlocBuilder<StudentSignInSubmitCubit, StudentSignInSubmitState>(
                  bloc: _submitCubit,
                  builder: (context, submitState) {
                    final hasUnexpected = _gateCubit
                        .hasUnexpectedAmongSelected();
                    final disabled =
                        (submitState is StudentSignInSubmitInProgress) ||
                        gate.unexpectedGateLoading ||
                        (hasUnexpected && !gate.unexpectedSignInAcknowledged);
                    return CustomButtonLayout(
                      confirmButtonLabel: 'Sign-In',
                      onPressedConfirm: disabled ? null : _submitSignIn,
                      showCancelButton: widget.isKiosk,
                      onPressedCancel: widget.isKiosk
                          ? () {
                              context.go('/kiosk');
                            }
                          : null,
                    );
                  },
                ),
          );
        },
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
        color: AppColors.attendanceSelectedTintColor,
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
