import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import 'staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/widgets/unexpected_sign_in_attention_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/presentation/features/geofencing/cubit/geofence_cubit.dart';

class StaffSignInForm extends StatefulWidget {
  const StaffSignInForm({super.key, this.staff, this.staffList});

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;

  static const String routeName = '/staff-sign-in-form';

  @override
  State<StaffSignInForm> createState() => _StaffSignInFormState();
}

class _StaffSignInFormState extends State<StaffSignInForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String? _schoolIana;
  List<StaffEntity> _selectedStaff = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona; // Admin can change time to past, but not future.
  Map<String, bool> _expectedTodayFromApi = {};
  bool _unexpectedGateLoading = true;
  bool _unexpectedSignInAcknowledged = false;
  int _unexpectedGateToken = 0;

  @override
  void initState() {
    super.initState();
    if (widget.staffList != null && widget.staffList!.isNotEmpty) {
      _selectedStaff = List<StaffEntity>.from(widget.staffList!);
    } else if (widget.staff != null) {
      _selectedStaff = <StaffEntity>[widget.staff!];
    } else {
      _selectedStaff = <StaffEntity>[
        StaffEntity(id: 1, name: 'Staff Member', primaryRoomId: 1),
      ];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSchoolAndPersona();
    });
  }

  String _naiveCalendarYyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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

    final isAdmin = await _resolveIsStaffAdminPersona();
    if (!mounted) return;
    setState(() {
      _isStaffAdminPersona = isAdmin;
    });
    await _runUnexpectedSignInGate();
  }

  void _setCurrentDateTimeFromSchool() {
    final iana = _schoolIana;
    if (iana != null && iana.isNotEmpty) {
      final dt = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(iana);
      setState(() {
        selectedDate = dt.$1;
        selectedTime = dt.$2;
      });
      return;
    }
    final now = DateTime.now();
    setState(() {
      selectedDate = now;
      selectedTime = TimeOfDay.fromDateTime(now);
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
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _resolveIsStaffAdminPersona() async {
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

  Future<String> _resolveStaffCode() => resolveStaffCodeForLoggedInUser();

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
    final nowUtc = DateTime.now().toUtc();

    // Teachers:
    // - can only sign in for themselves
    // - cannot modify date/time (defaults to current)
    late final DateTime occurredAt;
    late final String attendanceDate;

    if (!isStaffAdmin) {
      if (targetStaffCodes.length != 1 || targetStaffCodes.first != staffCode) {
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
      occurredAt = SchoolZoneDateTime.utcFromSchoolWallClock(
        schoolTimeZone,
        year: selectedDate.year,
        month: selectedDate.month,
        day: selectedDate.day,
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      );
      attendanceDate = SchoolZoneDateTime.yyyyMmDdFromUtcInstant(
        occurredAt,
        schoolTimeZone,
      );
    }

    // Admin cannot sign in for future date/time.
    if (isStaffAdmin && occurredAt.isAfter(nowUtc)) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('You cannot sign in for future date/time.'),
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

    Map<String, bool> expectedFromApi = <String, bool>{};
    try {
      expectedFromApi = await _fetchIsExpectedTodayFromSignInFormList(
        attendanceDate: attendanceDate,
      );
    } catch (_) {
      // Fall back to cached gate data, then [StaffEntity.isExpectedToday] / true.
      expectedFromApi = Map<String, bool>.from(_expectedTodayFromApi);
    }

    GeofenceState? geofenceState;
    try {
      geofenceState = context.read<GeofenceCubit>().state;
    } catch (_) {
      geofenceState = null;
    }
    final bool withinGeofence = geofenceState?.isWithinGeofence ?? false;

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

    late final Map<String, dynamic> payload;
    if (!isStaffAdmin) {
      // Self sign-in for teacher persona.
      payload = <String, dynamic>{
        'staffCode': staffCode,
        'method': 'APP',
        'latitude': position?.latitude ?? 0,
        'longitude': position?.longitude ?? 0,
        'withinGeofence': withinGeofence,
        'timeZone': schoolTimeZone,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
        'isExpectedToday': _isExpectedTodayForStaffCode(
          staffCode,
          expectedFromApi,
        ),
      };
    } else {
      // Admin sign-in: supports signing in other staff in a bulk-like request.
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

      payload = <String, dynamic>{
        'isExpectedToday': _requestBodyIsExpectedToday(
          staffCodes: staffCodes,
          fromApi: expectedFromApi,
        ),
        'attendanceDate': attendanceDate,
        'staffCode': staffCode,
        'staffCodes': staffCodes,
        'classroomCode': classroomCode,
        'classroomCodeByStaffCode': classroomCodeByStaffCode,
        'method': 'APP',
        'latitude': position?.latitude ?? 0,
        'longitude': position?.longitude ?? 0,
        'withinGeofence': withinGeofence,
        'timeZone': schoolTimeZone,
        'occurredAt': occurredAt.toUtc().toIso8601String(),
      };
    }

    try {
      final result = await serviceLocator<AttendanceRepository>()
          .submitStaffSignIn(payload: payload, isSelf: !isStaffAdmin);
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
        if (isStaffAdmin) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const StaffAttendanceTabbedView(),
            ),
            (route) => false,
          );
        } else {
          Navigator.pop(context);
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
                        isDisabled: _isStaffAdminPersona == false,
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
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Time'),
                      const SizedBox(height: 8),
                      IgnorePointer(
                        // Teachers cannot modify time; submission will also force "now".
                        ignoring: _isStaffAdminPersona == false,
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
            : _handleSubmit,
        showCancelButton: false,
      ),
    );
  }

  Widget _buildStaffCard(StaffEntity staff, {required bool canRemove}) {
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
                  fileUuid: staff.photoUuid ?? '',
                  name: staff.name,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: AppText.value(
                    staff.name.split(' ').first,
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
