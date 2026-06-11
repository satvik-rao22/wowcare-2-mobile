import 'package:isar/isar.dart';
import 'package:wowcare/core/util/isar_utils.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';

part 'event_collection.g.dart';

@collection
class EventCollection {
  Id get isarId => fastHash(code);

  @Index(unique: true, replace: true)
  late String code;
  late String type;
  late String name;
  @Index()
  late DateTime date;
  late bool allDay;
  late String startTime;
  late String endTime;
  late String description;
  late bool includeParents;
  late bool recurring;
  String? recurringPattern;
  DateTime? recurringEndDate;
  String? attachmentName;
  String? attachmentUrl;
  late String createdBy;
  late String createdByName;
  late DateTime createdAt;
  late DateTime updatedAt;

  List<EventAttendeeCollection>? classrooms;
  List<EventAttendeeCollection>? students;
  List<EventAttendeeCollection>? staff;
  List<EventRsvpCollection>? rsvps;

  EventCollection();

  factory EventCollection.fromEntity(Event event) {
    return EventCollection()
      ..code = event.code
      ..type = event.type.value
      ..name = event.name
      ..date = event.date
      ..allDay = event.allDay
      ..startTime = event.startTime
      ..endTime = event.endTime
      ..description = event.description
      ..includeParents = event.includeParents
      ..recurring = event.recurring
      ..recurringPattern = event.recurringPattern?.value
      ..recurringEndDate = event.recurringEndDate
      ..attachmentName = event.attachmentName
      ..attachmentUrl = event.attachmentUrl
      ..createdBy = event.createdBy
      ..createdByName = event.createdByName
      ..createdAt = event.createdAt
      ..updatedAt = event.updatedAt
      ..classrooms = event.classrooms
          .map(EventAttendeeCollection.fromEntity)
          .toList()
      ..students =
          event.students.map(EventAttendeeCollection.fromEntity).toList()
      ..staff = event.staff.map(EventAttendeeCollection.fromEntity).toList()
      ..rsvps = event.rsvps.map(EventRsvpCollection.fromEntity).toList();
  }

  Event toEntity() {
    return Event(
      code: code,
      type: EventType.fromValue(type),
      name: name,
      date: date,
      allDay: allDay,
      startTime: startTime,
      endTime: endTime,
      description: description,
      classrooms:
          (classrooms ?? const []).map((a) => a.toEntity()).toList(),
      students: (students ?? const []).map((a) => a.toEntity()).toList(),
      staff: (staff ?? const []).map((a) => a.toEntity()).toList(),
      includeParents: includeParents,
      rsvps: (rsvps ?? const []).map((r) => r.toEntity()).toList(),
      recurring: recurring,
      recurringPattern: EventRecurrence.fromValue(recurringPattern),
      recurringEndDate: recurringEndDate,
      attachmentName: attachmentName,
      attachmentUrl: attachmentUrl,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

@embedded
class EventAttendeeCollection {
  late String code;
  late String name;

  EventAttendeeCollection();

  factory EventAttendeeCollection.fromEntity(EventAttendee attendee) {
    return EventAttendeeCollection()
      ..code = attendee.code
      ..name = attendee.name;
  }

  EventAttendee toEntity() => EventAttendee(code: code, name: name);
}

@embedded
class EventRsvpCollection {
  late String userCode;
  late String userName;
  late String userType;
  late String status;
  late DateTime respondedAt;

  EventRsvpCollection();

  factory EventRsvpCollection.fromEntity(EventRsvp rsvp) {
    return EventRsvpCollection()
      ..userCode = rsvp.userCode
      ..userName = rsvp.userName
      ..userType = rsvp.userType
      ..status = rsvp.status.value
      ..respondedAt = rsvp.respondedAt;
  }

  EventRsvp toEntity() => EventRsvp(
        userCode: userCode,
        userName: userName,
        userType: userType,
        status: EventRsvpStatus.fromValue(status) ?? EventRsvpStatus.maybe,
        respondedAt: respondedAt,
      );
}
