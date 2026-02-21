import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'student_selection_sign_in_form.dart';

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
      body: Card(
        elevation: 0,
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sign-In',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color.fromRGBO(87, 51, 82, 1),
                  ),
                ),
                const SizedBox(height: 30),
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
                          const Text(
                            'Date',
                            style: TextStyle(
                              color: Color.fromRGBO(87, 51, 83, 0.5),
                              fontSize: 14,
                            ),
                          ),
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
                                Text(
                                  DateUtilsNew.formatToReadableDate(selectedDate),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
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
                          const Text(
                            'Time',
                            style: TextStyle(
                              color: Color.fromRGBO(87, 51, 83, 0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              _selectTime();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: const Color.fromRGBO(249, 245, 250, 1),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedTime.format(context),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SvgPicture.asset(MediaRes.clock_icon)
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: safeAreaBottom + 100),
              ],
            ),
          ),
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
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.themeColor.withOpacity(0.1),
                  child: Text(
                    student.fullName.isNotEmpty
                        ? student.fullName[0].toUpperCase()
                        : '',
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
