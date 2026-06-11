import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';

/// JSON-serializable event DTO. The shape mirrors what the future events
/// API is expected to return (ISO-8601 dates, uppercase enum codes), so the
/// mock seed file and a remote datasource can share this model untouched.
class EventModel extends Equatable {
  const EventModel({
    required this.code,
    required this.type,
    required this.name,
    required this.date,
    required this.allDay,
    this.startTime = '',
    this.endTime = '',
    this.description = '',
    this.classrooms = const <EventAttendeeModel>[],
    this.students = const <EventAttendeeModel>[],
    this.staff = const <EventAttendeeModel>[],
    this.includeParents = false,
    this.rsvps = const <EventRsvpModel>[],
    this.recurring = false,
    this.recurringPattern,
    this.recurringEndDate,
    this.attachmentName,
    this.attachmentUrl,
    this.createdBy = '',
    this.createdByName = '',
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<EventAttendeeModel> attendees(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => EventAttendeeModel.fromJson(
              m.map((k, v) => MapEntry(k.toString(), v))))
          .where((a) => a.code.isNotEmpty)
          .toList();
    }

    final rawRsvps = json['rsvps'];
    return EventModel(
      code: (json['code'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      date: _parseDate(json['date']) ?? DateTime.now(),
      allDay: json['allDay'] == true,
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      classrooms: attendees('classrooms'),
      students: attendees('students'),
      staff: attendees('staff'),
      includeParents: json['includeParents'] == true,
      rsvps: rawRsvps is List
          ? rawRsvps
              .whereType<Map>()
              .map((m) => EventRsvpModel.fromJson(
                  m.map((k, v) => MapEntry(k.toString(), v))))
              .where((r) => r.userCode.isNotEmpty)
              .toList()
          : const [],
      recurring: json['recurring'] == true,
      recurringPattern: json['recurringPattern']?.toString(),
      recurringEndDate: _parseDate(json['recurringEndDate']),
      attachmentName: json['attachmentName']?.toString(),
      attachmentUrl: json['attachmentUrl']?.toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdByName: (json['createdByName'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  factory EventModel.fromEntity(Event event) {
    return EventModel(
      code: event.code,
      type: event.type.value,
      name: event.name,
      date: event.date,
      allDay: event.allDay,
      startTime: event.startTime,
      endTime: event.endTime,
      description: event.description,
      classrooms:
          event.classrooms.map(EventAttendeeModel.fromEntity).toList(),
      students: event.students.map(EventAttendeeModel.fromEntity).toList(),
      staff: event.staff.map(EventAttendeeModel.fromEntity).toList(),
      includeParents: event.includeParents,
      rsvps: event.rsvps.map(EventRsvpModel.fromEntity).toList(),
      recurring: event.recurring,
      recurringPattern: event.recurringPattern?.value,
      recurringEndDate: event.recurringEndDate,
      attachmentName: event.attachmentName,
      attachmentUrl: event.attachmentUrl,
      createdBy: event.createdBy,
      createdByName: event.createdByName,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
  }

  final String code;
  final String type;
  final String name;
  final DateTime date;
  final bool allDay;
  final String startTime;
  final String endTime;
  final String description;
  final List<EventAttendeeModel> classrooms;
  final List<EventAttendeeModel> students;
  final List<EventAttendeeModel> staff;
  final bool includeParents;
  final List<EventRsvpModel> rsvps;
  final bool recurring;
  final String? recurringPattern;
  final DateTime? recurringEndDate;
  final String? attachmentName;
  final String? attachmentUrl;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'code': code,
      'type': type,
      'name': name,
      'date': date.toIso8601String(),
      'allDay': allDay,
      'startTime': startTime,
      'endTime': endTime,
      'description': description,
      'classrooms': classrooms.map((a) => a.toJson()).toList(),
      'students': students.map((a) => a.toJson()).toList(),
      'staff': staff.map((a) => a.toJson()).toList(),
      'includeParents': includeParents,
      'rsvps': rsvps.map((r) => r.toJson()).toList(),
      'recurring': recurring,
      'recurringPattern': recurringPattern,
      'recurringEndDate': recurringEndDate?.toIso8601String(),
      'attachmentName': attachmentName,
      'attachmentUrl': attachmentUrl,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
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
      classrooms: classrooms.map((a) => a.toEntity()).toList(),
      students: students.map((a) => a.toEntity()).toList(),
      staff: staff.map((a) => a.toEntity()).toList(),
      includeParents: includeParents,
      rsvps: rsvps.map((r) => r.toEntity()).toList(),
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

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  @override
  List<Object?> get props => [code, name, type, date, updatedAt];
}

class EventAttendeeModel extends Equatable {
  const EventAttendeeModel({required this.code, required this.name});

  factory EventAttendeeModel.fromJson(Map<String, dynamic> json) {
    return EventAttendeeModel(
      code: (json['code'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString(),
    );
  }

  factory EventAttendeeModel.fromEntity(EventAttendee attendee) {
    return EventAttendeeModel(code: attendee.code, name: attendee.name);
  }

  final String code;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'name': name,
      };

  EventAttendee toEntity() => EventAttendee(code: code, name: name);

  @override
  List<Object?> get props => [code, name];
}

class EventRsvpModel extends Equatable {
  const EventRsvpModel({
    required this.userCode,
    required this.userName,
    required this.userType,
    required this.status,
    required this.respondedAt,
  });

  factory EventRsvpModel.fromJson(Map<String, dynamic> json) {
    return EventRsvpModel(
      userCode: (json['userCode'] ?? '').toString().trim(),
      userName: (json['userName'] ?? '').toString(),
      userType: (json['userType'] ?? '').toString().toUpperCase(),
      status: (json['status'] ?? '').toString(),
      respondedAt:
          DateTime.tryParse((json['respondedAt'] ?? '').toString()) ??
              DateTime.now(),
    );
  }

  factory EventRsvpModel.fromEntity(EventRsvp rsvp) {
    return EventRsvpModel(
      userCode: rsvp.userCode,
      userName: rsvp.userName,
      userType: rsvp.userType,
      status: rsvp.status.value,
      respondedAt: rsvp.respondedAt,
    );
  }

  final String userCode;
  final String userName;
  final String userType;
  final String status;
  final DateTime respondedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userCode': userCode,
        'userName': userName,
        'userType': userType,
        'status': status,
        'respondedAt': respondedAt.toIso8601String(),
      };

  EventRsvp toEntity() => EventRsvp(
        userCode: userCode,
        userName: userName,
        userType: userType,
        status: EventRsvpStatus.fromValue(status) ?? EventRsvpStatus.maybe,
        respondedAt: respondedAt,
      );

  @override
  List<Object?> get props => [userCode, userType, status, respondedAt];
}
