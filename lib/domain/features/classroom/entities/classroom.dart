import 'package:equatable/equatable.dart';

class Classroom extends Equatable {
  const Classroom({
    required this.code,
    required this.name,
    this.minAgeYears = 0,
    this.maxAgeYears = 0,
  });

  final String code;
  final String name;

  /// Inclusive age bounds in whole YEARS, as returned by
  /// `GET /classroom/classroom/all` (e.g. `minAge: 2, maxAge: 4` = 2–4 years).
  /// 0 means that side is unset / not enforced.
  ///
  /// Used to warn (never to block) when a student's age falls outside the room
  /// — see [classroomAgeRangeWarning].
  final int minAgeYears;
  final int maxAgeYears;

  /// True when [ageYears] falls outside an enforced bound. Bounds are
  /// INCLUSIVE, and a 0 bound is treated as unset.
  bool isAgeOutsideRange(int ageYears) {
    if (minAgeYears > 0 && ageYears < minAgeYears) return true;
    if (maxAgeYears > 0 && ageYears > maxAgeYears) return true;
    return false;
  }

  @override
  List<Object?> get props => [code, name, minAgeYears, maxAgeYears];
}

