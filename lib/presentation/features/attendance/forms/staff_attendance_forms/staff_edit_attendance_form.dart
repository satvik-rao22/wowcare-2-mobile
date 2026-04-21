import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

class StaffEditAttendanceForm extends StatefulWidget {
  const StaffEditAttendanceForm({
    super.key,
    required this.staffAttendance,
    required this.attendanceDate,
  });

  final StaffAttendanceCardData staffAttendance;
  final DateTime attendanceDate;

  @override
  State<StaffEditAttendanceForm> createState() => _StaffEditAttendanceFormState();
}

class _StaffEditAttendanceFormState extends State<StaffEditAttendanceForm> {
  TimeOfDay? _signInTime;
  TimeOfDay? _signOutTime;
  TimeOfDay? _initialSignInTime;
  TimeOfDay? _initialSignOutTime;
  String _schoolIana = SchoolTimezoneResolver.fallbackTimeZone;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _bootstrapInitialTimes();
  }

  Future<void> _bootstrapInitialTimes() async {
    final schoolIana = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );
    if (!mounted) return;
    setState(() {
      _schoolIana = schoolIana;
      _signInTime = _parseTimeOrNull(widget.staffAttendance.signInTime);
      _signOutTime = _parseTimeOrNull(widget.staffAttendance.signOutTime);
      _initialSignInTime = _signInTime;
      _initialSignOutTime = _signOutTime;
    });
  }

  bool _sameTime(TimeOfDay? a, TimeOfDay? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.hour == b.hour && a.minute == b.minute;
  }

  TimeOfDay? _parseTimeOrNull(String? timeString) {
    if (timeString == null) {
      return null;
    }
    final raw = timeString.trim();
    if (raw.isEmpty) return null;
    if (raw.toLowerCase() == 'not yet signed out' ||
        raw.toLowerCase() == 'not yet signed in') {
      return null;
    }

    try {
      final iso = DateTime.tryParse(raw);
      if (iso != null) {
        return SchoolZoneDateTime.timeOfDayFromInstantInSchool(iso, _schoolIana);
      }
    } catch (_) {}

    final lower = raw.toLowerCase();
    final byIndex = lower.indexOf(' by ');
    final withoutBy = byIndex > 0 ? raw.substring(0, byIndex).trim() : raw;
    final normalized = withoutBy.replaceAll('.', '').trim();

    final ampmMatch = RegExp(
      r'(\d{1,2}:\d{2}(?::\d{2})?\s*[AaPp][Mm])',
    ).firstMatch(normalized);
    if (ampmMatch != null) {
      final candidate = ampmMatch.group(1)!.replaceAll(RegExp(r'\s+'), ' ');
      try {
        final hasSeconds = RegExp(r':\d{2}\s*[AaPp][Mm]$').hasMatch(candidate);
        final parsed = hasSeconds
            ? DateFormat('h:mm:ss a').parse(candidate)
            : DateFormat.jm().parse(candidate);
        return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
      } catch (_) {}
    }

    final hmsMatch = RegExp(r'(\d{1,2}):(\d{2})(?::\d{2})?').firstMatch(normalized);
    if (hmsMatch != null) {
      final hour = int.tryParse(hmsMatch.group(1)!);
      final minute = int.tryParse(hmsMatch.group(2)!);
      if (hour != null && minute != null && hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    return null;
  }

  void _handleSubmit() {
    if (_isSubmitting) return;
    _submitAsync();
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  Future<void> _submitAsync() async {
    final attendanceCode = _normalizeAttendanceRecordCode(
      widget.staffAttendance.attendanceRecordCode,
    );
    if (attendanceCode == null || attendanceCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Unable to update: missing attendance record code.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (_signInTime == null) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Sign-In time is required.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final date = widget.attendanceDate;
    final staffCode = widget.staffAttendance.id.trim();
    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Unable to update: missing staff code.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );

    final signedInChanged = !_sameTime(_signInTime, _initialSignInTime);
    final signedOutChanged = !_sameTime(_signOutTime, _initialSignOutTime);

    final signedInAt = signedInChanged
        ? SchoolZoneDateTime.utcFromSchoolWallClock(
            schoolTimeZone,
            year: date.year,
            month: date.month,
            day: date.day,
            hour: _signInTime!.hour,
            minute: _signInTime!.minute,
          )
        : null;
    final signedOutAt = signedOutChanged && _signOutTime != null
        ? SchoolZoneDateTime.utcFromSchoolWallClock(
            schoolTimeZone,
            year: date.year,
            month: date.month,
            day: date.day,
            hour: _signOutTime!.hour,
            minute: _signOutTime!.minute,
          )
        : null;

    final payload = <String, dynamic>{
      'staffCode': staffCode,
      if (signedInAt != null) 'signedInAt': signedInAt.toUtc().toIso8601String(),
      if (signedOutAt != null)
        'signedOutAt': signedOutAt.toUtc().toIso8601String(),
      if (signedInAt != null) 'SignedInMethod': 'APP',
      if (signedOutAt != null) 'SignedOutMethod': 'APP',
      'timeZone': schoolTimeZone,
    };

    try {
      final apiClient = serviceLocator<ApiClient>();
      await _patchStaffAttendanceRecord(
        apiClient: apiClient,
        attendanceCode: attendanceCode,
        body: payload,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Attendance updated successfully'),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(ApiErrorHandler.extractErrorMessage(e)),
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

  String? _normalizeAttendanceRecordCode(String? rawCode) {
    if (rawCode == null) return null;
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _patchStaffAttendanceRecord({
    required ApiClient apiClient,
    required String attendanceCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceDailyRecordByRowCode(attendanceCode),
      ApiConstants.attendanceBaseUrl,
    );
    await apiClient.client.patch<Map<String, dynamic>>(
      endpoint,
      data: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveSizing.isTablet(context);
    final staff = widget.staffAttendance;

    final titleName = staff.staffName.isNotEmpty
        ? staff.staffName.split(' ').first
        : 'Staff';

    return StaffFormLayout(
      title: "Edit $titleName's Attendance",
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStaffHeaderCard(staff),
            const SizedBox(height: 24),
            _buildTimeSection(
              context: context,
              label: 'Sign-In Time',
              time: _signInTime,
              onTimeChanged: (time) {
                setState(() {
                  _signInTime = time;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTimeSection(
              context: context,
              label: 'Sign-Out Time',
              time: _signOutTime,
              onTimeChanged: (time) {
                setState(() {
                  _signOutTime = time;
                });
              },
            ),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        onPressedCancel: _handleCancel,
        onPressedConfirm: _isSubmitting ? null : _handleSubmit,
        confirmButtonLabel: 'Submit',
      ),
    );
  }

  Widget _buildStaffHeaderCard(StaffAttendanceCardData staff) {
    return CustomSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 4),
          DocumentImageWidget(
            fileUuid: staff.staffPhotoUuid ?? '',
            name: staff.staffName,
            size: 36,
            fontSize: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.value(
                  staff.staffName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (staff.designationName != null &&
                    staff.designationName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AppText.small(
                    staff.designationName!,
                    style: const TextStyle(
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection({
    required BuildContext context,
    required String label,
    required TimeOfDay? time,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.label(label),
        const SizedBox(height: 8),
        SimpleTimePickerField(
          time: time,
          placeholder: 'Select time',
          onTimeSelected: onTimeChanged,
        ),
      ],
    );
  }
}

