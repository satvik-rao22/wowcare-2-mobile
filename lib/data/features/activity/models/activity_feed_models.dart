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
          final row = _rowFromJson(e);
          if (row != null) list.add(row);
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

  static ActivityFeedRow? _rowFromJson(Map<String, dynamic> json) {
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

      final activityDate = (json['activityDate'] ?? '').toString();
      if (activityDate.isEmpty) {
        return null;
      }
      final first = (json['studentFirstName'] ?? '').toString();
      final last = (json['studentLastName'] ?? '').toString();

      return ActivityFeedRow(
        activityTypeCode: (json['activityTypeCode'] ?? '').toString(),
        activityTypeName: (json['activityTypeName'] ?? '').toString(),
        activityDateIso: activityDate,
        description: (json['description'] ?? '').toString(),
        studentFirstName: first,
        studentMiddleName: (json['studentMiddleName'] as String?)?.trim(),
        studentLastName: last,
        createdBy: (json['createdBy'] ?? '').toString(),
        parameterValues: params,
        attachments: atts,
      );
    } catch (_) {
      return null;
    }
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}
