import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';

/// Classroom → members cascade for the Custom event audience, following the
/// school hierarchy (school → classroom → staff & students → parents).
///
/// When the creator picks a classroom, that classroom's students and allowed
/// staff are pre-selected; each can then be toggled off individually in the
/// student/staff pickers. Members picked manually (not belonging to any
/// selected classroom) survive classroom changes untouched.
class EventAudienceCascade {
  EventAudienceCascade._();

  /// Students are linked to their classroom by a name-or-code string
  /// ([Student.classroom] holds whatever the students API sent), so both
  /// are matched.
  static bool studentBelongsTo(Student student, EventAttendee classroom) {
    final link = student.classroom.trim();
    if (link.isEmpty) return false;
    return link == classroom.code || link == classroom.name;
  }

  /// Staff belong to a classroom when it is their primary room or in their
  /// allowed-classrooms list.
  static bool staffBelongsTo(StaffMember member, EventAttendee classroom) {
    return member.primaryClassroomCode == classroom.code ||
        member.allowedClassroomCodes.contains(classroom.code);
  }

  /// Student selection after the classroom selection changed.
  static List<EventAttendee> nextStudents({
    required List<EventAttendee> current,
    required List<EventAttendee> previousClassrooms,
    required List<EventAttendee> nextClassrooms,
    required List<Student> allStudents,
  }) {
    return _cascade(
      current: current,
      previousClassrooms: previousClassrooms,
      nextClassrooms: nextClassrooms,
      membersOf: (classroom) => [
        for (final student in allStudents)
          if (studentBelongsTo(student, classroom))
            EventAttendee(code: student.code, name: student.fullName),
      ],
    );
  }

  /// Staff selection after the classroom selection changed.
  static List<EventAttendee> nextStaff({
    required List<EventAttendee> current,
    required List<EventAttendee> previousClassrooms,
    required List<EventAttendee> nextClassrooms,
    required List<StaffMember> allStaff,
  }) {
    return _cascade(
      current: current,
      previousClassrooms: previousClassrooms,
      nextClassrooms: nextClassrooms,
      membersOf: (classroom) => [
        for (final member in allStaff)
          if (staffBelongsTo(member, classroom))
            EventAttendee(code: member.code, name: member.name),
      ],
    );
  }

  static List<EventAttendee> _cascade({
    required List<EventAttendee> current,
    required List<EventAttendee> previousClassrooms,
    required List<EventAttendee> nextClassrooms,
    required List<EventAttendee> Function(EventAttendee classroom) membersOf,
  }) {
    final previousCodes = {for (final c in previousClassrooms) c.code};
    final nextCodes = {for (final c in nextClassrooms) c.code};

    final selection = <String, EventAttendee>{
      for (final attendee in current) attendee.code: attendee,
    };

    // Drop members of now-removed classrooms — unless a still-selected
    // classroom also covers them.
    final coveredByKept = <String>{
      for (final classroom in nextClassrooms)
        ...membersOf(classroom).map((m) => m.code),
    };
    for (final classroom in previousClassrooms) {
      if (nextCodes.contains(classroom.code)) continue;
      for (final member in membersOf(classroom)) {
        if (!coveredByKept.contains(member.code)) {
          selection.remove(member.code);
        }
      }
    }

    // Pre-select members of newly added classrooms. `putIfAbsent` keeps the
    // creator's earlier picks (and their display names) intact.
    for (final classroom in nextClassrooms) {
      if (previousCodes.contains(classroom.code)) continue;
      for (final member in membersOf(classroom)) {
        selection.putIfAbsent(member.code, () => member);
      }
    }

    return selection.values.toList();
  }
}
