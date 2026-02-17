import 'package:flutter/material.dart';
import 'package:schoolerp/core/common/widgets/custom_confirm_button.dart';
import 'package:schoolerp/core/common/widgets/custom_scaffold.dart';
import 'package:schoolerp/features/student/domain/entities/studentData.dart';
import 'package:schoolerp/src/attendance/presentation/views/forms/student_attendance_forms/student_sign_in_form.dart';
import 'package:schoolerp/src/attendance/presentation/views/forms/student_attendance_forms/student_sign_out_form.dart';

class StudentSignInOutButton extends StatefulWidget {
  const StudentSignInOutButton({
    super.key,
  });

  static const String routeName = '/student-sign-in-out_button';

  @override
  _StudentSignInOutButtonState createState() => _StudentSignInOutButtonState();
}

class _StudentSignInOutButtonState extends State<StudentSignInOutButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final students =
        ModalRoute.of(context)!.settings.arguments as List<StudentEntity>;

    // Segregate students based on their sign-in status
    final signedInStudents =
        students.where((student) => student.isSignedIn).toList();
    final signedOutStudents =
        students.where((student) => !student.isSignedIn).toList();

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomConfirmButton(
                label: 'Sign In',
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    StudentSignInForm.routeName,
                    arguments: signedOutStudents,
                  );
                  Navigator.pop(context, result);
                },
              ),
              const SizedBox(height: 20), // Add some spacing
              CustomConfirmButton(
                label: 'Sign Out',
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    StudentSignOutForm.routeName,
                    arguments: signedInStudents,
                  );
                  Navigator.pop(context, result);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
