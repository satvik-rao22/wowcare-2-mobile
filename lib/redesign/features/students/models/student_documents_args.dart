import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Who the Documents screen is about, handed to it by the profile that
/// opened it (5f).
///
/// Typed rather than a `Map` in `extra`, and every field but the id is
/// optional: a deep link arrives with only the id, and the screen fetches the
/// rest rather than showing a blank header.
@immutable
class StudentDocumentsArgs extends Equatable {
  const StudentDocumentsArgs({
    required this.studentId,
    this.studentName = '',
    this.classroomName = '',
  });

  final String studentId;
  final String studentName;
  final String classroomName;

  @override
  List<Object?> get props => [studentId, studentName, classroomName];
}
