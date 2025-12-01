import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step1_screen.dart';

/// Main entry point for the 3-step student creation wizard.
/// Step 1 handles navigation to subsequent steps.
class AddStudentWizardScreen extends StatelessWidget {
  const AddStudentWizardScreen({super.key});

  static const String routeName = '/add-student-wizard-screen';

  @override
  Widget build(BuildContext context) {
    // Just show step 1 - it handles navigation to subsequent steps
    return const AddStudentStep1Screen();
  }
}

