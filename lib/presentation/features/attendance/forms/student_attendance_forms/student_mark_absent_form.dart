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

class StudentMarkAbsentForm extends StatefulWidget {
  const StudentMarkAbsentForm({
    super.key,
    required this.students,
    this.refreshCallback,
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;

  @override
  State<StudentMarkAbsentForm> createState() => _StudentMarkAbsentFormState();
}

class _StudentMarkAbsentFormState extends State<StudentMarkAbsentForm> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  Map<int, TextEditingController> notesControllers = {};
  List<StudentEntity> currentStudents = [];

  @override
  void initState() {
    super.initState();
    for (var student in widget.students) {
      notesControllers[student.id] = TextEditingController();
    }
    currentStudents = List.from(widget.students);
  }

  void _removeStudent(StudentEntity student) {
    setState(() {
      currentStudents.remove(student);
      notesControllers[student.id]?.dispose();
      notesControllers.remove(student.id);

      if (currentStudents.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in notesControllers.values) {
      controller.dispose();
    }
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
            AppText.title('Mark Absent'),
            const SizedBox(height: 24),
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
            if (currentStudents.isNotEmpty)
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: currentStudents.length,
                itemBuilder: (context, index) {
                  final student = currentStudents[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        _buildStudentChip(student),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: notesControllers[student.id],
                          hintText: 'Enter Absent Notes',
                        ),
                      ],
                    ),
                  );
                },
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
          confirmButtonLabel: 'Submit',
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
