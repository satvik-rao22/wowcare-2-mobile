import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'dashboard_overall_state.dart';

/// Aggregates loading states from all child dashboard cubits.
/// Provides a single point to check if the entire dashboard is loaded.
class DashboardOverallCubit extends Cubit<DashboardOverallState> {
  DashboardOverallCubit() : super(const DashboardOverallState.initial());

  /// Updates the loading state for a specific child cubit.
  /// [cubitType] should be the runtime type name (e.g., 'MyChildsDayCubit')
  void updateChildCubitState(String cubitType, bool isLoading) {
    final updated = Map<String, bool>.from(state.childCubitStates);
    updated[cubitType] = isLoading;

    // Determine overall status based on child states
    final hasError = updated.values.any((loading) => loading);
    final status = hasError
        ? DashboardOverallStatus.loading
        : DashboardOverallStatus.loaded;

    emit(state.copyWith(
      status: status,
      childCubitStates: updated,
    ));
  }

  /// Marks the entire dashboard as loading.
  void setLoading() {
    emit(state.copyWith(status: DashboardOverallStatus.loading));
  }

  /// Marks the entire dashboard as loaded.
  void setLoaded() {
    emit(state.copyWith(
      status: DashboardOverallStatus.loaded,
      errorMessage: null,
    ));
  }

  /// Marks the entire dashboard as refreshing (silent refresh).
  void setRefreshing() {
    emit(state.copyWith(status: DashboardOverallStatus.refreshing));
  }

  /// Sets an error state for the dashboard.
  void setError(String message) {
    emit(state.copyWith(
      status: DashboardOverallStatus.error,
      errorMessage: message,
    ));
  }

  /// Resets to initial state.
  void reset() {
    emit(const DashboardOverallState.initial());
  }
}
