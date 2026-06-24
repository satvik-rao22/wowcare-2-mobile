import 'package:equatable/equatable.dart';

/// A single shift block. [start]/[end] are in `hh:mm:ss a` format.
class Shift extends Equatable {
  const Shift({
    required this.start,
    required this.end,
    required this.room,
    this.isBreakShift = false,
    this.shiftCode = '',
  });

  final String start;
  final String end;
  final String room;
  final bool isBreakShift;

  /// Source shift identity (empty for mock/legacy data).
  final String shiftCode;

  @override
  List<Object?> get props => [start, end, room, isBreakShift, shiftCode];
}

/// All shifts for one day.
class DailyShifts extends Equatable {
  const DailyShifts({required this.shifts});

  final List<Shift> shifts;

  @override
  List<Object?> get props => [shifts];
}
