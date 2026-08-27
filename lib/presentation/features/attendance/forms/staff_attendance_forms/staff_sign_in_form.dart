import 'dart:async';
import 'dart:convert';
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
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_submit_cubit.dart';
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
  DateTime selectedDate = ServerTimeService.instance.now();
  TimeOfDay selectedTime = ServerTimeService.instance.timeOfDayNow();
  String? _schoolIana;
  List<StaffEntity> _selectedStaff = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona; // Admin can change time to past, but not future.
  bool?
  _isAdminRole; // Determines if staff can select other staff or only themselves
  Map<String, bool> _expectedTodayFromApi = {};
  bool _unexpectedGateLoading = true;
  bool _unexpectedSignInAcknowledged = false;
  String _notExpectedComment = '';
  int _unexpectedGateToken = 0;
  String?
  _currentStaffCode; // Current user's staff code - for self-only validation

  /// Owns the sign-in submit call (View -> Cubit -> UseCase -> Repository).
  /// Eagerly resolved so [dispose] can always close it.
  final StaffSignInSubmitCubit _submitCubit =
      serviceLocator<StaffSignInSubmitCubit>();

  @override
  void initState() {
    super.initState();
    // Initialize with empty list - will be populated after role check
    _selectedStaff = <StaffEntity>[];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeFormData());
    });
  }

  @override
  void dispose() {
    _submitCubit.close();
    super.dispose();
  }

  String _naiveCalendarYyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Initializes form data in proper order:
  /// 1. Load current staff code from storage (or use provided kiosk staffCode)
  /// 2. Initialize school/persona settings
  /// 3. Pre-populate self if non-admin and no staff was resolved from widget params
  ///    (covers both QR and GPS flows — regular staff can only sign in themselves)
  Future<void> _initializeFormData() async {
    // First: Load the current staff code
    final staffCode = widget.isKiosk && widget.staffCode != null
        ? widget.staffCode!.trim()
        : (await serviceLocator<StorageService>().getString(
                StorageKeys.staffCode,
              ))?.trim() ??
              '';
    if (!mounted) return;
    setState(() {
      _currentStaffCode = staffCode.isNotEmpty ? staffCode : null;
    });

    // Then: Initialize school and persona
    await _initializeSchoolAndPersona();

    // Non-admin staff (QR or GPS or KIOSK): if no staff pre-populated, pre-fill with self.
    // Also applies to admin scanning QR or opening from GPS (forceSelf=true).
    final isAdmin = _isAdminRole ?? false;
    final isQrFlow = widget.qrToken.isNotEmpty;
    final isKioskFlow = widget.isKiosk;
    if (mounted &&
        ((!isAdmin || isQrFlow || widget.forceSelf || isKioskFlow) &&
            _selectedStaff.isEmpty &&
            _currentStaffCode != null)) {
      final displayName = isKioskFlow
          ? (widget.staffName?.trim() ?? 'Staff')
          : (await serviceLocator<StorageService>().getString(
                  StorageKeys.displayName,
                ))?.trim() ??
                '';
      AppLogger.d(
        '[StaffSignIn] Kiosk=$isKioskFlow, DisplayName=$displayName, StaffName=${widget.staffName}',
      );
      if (!mounted) return;
      setState(() {
        _selectedStaff = [
          StaffEntity(
            id: 0,
            name: displayName,
            primaryRoomId: 0,
            classroomCode: '',
            classroomName: '',
            photoUuid: '',
            designation: 'Staff',
            staffCode: _currentStaffCode,
            isExpectedToday: true,
          ),
        ];
      });
    }
  }

  Future<void> _initializeSchoolAndPersona() async {
    final z = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );
    if (!mounted) return;
    setState(() {
      _schoolIana = z;
    });
    _setCurrentDateTimeFromSchool();

    // Check if user is admin - determines if staff selection is allowed
    final isAdmin = await _resolveIsStaffAdminPersona();
    final isAdminRole = await _checkIsAdminRole();
    if (!mounted) return;
    setState(() {
      _isStaffAdminPersona = isAdmin;
      _isAdminRole = isAdminRole;
    });

    // Apply staff selection restrictions based on role
    _applyStaffSelectionRestrictions(isAdminRole);

    await _runUnexpectedSignInGate();
  }

  /// Checks if the current user has admin role (director, admin, principal).
  /// Regular staff can only sign in themselves after QR validation.
  Future<bool> _checkIsAdminRole() async {
    final storage = serviceLocator<StorageService>();
    final role = (await storage.getString(StorageKeys.activeSchoolRole) ?? '')
        .trim()
        .toUpperCase();
    return role.contains('DIRECTOR') ||
        role.contains('ADMIN') ||
        role.contains('PRINCIPAL');
  }

  /// Applies staff selection restrictions:
  /// - Admin: Can select multiple staff members
  /// - Regular Staff: Can ONLY sign in themselves (self-only)
  void _applyStaffSelectionRestrictions(bool isAdmin) {
    if (isAdmin) {
      // Admin can sign in multiple staff members
      if (widget.staffList != null && widget.staffList!.isNotEmpty) {
        setState(() {
          _selectedStaff = List<StaffEntity>.from(widget.staffList!);
        });
      } else if (widget.staff != null) {
        setState(() {
          _selectedStaff = <StaffEntity>[widget.staff!];
        });
      }
    } else {
      // Regular staff: SELF-ONLY sign-in after QR validation
      // Find the current staff member from the staff list
      StaffEntity? currentStaff;
      if (_currentStaffCode != null &&
          _currentStaffCode!.isNotEmpty &&
          widget.staffList != null) {
        try {
          currentStaff = widget.staffList!.firstWhere(
            (staff) => (staff.staffCode ?? '').trim() == _currentStaffCode,
          );
        } catch (_) {
          // Staff not found in list
          currentStaff = widget.staff;
        }
      } else {
        currentStaff = widget.staff;
      }

      if (currentStaff != null) {
        setState(() {
          _selectedStaff = <StaffEntity>[currentStaff!];
        });
      }
    }
  }

  void _setCurrentDateTimeFromSchool() {
    final now = ServerTimeService.instance.now();
    setState(() {
      selectedDate = now;
      selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
    });
  }

  bool _hasUnexpectedAmongSelected() {
    for (final s in _selectedStaff) {
      final code = (s.staffCode ?? '').trim();
      if (code.isEmpty) continue;
      final expected = _expectedTodayFromApi[code] ?? s.isExpectedToday;
      if (!expected) return true;
    }
    return false;
  }

  List<String> _unexpectedStaffFullNames() {
    final out = <String>[];
    for (final s in _selectedStaff) {
      final code = (s.staffCode ?? '').trim();
      if (code.isEmpty) continue;
      final expected = _expectedTodayFromApi[code] ?? s.isExpectedToday;
      if (!expected) out.add(s.name);
    }
    return out;
  }

  Future<void> _runUnexpectedSignInGate() async {
    if (!mounted) return;
    if (_selectedStaff.isEmpty) {
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
      final map = await _fetchIsExpectedTodayFromSignInFormList(
        attendanceDate: dateStr,
      );
      if (!mounted || token != _unexpectedGateToken) return;
      setState(() {
        _expectedTodayFromApi = map;
      });
    } catch (_) {
      if (!mounted || token != _unexpectedGateToken) return;
      setState(() {
        _expectedTodayFromApi = {};
      });
    }

    if (!mounted || token != _unexpectedGateToken) return;

    if (!_hasUnexpectedAmongSelected()) {
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
      unexpectedFullNames: _unexpectedStaffFullNames(),
      forStaff: true,
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

  Future<bool> _resolveIsStaffAdminPersona() async {
    // RoleCubit's active persona is the canonical, persona-switch-aware
    // signal — staffType/roles in storage can lag a beat after a persona
    // switch and misresolve a staff/teacher persona as admin (see
    // AttendancePopup._loadStaffPersonaFlags for the same fix).
    if (mounted) {
      return !context.read<RoleCubit>().isStaff;
    }

    final storage = serviceLocator<StorageService>();
    final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
        .trim()
        .toUpperCase();

    if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
      return true;
    }

    // Fallback: parse roles JSON if staffType isn't cached yet.
    final rolesJson = await storage.getString(StorageKeys.roles);
    if (rolesJson == null || rolesJson.trim().isEmpty) return false;

    try {
      final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
      for (final r in roles) {
        final roleCode = ((r as Map<String, dynamic>)['role'] ?? '')
            .toString()
            .toUpperCase();
        if (roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN') {
          return true;
        }
      }
    } catch (_) {
      // More restrictive default: treat unknown as teacher.
    }
    return false;
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

  /// Loads `staffCode -> isExpectedToday` from the sign-in form list GET API
  /// for the given calendar date (same contract as the list shown in selection UI).
  Future<Map<String, bool>> _fetchIsExpectedTodayFromSignInFormList({
    required String attendanceDate,
  }) async {
    final useCase = serviceLocator<GetStaffSignInFormListUseCase>();
    final page = await useCase(
      fromAttendanceDate: attendanceDate,
      toAttendanceDate: attendanceDate,
      page: 0,
      size: 500,
    );
    return {
      for (final item in page.items) item.staffCode: item.isExpectedToday,
    };
  }

  bool _isExpectedTodayForStaffCode(String code, Map<String, bool> fromApi) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return true;
    final apiValue = fromApi[trimmed];
    if (apiValue != null) return apiValue;
    for (final s in _selectedStaff) {
      if ((s.staffCode ?? '').trim() == trimmed) {
        return s.isExpectedToday;
      }
    }
    return true;
  }

  /// OpenAPI defines a single [isExpectedToday] on the sign-in body (not a per-staff map).
  /// For one target, use that staff's value. For multiple targets, use the common value if
  /// all agree; if mixed, default to [true] (the API cannot express per-row flags).
  bool _requestBodyIsExpectedToday({
    required List<String> staffCodes,
    required Map<String, bool> fromApi,
  }) {
    if (staffCodes.isEmpty) return true;
    final vals = staffCodes
        .map((c) => _isExpectedTodayForStaffCode(c, fromApi))
        .toList();
    final first = vals.first;
    if (vals.every((v) => v == first)) return first;
    return true;
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
    if (_isSubmitting) return;
    if (_selectedStaff.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No staff selected to sign in'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    final targetStaffCodes = _selectedStaff
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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    final isStaffAdmin =
        _isStaffAdminPersona ?? await _resolveIsStaffAdminPersona();

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
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
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
        selectedDate: selectedDate,
        selectedTime: selectedTime,
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

    Map<String, bool> expectedFromApi = <String, bool>{};
    try {
      expectedFromApi = await _fetchIsExpectedTodayFromSignInFormList(
        attendanceDate: attendanceDate,
      );
    } catch (_) {
      // Fall back to cached gate data, then [StaffEntity.isExpectedToday] / true.
      expectedFromApi = Map<String, bool>.from(_expectedTodayFromApi);
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
    final String? notExpectedComment = _notExpectedComment.trim().isNotEmpty
        ? _notExpectedComment.trim()
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
        isExpectedToday: _isExpectedTodayForStaffCode(
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
        for (final s in _selectedStaff)
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
        isExpectedToday: _requestBodyIsExpectedToday(
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

    try {
      // Admin-only override: clear same-day absence records for any
      // selected staff who were marked absent, before creating the sign-in.
      // Self-service (non-admin / QR) sign-in never runs this — an absent
      // staff member cannot recover their own day this way.
      if (isStaffAdmin) {
        await _deleteTodaysAbsenceRecordsBeforeAdminSignIn(
          attendanceDateYyyyMmDd: attendanceDate,
          actingStaffCode: staffCode,
          targets: List<StaffEntity>.from(_selectedStaff),
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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
    setState(() {
      _selectedStaff.remove(staff);
      if (_selectedStaff.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            if (_selectedStaff.isNotEmpty)
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 3.5,
                ),
                itemCount: _selectedStaff.length,
                itemBuilder: (context, index) => _buildStaffCard(
                  _selectedStaff[index],
                  canRemove: _selectedStaff.length > 1,
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
                        isDisabled: _isStaffAdminPersona != true,
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
                            final picked = DateTime(
                              date.year,
                              date.month,
                              date.day,
                            );
                            selectedDate = picked.isAfter(today) ? today : date;
                          });
                          _runUnexpectedSignInGate();
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
                        ignoring: _isStaffAdminPersona != true,
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
            : _handleSubmit,
        showCancelButton: widget.isKiosk,
        onPressedCancel: widget.isKiosk
            ? () {
                context.go('/kiosk');
              }
            : null,
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
