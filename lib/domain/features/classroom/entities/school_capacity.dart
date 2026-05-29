import 'package:equatable/equatable.dart';

class SchoolCapacity extends Equatable {
  const SchoolCapacity({
    required this.capacity,
    required this.minAgeMonths,
    required this.maxAgeMonths,
  });

  final int capacity;
  final int minAgeMonths;
  final int maxAgeMonths;

  @override
  List<Object?> get props => [capacity, minAgeMonths, maxAgeMonths];
}
