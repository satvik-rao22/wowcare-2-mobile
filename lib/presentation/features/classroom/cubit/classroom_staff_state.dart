import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff_classroom/entities/staff_classroom_item.dart';

class ClassroomStaffState extends Equatable {
  const ClassroomStaffState({
    required this.staff,
    required this.isLoading,
    required this.isRefreshing,
    this.errorMessage,
    this.lastClassroomCode,
    this.attendanceStatusByStaffCode = const <String, String>{},
    this.attendanceStatusLoading = false,
    this.attendanceStatusError = false,
  });

  const ClassroomStaffState.initial()
      : staff = const [],
        isLoading = false,
        isRefreshing = false,
        errorMessage = null,
        lastClassroomCode = null,
        attendanceStatusByStaffCode = const <String, String>{},
        attendanceStatusLoading = false,
        attendanceStatusError = false;

  final List<StaffClassroomItem> staff;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String? lastClassroomCode;

  /// Today's sign-in status per staff code (separate from [staff]'s own
  /// expected/signed-in/absent flags) — drives the attendance dot and gates
  /// which attendance actions are available for the current selection.
  final Map<String, String> attendanceStatusByStaffCode;
  final bool attendanceStatusLoading;
  final bool attendanceStatusError;

  ClassroomStaffState copyWith({
    List<StaffClassroomItem>? staff,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    String? lastClassroomCode,
    Map<String, String>? attendanceStatusByStaffCode,
    bool? attendanceStatusLoading,
    bool? attendanceStatusError,
  }) {
    return ClassroomStaffState(
      staff: staff ?? this.staff,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      lastClassroomCode: lastClassroomCode ?? this.lastClassroomCode,
      attendanceStatusByStaffCode:
          attendanceStatusByStaffCode ?? this.attendanceStatusByStaffCode,
      attendanceStatusLoading:
          attendanceStatusLoading ?? this.attendanceStatusLoading,
      attendanceStatusError: attendanceStatusError ?? this.attendanceStatusError,
    );
  }

  @override
  List<Object?> get props => [
        staff,
        isLoading,
        isRefreshing,
        errorMessage,
        lastClassroomCode,
        attendanceStatusByStaffCode,
        attendanceStatusLoading,
        attendanceStatusError,
      ];
}

