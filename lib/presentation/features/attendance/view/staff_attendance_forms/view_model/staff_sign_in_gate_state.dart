import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../model/staff_entity.dart';

/// State for the staff sign-in form's non-submit business logic: the picked
/// date/time, school zone, persona/admin flags, current staff code, the working
/// staff list, and the unexpected-sign-in gate. Owned by [StaffSignInGateCubit];
/// the widget holds no business state.
class StaffSignInGateState extends Equatable {
  const StaffSignInGateState({
    required this.selectedDate,
    required this.selectedTime,
    this.schoolIana,
    this.isStaffAdminPersona,
    this.isAdminRole,
    this.currentStaffCode,
    this.selectedStaff = const [],
    this.expectedTodayFromApi = const {},
    this.unexpectedGateLoading = true,
    this.unexpectedSignInAcknowledged = false,
    this.notExpectedComment = '',
  });

  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String? schoolIana;

  /// Admin persona may back-date the time (never future); null until resolved.
  final bool? isStaffAdminPersona;

  /// Admin role: may select other staff (vs self-only); null until resolved.
  final bool? isAdminRole;

  /// Current user's staff code (self-only validation / prefill).
  final String? currentStaffCode;

  final List<StaffEntity> selectedStaff;

  /// staffCode -> isExpectedToday, from the sign-in form-list API.
  final Map<String, bool> expectedTodayFromApi;

  final bool unexpectedGateLoading;
  final bool unexpectedSignInAcknowledged;
  final String notExpectedComment;

  StaffSignInGateState copyWith({
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    String? schoolIana,
    bool? isStaffAdminPersona,
    bool? isAdminRole,
    String? currentStaffCode,
    List<StaffEntity>? selectedStaff,
    Map<String, bool>? expectedTodayFromApi,
    bool? unexpectedGateLoading,
    bool? unexpectedSignInAcknowledged,
    String? notExpectedComment,
  }) {
    return StaffSignInGateState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      schoolIana: schoolIana ?? this.schoolIana,
      isStaffAdminPersona: isStaffAdminPersona ?? this.isStaffAdminPersona,
      isAdminRole: isAdminRole ?? this.isAdminRole,
      currentStaffCode: currentStaffCode ?? this.currentStaffCode,
      selectedStaff: selectedStaff ?? this.selectedStaff,
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
    isStaffAdminPersona,
    isAdminRole,
    currentStaffCode,
    selectedStaff,
    expectedTodayFromApi,
    unexpectedGateLoading,
    unexpectedSignInAcknowledged,
    notExpectedComment,
  ];
}
