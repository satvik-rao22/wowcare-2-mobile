import 'package:equatable/equatable.dart';

class Classroom extends Equatable {
  const Classroom({
    required this.code,
    required this.name,
    this.minAgeMonths = 0,
    this.maxAgeMonths = 0,
  });

  final String code;
  final String name;

  /// Inclusive age bounds in whole MONTHS, as returned by
  /// `GET /classroom/classroom/all`. 0 means that side is unset / not enforced.
  ///
  /// Used to warn (never to block) when a student's age falls outside the room
  /// — see [classroomAgeRangeWarning].
  final int minAgeMonths;
  final int maxAgeMonths;

  /// True when [ageMonths] falls outside an enforced bound. Bounds are
  /// INCLUSIVE, and a 0 bound is treated as unset, matching the web client.
  bool isAgeOutsideRange(int ageMonths) {
    if (minAgeMonths > 0 && ageMonths < minAgeMonths) return true;
    if (maxAgeMonths > 0 && ageMonths > maxAgeMonths) return true;
    return false;
  }

  @override
  List<Object?> get props => [code, name, minAgeMonths, maxAgeMonths];
}

