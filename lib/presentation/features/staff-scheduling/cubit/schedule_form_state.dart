abstract class ScheduleFormState {}

class ScheduleFormInitial extends ScheduleFormState {}

class ScheduleFormSubmitting extends ScheduleFormState {}

class ScheduleFormSuccess extends ScheduleFormState {}

class ScheduleFormError extends ScheduleFormState {
  final String message;
  ScheduleFormError(this.message);
}
