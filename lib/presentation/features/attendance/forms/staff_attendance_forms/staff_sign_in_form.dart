import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_profile_avatar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'staff_entity.dart';

class StaffSignInForm extends StatefulWidget {
  const StaffSignInForm({
    super.key,
    this.staff,
  });

  final StaffEntity? staff;

  static const String routeName = '/staff-sign-in-form';

  @override
  State<StaffSignInForm> createState() => _StaffSignInFormState();
}

class _StaffSignInFormState extends State<StaffSignInForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _handleSubmit() {
    // UI-only: Just show success and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed-In successfully'),
        backgroundColor: AppColors.successColor,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveSizing.isTablet(context);
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Navigator.pop(context),
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
            AppText.title('Sign-In'),
            const SizedBox(height: 24),
            if (currentStaff != null)
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: isTablet ? 16 : 12,
                  mainAxisSpacing: isTablet ? 16 : 12,
                  childAspectRatio: 3.5,
                ),
                itemCount: 1,
                itemBuilder: (context, index) => _buildStaffCard(currentStaff!),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(isTablet),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: _buildTimeField(isTablet),
                ),
              ],
            ),
            SizedBox(height: safeAreaBottom + 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom,
          left: isTablet ? 24 : 16,
          right: isTablet ? 24 : 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTablet ? 40.0 : 24.0),
            topRight: Radius.circular(isTablet ? 40.0 : 24.0),
          ),
        ),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Sign-In',
          onPressedConfirm: _handleSubmit,
          showCancelButton: false,
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffEntity staff) {
    return CustomSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.themeColor,
            child: Text(
              _getInitials(staff.name),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Widget _buildDateField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.label('Date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
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
                  DateFormat('MMM dd, yyyy').format(selectedDate),
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

  Widget _buildTimeField(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.label('Time'),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectTime,
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
                AppText.value(selectedTime.format(context)),
                SvgPicture.asset(
                  MediaRes.clock_icon,
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
