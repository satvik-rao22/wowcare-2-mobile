import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_form_list_usecase.dart';
import 'staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

class StaffSignInForm extends StatefulWidget {
  const StaffSignInForm({
    super.key,
    this.staff,
    this.staffList,
  });

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;

  static const String routeName = '/staff-sign-in-form';

  @override
  State<StaffSignInForm> createState() => _StaffSignInFormState();
}

class _StaffSignInFormState extends State<StaffSignInForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<StaffEntity> _selectedStaff = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona; // Admin can change time to past, but not future.

  @override
  void initState() {
    super.initState();
    if (widget.staffList != null && widget.staffList!.isNotEmpty) {
      _selectedStaff = List<StaffEntity>.from(widget.staffList!);
    } else if (widget.staff != null) {
      _selectedStaff = <StaffEntity>[widget.staff!];
    } else {
      _selectedStaff = <StaffEntity>[
        StaffEntity(
          id: 1,
          name: 'Staff Member',
          primaryRoomId: 1,
        ),
      ];
    }
    _loadPersonaFlags();
  }

  Future<void> _loadPersonaFlags() async {
    final isAdmin = await _resolveIsStaffAdminPersona();
    if (!mounted) return;
    setState(() {
      _isStaffAdminPersona = isAdmin;
      // Teachers cannot modify date/time: lock to "now".
      if (!_isStaffAdminPersona!) {
        selectedDate = DateTime.now();
        selectedTime = TimeOfDay.now();
      }
    });
  }

  Future<bool> _resolveIsStaffAdminPersona() async {
    final storage = serviceLocator<StorageService>();
    final staffType =
        (await storage.getString(StorageKeys.staffType) ?? '')
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
        if (roleCode == 'SCHOOL_ADMIN' ||
            roleCode == 'ORGANIZATION_ADMIN') {
          return true;
        }
      }
    } catch (_) {
      // More restrictive default: treat unknown as teacher.
    }
    return false;
  }

  Future<String> _resolveStaffCode() =>
      resolveStaffCodeForLoggedInUser();

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

  bool _isExpectedTodayForStaffCode(
    String code,
    Map<String, bool> fromApi,
  ) {
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
        snackBar: 
        const SnackBar(
          content: Text('No staff selected to sign in'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final client = serviceLocator<ApiClient>().client;
    // Default: admin-style sign-in (can sign in other staff).
    // Teachers: will switch to self-sign-in endpoint below.
    String endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceRecordsSignIn,
      ApiConstants.attendanceBaseUrl,
    );

    final staffCode = await _resolveStaffCode();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
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
        snackBar: 
        const SnackBar(
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
    final now = DateTime.now();
    final nowUtc = now.toUtc();

    // Teachers:
    // - can only sign in for themselves
    // - cannot modify date/time (defaults to current)
    final DateTime effectiveDate;
    final TimeOfDay effectiveTime;
    if (!isStaffAdmin) {
      if (targetStaffCodes.length != 1 || targetStaffCodes.first != staffCode) {
        CoreUtils.showTopSnackBarFromSnackBar(
          context: context,
          snackBar: 
          const SnackBar(
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
      effectiveDate = now;
      effectiveTime = TimeOfDay.fromDateTime(now);
    } else {
      effectiveDate = selectedDate;
      effectiveTime = selectedTime;
    }

    final attendanceDate =
        '${effectiveDate.year.toString().padLeft(4, '0')}-${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')}';

    final occurredAt = DateTime(
      effectiveDate.year,
      effectiveDate.month,
      effectiveDate.day,
      effectiveTime.hour,
      effectiveTime.minute,
    ).toUtc();

    // Admin cannot sign in for future date/time.
    if (isStaffAdmin && occurredAt.isAfter(nowUtc)) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
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
      expectedFromApi =
          await _fetchIsExpectedTodayFromSignInFormList(
        attendanceDate: attendanceDate,
      );
    } catch (_) {
      // Fall back to [StaffEntity.isExpectedToday] / true when the list call fails.
    }

    late final Map<String, dynamic> payload;
    if (!isStaffAdmin) {
      // Self sign-in for teacher persona.
      endpoint = ApiPaths.urlWithBase(
        ApiPaths.staffAttendanceRecordsSignInSelf,
        ApiConstants.attendanceBaseUrl,
      );
      payload = <String, dynamic>{
        'staffCode': staffCode,
        'method': 'APP',
        'latitude': 0,
        'longitude': 0,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': occurredAt.toIso8601String(),
        'isExpectedToday':
            _isExpectedTodayForStaffCode(staffCode, expectedFromApi),
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
        'latitude': 0,
        'longitude': 0,
        'withinGeofence': true,
        'timeZone': 'Asia/Kolkata',
        'occurredAt': occurredAt.toIso8601String(),
      };
    }

    try {
      final response = await client.post<dynamic>(
        endpoint,
        data: payload,
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
        snackBar: 
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? AppColors.successColor : AppColors.errorColor,
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
                itemBuilder: (context, index) =>
                    _buildStaffCard(_selectedStaff[index]),
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
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final picked = DateTime(date.year, date.month, date.day);
                            selectedDate = picked.isAfter(today) ? today : date;
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
        onPressedConfirm: _isSubmitting ? null : _handleSubmit,
        showCancelButton: false,
      ),
    );
  }

  Widget _buildStaffCard(StaffEntity staff) {
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
        ],
      ),
    );
  }
}
