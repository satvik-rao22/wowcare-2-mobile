import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';

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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _signInTime = _parseTimeOrNull(widget.staffAttendance.signInTime);
    _signOutTime = _parseTimeOrNull(widget.staffAttendance.signOutTime);
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
        final local = iso.toLocal();
        return TimeOfDay(hour: local.hour, minute: local.minute);
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
    final attendanceCode = _normalizeAttendanceRecordCodeForMutation(
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

    final staffCode = await resolveStaffCodeForLoggedInUser();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Unable to resolve staffCode. Please re-login.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    final date = widget.attendanceDate;
    final signedInAt = DateTime.utc(
      date.year,
      date.month,
      date.day,
      _signInTime!.hour,
      _signInTime!.minute,
    );
    final signedOutAt = _signOutTime == null
        ? null
        : DateTime.utc(
            date.year,
            date.month,
            date.day,
            _signOutTime!.hour,
            _signOutTime!.minute,
          );

    final payload = <String, dynamic>{
      'staffCode': staffCode,
      'signedInAt': signedInAt.toIso8601String(),
      'signedOutAt': signedOutAt?.toIso8601String(),
      'signedInMethod': 'APP',
      'signedOutMethod': 'APP',
      'signedInLocationLat': 0,
      'signedInLocationLong': 0,
      'signedInWithinGeofence': true,
      'signedOutLocationLat': 0,
      'signedOutLocationLong': 0,
      'signedOutWithinGeofence': true,
      'notes': null,
      'timeZone': DateTime.now().timeZoneName,
    };

    try {
      final client = serviceLocator<ApiClient>().client;
      final endpoint = ApiPaths.urlWithBase(
        '/api/v1/staff-attendance-records/$attendanceCode',
        ApiConstants.attendanceBaseUrl,
      );

      final response = await client.patch<Map<String, dynamic>>(
        endpoint,
        data: payload,
      );

      final message =
          (response.data?['message'] ?? 'Attendance updated successfully')
              .toString();
      if (!mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(message),
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

  String? _normalizeAttendanceRecordCodeForMutation(String? rawCode) {
    if (rawCode == null) return null;
    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) return null;
    final tildeIndex = trimmed.indexOf('~');
    if (tildeIndex <= 0) return trimmed;
    return trimmed.substring(0, tildeIndex);
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

