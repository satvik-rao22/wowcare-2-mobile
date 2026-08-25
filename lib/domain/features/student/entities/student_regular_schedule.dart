import 'package:equatable/equatable.dart';

class StudentRegularScheduleEntry extends Equatable {
  const StudentRegularScheduleEntry({
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final String dayOfWeek;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  @override
  List<Object?> get props => [
    dayOfWeek,
    startHour,
    startMinute,
    endHour,
    endMinute,
  ];
}
