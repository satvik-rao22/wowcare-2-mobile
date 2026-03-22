import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/attendance/usecases/update_student_attendance_record_usecase.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
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

  @override
  void initState() {
    super.initState();
    _updateUseCase = serviceLocator<UpdateStudentAttendanceRecordUseCase>();
    _signInTime = _parseTimeOrNull(widget.studentAttendance.signInTime);
    _signOutTime = _parseTimeOrNull(widget.studentAttendance.signOutTime);
  }

  TimeOfDay? _parseTimeOrNull(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return null;
    }

    try {
      // Expect formats like "10:18 AM" or "10:18 AM By John"
      final parts = timeString.split(' ');
      final candidate = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : timeString;
      final parsed = DateFormat.jm().parse(candidate);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      return null;
    }
  }

  void _handleSubmit() {
    _submitAsync();
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  Future<String> _resolveStaffCode() async {
    final storage = serviceLocator<StorageService>();
    return (await storage.getString(StorageKeys.staffCode) ?? '').trim();
  }

  Future<void> _submitAsync() async {
    final attendanceCode = widget.studentAttendance.attendanceRecordCode;
    if (attendanceCode == null || attendanceCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update: missing attendance record code.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final staffCode = await _resolveStaffCode();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to resolve staffCode. Please re-login.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final date = widget.attendanceDate;
    DateTime? signedInAt;
    DateTime? signedOutAt;

    // Preserve semantics: only send times that were present originally.
    if (widget.studentAttendance.signInTime != null &&
        widget.studentAttendance.signInTime!.isNotEmpty &&
        _signInTime != null) {
      // Build an explicit UTC timestamp so the backend receives a proper
      // ISO8601 value like "2026-03-04T16:31:00.000Z".
      signedInAt = DateTime.utc(
        date.year,
        date.month,
        date.day,
        _signInTime!.hour,
        _signInTime!.minute,
      );
    }

    if (widget.studentAttendance.signOutTime != null &&
        widget.studentAttendance.signOutTime!.isNotEmpty &&
        _signOutTime != null) {
      signedOutAt = DateTime.utc(
        date.year,
        date.month,
        date.day,
        _signOutTime!.hour,
        _signOutTime!.minute,
      );
    }

    final classroomCode = widget.studentAttendance.classroomCode;
    final timeZone = DateTime.now().timeZoneName;

    try {
      final message = await _updateUseCase(
        attendanceRecordCode: attendanceCode,
        staffCode: staffCode,
        signedInAt: signedInAt,
        signedOutAt: signedOutAt,
        originalClassroomCode: classroomCode,
        currentClassroomCode: classroomCode,
        notes: null,
        timeZone: timeZone,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.successColor,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveSizing.isTablet(context);
    final student = widget.studentAttendance;
    final titleName = student.studentName.isNotEmpty
        ? student.studentName.split(' ').first
        : 'Student';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        title: Text(
          "Edit $titleName's Attendance",
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            color: Color(0xff573353),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          isTablet ? 24 : 16,
          8,
          isTablet ? 24 : 16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: CustomButtonLayout(
          onPressedCancel: _handleCancel,
          onPressedConfirm: _handleSubmit,
          confirmButtonLabel: 'Submit',
        ),
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

