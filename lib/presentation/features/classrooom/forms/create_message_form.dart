import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:schoolerp/core/common/widgets/custom_button_layout.dart';
import 'package:schoolerp/core/common/widgets/custom_scaffold.dart';
import 'package:schoolerp/core/helpers/student_helper.dart';
import 'package:schoolerp/core/res/media_res.dart';
import 'package:schoolerp/features/student/domain/entities/studentData.dart';

class CreateMessageForm extends StatelessWidget {
  CreateMessageForm({super.key, required this.students});
  final List<StudentEntity> students;

  Container _buildStudentCard(StudentHelper student) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromRGBO(89, 120, 247, 1)),
          borderRadius: BorderRadius.circular(8),
          color: const Color.fromRGBO(249, 245, 250, 1),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: NetworkImage(student.avatarUrl),
              radius: 12,
            ),
            const SizedBox(width: 8),
            Text(
              student.name.split(' ').first,
              style: const TextStyle(
                color: Color.fromRGBO(87, 51, 83, 1),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            SvgPicture.asset(MediaRes.delete_icon),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      body: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Message',
                  style: TextStyle(
                    color: Color.fromRGBO(87, 51, 82, 1),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
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
                  itemCount: 3,
                  itemBuilder: (context, index) =>
                      _buildStudentCard(students[index] as StudentHelper),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Hello Parents, Children had a good day today!',
                    hintStyle: const TextStyle(
                      color: const Color.fromRGBO(87, 51, 83, 0.5),
                      fontSize: 15,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: const Color.fromRGBO(87, 51, 83, 0.5),
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
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      hasBackButton: true,
      showCustomNavigationBar: false,
      customButtonLayout: CustomButtonLayout(
        confirmButtonLabel: 'Submit',
        onPressedConfirm: () {},
      ),
    );
  }
}
