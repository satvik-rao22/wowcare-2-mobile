import 'dart:convert';

import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';

/// JSON-serializable snapshot of [ActivityFeedPage] for [CacheManager].
class ActivityFeedPageCacheCodec {
  static const int _version = 1;

  static String cacheIdentifier(String requestKey) {
    return base64Url.encode(utf8.encode(requestKey)).replaceAll('=', '');
  }

  static String dailyCacheKey(String requestKey) {
    return CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'feed_daily',
      identifier: cacheIdentifier(requestKey),
    );
  }

  static String rangeCacheKey(String requestKey) {
    return CacheManager.buildCacheKey(
      feature: 'activity',
      resource: 'feed_range',
      identifier: cacheIdentifier(requestKey),
    );
  }

  static Map<String, dynamic> encode(ActivityFeedPage page) {
    return {
      'v': _version,
      'totalElements': page.totalElements,
      'totalPages': page.totalPages,
      'pageNumber': page.pageNumber,
      'last': page.last,
      'content': page.content.map(_encodeRow).toList(),
    };
  }

  static ActivityFeedPage? decode(
    Map<String, dynamic>? payload, {
    required int currentRevision,
  }) {
    if (payload == null) return null;
    final rev = payload['feedCacheRevision'];
    if (rev is! int || rev != currentRevision) return null;
    final pageMap = payload['page'];
    if (pageMap is! Map) return null;
    final m = Map<String, dynamic>.from(pageMap);
    if (m['v'] != _version) return null;

    final rawContent = m['content'];
    if (rawContent is! List) return null;
    final rows = <ActivityFeedRow>[];
    for (final e in rawContent) {
      if (e is Map) {
        final row = _decodeRow(Map<String, dynamic>.from(e));
        if (row != null) rows.add(row);
      }
    }

    return ActivityFeedPage(
      content: rows,
      totalElements: _asInt(m['totalElements']),
      totalPages: _asInt(m['totalPages']),
      pageNumber: _asInt(m['pageNumber']),
      last: m['last'] == true,
    );
  }

  static Map<String, dynamic> wrapPage(
    ActivityFeedPage page,
    int feedCacheRevision,
  ) {
    return {
      'page': encode(page),
      'feedCacheRevision': feedCacheRevision,
    };
  }

  static Map<String, dynamic> _encodeRow(ActivityFeedRow r) {
    return {
      'activityCode': r.activityCode,
      'studentCode': r.studentCode,
      'classroomCode': r.classroomCode,
      'activityTypeCode': r.activityTypeCode,
      'activityTypeName': r.activityTypeName,
      'activityDateIso': r.activityDateIso,
      'description': r.description,
      'studentFirstName': r.studentFirstName,
      'studentMiddleName': r.studentMiddleName,
      'studentLastName': r.studentLastName,
      'students': r.students
          .map((e) => Map<String, String>.from(e))
          .toList(),
      'createdBy': r.createdBy,
      'parameterValues':
          r.parameterValues.map((e) => Map<String, dynamic>.from(e)).toList(),
      'attachments':
          r.attachments.map((e) => Map<String, dynamic>.from(e)).toList(),
    };
  }

  static String? _optionalNonEmptyString(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  static ActivityFeedRow? _decodeRow(Map<String, dynamic> j) {
    try {
      final activityDate = (j['activityDateIso'] ?? '').toString();
      if (activityDate.isEmpty) return null;
      final pv = j['parameterValues'];
      final at = j['attachments'];
      final rawStudents = j['students'];
      return ActivityFeedRow(
        activityCode: _optionalNonEmptyString(j['activityCode']),
        studentCode: _optionalNonEmptyString(j['studentCode']),
        classroomCode: _optionalNonEmptyString(j['classroomCode']),
        activityTypeCode: (j['activityTypeCode'] ?? '').toString(),
        activityTypeName: (j['activityTypeName'] ?? '').toString(),
        activityDateIso: activityDate,
        description: (j['description'] ?? '').toString(),
        studentFirstName: (j['studentFirstName'] ?? '').toString(),
        studentMiddleName: (j['studentMiddleName'] as String?)?.trim(),
        studentLastName: (j['studentLastName'] ?? '').toString(),
        students: rawStudents is List
            ? rawStudents
                .whereType<Map>()
                .map(
                  (e) => Map<String, String>.from(
                    e.map(
                      (key, value) => MapEntry(
                        key.toString(),
                        value?.toString() ?? '',
                      ),
                    ),
                  ),
                )
                .toList()
            : const [],
        createdBy: (j['createdBy'] ?? '').toString(),
        parameterValues: pv is List
            ? pv
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [],
        attachments: at is List
            ? at
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [],
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
