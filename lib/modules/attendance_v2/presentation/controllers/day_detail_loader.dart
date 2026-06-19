import '../../domain/entities/day_detail.dart';

/// Lazily loads the sessions/breaks for a day when its row is expanded.
typedef DayDetailLoader = Future<DayDetail> Function(DateTime date);
