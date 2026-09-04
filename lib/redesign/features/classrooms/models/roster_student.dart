import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';

/// What a tag or a trailing flag means. Teal is a student fact, sun is a
/// caution, danger is a care need, navy is neutral.
enum RosterTone { student, staff, danger, neutral }

/// One care need, schedule note or subsidy tag on a student.
@immutable
class RosterTag extends Equatable {
  const RosterTag({required this.label, this.tone = RosterTone.student});

  final String label;
  final RosterTone tone;

  @override
  List<Object?> get props => [label, tone];
}

/// A student on a classroom's roster (7c, 7e), with the panel that opens
/// under the row.
///
/// Mirrors what `classroom_student_list_item.dart` draws today plus what the
/// student-classroom response already carries.
@immutable
class RosterStudent extends Equatable {
  const RosterStudent({
    required this.id,
    required this.name,
    required this.initials,
    required this.age,
    required this.attendance,
    required this.timeLabel,
    this.flag,
    this.flagTone = RosterTone.neutral,
    this.careNeeds = const <RosterTag>[],
    this.weekdays = const <bool>[true, true, true, true, true],
    this.hours = '',
    this.guardianName,
    this.moveNote,
    this.isNapping = false,
  });

  final String id;
  final String name;
  final String initials;

  /// "3 yrs 1 mo".
  final String age;

  final AttendanceStatus attendance;

  /// "8:12", "expected today", "Marked 7:55 AM".
  final String timeLabel;

  /// The one word the row flags at a glance: an allergy, a nap, a gap.
  final String? flag;
  final RosterTone flagTone;

  final List<RosterTag> careNeeds;

  /// Monday to Friday, in that order.
  final List<bool> weekdays;

  /// "7:30 to 17:30".
  final String hours;

  final String? guardianName;

  /// A planned classroom move, already recorded in Movements. Read-only here:
  /// this module never books one.
  final String? moveNote;

  final bool isNapping;

  String get firstName => name.split(' ').first;
  bool get isSignedIn => attendance == AttendanceStatus.signedIn;

  /// Whether [query] matches this student, case-insensitively.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q);
  }

  @override
  List<Object?> get props => [
    id,
    name,
    initials,
    age,
    attendance,
    timeLabel,
    flag,
    flagTone,
    careNeeds,
    weekdays,
    hours,
    guardianName,
    moveNote,
    isNapping,
  ];
}
