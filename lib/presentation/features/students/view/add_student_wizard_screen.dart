import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step1_screen.dart';

/// Main entry point for the 3-step student creation wizard.
/// Step 1 handles navigation to subsequent steps.
class AddStudentWizardScreen extends StatelessWidget {
  const AddStudentWizardScreen({super.key});

  static const String routeName = '/add-student-wizard-screen';

  @override
  Widget build(BuildContext context) {
    // Provide ClassroomCubit so step 1 can load classrooms from API
    return BlocProvider<ClassroomCubit>(
      create: (_) =>
          serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
      child: const AddStudentStep1Screen(),
    );
  }
}

