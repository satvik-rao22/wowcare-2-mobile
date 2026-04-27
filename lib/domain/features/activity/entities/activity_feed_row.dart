import 'package:equatable/equatable.dart';

import 'activity_detail.dart';

/// One row from `GET /api/v1/activities/feed/daily` (`data.content[]`).
class ActivityFeedRow extends Equatable {
  const ActivityFeedRow({
    this.activityCode,
    this.studentCode,
    this.classroomCode,
    required this.activityTypeCode,
    required this.activityTypeName,
    required this.activityDateIso,
    required this.description,
    required this.studentFirstName,
    this.studentMiddleName,
    required this.studentLastName,
    required this.createdBy,
    required this.parameterValues,
    required this.attachments,
    this.students = const [],
    this.napStart,
    this.napEnd,
    this.approvalStatus,
  });

  /// Present on feed rows and on `GET /api/v1/activities/code/{code}` — used for edit/PATCH.
  final String? activityCode;
  final String? studentCode;
  final String? classroomCode;
  final String activityTypeCode;
  final String activityTypeName;
  final String activityDateIso;
  final String description;
  final String studentFirstName;
  final String? studentMiddleName;
  final String studentLastName;
  final String createdBy;
  final List<Map<String, dynamic>> parameterValues;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, String>> students;
  final bool? napStart;
  final bool? napEnd;
  final String? approvalStatus;

  factory ActivityFeedRow.fromActivityDetail(ActivityDetail d) {
    final firstName = d.studentFirstName.trim();
    final middleName = (d.studentMiddleName ?? '').trim();
    final lastName = d.studentLastName.trim();
    final fullName = [firstName, middleName, lastName]
        .where((p) => p.isNotEmpty)
        .join(' ')
        .trim();
    return ActivityFeedRow(
      activityCode: d.code,
      studentCode: d.studentCode,
      classroomCode: d.classroomCode,
      activityTypeCode: d.activityTypeCode,
      activityTypeName: d.activityTypeName,
      activityDateIso: d.activityDateIso,
      description: d.description,
      studentFirstName: d.studentFirstName,
      studentMiddleName: d.studentMiddleName,
      studentLastName: d.studentLastName,
      createdBy: d.createdBy,
      parameterValues: d.parameterValues,
      attachments: d.attachments,
      napStart: null,
      napEnd: null,
      approvalStatus: null,
      students: fullName.isEmpty
          ? const []
          : [
              {
                'name': fullName,
                if ((d.studentCode ?? '').trim().isNotEmpty)
                  'studentCode': d.studentCode!.trim(),
              },
            ],
    );
  }

  String get studentDisplayName {
    if (students.isNotEmpty) {
      final names = students
          .map((s) => (s['name'] ?? '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (names.isNotEmpty) return names.join(', ');
    }
    final parts = [
      studentFirstName.trim(),
      (studentMiddleName ?? '').trim(),
      studentLastName.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [
        activityCode,
        studentCode,
        classroomCode,
        activityTypeCode,
        activityTypeName,
        activityDateIso,
        description,
        studentFirstName,
        studentMiddleName,
        studentLastName,
        createdBy,
        parameterValues,
        attachments,
        students,
        napStart,
        napEnd,
        approvalStatus,
      ];
}

class ActivityFeedPage extends Equatable {
  const ActivityFeedPage({
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

  @override
  List<Object?> get props =>
      [content, totalElements, totalPages, pageNumber, last];
}
