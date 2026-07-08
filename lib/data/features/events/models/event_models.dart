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
    this.version = 0,
    this.createdBy = '',
    this.createdByName = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Parses the scheduler API event payload (§4.3 of the frontend contract):
  /// `seriesStartDate`/`seriesStartTime`/`allDayFlag`/`recurringFlag`/`rrule`
  /// plus `audiences` selectors. Distinct from [EventModel.fromJson], which
  /// keeps understanding the legacy seed-file shape.
  ///
  /// The API returns audiences as bare selectors (kind + code, no display
  /// name), so attendee names come back empty — callers that already know
  /// the names (create/update flows) merge them back in.
  factory EventModel.fromApi(Map<String, dynamic> json) {
    final classrooms = <EventAttendeeModel>[];
    final students = <EventAttendeeModel>[];
    final staff = <EventAttendeeModel>[];
    final audiences = json['audiences'];
    if (audiences is List) {
      for (final entry in audiences.whereType<Map>()) {
        final kind = (entry['selectorKind'] ?? '').toString().toUpperCase();
        final code = (entry['selectorCode'] ?? '').toString().trim();
        if (code.isEmpty) continue; // SCHOOL_WIDE / ALL_* carry no code.
        final attendee = EventAttendeeModel(code: code, name: '');
        switch (kind) {
          case 'CLASSROOM':
            classrooms.add(attendee);
          case 'STUDENT':
            students.add(attendee);
          case 'STAFF':
            staff.add(attendee);
        }
      }
    }

    final rrule = (json['rrule'] ?? '').toString();
    return EventModel(
      code: (json['code'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      date: _parseDate(json['seriesStartDate']) ?? DateTime.now(),
      allDay: json['allDayFlag'] == true,
      startTime: _hhmm(json['seriesStartTime']),
      endTime: _hhmm(json['seriesEndTime']),
      description: (json['description'] ?? '').toString(),
      classrooms: classrooms,
      students: students,
      staff: staff,
      includeParents: json['includeParentsFlag'] == true,
      recurring: json['recurringFlag'] == true,
      recurringPattern: _rruleFreq(rrule),
      recurringEndDate:
          _parseDate(json['rruleUntil']) ?? _rruleUntil(rrule),
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdBy: (json['createdBy'] ?? '').toString(),
      createdByName: (json['createdByName'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

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
      version: event.version,
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
  final int version;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Builds the `POST /api/v1/events` body (§4.1 of the frontend contract)
  /// from a form draft. Times go as `HH:mm:ss` and are omitted for all-day
  /// events; the recurrence is encoded as an RFC 5545 `rrule`.
  static Map<String, dynamic> createBody(Event event) {
    return <String, dynamic>{
      'type': event.type.value,
      'name': event.name,
      if (event.description.isNotEmpty) 'description': event.description,
      'seriesStartDate': formatDate(event.date),
      if (!event.allDay && event.startTime.isNotEmpty)
        'seriesStartTime': _apiTime(event.startTime),
      if (!event.allDay && event.endTime.isNotEmpty)
        'seriesEndTime': _apiTime(event.endTime),
      'allDayFlag': event.allDay,
      'audienceScope': _audienceScope(event.type),
      'includeParentsFlag': event.includeParents,
      'recurringFlag': event.recurring,
      if (event.recurring && event.recurringPattern != null)
        'rrule': buildRrule(event),
      'audiences': _audiences(event),
    };
  }

  /// `AudienceScope` derived from the UI's event type (§4.2). CUSTOM and
  /// INDIVIDUAL both map to the CUSTOM scope with mixed selectors —
  /// pending confirmation from the backend, which only documents the
  /// School/Classroom/Student/Staff modes.
  static String _audienceScope(EventType type) {
    switch (type) {
      case EventType.school:
        return 'SCHOOL';
      case EventType.classroom:
        return 'CLASSROOM_SET';
      case EventType.student:
        return 'STUDENT_SET';
      case EventType.staff:
        return 'STAFF_SET';
      case EventType.custom:
      case EventType.individual:
        return 'CUSTOM';
    }
  }

  /// Audience selectors per mode (§4.2). School events send the single
  /// SCHOOL_WIDE selector — the server expands classrooms/staff/admins
  /// itself, so the locally-snapshotted classroom list is ignored.
  static List<Map<String, String>> _audiences(Event event) {
    Map<String, String> selector(String kind, [String? code]) => {
          'selectorKind': kind,
          if (code != null) 'selectorCode': code,
        };

    switch (event.type) {
      case EventType.school:
        return [selector('SCHOOL_WIDE')];
      case EventType.classroom:
        return [
          for (final c in event.classrooms) selector('CLASSROOM', c.code),
        ];
      case EventType.student:
        return [
          for (final s in event.students) selector('STUDENT', s.code),
        ];
      case EventType.staff:
        return [for (final s in event.staff) selector('STAFF', s.code)];
      case EventType.custom:
      case EventType.individual:
        return [
          for (final c in event.classrooms) selector('CLASSROOM', c.code),
          for (final s in event.students) selector('STUDENT', s.code),
          for (final s in event.staff) selector('STAFF', s.code),
        ];
    }
  }

  /// RRULE per the contract's §5.1 mapping. Weekly recurs on the start
  /// date's weekday (no BYDAY needed); monthly pins BYMONTHDAY to the
  /// start date's day.
  static String buildRrule(Event event) {
    final until = event.recurringEndDate;
    final untilPart = until != null ? ';UNTIL=${_compactDate(until)}' : '';
    switch (event.recurringPattern!) {
      case EventRecurrence.daily:
        return 'FREQ=DAILY$untilPart';
      case EventRecurrence.weekly:
        return 'FREQ=WEEKLY$untilPart';
      case EventRecurrence.monthly:
        return 'FREQ=MONTHLY;BYMONTHDAY=${event.date.day}$untilPart';
    }
  }

  /// FREQ token of an RRULE → [EventRecurrence] code, null when absent
  /// or unsupported by the UI (e.g. YEARLY).
  static String? _rruleFreq(String rrule) {
    final match = RegExp('FREQ=([A-Z]+)').firstMatch(rrule.toUpperCase());
    final freq = match?.group(1);
    return (freq == 'DAILY' || freq == 'WEEKLY' || freq == 'MONTHLY')
        ? freq
        : null;
  }

  /// UNTIL token of an RRULE (compact `yyyyMMdd` or full
  /// `yyyyMMdd'T'HHmmss[Z]`) → date, null when absent.
  static DateTime? _rruleUntil(String rrule) {
    final match =
        RegExp('UNTIL=([0-9]{8})').firstMatch(rrule.toUpperCase());
    final raw = match?.group(1);
    if (raw == null) return null;
    return DateTime.tryParse(
      '${raw.substring(0, 4)}-${raw.substring(4, 6)}-${raw.substring(6)}',
    );
  }

  /// `yyyy-MM-dd` for API date fields.
  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _compactDate(DateTime date) =>
      formatDate(date).replaceAll('-', '');

  /// API `HH:mm:ss` → UI `HH:mm` (the form's time parser only accepts
  /// two segments, so seconds must be stripped here).
  static String _hhmm(dynamic raw) {
    final value = (raw ?? '').toString().trim();
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  /// UI `HH:mm` → API `HH:mm:ss`.
  static String _apiTime(String hhmm) =>
      hhmm.length == 5 ? '$hhmm:00' : hhmm;

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
      version: version,
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
