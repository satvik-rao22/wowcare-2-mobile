import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// The rules 5d and 5e both enforce, in one place so the wizard and the edit
/// form cannot drift apart.
///
/// [today] is passed in because a school's day belongs to its own timezone,
/// not the device's, and because a date rule that reads the clock cannot be
/// tested.
class StudentValidator {
  const StudentValidator({required this.today});

  final DateTime today;

  /// Which of a wizard step's fields are wrong. An empty map is a step that
  /// may be left.
  Map<StudentField, String> forStep(int step, StudentDraft draft) =>
      switch (step) {
        1 => details(draft),
        2 => guardian(draft),
        _ => const <StudentField, String>{},
      };

  /// Step one, and the top half of the edit form.
  Map<StudentField, String> details(StudentDraft draft) {
    final errors = <StudentField, String>{};

    if (draft.firstName.trim().isEmpty) {
      errors[StudentField.firstName] = StudentsStrings.firstNameRequired;
    }
    if (draft.lastName.trim().isEmpty) {
      errors[StudentField.lastName] = StudentsStrings.lastNameRequired;
    }
    if (draft.classroomName == null && draft.status != StudentStatus.inactive) {
      errors[StudentField.classroom] = StudentsStrings.classroomRequired;
    }

    final dob = draft.dateOfBirth;
    if (dob == null) {
      if (draft.status == StudentStatus.active) {
        errors[StudentField.birthDate] = StudentsStrings.birthDateRequired;
      }
    } else if (!dob.isBefore(_startOfToday)) {
      errors[StudentField.birthDate] = StudentsStrings.birthDatePast;
    }

    if (draft.status == StudentStatus.upcoming) {
      final start = draft.schoolStartDate;
      if (start == null) {
        errors[StudentField.schoolStartDate] =
            StudentsStrings.schoolStartRequired;
      } else if (start.isBefore(_startOfToday)) {
        errors[StudentField.schoolStartDate] =
            StudentsStrings.schoolStartFuture;
      }
    }

    return errors;
  }

  /// Step two. Only reached when the step is taken rather than skipped.
  Map<StudentField, String> guardian(StudentDraft draft) {
    final errors = <StudentField, String>{};

    if (draft.guardianSource == GuardianSource.existing) {
      if (draft.guardianId == null) {
        errors[StudentField.guardian] = StudentsStrings.guardianRequired;
      }
    } else {
      if (draft.guardianName.trim().isEmpty) {
        errors[StudentField.guardianName] = StudentsStrings.firstNameRequired;
      }
      final email = draft.guardianEmail.trim();
      if (email.isEmpty) {
        errors[StudentField.guardianEmail] = StudentsStrings.emailRequired;
      } else if (!_looksLikeEmail(email)) {
        errors[StudentField.guardianEmail] = StudentsStrings.emailInvalid;
      }
      if (draft.guardianPhone.trim().isEmpty) {
        errors[StudentField.guardianPhone] = StudentsStrings.phoneRequired;
      }
    }

    if (draft.relation == null) {
      errors[StudentField.relation] = StudentsStrings.relationRequired;
    }
    return errors;
  }

  DateTime get _startOfToday => DateTime(today.year, today.month, today.day);

  /// Deliberately loose: the backend is the authority on an address, and a
  /// strict pattern here only rejects addresses that work.
  static bool _looksLikeEmail(String value) {
    final at = value.indexOf('@');
    if (at <= 0 || at == value.length - 1) return false;
    final domain = value.substring(at + 1);
    return domain.contains('.') &&
        !domain.startsWith('.') &&
        !domain.endsWith('.') &&
        !value.contains(' ');
  }
}
