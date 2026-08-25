import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';

class ClassroomStaffState extends Equatable {
  const ClassroomStaffState({
    required this.staff,
    required this.isLoading,
    required this.isRefreshing,
    this.errorMessage,
    this.lastClassroomCode,
  });

  const ClassroomStaffState.initial()
    : staff = const [],
      isLoading = false,
      isRefreshing = false,
      errorMessage = null,
      lastClassroomCode = null;

  final List<StaffClassroomItem> staff;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String? lastClassroomCode;

  ClassroomStaffState copyWith({
    List<StaffClassroomItem>? staff,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    String? lastClassroomCode,
  }) {
    return ClassroomStaffState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      lastClassroomCode: lastClassroomCode ?? this.lastClassroomCode,
    );
  }

  @override
  List<Object?> get props => [
    staff,
    isLoading,
    isRefreshing,
    errorMessage,
    lastClassroomCode,
  ];
}
