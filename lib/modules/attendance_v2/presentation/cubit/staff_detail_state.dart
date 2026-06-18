import 'package:equatable/equatable.dart';
import '../../domain/entities/staff_overtime_profile.dart';

enum Av2Status { initial, loading, loaded, error }

class StaffDetailState extends Equatable {
  const StaffDetailState({
    required this.status,
    this.profile,
    this.errorMessage,
  });

  const StaffDetailState.initial()
      : status = Av2Status.initial,
        profile = null,
        errorMessage = null;

  final Av2Status status;
  final StaffOvertimeProfile? profile;
  final String? errorMessage;

  bool get isLoading => status == Av2Status.loading;
  bool get isLoaded => status == Av2Status.loaded && profile != null;
  bool get isError => status == Av2Status.error;

  StaffDetailState copyWith({
    Av2Status? status,
    StaffOvertimeProfile? profile,
    String? errorMessage,
  }) {
    return StaffDetailState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, profile, errorMessage];
}
