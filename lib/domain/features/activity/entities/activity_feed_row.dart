import 'package:equatable/equatable.dart';

/// One row from `GET /api/v1/activities/feed/daily` (`data.content[]`).
class ActivityFeedRow extends Equatable {
  const ActivityFeedRow({
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
  });

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

  String get studentDisplayName {
    final parts = [
      studentFirstName.trim(),
      (studentMiddleName ?? '').trim(),
      studentLastName.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(' ');
  }

  @override
  List<Object?> get props => [
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
