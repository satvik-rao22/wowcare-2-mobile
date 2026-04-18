import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/attendance/usecases/update_student_attendance_record_usecase.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/student_attendance_card.dart';

class StudentEditAttendanceForm extends StatefulWidget {
  const StudentEditAttendanceForm({
    super.key,
    required this.studentAttendance,
    required this.attendanceDate,
  });

  final StudentAttendanceCardData studentAttendance;
  final DateTime attendanceDate;

  @override
  State<StudentEditAttendanceForm> createState() => _StudentEditAttendanceFormState();
}

class _StudentEditAttendanceFormState extends State<StudentEditAttendanceForm> {
  TimeOfDay? _signInTime;
  TimeOfDay? _signOutTime;
  late final UpdateStudentAttendanceRecordUseCase _updateUseCase;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _updateUseCase = serviceLocator<UpdateStudentAttendanceRecordUseCase>();
    _signInTime = _parseTimeOrNull(widget.studentAttendance.signInTime);
    _signOutTime = _parseTimeOrNull(widget.studentAttendance.signOutTime);
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

  Future<String> _resolveStaffCode() =>
      resolveStaffCodeForLoggedInUser();

  Future<void> _submitAsync() async {
    setState(() {
      _isSubmitting = true;
    });

    final attendanceCode = widget.studentAttendance.attendanceRecordCode;
    if (attendanceCode == null || attendanceCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('Unable to update: missing attendance record code.'),
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

    final staffCode = await _resolveStaffCode();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
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
    if (_signInTime == null) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Sign-In time is required.'),
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

    // Send prefilled/edited sign-in and optional sign-out values to patch API.
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

    final classroomCode = widget.studentAttendance.classroomCode;
    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );

    try {
      final message = await _updateUseCase(
        attendanceRecordCode: attendanceCode,
        staffCode: staffCode,
        signedInAt: signedInAt,
        signedOutAt: signedOutAt,
        originalClassroomCode: classroomCode,
        currentClassroomCode: classroomCode,
        notes: null,
        timeZone: schoolTimeZone,
      );

      if (!mounted) return;

      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
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

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveSizing.isTablet(context);
    final student = widget.studentAttendance;
    final titleName = student.studentName.isNotEmpty
        ? student.studentName.split(' ').first
        : 'Student';

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
            _buildStudentHeaderCard(student),
            const SizedBox(height: 24),
            _buildTimeSection(
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

  Widget _buildStudentHeaderCard(StudentAttendanceCardData student) {
    return CustomSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 4),
          DocumentImageWidget(
            fileUuid: student.studentPhotoUuid ?? '',
            name: student.studentName,
            size: 36,
            fontSize: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.value(
                  student.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AppText.small(
                  student.roomName,
                  style: const TextStyle(
                    color: AppColors.secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection({
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

