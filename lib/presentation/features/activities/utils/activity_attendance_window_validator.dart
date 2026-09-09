import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';

/// Thin `BuildContext`-aware wrapper around
/// `ActivityEditorCubit.validateStudentsWithinAttendanceWindow` — the cubit
/// does all the data/logic work (staff-type checks, sign-in-status API
/// calls), this just shows the failure snackbar when it says the window
/// isn't valid. No `StorageService`/use-case is resolved here anymore
/// (Mandate 5): everything routes through the already-provided [editor].
Future<bool> validateStudentsWithinAttendanceWindow({
  required BuildContext context,
  required ActivityEditorCubit editor,
  required List<Map<String, dynamic>> students,
  DateTime? selectedDate,
  TimeOfDay? selectedTime,
}) async {
  final result = await editor.validateStudentsWithinAttendanceWindow(
    students: students,
    selectedDate: selectedDate,
    selectedTime: selectedTime,
  );
  if (!result.isValid && context.mounted) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: result.failureMessage ?? 'Please try again.',
      isWarning: true,
    );
  }
  return result.isValid;
}
