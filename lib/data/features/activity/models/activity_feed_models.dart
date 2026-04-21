import '../../../../domain/features/activity/entities/activity_feed_row.dart';

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

      final code = (json['code'] ?? json['activityCode'] ?? '')
          .toString()
          .trim();
      final room = (json['classroomCode'] ?? '').toString().trim();
      final activityTypeCode = (json['activityTypeCode'] ?? '').toString();
      final activityTypeName = (json['activityTypeName'] ?? '').toString();
      final description = (json['description'] ?? '').toString();
      final createdBy = (json['createdBy'] ?? '').toString();

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
          if (name.isNotEmpty || stu.isNotEmpty) {
            students.add({
              if (name.isNotEmpty) 'name': name,
              if (stu.isNotEmpty) 'studentCode': stu,
            });
          }
        }
      }
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
            parameterValues: params,
            attachments: atts,
            students: students,
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
          parameterValues: params,
          attachments: atts,
          students: const [],
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
}
