import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_remove_tile.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_events.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_out_request.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_sign_out_submit_cubit.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'staff_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_persona_resolver.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_redirect.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

class StaffSignOutForm extends StatefulWidget {
  const StaffSignOutForm({
    super.key,
    this.staff,
    this.staffList,
    this.qrToken = '',
    this.isKiosk = false,
    this.staffCode,
    this.staffName,
    this.pin,
  });

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;
  final String qrToken;

  /// True when called from kiosk flow.
  final bool isKiosk;

  /// Staff code from kiosk PIN verification. Only set when isKiosk=true.
  final String? staffCode;

  /// Staff name from kiosk PIN verification. Only set when isKiosk=true.
  final String? staffName;

  /// PIN from kiosk access. Included in API payload for kiosk sign-out.
  final String? pin;

  static const String routeName = '/staff-sign-out-form';

  @override
  State<StaffSignOutForm> createState() => _StaffSignOutFormState();
}

class _StaffSignOutFormState extends State<StaffSignOutForm> {
  DateTime selectedDate = ServerTimeService.instance.now();
  TimeOfDay selectedTime = ServerTimeService.instance.timeOfDayNow();
  String? _schoolIana;
  List<StaffEntity> _selectedStaff = [];
  bool _isSubmitting = false;
  bool?
  _isStaffAdminPersona; // Admin can backdate (past) but not future; teacher is locked to "now".
  String? _currentStaffCode; // Current user's staff code

  /// Owns the sign-out submit call (View -> Cubit -> UseCase -> Repository).
  /// Eagerly resolved so [dispose] can always close it.
  final StaffSignOutSubmitCubit _submitCubit =
      serviceLocator<StaffSignOutSubmitCubit>();

  /// True when this form targets the logged-in user's own attendance record
  /// (My Attendance) rather than another staff member's. Self attendance can
  /// never have its date/time edited, even by an admin persona — only
  /// admin-managed OTHER-staff attendance allows picking a date/time.
  bool get _isSelfTarget {
    if (widget.isKiosk || widget.qrToken.isNotEmpty) return true;
    final code = _currentStaffCode;
    if (code == null || code.isEmpty) return false;
    return _selectedStaff.length == 1 &&
        (_selectedStaff.first.staffCode ?? '').trim() == code;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeFormData());
    });
  }

  /// Initializes form with logged-in user data
  Future<void> _initializeFormData() async {
    // Load current staff code from storage (or use provided kiosk staffCode)
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

    // Apply staff selection with logged-in user
    _applyStaffSelectionRestrictions();

    // Load persona flags (admin check, timezone, etc.)
    await _loadPersonaFlags();

    // When coming from QR scan or kiosk, form is pre-populated with logged-in user
    // User must manually tap Sign-Out button to submit (not auto-submit)
    if (widget.qrToken.isNotEmpty || widget.isKiosk) {
      // QR token/kiosk PIN is passed to form and will be included in submission
    }
  }

  @override
  void dispose() {
    _submitCubit.close();
    super.dispose();
  }

  /// Applies staff selection restrictions based on role
  void _applyStaffSelectionRestrictions() {
    if (widget.staffList != null && widget.staffList!.isNotEmpty) {
      // Admin can sign out multiple staff members
      _selectedStaff = List<StaffEntity>.from(widget.staffList!);
    } else if (widget.staff != null) {
      // Staff provided, use it
      _selectedStaff = <StaffEntity>[widget.staff!];
    } else if (_currentStaffCode != null && _currentStaffCode!.isNotEmpty) {
      // Try to find current staff in the list by staff code
      StaffEntity? currentStaff;
      if (widget.staffList != null) {
        try {
          currentStaff = widget.staffList!.firstWhere(
            (staff) => (staff.staffCode ?? '').trim() == _currentStaffCode,
          );
        } catch (_) {
          // Staff not found in list
        }
      }
      if (currentStaff != null) {
        _selectedStaff = <StaffEntity>[currentStaff];
      } else {
        // If still no staff found, try to create from storage
        _createStaffFromStorage();
      }
    } else {
      // Last resort: try to load from storage
      _createStaffFromStorage();
    }
  }

  /// Creates staff entity from storage (name, designation, code) or from kiosk params
  Future<void> _createStaffFromStorage() async {
    final storage = serviceLocator<StorageService>();

    // For kiosk mode, use the provided staffCode
    final staffCode = widget.isKiosk && widget.staffCode != null
        ? widget.staffCode!.trim()
        : (await storage.getString(StorageKeys.staffCode) ?? '').trim();

    final displayName = widget.isKiosk
        ? (widget.staffName?.trim() ?? 'Staff')
        : (await storage.getString(StorageKeys.displayName) ?? '').trim();
    final designation = widget.isKiosk
        ? 'Staff'
        : (await storage.getString(StorageKeys.staffDesignation) ?? '').trim();

    AppLogger.d(
      '[StaffSignOut] Kiosk=${widget.isKiosk}, DisplayName=$displayName, StaffName=${widget.staffName}',
    );

    if (!mounted) return;

    if (displayName.isNotEmpty && staffCode.isNotEmpty) {
      setState(() {
        _selectedStaff = <StaffEntity>[
          StaffEntity(
            id: 0,
            name: displayName,
            primaryRoomId: 0,
            classroomCode: '',
            classroomName: '',
            photoUuid: '',
            designation: designation.isNotEmpty ? designation : 'Staff',
            staffCode: staffCode,
            isExpectedToday: true,
          ),
        ];
      });
    }
  }

  Future<void> _loadPersonaFlags() async {
    String? iana;
    try {
      iana = await _submitCubit.resolveFreshSchoolTimeZone();
    } catch (_) {}

    final isAdmin = await _resolveIsStaffAdminPersona();
    if (!mounted) return;
    setState(() {
      _schoolIana = iana;
      _isStaffAdminPersona = isAdmin;
      final n = ServerTimeService.instance.now();
      selectedDate = n;
      selectedTime = TimeOfDay(hour: n.hour, minute: n.minute);
    });
  }

  Future<bool> _resolveIsStaffAdminPersona() =>
      resolveIsStaffAdminPersonaForView(context, mounted: mounted);

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

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (_selectedStaff.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No staff selected to sign out'),
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

    final schoolTimeZone = await _submitCubit.resolveFreshSchoolTimeZone();

    // Teachers can only sign out themselves and cannot modify time.
    late final DateTime occurredAt;
    late final String attendanceDate;

    // Kiosk/QR is always "now" — physical proof of presence — regardless of
    // persona or target.
    final bool isKioskOrQr = widget.isKiosk || widget.qrToken.isNotEmpty;

    if (!isStaffAdmin) {
      if (targetStaffCodes.length != 1 || targetStaffCodes.first != staffCode) {
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: const SnackBar(
            content: Text('Teachers can only sign out for themselves.'),
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
    } else if (isKioskOrQr) {
      occurredAt = SchoolZoneDateTime.utcNowInSchool(schoolTimeZone);
      attendanceDate = SchoolZoneDateTime.yyyyMmDdFromUtcInstant(
        occurredAt,
        schoolTimeZone,
      );
    } else {
      // Admin persona: always honors the picker, including for their own
      // record — already routed through the admin/bulk endpoint below (see
      // isSelfSignOut), so the backend accepts the custom occurredAt.
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

    // Admin future-date/time was previously blocked here client-side by
    // comparing `occurredAt` against a separately-captured `nowUtc` a few
    // statements earlier — clock drift (or just the wall clock ticking
    // forward) between those two reads could false-positive this warning
    // even for an unmodified, still-defaulted-to-now pick. The backend
    // already rejects an actually-future sign-out; no need to duplicate
    // (and potentially misfire) that check here.

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

    // QR scan is physical proof of presence — skip GPS geofence check.
    // Kiosk is a fixed location device — always within geofence.
    // For GPS sign-out, read the singleton directly (form may be outside the
    // dashboard BlocProvider tree when pushed via MaterialPageRoute).
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

    final bool isQrSignOut = widget.qrToken.isNotEmpty;
    final String signOutMethod = isQrSignOut
        ? 'QR'
        : (isStaffAdmin ? 'APP' : 'GPS');

    // QR scan is always self sign-out — the person holding the phone is signing
    // themselves out. Kiosk is always self sign-out (staff member via PIN).
    // An admin persona (including signing out their own record from My Day)
    // routes through the admin/bulk endpoint so their picked date/time is
    // honored — only non-admins use the strictly-"now" self endpoint.
    final bool isSelfSignOut = !isStaffAdmin || isQrSignOut || widget.isKiosk;

    // Assemble a typed StaffSignOutRequest whose toPayload() reproduces the
    // exact payload map this form used to build (single shape; kiosk overrides
    // the method to PIN and the pin/qrToken keys stay mutually exclusive).
    final request = StaffSignOutRequest(
      attendanceDate: attendanceDate,
      staffCode: staffCode,
      staffCodes: staffCodes,
      classroomCode: classroomCode,
      classroomCodeByStaffCode: classroomCodeByStaffCode,
      signOutMethod: signOutMethod,
      isKiosk: widget.isKiosk,
      latitude: position?.latitude ?? 0,
      longitude: position?.longitude ?? 0,
      withinGeofence: withinGeofence,
      timeZone: schoolTimeZone,
      occurredAtIso: occurredAt.toUtc().toIso8601String(),
      pin: widget.pin,
      qrToken: isQrSignOut ? widget.qrToken : null,
    );

    try {
      final result = await _submitCubit.submit(
        request: request,
        isSelf: isSelfSignOut,
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
        if (widget.isKiosk) {
          // For kiosk: show success for 2 seconds then return to kiosk dashboard
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            // Reload QR code before returning to dashboard
            AppLogger.d('[Kiosk] Staff sign-out success - reloading QR code');
            unawaited(context.read<KioskDashboardCubit>().loadQrCode());
            context.go('/kiosk');
          }
        } else {
          final isSelfSignOut = _isSelfTarget;
          if (isSelfSignOut) {
            context.read<GeofenceCubit>().updateStaffSignInStatus(false);
            unawaited(context.read<GeofenceCubit>().checkStaffSignInStatus());
          }
          _navigateAfterSubmit(
            isSelfSignOut: isSelfSignOut,
            isStaffAdmin: isStaffAdmin,
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

  void _navigateAfterSubmit({
    required bool isSelfSignOut,
    required bool isStaffAdmin,
  }) {
    if (widget.qrToken.isNotEmpty) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      context.go('/dashboard');
      return;
    }

    if (isSelfSignOut || !isStaffAdmin) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    } else {
      redirectToAttendanceDaily(context, StaffAttendanceTabbedView.routeName);
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
      title: 'Sign-Out',
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
                itemBuilder: (context, index) => AttendanceRemoveTile(
                  name: _selectedStaff[index].name,
                  photoUuid: _selectedStaff[index].photoUuid ?? '',
                  horizontalPadding: AppSpacing.sm,
                  canRemove: _selectedStaff.length > 1,
                  onRemove: () => _removeStaff(_selectedStaff[index]),
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
