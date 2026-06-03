import 'package:equatable/equatable.dart';

enum DashboardStatus {
  initial,
  loading,
  ready,
  refreshing,
  partialError,
  failure,
}

class DashboardState extends Equatable {
  final DashboardStatus status;
  final String? errorMessage;

  const DashboardState({
    required this.status,
    this.errorMessage,
  });

  bool get isInitial => status == DashboardStatus.initial;
  bool get isLoading => status == DashboardStatus.loading;
  bool get isReady => status == DashboardStatus.ready;
  bool get isRefreshing => status == DashboardStatus.refreshing;
  bool get isPartialError => status == DashboardStatus.partialError;
  bool get isFailure => status == DashboardStatus.failure;

  DashboardState copyWith({
    DashboardStatus? status,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
