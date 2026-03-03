import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'staff_entity.dart';

class StaffMarkAbsentForm extends StatefulWidget {
  const StaffMarkAbsentForm({super.key, this.staff});

  final StaffEntity? staff;

  static const String routeName = '/staff-mark-absent-form';

  @override
  State<StaffMarkAbsentForm> createState() => _StaffMarkAbsentFormState();
}

class _StaffMarkAbsentFormState extends State<StaffMarkAbsentForm> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  final TextEditingController notesController = TextEditingController();
  StaffEntity? currentStaff;

  @override
  void initState() {
    super.initState();
    currentStaff = widget.staff ?? StaffEntity(
      id: 1,
      name: 'Staff Member',
      primaryRoomId: 1,
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: isStartDate ? DateTime.now() : startDate,
      lastDate: DateTime(2025, 12, 31),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          if (startDate.isAfter(endDate)) {
            endDate = startDate;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  void _handleSubmit() {
    // UI-only: Just show success and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked Absent successfully'),
        backgroundColor: AppColors.successColor,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'Mark Absent',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDateField(context, true),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildDateField(context, false),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (currentStaff != null) ...[
              RemoveStaffTile(staff: currentStaff!),
              const SizedBox(height: 20),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: 'Enter Absent Notes',
                  hintStyle: AppTextStyles.body.copyWith(
                    color: const Color.fromRGBO(87, 51, 83, 0.5),
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(87, 51, 83, 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(87, 51, 83, 0.4),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color.fromRGBO(87, 51, 83, 0.4),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.cardColor,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Submit',
        onPressedConfirm: _handleSubmit,
        showCancelButton: false,
      ),
    );
  }

  Widget _buildDateField(BuildContext context, bool isStartDate) {
    final date = isStartDate ? startDate : endDate;
    final label = isStartDate ? 'Start Date' : 'End Date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.label(label),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context, isStartDate),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
              color: const Color.fromRGBO(249, 245, 250, 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.value(
                  DateUtilsNew.formatToReadableDate(date),
                ),
                SvgPicture.asset(
                  MediaRes.calender_icon,
                  height: 20,
                  width: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RemoveStaffTile extends StatelessWidget {
  final StaffEntity staff;

  const RemoveStaffTile({
    super.key,
    required this.staff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
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
                  size: 30,
                  name: staff.name,
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

