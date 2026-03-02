import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_text_field.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
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
    final isTablet = ResponsiveSizing.isTablet(context);

    return StaffFormLayout(
      title: 'Mark Absent',
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDateField(context, true, isTablet),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: _buildDateField(context, false, isTablet),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (currentStaff != null) ...[
              _buildStaffCard(currentStaff!),
              const SizedBox(height: 20),
              CustomTextField(
                controller: notesController,
                hintText: 'Enter Absent Notes',
              ),
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

  Widget _buildStaffCard(StaffEntity staff) {
    return CustomSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 4),
          DocumentImageWidget(
            fileUuid: '',
            name: staff.name,
            size: 30,
            fontSize: 12,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText.value(
              staff.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context, bool isStartDate, bool isTablet) {
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
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 8,
              vertical: isTablet ? 14 : 12,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorderColor),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.fieldBackgroundColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.value(
                  DateFormat('MMM dd, yyyy').format(date),
                ),
                SvgPicture.asset(
                  MediaRes.calender_icon,
                  height: 20,
                  width: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
