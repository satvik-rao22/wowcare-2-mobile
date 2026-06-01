part of 'dashboard_attention_cubit.dart';

enum DashboardAttentionStatus {
  initial,
  loading,
  loaded,
  refreshing,
  partialFailure,
  error,
}

class DashboardAttentionState extends Equatable {
  const DashboardAttentionState({
    this.status = DashboardAttentionStatus.initial,
    this.pendingIncidents = 0,
    this.pendingMovements = 0,
    this.overdueMovements = 0,
    this.expiredDocuments = 0,
    this.expiringDocuments = 0,
    this.expiredStudentDocuments = 0,
    this.expiringStudentDocuments = 0,
    this.overdueCheckups = 0,
    this.missingCheckups = 0,
    this.errorMessage,
  });

  final DashboardAttentionStatus status;
  final int pendingIncidents;
  final int pendingMovements;
  final int overdueMovements;
  final int expiredDocuments;
  final int expiringDocuments;
  final int expiredStudentDocuments;
  final int expiringStudentDocuments;
  final int overdueCheckups;
  final int missingCheckups;
  final String? errorMessage;

  bool get isInitial => status == DashboardAttentionStatus.initial;
  bool get isLoading => status == DashboardAttentionStatus.loading;
  bool get isLoaded =>
      status == DashboardAttentionStatus.loaded ||
      status == DashboardAttentionStatus.partialFailure;
  bool get isRefreshing => status == DashboardAttentionStatus.refreshing;

  DashboardAttentionState copyWith({
    DashboardAttentionStatus? status,
    int? pendingIncidents,
    int? pendingMovements,
    int? overdueMovements,
    int? expiredDocuments,
    int? expiringDocuments,
    int? expiredStudentDocuments,
    int? expiringStudentDocuments,
    int? overdueCheckups,
    int? missingCheckups,
    String? errorMessage,
  }) {
    return DashboardAttentionState(
      status: status ?? this.status,
      pendingIncidents: pendingIncidents ?? this.pendingIncidents,
      pendingMovements: pendingMovements ?? this.pendingMovements,
      overdueMovements: overdueMovements ?? this.overdueMovements,
      expiredDocuments: expiredDocuments ?? this.expiredDocuments,
      expiringDocuments: expiringDocuments ?? this.expiringDocuments,
      expiredStudentDocuments:
          expiredStudentDocuments ?? this.expiredStudentDocuments,
      expiringStudentDocuments:
          expiringStudentDocuments ?? this.expiringStudentDocuments,
      overdueCheckups: overdueCheckups ?? this.overdueCheckups,
      missingCheckups: missingCheckups ?? this.missingCheckups,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pendingIncidents,
    pendingMovements,
    overdueMovements,
    expiredDocuments,
    expiringDocuments,
    expiredStudentDocuments,
    expiringStudentDocuments,
    overdueCheckups,
    missingCheckups,
    errorMessage,
  ];
}
