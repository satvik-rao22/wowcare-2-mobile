part of 'publish_shifts_cubit.dart';

enum PublishShiftsStatus { idle, submitting, success, error }

class PublishShiftsState extends Equatable {
  const PublishShiftsState({
    this.status = PublishShiftsStatus.idle,
    this.errorMessage,
  });

  final PublishShiftsStatus status;
  final String? errorMessage;

  bool get isSubmitting => status == PublishShiftsStatus.submitting;

  PublishShiftsState copyWith({
    PublishShiftsStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PublishShiftsState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
