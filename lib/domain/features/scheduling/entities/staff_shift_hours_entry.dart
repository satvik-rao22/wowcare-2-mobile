import 'package:equatable/equatable.dart';

/// One row from `POST /api/v1/staff-shifts/hours/range`.
class StaffShiftHoursEntry extends Equatable {
  const StaffShiftHoursEntry({
    required this.staffCode,
    required this.shiftDate,
    required this.availableHours,
    required this.scheduledHours,
    required this.unscheduledHours,
  });

  final String staffCode;
  final DateTime shiftDate;
  final double availableHours;
  final double scheduledHours;
  final double unscheduledHours;

  @override
  List<Object?> get props => [
        staffCode,
        shiftDate,
        availableHours,
        scheduledHours,
        unscheduledHours,
      ];
}

/// Aggregated hours for one staff member on one calendar day.
class StaffHoursTotals extends Equatable {
  const StaffHoursTotals({
    this.availableHours = 0,
    this.scheduledHours = 0,
    this.unscheduledHours = 0,
  });

  final double availableHours;
  final double scheduledHours;
  final double unscheduledHours;

  static const zero = StaffHoursTotals();

  @override
  List<Object?> get props =>
      [availableHours, scheduledHours, unscheduledHours];
}
