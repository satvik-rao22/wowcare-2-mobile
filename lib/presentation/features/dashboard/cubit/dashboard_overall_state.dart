part of 'dashboard_overall_cubit.dart';

enum DashboardOverallStatus {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

class DashboardOverallState extends Equatable {
  const DashboardOverallState({
    this.status = DashboardOverallStatus.initial,
    this.errorMessage,
    this.childCubitStates = const {},
  });

  const DashboardOverallState.initial()
      : status = DashboardOverallStatus.initial,
        errorMessage = null,
        childCubitStates = const {};

  final DashboardOverallStatus status;
  final String? errorMessage;

  /// Maps cubit runtimeType to its loading state.
  /// Used to aggregate loading states from all child cubits.
  final Map<String, bool> childCubitStates;

  bool get isLoading => status == DashboardOverallStatus.loading;
  bool get isRefreshing => status == DashboardOverallStatus.refreshing;
  bool get isLoaded => status == DashboardOverallStatus.loaded;
  bool get isError => status == DashboardOverallStatus.error;

  /// Returns true if ANY child cubit is still loading.
  bool get anyChildLoading => childCubitStates.values.any((isLoading) => isLoading);

  DashboardOverallState copyWith({
    DashboardOverallStatus? status,
    String? errorMessage,
    Map<String, bool>? childCubitStates,
  }) {
    return DashboardOverallState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      childCubitStates: childCubitStates ?? this.childCubitStates,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, childCubitStates];
}
