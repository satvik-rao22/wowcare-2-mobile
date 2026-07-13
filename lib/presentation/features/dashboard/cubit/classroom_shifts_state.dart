part of 'classroom_shifts_cubit.dart';

enum ClassroomShiftsStatus { initial, loading, loaded, error }

class ClassroomShiftsState extends Equatable {
  const ClassroomShiftsState({
    required this.status,
    required this.date,
    required this.entries,
    this.errorMessage,
  });

  const ClassroomShiftsState.initial()
    : status = ClassroomShiftsStatus.initial,
      date = null,
      entries = const [],
      errorMessage = null;

  final ClassroomShiftsStatus status;
  final DateTime? date;
  final List<ClassroomShiftEntry> entries;
  final String? errorMessage;

  bool get isLoading => status == ClassroomShiftsStatus.loading;
  bool get isLoaded => status == ClassroomShiftsStatus.loaded;
  bool get isError => status == ClassroomShiftsStatus.error;

  ClassroomShiftsState copyWith({
    ClassroomShiftsStatus? status,
    DateTime? date,
    List<ClassroomShiftEntry>? entries,
    String? errorMessage,
  }) {
    return ClassroomShiftsState(
      status: status ?? this.status,
      date: date ?? this.date,
      entries: entries ?? this.entries,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, date, entries, errorMessage];
}
