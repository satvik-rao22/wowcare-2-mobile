import '../../../../domain/features/activity/entities/activity_feed_row.dart';
import 'activity_json_aliases.dart';

class ActivityFeedPageModel {
  ActivityFeedPageModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.pageNumber,
    required this.last,
  });

  final List<ActivityFeedRow> content;
  final int totalElements;
  final int totalPages;
  final int pageNumber;
  final bool last;

  factory ActivityFeedPageModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      return ActivityFeedPageModel(
        content: const [],
        totalElements: 0,
        totalPages: 0,
        pageNumber: 0,
        last: true,
      );
    }

    final rawContent = data['content'];
    final list = <ActivityFeedRow>[];
    if (rawContent is List<dynamic>) {
      for (final e in rawContent) {
        if (e is Map<String, dynamic>) {
          list.addAll(_rowsFromJson(e));
        }
      }
    }

    return ActivityFeedPageModel(
      content: list,
      totalElements: _asInt(data['totalElements']),
      totalPages: _asInt(data['totalPages']),
      pageNumber: _asInt(data['number']),
      last: data['last'] == true,
    );
  }

  ActivityFeedPage toEntity() => ActivityFeedPage(
        content: content,
        totalElements: totalElements,
        totalPages: totalPages,
        pageNumber: pageNumber,
        last: last,
      );

  static List<ActivityFeedRow> _rowsFromJson(Map<String, dynamic> json) {
    try {
      bool? aggregateNapFlagFromStudents(
        List<Map<String, String>> students,
        String flagKey,
      ) {
        if (students.isEmpty) return null;
        var sawTrue = false;
        var sawFalse = false;
        for (final s in students) {
          final v = _activityBoolFromDynamic(s[flagKey]);
          if (v == true) {
            sawTrue = true;
          } else if (v == false) {
            sawFalse = true;
          }
        }
        if (sawTrue && !sawFalse) return true;
        if (!sawTrue && sawFalse) return false;
        return sawTrue ? true : null;
      }

      final params = <Map<String, dynamic>>[];
      final rawPv = json['parameterValues'];
      if (rawPv is List<dynamic>) {
        for (final p in rawPv) {
          if (p is Map<String, dynamic>) params.add(p);
        }
      }
      final atts = <Map<String, dynamic>>[];
      final rawAtt = json['attachments'];
      if (rawAtt is List<dynamic>) {
        for (final a in rawAtt) {
          if (a is Map<String, dynamic>) atts.add(a);
        }
      }
      final singleAttachment = json['attachment'];
      if (singleAttachment is Map<String, dynamic>) {
        atts.add(singleAttachment);
      }

      final activityDate = (json['activityDate'] ?? '').toString();
      if (activityDate.isEmpty) {
        return const [];
      }

      final code = _resolveActivityCode(json);
      final room = (json['classroomCode'] ?? '').toString().trim();
      final activityTypeCode = (json['activityTypeCode'] ?? '').toString();
      final activityTypeName = (json['activityTypeName'] ?? '').toString();
      final description = (json['description'] ?? '').toString();
      final createdBy = (json['createdBy'] ?? '').toString();
      final staffCode = (json['staffCode'] ?? '').toString().trim();
      final approvalStatus = resolveActivityApprovalStatusAlias(json);
      final napStart = _activityBoolFromDynamic(json['napStart']);
      final napEnd = _activityBoolFromDynamic(json['napEnd']);

      final students = <Map<String, String>>[];
      final rawStudents = json['students'];
      if (rawStudents is List<dynamic> && rawStudents.isNotEmpty) {
        for (final s in rawStudents) {
          if (s is! Map<String, dynamic>) continue;
          final first = (s['firstName'] ?? '').toString().trim();
          final middle = (s['middleName'] ?? '').toString().trim();
          final last = (s['lastName'] ?? '').toString().trim();
          final name = [first, middle, last].where((p) => p.isNotEmpty).join(' ');
          final stu = (s['studentCode'] ?? '').toString().trim();
          final napStartRaw = s['napStart'];
          final napEndRaw = s['napEnd'];
          final napStartText = napStartRaw == null
              ? ''
              : napStartRaw.toString().trim();
          final napEndText = napEndRaw == null ? '' : napEndRaw.toString().trim();
          if (name.isNotEmpty || stu.isNotEmpty) {
            students.add({
              if (name.isNotEmpty) 'name': name,
              if (stu.isNotEmpty) 'studentCode': stu,
              if (napStartText.isNotEmpty) 'napStart': napStartText,
              if (napEndText.isNotEmpty) 'napEnd': napEndText,
            });
          }
        }
      }
      final studentNapStart = aggregateNapFlagFromStudents(students, 'napStart');
      final studentNapEnd = aggregateNapFlagFromStudents(students, 'napEnd');
      final effectiveNapStart = napStart ?? studentNapStart;
      final effectiveNapEnd = napEnd ?? studentNapEnd;
      if (students.isNotEmpty) {
        final first = students.first;
        final firstName = (first['name'] ?? '').trim();
        final firstCode = (first['studentCode'] ?? '').trim();
        return [
          ActivityFeedRow(
            activityCode: code.isEmpty ? null : code,
            studentCode: firstCode.isEmpty ? null : firstCode,
            classroomCode: room.isEmpty ? null : room,
            activityTypeCode: activityTypeCode,
            activityTypeName: activityTypeName,
            activityDateIso: activityDate,
            description: description,
            studentFirstName: firstName,
            studentMiddleName: null,
            studentLastName: '',
            createdBy: createdBy,
            staffCode: staffCode.isEmpty ? null : staffCode,
            parameterValues: params,
            attachments: atts,
            students: students,
            napStart: effectiveNapStart,
            napEnd: effectiveNapEnd,
            approvalStatus:
                approvalStatus.isEmpty ? null : approvalStatus.toUpperCase(),
          ),
        ];
      }

      // Fallback for old feed response shape.
      final stu = (json['studentCode'] ?? '').toString().trim();
      return [
        ActivityFeedRow(
          activityCode: code.isEmpty ? null : code,
          studentCode: stu.isEmpty ? null : stu,
          classroomCode: room.isEmpty ? null : room,
          activityTypeCode: activityTypeCode,
          activityTypeName: activityTypeName,
          activityDateIso: activityDate,
          description: description,
          studentFirstName: (json['studentFirstName'] ?? '').toString(),
          studentMiddleName: (json['studentMiddleName'] as String?)?.trim(),
          studentLastName: (json['studentLastName'] ?? '').toString(),
          createdBy: createdBy,
          staffCode: staffCode.isEmpty ? null : staffCode,
          parameterValues: params,
          attachments: atts,
          students: const [],
          napStart: effectiveNapStart,
          napEnd: effectiveNapEnd,
          approvalStatus:
              approvalStatus.isEmpty ? null : approvalStatus.toUpperCase(),
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// The activity's identifying code, under whichever key this endpoint/
  /// response-version used. Declared once here instead of re-derived at every
  /// call site, so a new alias is added in one place, not copy-pasted.
  static String _resolveActivityCode(Map<String, dynamic> json) {
    return (json['cardGroupCode'] ??
            json['code'] ??
            json['batchGroupCode'] ??
            json['activityCode'] ??
            '')
        .toString()
        .trim();
  }

  /// Accepts a real bool OR its string form ('true'/'false'), which the API
  /// sends inconsistently depending on endpoint. Returns null for anything
  /// else (including absent), which callers treat as "unknown", not "false".
  static bool? _activityBoolFromDynamic(dynamic raw) {
    if (raw is bool) return raw;
    final v = (raw ?? '').toString().trim().toLowerCase();
    if (v == 'true') return true;
    if (v == 'false') return false;
    return null;
  }
}
