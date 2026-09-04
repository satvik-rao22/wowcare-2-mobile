import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/attendance/models/attendance_audience.dart';

/// One person's totals over a range: how long they attended, and on how many
/// days. Both come back on the range call the app already makes.
@immutable
class RangeEntry extends Equatable {
  const RangeEntry({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.classroomName,
    required this.audience,
    required this.attendedHours,
    required this.attendedMinutes,
    required this.attendedDays,
  });

  final String id;
  final String fullName;
  final String initials;
  final String classroomName;
  final AttendanceAudience audience;

  final int attendedHours;
  final int attendedMinutes;
  final int attendedDays;

  @override
  List<Object?> get props => <Object?>[
    id,
    fullName,
    initials,
    classroomName,
    audience,
    attendedHours,
    attendedMinutes,
    attendedDays,
  ];
}

/// One page of the range list. The list pages as it is scrolled, which is
/// what the real call does.
@immutable
class RangePage extends Equatable {
  const RangePage({
    required this.entries,
    required this.page,
    required this.totalElements,
    required this.hasMore,
  });

  final List<RangeEntry> entries;
  final int page;
  final int totalElements;
  final bool hasMore;

  @override
  List<Object?> get props => <Object?>[entries, page, totalElements, hasMore];
}
