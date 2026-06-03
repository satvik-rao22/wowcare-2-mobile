import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';

class StudentSignInOutSelectionScreen extends StatelessWidget {
  static const String routeName = '/student-sign-in-out-selection';

  const StudentSignInOutSelectionScreen({
    required this.signedInCodes,
    required this.signedOutCodes,
    super.key,
  });

  final List<String> signedInCodes;
  final List<String> signedOutCodes;

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'Sign In / Sign Out',
      bottomBar: const SizedBox.shrink(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select an action for your children attendance today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            CustomConfirmButton(
              label: 'Sign In',
              onPressed: () {
                context.go(
                  '/dashboard/student-selection-sign-in-form',
                  extra: <String, dynamic>{
                    'allowedStudentCodes': signedOutCodes,
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            CustomConfirmButton(
              label: 'Sign Out',
              onPressed: () {
                context.go(
                  '/dashboard/student-selection-sign-out-form',
                  extra: <String, dynamic>{
                    'allowedStudentCodes': signedInCodes,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
