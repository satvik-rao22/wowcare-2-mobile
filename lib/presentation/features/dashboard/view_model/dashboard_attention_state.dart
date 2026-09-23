part of 'dashboard_attention_cubit.dart';

enum DashboardAttentionStatus {
  initial,
  loading,
  loaded,
  refreshing,
  partialFailure,
  error,

  /// [StorageKeys.schoolCode] wasn't available yet when [load] ran (e.g. the
  /// dashboard mounted before school context finished resolving after
  /// login). Deliberately excluded from [isLoaded] so a later [load] call
  /// isn't short-circuited by the silent-revisit guard and can actually
  /// retry once the school code is available.
  awaitingSchoolContext,
}

class DashboardAttentionState extends Equatable {
  const DashboardAttentionState({
    this.status = DashboardAttentionStatus.initial,
    this.pendingIncidents = 0,
    this.pendingRegularizations = 0,
    this.pendingMovements = 0,
    this.overdueMovements = 0,
    this.expiredDocuments = 0,
    this.expiringDocuments = 0,
    this.expiredStudentDocuments = 0,
    this.expiringStudentDocuments = 0,
    this.overdueCheckups = 0,
    this.missingCheckups = 0,
    this.overdueStudentCheckups = 0,
    this.missingStudentCheckups = 0,
    this.errorMessage,
  });

  final DashboardAttentionStatus status;
  final int pendingIncidents;

  /// Attendance corrections awaiting this admin's approval.
  final int pendingRegularizations;
  final int pendingMovements;
  final int overdueMovements;
  final int expiredDocuments;
  final int expiringDocuments;
  final int expiredStudentDocuments;
  final int expiringStudentDocuments;
  // Staff physical checkups
  final int overdueCheckups;
  final int missingCheckups;
  // Student physical checkups
  final int overdueStudentCheckups;
  final int missingStudentCheckups;
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
    int? pendingRegularizations,
    int? pendingMovements,
    int? overdueMovements,
    int? expiredDocuments,
    int? expiringDocuments,
    int? expiredStudentDocuments,
    int? expiringStudentDocuments,
    int? overdueCheckups,
    int? missingCheckups,
    int? overdueStudentCheckups,
    int? missingStudentCheckups,
    String? errorMessage,
  }) {
    return DashboardAttentionState(
      status: status ?? this.status,
      pendingIncidents: pendingIncidents ?? this.pendingIncidents,
      pendingRegularizations:
          pendingRegularizations ?? this.pendingRegularizations,
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
      overdueStudentCheckups:
          overdueStudentCheckups ?? this.overdueStudentCheckups,
      missingStudentCheckups:
          missingStudentCheckups ?? this.missingStudentCheckups,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    pendingIncidents,
    pendingRegularizations,
    pendingMovements,
    overdueMovements,
    expiredDocuments,
    expiringDocuments,
    expiredStudentDocuments,
    expiringStudentDocuments,
    overdueCheckups,
    missingCheckups,
    overdueStudentCheckups,
    missingStudentCheckups,
    errorMessage,
  ];
}
