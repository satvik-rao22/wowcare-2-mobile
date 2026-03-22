import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'staff_entity.dart';

class StaffSignOutForm extends StatefulWidget {
  const StaffSignOutForm({super.key, this.staff});

  final StaffEntity? staff;

  static const String routeName = '/staff-sign-out-form';

  @override
  State<StaffSignOutForm> createState() => _StaffSignOutFormState();
}

class _StaffSignOutFormState extends State<StaffSignOutForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  StaffEntity? currentStaff;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    currentStaff = widget.staff ?? StaffEntity(
      id: 1,
      name: 'Staff Member',
      primaryRoomId: 1,
    );
  }

  Future<String> _resolveStaffCode() async {
    final storage = serviceLocator<StorageService>();
    return (await storage.getString(StorageKeys.staffCode) ?? '').trim();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    if (currentStaff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No staff selected to sign out'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final client = serviceLocator<ApiClient>().client;
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceRecordsSignOut,
      ApiConstants.attendanceBaseUrl,
    );

    final attendanceDate =
        '${selectedDate.year.toString().padLeft(4, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final occurredAt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    ).toUtc();

    final staffCode = await _resolveStaffCode();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to resolve staffCode. Please re-login.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    final targetStaffCode = (currentStaff!.staffCode ?? '').trim();
    if (targetStaffCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target staff code is missing. Please refresh list.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }
    final staffCodes = <String>[targetStaffCode];
    const classroomCode = '';

    final classroomCodeByStaffCode = <String, String>{
      for (final code in staffCodes) code: classroomCode
    };

    final payload = <String, dynamic>{
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

    try {
      final response = await client.post<dynamic>(
        endpoint,
        data: payload,
      );

      final data = response.data;
      bool success = false;
      String message = 'Signed-Out successfully';

      if (data is Map<String, dynamic>) {
        success = data['success'] as bool? ?? false;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? AppColors.successColor : AppColors.errorColor,
        ),
      );

      if (success) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign out staff. Please try again.'),
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
      title: 'Sign-Out',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentStaff != null)
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 3.5,
                ),
                itemCount: 1,
                itemBuilder: (context, index) => _buildStaffCard(currentStaff!),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppText.value(
                              DateUtilsNew.formatToReadableDate(selectedDate),
                            ),
                            SvgPicture.asset(
                              MediaRes.calender_icon,
                              colorFilter: ColorFilter.mode(
                                Colors.grey.shade600,
                                BlendMode.srcIn,
                              ),
                            )
                          ],
                        ),
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
                      SimpleTimePickerField(
                        time: selectedTime,
                        onTimeSelected: (t) {
                          setState(() {
                            selectedTime = t;
                          });
                        },
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
                  child: Text(
                    staff.name.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
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
