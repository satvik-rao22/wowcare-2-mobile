import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/event_upload_session.dart';

/// JSON-serializable event DTO. The shape mirrors what the future events
/// API is expected to return (ISO-8601 dates, uppercase enum codes), so the
/// mock seed file and a remote datasource can share this model untouched.
class EventModel extends Equatable {
  const EventModel({
    required this.code,
    this.occurrenceCode = '',
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
    this.parents = const <EventAttendeeModel>[],
    this.includeParents = false,
    this.rsvps = const <EventRsvpModel>[],
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

  /// Parses the scheduler API event payload (§4.3 of the frontend contract):
  /// `seriesStartDate`/`seriesStartTime`/`allDayFlag`/`recurringFlag`/`rrule`
  /// plus `audiences` selectors. Distinct from [EventModel.fromJson], which
  /// keeps understanding the legacy seed-file shape.
  ///
  /// Audience selectors carry a hydrated `selectorName`; the occasional
  /// null name (unhydrated row) is left empty and filled client-side by
  /// the attendee-name resolver as a fallback.
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
        final attendee = EventAttendeeModel(
          code: code,
          name: (entry['selectorName'] ?? '').toString().trim(),
        );
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
    final recurring = json['recurringFlag'] == true;
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
      recurring: recurring,
      recurrence: recurring
          ? parseRrule(rrule, untilOverride: _parseDate(json['rruleUntil']))
          : null,
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdBy: (json['createdBy'] ?? '').toString(),
      createdByName: (json['createdByName'] ?? '').toString(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  /// One row of `GET /api/v1/occurrences` — the occurrence-based read
  /// view. Carries display fields (occurrence overrides pre-applied by the
  /// server), the caller's `myRsvp`, and the full hydrated `participants`
  /// roster with per-person RSVPs, so no follow-up calls are needed.
  factory EventModel.fromOccurrenceApi(Map<String, dynamic> json) {
    String codeOf(Map entry) =>
        (entry['entityCode'] ?? entry['partyCode'] ?? '').toString().trim();

    List<EventAttendeeModel> group(dynamic entries) {
      if (entries is! List) return const <EventAttendeeModel>[];
      return [
        for (final entry in entries.whereType<Map>())
          if (codeOf(entry).isNotEmpty)
            EventAttendeeModel(
              code: codeOf(entry),
              name: (entry['name'] ?? '').toString().trim(),
              linkedCode:
                  (entry['linkedStudentCode'] ?? '').toString().trim(),
            ),
      ];
    }

    // Per-person responses (explicit rows + implicit student ATTENDING)
    // feed the RSVP summary and the roster sheets.
    List<EventRsvpModel> responses(dynamic entries, String partyType) =>
        entries is! List
            ? const <EventRsvpModel>[]
            : [
                for (final entry in entries.whereType<Map>())
                  if ((entry['rsvp'] ?? '').toString().trim().isNotEmpty)
                    EventRsvpModel(
                      userCode: (entry['partyCode'] ?? '').toString().trim(),
                      userName: (entry['name'] ?? '').toString().trim(),
                      userType: partyType,
                      status: (entry['rsvp'] ?? '').toString(),
                      respondedAt: _parseDate(entry['respondedAt']) ??
                          DateTime.now(),
                    ),
              ];

    final participants = json['participants'];
    final classrooms = participants is Map ? participants['classroom'] : null;
    final students = participants is Map ? participants['students'] : null;
    final staff = participants is Map ? participants['staff'] : null;
    final parents = participants is Map ? participants['parents'] : null;

    final myRsvp = json['myRsvp'];
    final myRsvpImplicit = myRsvp is Map && myRsvp['implicit'] == true;

    return EventModel(
      code: (json['eventCode'] ?? '').toString().trim(),
      occurrenceCode: (json['occurrenceCode'] ?? '').toString().trim(),
      type: (json['type'] ?? '').toString(),
      name: (json['displayName'] ?? '').toString(),
      description: (json['displayDescription'] ?? '').toString(),
      date: _parseDate(json['scheduledStartDate']) ?? DateTime.now(),
      allDay: json['allDayFlag'] == true,
      startTime: _hhmm(json['scheduledStartTime']),
      endTime: _hhmm(json['scheduledEndTime']),
      classrooms: group(classrooms),
      students: group(students),
      staff: group(staff),
      parents: group(parents),
      includeParents: json['includeParentsFlag'] == true,
      rsvps: [
        ...responses(staff, 'STAFF'),
        ...responses(students, 'STUDENT'),
        ...responses(parents, 'PARENT'),
      ],
      // Implicit student rows aren't the caller's own choice.
      myRsvpStatus: myRsvp is Map && !myRsvpImplicit
          ? myRsvp['status']?.toString()
          : null,
      recurring: json['recurring'] == true,
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
      recurrence: _legacyRule(json),
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
      occurrenceCode: event.occurrenceCode,
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
      parents: event.parents.map(EventAttendeeModel.fromEntity).toList(),
      includeParents: event.includeParents,
      rsvps: event.rsvps.map(EventRsvpModel.fromEntity).toList(),
      myRsvpStatus: event.myRsvpStatus?.value,
      recurring: event.recurring,
      recurrence: event.recurrence,
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
  final String occurrenceCode;
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
  final List<EventAttendeeModel> parents;
  final bool includeParents;
  final List<EventRsvpModel> rsvps;
  final String? myRsvpStatus;
  final bool recurring;
  final RecurrenceRule? recurrence;
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
  static Map<String, dynamic> createBody(
    Event event, {
    List<String> assetCodes = const [],
  }) {
    return <String, dynamic>{
      'type': event.type.value,
      'name': event.name,
      if (event.description.isNotEmpty) 'description': event.description,
      'seriesStartDate': formatDate(event.date),
      if (!event.allDay && event.startTime.isNotEmpty)
        'seriesStartTime': apiTime(event.startTime),
      if (!event.allDay && event.endTime.isNotEmpty)
        'seriesEndTime': apiTime(event.endTime),
      'allDayFlag': event.allDay,
      'audienceScope': _audienceScope(event.type),
      'includeParentsFlag': event.includeParents,
      'recurringFlag': event.recurring,
      if (event.recurring && event.recurrence != null)
        'rrule': buildRrule(event),
      'audiences': _audiences(event),
      // Ready asset codes from the upload session. Omitted when empty so an
      // event with no attachments does not send an empty array.
      if (assetCodes.isNotEmpty) 'attachmentAssetCodes': assetCodes,
    };
  }

  /// Builds the `PATCH /api/v1/events/{code}` body. Everything is editable
  /// except the event type (and its derived audience scope) — changing the
  /// type means delete + recreate.
  static Map<String, dynamic> updateBody(
    Event event, {
    List<String>? assetCodes,
  }) {
    final body = createBody(event, assetCodes: assetCodes ?? const [])
      ..remove('type')
      ..remove('audienceScope');
    // Sent even when empty so a cleared description persists (PATCH
    // treats only OMITTED fields as untouched; createBody omits blanks).
    body['description'] = event.description;
    // Full replace when present, untouched when null — so a save that staged no
    // new files leaves the existing attachments alone.
    if (assetCodes != null) body['attachmentAssetCodes'] = assetCodes;
    return body;
  }

  /// Parses `POST /events/upload-session`, falling back to
  /// [fallbackDocumentBasePath] when the response omits the document base path.
  static EventUploadSession uploadSession(
    dynamic raw, {
    required String fallbackDocumentBasePath,
  }) {
    final data = raw is Map<String, dynamic> ? raw['data'] : null;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected event upload-session response format');
    }
    final sessionCode = (data['sessionCode'] ?? '').toString().trim();
    if (sessionCode.isEmpty) {
      throw Exception('Event upload session code is missing');
    }
    final basePath = (data['documentApiBasePath'] ?? '').toString().trim();
    return EventUploadSession(
      sessionCode: sessionCode,
      documentApiBasePath:
          basePath.isEmpty ? fallbackDocumentBasePath : basePath,
    );
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

  /// RFC 5545 RRULE for the Teams-style [Event.recurrence], anchored at
  /// [Event.date]. Emits `INTERVAL` for "every N", plain `BYDAY` for
  /// weekday sets, ordinal `BYDAY` (`3WE`, `-1FR`) for nth-weekday
  /// monthly/yearly modes, and `BYMONTH`/`BYMONTHDAY` anchors.
  static String buildRrule(Event event) {
    final rule = event.recurrence!;
    final start = event.date;

    var frequency = rule.frequency;
    String? byDay;
    String? byMonthDay;
    String? byMonth;

    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        // Teams semantics: "every day on Mon, Wed" is weekly-on-those-days.
        if (rule.interval == 1 &&
            rule.daysOfWeek.isNotEmpty &&
            rule.daysOfWeek.length < 7) {
          frequency = RecurrenceFrequency.weekly;
          byDay = _plainByDay(rule.daysOfWeek);
        }
      case RecurrenceFrequency.weekly:
        byDay = _plainByDay(
          rule.daysOfWeek.isEmpty ? {start.weekday} : rule.daysOfWeek,
        );
      case RecurrenceFrequency.monthly:
        if (rule.monthlyMode == MonthlyRepeatMode.dayOfMonth) {
          byMonthDay = '${start.day}';
        } else {
          byDay = _ordinalByDay(start);
        }
      case RecurrenceFrequency.yearly:
        byMonth = '${start.month}';
        if (rule.yearlyMode == YearlyRepeatMode.date) {
          byMonthDay = '${start.day}';
        } else {
          byDay = _ordinalByDay(start);
        }
    }

    final end = rule.endDate;
    return [
      'FREQ=${frequency.value}',
      if (rule.interval > 1) 'INTERVAL=${rule.interval}',
      if (byMonth != null) 'BYMONTH=$byMonth',
      if (byMonthDay != null) 'BYMONTHDAY=$byMonthDay',
      if (byDay != null) 'BYDAY=$byDay',
      if (end != null) 'UNTIL=${_compactDate(end)}',
    ].join(';');
  }

  /// Parses the scheduler API's RRULE back into a [RecurrenceRule];
  /// [untilOverride] (the response's explicit `rruleUntil`) wins over the
  /// UNTIL token. Returns null when FREQ is missing or unknown.
  static RecurrenceRule? parseRrule(String rrule, {DateTime? untilOverride}) {
    final tokens = <String, String>{};
    for (final part in rrule.toUpperCase().split(';')) {
      final split = part.indexOf('=');
      if (split <= 0) continue;
      tokens[part.substring(0, split).trim()] =
          part.substring(split + 1).trim();
    }

    final frequency = RecurrenceFrequency.fromValue(tokens['FREQ']);
    if (frequency == null) return null;

    final daysOfWeek = <int>{};
    var hasOrdinalByDay = false;
    for (final token in (tokens['BYDAY'] ?? '').split(',')) {
      final match =
          RegExp(r'^(-?[0-9]+)?([A-Z]{2})$').firstMatch(token.trim());
      if (match == null) continue;
      if (match.group(1) != null) hasOrdinalByDay = true;
      final weekday = _weekdayFromToken[match.group(2)];
      if (weekday != null) daysOfWeek.add(weekday);
    }

    return RecurrenceRule(
      frequency: frequency,
      interval: (int.tryParse(tokens['INTERVAL'] ?? '') ?? 1).clamp(1, 99),
      // An ordinal BYDAY (3WE) anchors monthly/yearly nth-weekday modes;
      // it is not a weekday set.
      daysOfWeek: hasOrdinalByDay ? const <int>{} : daysOfWeek,
      monthlyMode: hasOrdinalByDay
          ? MonthlyRepeatMode.nthWeekday
          : MonthlyRepeatMode.dayOfMonth,
      yearlyMode: hasOrdinalByDay
          ? YearlyRepeatMode.nthWeekday
          : YearlyRepeatMode.date,
      endDate: untilOverride ?? _rruleUntil(rrule),
    );
  }

  /// Simple rule from the legacy seed-file keys
  /// (`recurringPattern: DAILY|WEEKLY|MONTHLY` + `recurringEndDate`).
  static RecurrenceRule? _legacyRule(Map<String, dynamic> json) {
    if (json['recurring'] != true) return null;
    final frequency =
        RecurrenceFrequency.fromValue(json['recurringPattern']?.toString());
    if (frequency == null) return null;
    return RecurrenceRule(
      frequency: frequency,
      endDate: _parseDate(json['recurringEndDate']),
    );
  }

  static const Map<int, String> _weekdayTokens = {
    DateTime.monday: 'MO',
    DateTime.tuesday: 'TU',
    DateTime.wednesday: 'WE',
    DateTime.thursday: 'TH',
    DateTime.friday: 'FR',
    DateTime.saturday: 'SA',
    DateTime.sunday: 'SU',
  };

  static final Map<String, int> _weekdayFromToken = {
    for (final entry in _weekdayTokens.entries) entry.value: entry.key,
  };

  static String _plainByDay(Set<int> days) {
    final sorted = days.toList()..sort();
    return sorted.map((day) => _weekdayTokens[day]!).join(',');
  }

  /// `3WE` for the third Wednesday, `-1FR` when [date] is the month's last
  /// occurrence of its weekday (Teams "last Friday").
  static String _ordinalByDay(DateTime date) {
    final ordinal = RecurrenceRule.isLastWeekdayOfMonth(date)
        ? -1
        : RecurrenceRule.nthWeekdayOfMonth(date);
    return '$ordinal${_weekdayTokens[date.weekday]!}';
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
  static String apiTime(String hhmm) =>
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
      'recurringPattern': recurrence?.frequency.value,
      'recurringEndDate': recurrence?.endDate?.toIso8601String(),
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
      occurrenceCode: occurrenceCode,
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
      parents: parents.map((a) => a.toEntity()).toList(),
      includeParents: includeParents,
      rsvps: rsvps.map((r) => r.toEntity()).toList(),
      myRsvpStatus: EventRsvpStatus.fromValue(myRsvpStatus),
      recurring: recurring,
      recurrence: recurrence,
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
  const EventAttendeeModel({
    required this.code,
    required this.name,
    this.linkedCode = '',
  });

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
  final String linkedCode;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'name': name,
      };

  EventAttendee toEntity() =>
      EventAttendee(code: code, name: name, linkedCode: linkedCode);

  @override
  List<Object?> get props => [code, name, linkedCode];
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

  /// One row of the occurrence RSVPs roster
  /// (`GET /events/{code}/occurrences/{occ}/rsvps` — §08.4): partyCode /
  /// partyName / partyType / status / respondedAt. Implicit student rows
  /// arrive as regular ATTENDING rows, matching the API's count semantics.
  factory EventRsvpModel.fromApi(Map<String, dynamic> json) {
    final code = (json['partyCode'] ?? '').toString().trim();
    final name = (json['partyName'] ?? '').toString().trim();
    return EventRsvpModel(
      userCode: code,
      userName: name.isNotEmpty ? name : code,
      userType: (json['partyType'] ?? '').toString().toUpperCase(),
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
