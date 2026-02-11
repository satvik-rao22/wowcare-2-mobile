import 'package:equatable/equatable.dart';

class StaffCount extends Equatable {
  const StaffCount({
    required this.total,
    required this.active,
    required this.upcoming,
  });

  final int total;
  final int active;
  final int upcoming;

  @override
  List<Object?> get props => [total, active, upcoming];
}


