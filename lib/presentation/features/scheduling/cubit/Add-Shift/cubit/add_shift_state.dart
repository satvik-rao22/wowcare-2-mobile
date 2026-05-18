import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../../../domain/features/staff/entities/staff_profile.dart';

class AddShiftState extends Equatable {
  final DateTime? shiftDate;
  final String? selectedStaffCode;
  final String? selectedClassroomCode;

  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  final TimeOfDay? breakStartTime;
  final TimeOfDay? breakEndTime;

  final List<String> selectedDays;
  final DateTime? repeatUntilDate;

  final String notes;

  final bool publish;

  final bool isLoading;
  final bool isProfileLoading;
  final bool isSubmitting;

  final List<String> allowedClassroomCodes;
  final List<AllowedClassroom> allowedClassrooms;

  final String? error;

  const AddShiftState({
    this.shiftDate,
    this.selectedStaffCode,
    this.selectedClassroomCode,
    this.startTime,
    this.endTime,
    this.breakStartTime,
    this.breakEndTime,
    this.selectedDays = const [],
    this.repeatUntilDate,
    this.notes = '',
    this.publish = false,
    this.isLoading = false,
    this.isProfileLoading = false,
    this.isSubmitting = false,
    this.allowedClassroomCodes = const [],
    this.allowedClassrooms = const [],
    this.error,
  });

  bool get isRecurring => selectedDays.isNotEmpty;

  AddShiftState copyWith({
    DateTime? shiftDate,
    String? selectedStaffCode,
    String? selectedClassroomCode,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    TimeOfDay? breakStartTime,
    TimeOfDay? breakEndTime,
    List<String>? selectedDays,
    DateTime? repeatUntilDate,
    bool clearRepeatUntilDate = false,
    String? notes,
    bool? publish,
    bool? isLoading,
    bool? isProfileLoading,
    bool? isSubmitting,
    List<String>? allowedClassroomCodes,
    List<AllowedClassroom>? allowedClassrooms,
    String? error,
  }) {
    return AddShiftState(
      shiftDate: shiftDate ?? this.shiftDate,
      selectedStaffCode: selectedStaffCode ?? this.selectedStaffCode,
      selectedClassroomCode:
          selectedClassroomCode ?? this.selectedClassroomCode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      breakEndTime: breakEndTime ?? this.breakEndTime,
      selectedDays: selectedDays ?? this.selectedDays,
      repeatUntilDate: clearRepeatUntilDate
          ? null
          : (repeatUntilDate ?? this.repeatUntilDate),
      notes: notes ?? this.notes,
      publish: publish ?? this.publish,
      isLoading: isLoading ?? this.isLoading,
      isProfileLoading: isProfileLoading ?? this.isProfileLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      allowedClassroomCodes:
          allowedClassroomCodes ?? this.allowedClassroomCodes,
      allowedClassrooms: allowedClassrooms ?? this.allowedClassrooms,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    shiftDate,
    selectedStaffCode,
    selectedClassroomCode,
    startTime,
    endTime,
    breakStartTime,
    breakEndTime,
    selectedDays,
    repeatUntilDate,
    notes,
    publish,
    isLoading,
    isProfileLoading,
    isSubmitting,
    allowedClassroomCodes,
    allowedClassrooms,
    error,
  ];
}
