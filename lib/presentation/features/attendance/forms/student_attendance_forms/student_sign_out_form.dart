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

// Mock student entity for UI-only implementation
class StudentEntity {
  final int id;
  final String fullName;
  final int roomId;
  final String roomName;
  final String photoUuid;

  StudentEntity({
    required this.id,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    this.photoUuid = '',
  });
}

class StudentSignOutForm extends StatefulWidget {
  const StudentSignOutForm({
    required this.students,
    this.refreshCallback,
    super.key,
  });

  final List<StudentEntity> students;
  final VoidCallback? refreshCallback;

  static const String routeName = '/student-sign-out-form';

  @override
  State<StudentSignOutForm> createState() => _StudentSignOutFormState();
}

class _StudentSignOutFormState extends State<StudentSignOutForm> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  List<StudentEntity> currentStudents = [];

  @override
  void initState() {
    super.initState();
    if (widget.students.isNotEmpty) {
      currentStudents = List.from(widget.students);
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
        content: Text('Signed-Out successfully'),
        backgroundColor: AppColors.successColor,
      ),
    );
    Navigator.pop(context);
    widget.refreshCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (currentStudents.isEmpty && widget.students.isNotEmpty) {
      currentStudents = List.from(widget.students);
    }

    return StaffFormLayout(
      title: 'Sign-Out',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 3.5,
              ),
              itemCount: currentStudents.length,
              itemBuilder: (context, index) => RemoveStudentTile(
                student: currentStudents[index],
                onRemove: () => _removeStudent(currentStudents[index]),
              ),
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
                            ),
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
        onPressedConfirm: _handleSubmit,
        showCancelButton: false,
      ),
    );
  }
}

class RemoveStudentTile extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onRemove;

  const RemoveStudentTile({
    super.key,
    required this.student,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
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
                  fileUuid: student.photoUuid,
                  name: student.fullName,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    student.fullName.split(' ').first,
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
          GestureDetector(
            onTap: onRemove,
            child: SvgPicture.asset(
              MediaRes.delete_icon,
              height: 18,
              width: 18,
            ),
          ),
        ],
      ),
    );
  }
}
