import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

// Mock student entity for UI-only implementation
class StudentEntity {
  final int id;
  final String fullName;
  final int roomId;
  final String roomName;

  StudentEntity({
    required this.id,
    required this.fullName,
    required this.roomId,
    required this.roomName,
  });
}

class StudentSignInForm extends StatefulWidget {
  const StudentSignInForm({
    super.key,
    required this.students,
    this.refreshCallback,
  });

  final VoidCallback? refreshCallback;
  final List<StudentEntity> students;

  static const String routeName = '/student-sign-in-form';

  @override
  State<StudentSignInForm> createState() => _StudentSignInFormState();
}

class _StudentSignInFormState extends State<StudentSignInForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<StudentEntity> currentStudents = [];

  @override
  void initState() {
    super.initState();
    currentStudents = List.from(widget.students);
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

  void _removeStudent(StudentEntity student) {
    setState(() {
      currentStudents.remove(student);
      if (currentStudents.isEmpty) {
        Navigator.pop(context);
      }
    });
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
    widget.refreshCallback?.call();
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
            if (currentStudents.isNotEmpty) ...[
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: isTablet ? 16 : 12,
                  mainAxisSpacing: isTablet ? 16 : 12,
                  childAspectRatio: 3.5,
                ),
                itemCount: currentStudents.length,
                itemBuilder: (context, index) {
                  final student = currentStudents[index];
                  return _buildStudentChip(student);
                },
              ),
              const SizedBox(height: 24),
            ],
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

  Widget _buildStudentChip(StudentEntity student) {
    return CustomSectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: AppText.value(
              student.fullName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.errorColor),
            onPressed: () => _removeStudent(student),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
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
