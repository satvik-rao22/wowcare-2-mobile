import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// Mock student entity for UI-only implementation
class StudentEntity {
  final int id;
  final String fullName;
  final int roomId;
  final String roomName;
  final String photoUuid;
  final List<TagEntity> tags;

  StudentEntity({
    required this.id,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    this.photoUuid = '',
    this.tags = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Mock tag entity for UI-only implementation
class TagEntity {
  final String name;

  TagEntity({required this.name});
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Text(
              'Mark Absent',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 17 * (-3 / 100),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Start Date',
                                    style: TextStyle(
                                      color: Color.fromRGBO(87, 51, 83, 0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context, true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                        borderRadius: BorderRadius.circular(8),
                                        color:
                                            const Color.fromRGBO(249, 245, 250, 1),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateUtilsNew.formatToReadableDate(
                                                startDate),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SvgPicture.asset(
                                              MediaRes.calender_icon)
                                        ],
                                      ),
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
                                  const Text(
                                    'End Date',
                                    style: TextStyle(
                                      color: Color.fromRGBO(87, 51, 83, 0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () => _selectDate(context, false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                        borderRadius: BorderRadius.circular(8),
                                        color:
                                            const Color.fromRGBO(249, 245, 250, 1),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateUtilsNew.formatToReadableDate(
                                                endDate),
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SvgPicture.asset(
                                              MediaRes.calender_icon)
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: currentStudents.length,
                          itemBuilder: (context, index) {
                            final student = currentStudents[index];

                            return Column(
                              children: [
                                RemoveStudentTile(
                                  student: student,
                                  onRemove: () => _removeStudent(student),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: notesControllers[student.id],
                                  decoration: InputDecoration(
                                    hintText: 'Enter Absent Notes',
                                    hintStyle: const TextStyle(
                                      color: Color.fromRGBO(87, 51, 83, 0.5),
                                      fontSize: 15,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: Color.fromRGBO(87, 51, 83, 0.4)),
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
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom,
          left: 16,
          right: 16,
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
        ),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Submit',
          onPressedConfirm: _handleSubmit,
          showCancelButton: false,
        ),
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
                  fileUuid: student.photoUuid,
                  size: 30,
                  name: student.fullName,
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
            child: SvgPicture.asset(MediaRes.delete_icon),
          )
        ],
      ),
    );
  }
}
