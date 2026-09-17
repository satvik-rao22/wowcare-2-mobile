import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';

/// Fills empty attendee display names on API-loaded events.
///
/// The events API returns audiences as bare selector codes (no names)
/// until it hydrates participants server-side, so screens resolve names
/// client-side against the loaded classroom/student/staff lists. Codes
/// with no local match fall back to the code itself, so chips never
/// render blank.
class EventAttendeeNames {
  EventAttendeeNames._();

  /// Returns [event] with attendee names resolved from the
  /// [ClassroomCubit] / [StudentCubit] / [StaffCubit] found in [context].
  /// Uses `watch` by default so the display refreshes as those lists load;
  /// pass [listen] false from `initState`-style call sites.
  static Event resolve(
    BuildContext context,
    Event event, {
    bool listen = true,
  }) {
    ClassroomState classroomState;
    StudentState studentState;
    StaffState staffState;
    if (listen) {
      classroomState = context.watch<ClassroomCubit>().state;
      studentState = context.watch<StudentCubit>().state;
      staffState = context.watch<StaffCubit>().state;
    } else {
      classroomState = context.read<ClassroomCubit>().state;
      studentState = context.read<StudentCubit>().state;
      staffState = context.read<StaffCubit>().state;
    }

    final classrooms = _fill(event.classrooms, {
      for (final c in classroomState.classrooms) c.code: c.name,
    });
    final students = _fill(event.students, {
      for (final s in studentState.items) s.code: s.fullName,
    });
    final staff = _fill(event.staff, {
      for (final s in staffState.items) s.code: s.name,
    });

    if (classrooms == null && students == null && staff == null) return event;
    return event.copyWith(
      classrooms: classrooms ?? event.classrooms,
      students: students ?? event.students,
      staff: staff ?? event.staff,
    );
  }

  /// Null when nothing needed resolving (avoids needless copies).
  static List<EventAttendee>? _fill(
    List<EventAttendee> attendees,
    Map<String, String> nameByCode,
  ) {
    if (attendees.every((a) => a.name.trim().isNotEmpty)) return null;
    return [
      for (final attendee in attendees)
        attendee.name.trim().isNotEmpty
            ? attendee
            : EventAttendee(
                code: attendee.code,
                name: (nameByCode[attendee.code] ?? '').trim().isNotEmpty
                    ? nameByCode[attendee.code]!.trim()
                    : attendee.code,
              ),
    ];
  }
}
