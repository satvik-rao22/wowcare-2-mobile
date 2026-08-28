import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_staff_absence_record_usecase.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_absent.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_in_request.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_events.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_submit_state.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_gate_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_gate_state.dart';
import 'staff_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_redirect.dart';
import 'package:wowcare/presentation/features/attendance/widgets/unexpected_sign_in_attention_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

class StaffSignInForm extends StatefulWidget {
  const StaffSignInForm({
    super.key,
    this.staff,
    this.staffList,
    this.qrToken = '',
    this.forceSelf = false,
    this.isKiosk = false,
    this.staffCode,
    this.staffName,
    this.pin,
  });

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;
  final String qrToken;

  /// When true, always uses the self sign-in endpoint regardless of admin role.
  /// Set this when opening the form from a personal GPS sign-in button.
  final bool forceSelf;

  /// True when called from kiosk flow.
  final bool isKiosk;

  /// Staff code from kiosk PIN verification. Only set when isKiosk=true.
  final String? staffCode;

  /// Staff name from kiosk PIN verification. Only set when isKiosk=true.
  final String? staffName;

  /// PIN from kiosk access. Included in API payload for kiosk sign-in.
  final String? pin;

  static const String routeName = '/staff-sign-in-form';

  @override
  State<StaffSignInForm> createState() => _StaffSignInFormState();
}

class _StaffSignInFormState extends State<StaffSignInForm> {
  /// Owns the sign-in submit call (View -> Cubit -> UseCase -> Repository).
  /// Eagerly resolved so [dispose] can always close it.
  final StaffSignInSubmitCubit _submitCubit =
      serviceLocator<StaffSignInSubmitCubit>();

  /// Owns ALL of the form's business state (date/time, school zone, persona,
  /// current staff, unexpected-sign-in gate). The View is now stateless
  /// (no `setState`) and reads everything via `BlocBuilder`. Dialog + navigation
  /// stay here in the View — the cubit never touches [BuildContext].
  final StaffSignInGateCubit _gateCubit =
      serviceLocator<StaffSignInGateCubit>();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeFormData());
    });
  }

  @override
  void dispose() {
    _gateCubit.close();
    _submitCubit.close();
    super.dispose();
  }

  /// Initializes form data in proper order (identical to the widget's original
  /// orchestration, now driving the cubit):
  /// 1. Load current staff code (kiosk staffCode, else storage)
  /// 2. Initialize school/persona settings + selection restrictions
  /// 3. Run the unexpected-sign-in gate (dialog + nav owned here)
  /// 4. Pre-populate self if non-admin/QR/GPS/kiosk and no staff resolved yet
  Future<void> _initializeFormData() async {
    await _gateCubit.loadCurrentStaffCode(
      isKiosk: widget.isKiosk,
      kioskStaffCode: widget.staffCode,
    );
    if (!mounted) return;
    // The View resolves the persona — RoleCubit's active persona is the
    // canonical, persona-switch-aware signal and needs BuildContext.
    final isStaffAdmin = !context.read<RoleCubit>().isStaff;
    await _gateCubit.initializeSchoolAndPersona(
      isStaffAdminPersona: isStaffAdmin,
      staff: widget.staff,
      staffList: widget.staffList,
    );
    if (!mounted) return;
    await _runGate();
    if (!mounted) return;
    await _gateCubit.applyExtraSelfPrefill(
      isKiosk: widget.isKiosk,
      kioskStaffName: widget.staffName,
      forceSelf: widget.forceSelf,
      qrToken: widget.qrToken,
    );
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
        forStaff: true,
      );
      if (!mounted) return;
      if (result?.confirmed == true) {
        _gateCubit.acknowledgeUnexpected(result?.comment ?? '');
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<String> _resolveStaffCode() async {
    // In kiosk mode, use the staff code from PIN verification
    if (widget.isKiosk &&
        widget.staffCode != null &&
        widget.staffCode!.isNotEmpty) {
      return widget.staffCode!.trim();
    }
    // Otherwise, resolve from logged-in user
    return resolveStaffCodeForLoggedInUser();
  }

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

  /// Admin override sign-in: for staff marked absent on
  /// [attendanceDateYyyyMmDd], delete their absence record first so the day
  /// isn't left with both an ABSENT record and a sign-in. Only ever called
  /// for the admin persona (see call site in [_handleSubmit]) — self-service
  /// staff sign-in never reaches this, matching [StaffAttendanceGate]'s rule
  /// that an absent staff member cannot recover their own day.
  Future<void> _deleteTodaysAbsenceRecordsBeforeAdminSignIn({
    required String attendanceDateYyyyMmDd,
    required String actingStaffCode,
    required List<StaffEntity> targets,
  }) async {
    final allItems = <StaffAttendanceAbsentItem>[];

    // The absent-form-list lookup is a best-effort PRE-step: it exists only
    // to clear a same-day absence record before signing the staff member in.
    // If it fails, do NOT abort the whole sign-in — skip the deletion and
    // let the sign-in POST run; the backend is the actionable source of
    // truth if a stale absence record does end up blocking it.
    try {
      var page = 0;
      const pageSize = 200;
      while (true) {
        final absentPage =
            await serviceLocator<GetStaffAbsentFormListUseCase>()(
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
        '[StaffSignIn] absent-form-list lookup failed ($e); '
        'proceeding to sign-in without clearing absence records',
      );
      return;
    }

    final processedStaffCodes = <String>{};
    for (final s in targets) {
      final sc = (s.staffCode ?? '').trim();
      if (sc.isEmpty || processedStaffCodes.contains(sc)) continue;

      final matches = allItems.where((it) {
        if (it.staffCode.trim() != sc) return false;
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
          'Cannot sign in ${s.name}: marked absent for this day but the '
          'absence record could not be resolved. Refresh and try again.',
        );
      }

      final room = (s.classroomCode ?? '').trim();
      var chosen = withCode.first;
      if (room.isNotEmpty) {
        final byRoom = withCode
            .where((it) => it.classroomCode.trim() == room)
            .toList();
        if (byRoom.isNotEmpty) {
          chosen = byRoom.first;
        }
      }

      await serviceLocator<DeleteStaffAbsenceRecordUseCase>()(
        absenceRecordCode: chosen.absenceRecordCode!.trim(),
        staffCode: actingStaffCode,
      );
      processedStaffCodes.add(sc);
    }
  }

  Future<void> _handleSubmit() async {
    if (_submitInFlight) return;
    final selectedStaff = _gateCubit.state.selectedStaff;
    if (selectedStaff.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No staff selected to sign in'),
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

    final targetStaffCodes = selectedStaff
        .map((s) => (s.staffCode ?? '').trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (targetStaffCodes.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Target staff code is missing. Please refresh list.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final isStaffAdmin = _gateCubit.state.isStaffAdminPersona ?? false;

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );

    // Teachers:
    // - can only sign in for themselves
    // - cannot modify date/time (defaults to current)
    late final DateTime occurredAt;
    late final String attendanceDate;

    // QR sign-in is always "now" — it's physical proof of presence at the
    // scan moment, regardless of persona.
    final bool isQrForTime = widget.qrToken.isNotEmpty;
    if (!isStaffAdmin || isQrForTime) {
      if (!isStaffAdmin &&
          (targetStaffCodes.length != 1 ||
              targetStaffCodes.first != staffCode)) {
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('Teachers can only sign in for themselves.'),
            backgroundColor: AppColors.warningColor,
          ),
        );
        return;
      }
      occurredAt = SchoolZoneDateTime.utcNowInSchool(schoolTimeZone);
      attendanceDate = SchoolZoneDateTime.yyyyMmDdFromUtcInstant(
        occurredAt,
        schoolTimeZone,
      );
    } else {
      // Admin persona: always honors the picker, including for their own
      // record — that case is routed through the admin/bulk endpoint below
      // so the backend accepts the custom occurredAt.
      occurredAt = SchoolZoneDateTime.resolvePickedInstantUtc(
        schoolTimeZone,
        selectedDate: _gateCubit.state.selectedDate,
        selectedTime: _gateCubit.state.selectedTime,
      );
      attendanceDate = SchoolZoneDateTime.yyyyMmDdFromUtcInstant(
        occurredAt,
        schoolTimeZone,
      );
    }

    // Admin GPS (picker) future-date/time was previously blocked here
    // client-side by comparing `occurredAt` against a separately-captured
    // `nowUtc` a few statements earlier — clock drift (or just the wall
    // clock ticking forward) between those two reads could false-positive
    // this warning even for an unmodified, still-defaulted-to-now pick. The
    // backend already rejects an actually-future sign-in; no need to
    // duplicate (and potentially misfire) that check here.

    // Re-fetch expected-today fresh at submit time (as the widget did), falling
    // back to the gate's cached map on error.
    Map<String, bool> expectedFromApi;
    try {
      expectedFromApi = await _gateCubit.fetchExpectedToday(
        attendanceDate: attendanceDate,
      );
    } catch (_) {
      expectedFromApi = Map<String, bool>.from(
        _gateCubit.state.expectedTodayFromApi,
      );
    }

    // QR scan is physical proof of presence — skip GPS geofence check.
    // Kiosk is a fixed location device — always within geofence.
    final bool withinGeofence;
    if (widget.qrToken.isNotEmpty || widget.isKiosk) {
      withinGeofence = true;
    } else {
      GeofenceState? geofenceState;
      try {
        geofenceState = serviceLocator<GeofenceCubit>().state;
      } catch (_) {
        geofenceState = null;
      }
      withinGeofence = geofenceState?.isWithinGeofence ?? false;
    }

    // GPS is optional for kiosk (fixed location device)
    Position? position;
    if (!widget.isKiosk) {
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
    }

    final bool isQrSignIn = widget.qrToken.isNotEmpty;
    // The dashboard's personal sign-in card (forceSelf) is a GPS sign-in for
    // both admin and staff personas — only the admin bulk picker flow reports
    // 'APP'.
    final String signInMethod = isQrSignIn
        ? 'QR'
        : (isStaffAdmin && !widget.forceSelf ? 'PIN' : 'GPS');

    // Whether this sign-in targets the current user's own record — drives
    // post-submit UI (geofence status sync, navigating back vs to the daily
    // view), independent of which endpoint actually handles the submission.
    final bool isSelfSignIn = !isStaffAdmin || isQrSignIn || widget.forceSelf;
    // Which endpoint/payload shape to submit through. An admin persona acting
    // on their own record (e.g. My Day's Sign-In) still routes through the
    // admin/bulk endpoint so the picked date/time is honored — the /self
    // endpoint always forces "now".
    final bool useSelfEndpoint = !isStaffAdmin || isQrSignIn;

    // Resolve the values the two shapes share into locals (keeping every guard
    // above), then assemble a typed StaffSignInRequest whose toPayload()
    // reproduces the exact payload map this form used to build for each shape.
    final double latitude = position?.latitude ?? 0;
    final double longitude = position?.longitude ?? 0;
    final String occurredAtIso = occurredAt.toUtc().toIso8601String();
    final String notExpectedCommentRaw = _gateCubit.state.notExpectedComment;
    final String? notExpectedComment = notExpectedCommentRaw.trim().isNotEmpty
        ? notExpectedCommentRaw.trim()
        : null;

    final StaffSignInRequest request;
    if (useSelfEndpoint) {
      // Self sign-in: matches POST /staff-attendance-records/sign-in/self body.
      request = StaffSignInRequest(
        mode: StaffSignInMode.self,
        staffCode: staffCode,
        signInMethod: signInMethod,
        latitude: latitude,
        longitude: longitude,
        withinGeofence: withinGeofence,
        timeZone: schoolTimeZone,
        occurredAtIso: occurredAtIso,
        isExpectedToday: _gateCubit.isExpectedTodayForStaffCode(
          staffCode,
          expectedFromApi,
        ),
        isKiosk: widget.isKiosk,
        pin: widget.pin,
        qrToken: isQrSignIn ? widget.qrToken : null,
        notExpectedComment: notExpectedComment,
      );
    } else {
      // Admin bulk sign-in: supports signing in other staff.
      final staffCodes = targetStaffCodes;
      final classroomCodeByStaffCode = <String, String>{
        for (final s in selectedStaff)
          if ((s.staffCode ?? '').trim().isNotEmpty &&
              (s.classroomCode ?? '').trim().isNotEmpty)
            s.staffCode!.trim(): s.classroomCode!.trim(),
      };
      final String classroomCode = classroomCodeByStaffCode.isNotEmpty
          ? classroomCodeByStaffCode.values.first
          : '';

      request = StaffSignInRequest(
        mode: StaffSignInMode.adminBulk,
        staffCode: staffCode,
        signInMethod: signInMethod,
        latitude: latitude,
        longitude: longitude,
        withinGeofence: withinGeofence,
        timeZone: schoolTimeZone,
        occurredAtIso: occurredAtIso,
        isExpectedToday: _gateCubit.requestBodyIsExpectedToday(
          staffCodes: staffCodes,
          fromApi: expectedFromApi,
        ),
        attendanceDate: attendanceDate,
        staffCodes: staffCodes,
        classroomCode: classroomCode,
        classroomCodeByStaffCode: classroomCodeByStaffCode,
        notExpectedComment: notExpectedComment,
      );
    }

    // Submit state (spinner / button-disable) is driven by [_submitCubit], which
    // emits InProgress at the start of submit() below and Success/Failure at the
    // end. [_submitInFlight] is only a re-entrancy guard (covers the pre-steps
    // too), never UI state.
    _submitInFlight = true;
    try {
      // Admin-only override: clear same-day absence records for any
      // selected staff who were marked absent, before creating the sign-in.
      // Self-service (non-admin / QR) sign-in never runs this — an absent
      // staff member cannot recover their own day this way.
      if (isStaffAdmin) {
        await _deleteTodaysAbsenceRecordsBeforeAdminSignIn(
          attendanceDateYyyyMmDd: attendanceDate,
          actingStaffCode: staffCode,
          targets: List<StaffEntity>.from(selectedStaff),
        );
      }

      final result = await _submitCubit.submit(
        request: request,
        isSelf: useSelfEndpoint,
      );
      final isAlreadySignedIn = !result.success &&
          result.message.toLowerCase().contains('already signed');
      final success = result.success || isAlreadySignedIn;
      var message = result.message;

      if (!mounted) return;

      if (isAlreadySignedIn) {
        message = 'Already signed in for today';
      } else if (success &&
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
        if (widget.isKiosk) {
          // For kiosk: show success for 2 seconds then return to kiosk dashboard
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            // Reload QR code before returning to dashboard
            AppLogger.d('[Kiosk] Staff sign-in success - reloading QR code');
            unawaited(context.read<KioskDashboardCubit>().loadQrCode());
            context.go('/kiosk');
          }
        } else {
          if (isSelfSignIn) {
            context.read<GeofenceCubit>().updateStaffSignInStatus(true);
            unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
          }
          _navigateAfterSubmit(
            isSelfSignIn: isSelfSignIn,
            isStaffAdmin: isStaffAdmin,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      final isAlreadySignedIn =
          errorMessage.toLowerCase().contains('already signed');
      if (isAlreadySignedIn) {
        AttendanceEvents.notifyChanged();
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('Already signed in for today'),
            backgroundColor: AppColors.successColor,
          ),
        );
        if (widget.isKiosk) {
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            unawaited(context.read<KioskDashboardCubit>().loadQrCode());
            context.go('/kiosk');
          }
        } else {
          if (isSelfSignIn) {
            context.read<GeofenceCubit>().updateStaffSignInStatus(true);
            unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
          }
          _navigateAfterSubmit(
            isSelfSignIn: isSelfSignIn,
            isStaffAdmin: isStaffAdmin,
          );
        }
      } else {
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      _submitInFlight = false;
    }
  }

  void _navigateAfterSubmit({
    required bool isSelfSignIn,
    required bool isStaffAdmin,
  }) {
    if (widget.qrToken.isNotEmpty) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      context.go('/dashboard');
      return;
    }

    if (isSelfSignIn || !isStaffAdmin) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    } else {
      redirectToAttendanceDaily(
        context,
        StaffAttendanceTabbedView.routeName,
      );
    }
  }

  void _removeStaff(StaffEntity staff) {
    final nowEmpty = _gateCubit.removeStaff(staff);
    if (nowEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffSignInGateCubit>.value(
      value: _gateCubit,
      child: BlocBuilder<StaffSignInGateCubit, StaffSignInGateState>(
        builder: (context, gate) {
          final selectedStaff = gate.selectedStaff;
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
                  if (selectedStaff.isNotEmpty)
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
                      itemCount: selectedStaff.length,
                      itemBuilder: (context, index) => _buildStaffCard(
                        selectedStaff[index],
                        canRemove: selectedStaff.length > 1,
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
                              isDisabled: gate.isStaffAdminPersona != true,
                              onDateSelected: (date) {
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
                                final picked = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                );
                                final clamped =
                                    picked.isAfter(today) ? today : date;
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
                              // Teachers cannot modify time; submission will also
                              // force "now" for them. Admin personas can edit the
                              // time even for their own record.
                              ignoring: gate.isStaffAdminPersona != true,
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
                BlocBuilder<StaffSignInSubmitCubit, StaffSignInSubmitState>(
              bloc: _submitCubit,
              builder: (context, submitState) {
                final hasUnexpected = _gateCubit.hasUnexpectedAmongSelected();
                final disabled =
                    (submitState is StaffSignInSubmitInProgress) ||
                        gate.unexpectedGateLoading ||
                        (hasUnexpected && !gate.unexpectedSignInAcknowledged);
                return CustomButtonLayout(
                  confirmButtonLabel: 'Sign-In',
                  onPressedConfirm: disabled ? null : _handleSubmit,
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

  Widget _buildStaffCard(StaffEntity staff, {required bool canRemove}) {
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
                  fileUuid: staff.photoUuid ?? '',
                  name: staff.name,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: AppSpacing.s6),
                Flexible(
                  child: AppText.value(
                    staff.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            GestureDetector(
              onTap: () => _removeStaff(staff),
              child: SvgPicture.asset(MediaRes.delete_icon),
            ),
        ],
      ),
    );
  }
}
