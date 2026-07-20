import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/events/entities/recurrence_rule.dart';

export 'package:wowcare/domain/features/events/entities/recurrence_rule.dart';

/// Audience scope of an event. Stored/transported as the uppercase
/// [value] string so backend integration only has to agree on codes.
enum EventType {
  school('SCHOOL'),
  classroom('CLASSROOM'),
  student('STUDENT'),
  staff('STAFF'),
  custom('CUSTOM'),
  individual('INDIVIDUAL');

  const EventType(this.value);

  final String value;

  String get label {
    switch (this) {
      case EventType.school:
        return 'School';
      case EventType.classroom:
        return 'Classroom';
      case EventType.student:
        return 'Student';
      case EventType.staff:
        return 'Staff';
      case EventType.custom:
        return 'Custom';
      case EventType.individual:
        return 'Individual';
    }
  }

  static EventType fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    return EventType.values.firstWhere(
      (t) => t.value == normalized,
      orElse: () => EventType.custom,
    );
  }
}

enum EventRsvpStatus {
  attending('ATTENDING'),
  maybe('MAYBE'),
  notAttending('NOT_ATTENDING');

  const EventRsvpStatus(this.value);

  final String value;

  String get label {
    switch (this) {
      case EventRsvpStatus.attending:
        return 'Attending';
      case EventRsvpStatus.maybe:
        return 'Maybe';
      case EventRsvpStatus.notAttending:
        return 'Not Attending';
    }
  }

  static EventRsvpStatus? fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    for (final status in EventRsvpStatus.values) {
      if (status.value == normalized) return status;
    }
    return null;
  }
}

/// Lightweight reference to an invited entity (classroom, student or staff).
/// The display [name] is denormalized so cards/details render without a
/// lookup against the entity's own module.
class EventAttendee extends Equatable {
  const EventAttendee({
    required this.code,
    required this.name,
    this.linkedCode = '',
  });

  final String code;
  final String name;

  /// Related entity code — for a parent row, the linked student's code
  /// (used to show the child's name next to the parent).
  final String linkedCode;

  @override
  List<Object?> get props => [code, name, linkedCode];
}

class EventRsvp extends Equatable {
  const EventRsvp({
    required this.userCode,
    required this.userName,
    required this.userType,
    required this.status,
    required this.respondedAt,
  });

  final String userCode;
  final String userName;

  /// STUDENT | STAFF | PARENT
  final String userType;
  final EventRsvpStatus status;
  final DateTime respondedAt;

  @override
  List<Object?> get props => [userCode, userName, userType, status, respondedAt];
}

class Event extends Equatable {
  const Event({
    required this.code,
    this.occurrenceCode = '',
    required this.type,
    required this.name,
    required this.date,
    required this.allDay,
    this.startTime = '',
    this.endTime = '',
    this.description = '',
    this.classrooms = const <EventAttendee>[],
    this.students = const <EventAttendee>[],
    this.staff = const <EventAttendee>[],
    this.parents = const <EventAttendee>[],
    this.includeParents = false,
    this.rsvps = const <EventRsvp>[],
    this.myRsvpStatus,
    this.recurring = false,
    this.recurrence,
    this.attachmentName,
    this.attachmentUrl,
    this.version = 0,
    this.createdBy = '',
    this.createdByName = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String code;

  /// Code of the specific occurrence this view represents (occurrence-based
  /// reads return one row per occurrence). Empty for locally drafted events.
  final String occurrenceCode;
  final EventType type;
  final String name;

  /// Calendar day of the (first) occurrence; time-of-day lives in
  /// [startTime]/[endTime] as `HH:mm`, empty when [allDay].
  final DateTime date;
  final bool allDay;
  final String startTime;
  final String endTime;
  final String description;
  final List<EventAttendee> classrooms;
  final List<EventAttendee> students;
  final List<EventAttendee> staff;

  /// Invited parents/guardians (server-resolved participant roster).
  final List<EventAttendee> parents;
  final bool includeParents;
  final List<EventRsvp> rsvps;

  /// The current user's RSVP on this occurrence, resolved by the API via
  /// `X-Party-Code`. Null when not responded (or not a participant).
  final EventRsvpStatus? myRsvpStatus;
  final bool recurring;

  /// Teams-style repeat rule; null for one-off events.
  final RecurrenceRule? recurrence;
  final String? attachmentName;
  final String? attachmentUrl;

  /// Optimistic-locking version echoed back as the `If-Match` header on
  /// `PATCH`/`DELETE` requests, mirroring [Holiday.version].
  final int version;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get attendeeCount =>
      classrooms.length + students.length + staff.length;

  /// Last day of the series (the rule's UNTIL); null for one-off events
  /// and for rules without an end.
  DateTime? get recurringEndDate => recurrence?.endDate;

  EventRsvp? rsvpFor(String userCode) {
    final trimmed = userCode.trim();
    if (trimmed.isEmpty) return null;
    for (final rsvp in rsvps) {
      if (rsvp.userCode == trimmed) return rsvp;
    }
    return null;
  }

  int rsvpCount(EventRsvpStatus status) =>
      rsvps.where((r) => r.status == status).length;

  /// Whether the event has fully passed as of [now] — i.e. it has no
  /// occurrence today or later. Non-recurring events are completed once
  /// [date] is before today; recurring events once their [recurringEndDate]
  /// has passed. A recurring event without an end date is treated as ongoing
  /// and never reports completed.
  bool isCompletedAsOf(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = recurring ? recurringEndDate : date;
    if (lastDate == null) return false;
    final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
    return last.isBefore(today);
  }

  bool get isCompleted => isCompletedAsOf(DateTime.now());

  /// Whether this event (including recurring expansions) lands on [day].
  bool occursOn(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final first = DateTime(date.year, date.month, date.day);
    if (target == first) return true;
    if (!recurring || recurrence == null) return false;
    return recurrence!.matches(target, first);
  }

  Event copyWith({
    String? code,
    String? occurrenceCode,
    EventType? type,
    String? name,
    DateTime? date,
    bool? allDay,
    String? startTime,
    String? endTime,
    String? description,
    List<EventAttendee>? classrooms,
    List<EventAttendee>? students,
    List<EventAttendee>? staff,
    List<EventAttendee>? parents,
    bool? includeParents,
    List<EventRsvp>? rsvps,
    EventRsvpStatus? Function()? myRsvpStatus,
    bool? recurring,
    RecurrenceRule? Function()? recurrence,
    String? Function()? attachmentName,
    String? Function()? attachmentUrl,
    int? version,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      code: code ?? this.code,
      occurrenceCode: occurrenceCode ?? this.occurrenceCode,
      type: type ?? this.type,
      name: name ?? this.name,
      date: date ?? this.date,
      allDay: allDay ?? this.allDay,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      classrooms: classrooms ?? this.classrooms,
      students: students ?? this.students,
      staff: staff ?? this.staff,
      parents: parents ?? this.parents,
      includeParents: includeParents ?? this.includeParents,
      rsvps: rsvps ?? this.rsvps,
      myRsvpStatus:
          myRsvpStatus != null ? myRsvpStatus() : this.myRsvpStatus,
      recurring: recurring ?? this.recurring,
      recurrence: recurrence != null ? recurrence() : this.recurrence,
      attachmentName:
          attachmentName != null ? attachmentName() : this.attachmentName,
      attachmentUrl:
          attachmentUrl != null ? attachmentUrl() : this.attachmentUrl,
      version: version ?? this.version,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        code,
        occurrenceCode,
        type,
        name,
        date,
        allDay,
        startTime,
        endTime,
        description,
        classrooms,
        students,
        staff,
        parents,
        includeParents,
        rsvps,
        myRsvpStatus,
        recurring,
        recurrence,
        attachmentName,
        attachmentUrl,
        version,
        createdBy,
        createdByName,
        createdAt,
        updatedAt,
      ];
}
