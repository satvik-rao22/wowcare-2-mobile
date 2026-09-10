import 'package:wowcare/domain/features/activity/entities/activity_feed_row.dart';

/// Merges parallel feed page responses (e.g. one per guardian child) into one page.
ActivityFeedPage mergeActivityFeedPages(List<ActivityFeedPage> pages) {
  if (pages.isEmpty) {
    return const ActivityFeedPage(
      content: [],
      totalElements: 0,
      totalPages: 0,
      pageNumber: 0,
      last: true,
    );
  }

  final merged = <ActivityFeedRow>[];
  for (final p in pages) {
    merged.addAll(p.content);
  }

  final seen = <String>{};
  final deduped = <ActivityFeedRow>[];
  for (final r in merged) {
    final ac = (r.activityCode ?? '').trim();
    final key = ac.isNotEmpty
        ? ac
        : '${r.activityDateIso}|${r.studentCode ?? ''}|${r.activityTypeCode}|${r.description}';
    if (seen.contains(key)) continue;
    seen.add(key);
    deduped.add(r);
  }

  deduped.sort((a, b) => b.activityDateIso.compareTo(a.activityDateIso));

  final last = pages.every((p) => p.last);
  final pageNumber = pages.first.pageNumber;
  final maxTotalPages = pages
      .map((p) => p.totalPages)
      .fold<int>(0, (a, b) => a > b ? a : b);
  final totalElements = pages
      .map((p) => p.totalElements)
      .fold<int>(0, (a, b) => a + b);

  return ActivityFeedPage(
    content: deduped,
    totalElements: totalElements,
    totalPages: maxTotalPages,
    pageNumber: pageNumber,
    last: last,
  );
}
