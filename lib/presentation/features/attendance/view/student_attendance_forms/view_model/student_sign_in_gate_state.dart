import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../student_sign_in_form.dart' show StudentEntity;

/// State for the student sign-in form's non-submit business logic: the working
/// student list, persona/identity, the picked date/time, and the
/// unexpected-sign-in gate. Owned by [StudentSignInGateCubit]; the widget holds
/// no business state.
class StudentSignInGateState extends Equatable {
  const StudentSignInGateState({
    required this.selectedDate,
    required this.selectedTime,
    this.schoolIana,
    this.isStaffPersona,
    this.currentStudents = const [],
    this.expectedTodayFromApi = const {},
    this.unexpectedGateLoading = true,
    this.unexpectedSignInAcknowledged = false,
    this.notExpectedComment = '',
  });

  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  /// School IANA id from API; when set, date/time defaults and occurredAt use it.
  final String? schoolIana;

  /// True for staff-side logins (gates date/time editing); null until resolved.
  final bool? isStaffPersona;

  final List<StudentEntity> currentStudents;

  /// studentCode -> isExpectedToday, from the sign-in form-list API.
  final Map<String, bool> expectedTodayFromApi;

  final bool unexpectedGateLoading;
  final bool unexpectedSignInAcknowledged;
  final String notExpectedComment;

  StudentSignInGateState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    String? schoolIana,
    bool? isStaffPersona,
    List<StudentEntity>? currentStudents,
    Map<String, bool>? expectedTodayFromApi,
    bool? unexpectedGateLoading,
    bool? unexpectedSignInAcknowledged,
    String? notExpectedComment,
  }) {
    return StudentSignInGateState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      schoolIana: schoolIana ?? this.schoolIana,
      isStaffPersona: isStaffPersona ?? this.isStaffPersona,
      currentStudents: currentStudents ?? this.currentStudents,
      expectedTodayFromApi: expectedTodayFromApi ?? this.expectedTodayFromApi,
      unexpectedGateLoading:
          unexpectedGateLoading ?? this.unexpectedGateLoading,
      unexpectedSignInAcknowledged:
          unexpectedSignInAcknowledged ?? this.unexpectedSignInAcknowledged,
      notExpectedComment: notExpectedComment ?? this.notExpectedComment,
    );
  }

  @override
  List<Object?> get props => [
    selectedDate,
    selectedTime,
    schoolIana,
    isStaffPersona,
    currentStudents,
    expectedTodayFromApi,
    unexpectedGateLoading,
    unexpectedSignInAcknowledged,
    notExpectedComment,
  ];
}
