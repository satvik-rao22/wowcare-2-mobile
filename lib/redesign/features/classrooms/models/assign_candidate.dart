import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Which of the two assign flows is running (7g, 7h).
enum AssignKind { students, staff }

/// Somebody who could be put into this classroom (7g, 7h).
///
/// One shape for both flows: `assign_student_to_classroom_form.dart` and the
/// staff assign form post the same way, a list of codes against a classroom,
/// applied immediately. A future-dated move is on the costly list and is not
/// offered here.
@immutable
class AssignCandidate extends Equatable {
  const AssignCandidate({
    required this.id,
    required this.name,
    required this.initials,
    required this.group,
    this.age = '',
    this.designation,
    this.note,
    this.isOutsideAgeRange = false,
  });

  final String id;
  final String name;
  final String initials;

  /// Where they are now: "Unassigned", "Bluebell", "Acorn". The chips over
  /// step one are built from these.
  final String group;

  /// "2 yrs 7 mo". Empty for staff.
  final String age;

  /// A staff member's designation. Null for students.
  final String? designation;

  /// The quiet third line on a staff row: "Already in Bluebell and Acorn".
  final String? note;

  /// The classroom's age band does not cover them. A warning, never a block:
  /// `Classroom.isAgeOutsideRange` warns and the web client still assigns.
  final bool isOutsideAgeRange;

  String get firstName => name.split(' ').first;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        group.toLowerCase().contains(q) ||
        (designation?.toLowerCase().contains(q) ?? false);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    initials,
    group,
    age,
    designation,
    note,
    isOutsideAgeRange,
  ];
}
