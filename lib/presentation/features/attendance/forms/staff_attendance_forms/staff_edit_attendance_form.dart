import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/attendance/view/screens/widgets/staff_attendance_card.dart';

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
  late TimeOfDay _signInTime;
  late TimeOfDay _signOutTime;

  @override
  void initState() {
    super.initState();
    _signInTime = _parseTimeOrNow(widget.staffAttendance.signInTime);
    _signOutTime = _parseTimeOrNow(widget.staffAttendance.signOutTime);
  }

  TimeOfDay _parseTimeOrNow(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return TimeOfDay.now();
    }

    try {
      // Expect formats like "10:18 AM" or "10:18 AM By John"
      final parts = timeString.split(' ');
      final candidate = parts.length >= 2 ? '${parts[0]} ${parts[1]}' : timeString;
      final parsed = DateFormat.jm().parse(candidate);
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  void _handleSubmit() {
    // UI-only behaviour for now: just show confirmation
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Attendance updated successfully',
      isSuccess: true,
    );
    Navigator.pop(context);
  }

  void _handleCancel() {
    Navigator.pop(context);
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
        onPressedConfirm: _handleSubmit,
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
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.label(label),
        const SizedBox(height: 8),
        SimpleTimePickerField(
          time: time,
          onTimeSelected: onTimeChanged,
        ),
      ],
    );
  }
}

