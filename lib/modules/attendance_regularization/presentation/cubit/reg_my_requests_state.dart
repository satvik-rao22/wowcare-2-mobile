import 'package:equatable/equatable.dart';

import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/regularization_request.dart';

enum RegListStatus { initial, loading, loaded, error }

/// State of the staff's "My regularizations" screen.
class RegMyRequestsState extends Equatable {
  const RegMyRequestsState({
    this.status = RegListStatus.initial,
    this.requests = const [],
    this.gate,
    this.hasMore = false,
    this.page = 0,
    this.loadingMore = false,
    this.busyCode,
    this.message = '',
  });

  final RegListStatus status;
  final List<RegularizationRequest> requests;

  /// The unresolved day, if any — drives the needs-attention banner. Present
  /// whether or not a request has been raised: once raised it flips to
  /// "awaiting approval", because the day is still uncounted (§8.1).
  final MissedSignout? gate;

  final bool hasMore;
  final int page;

  /// A second page is in flight — keeps the list visible while it loads.
  final bool loadingMore;

  /// The row currently being edited, so only that tile shows a spinner.
  final String? busyCode;

  /// Error text, or the last action's confirmation.
  final String message;

  bool get isLoading => status == RegListStatus.loading;
  bool get isError => status == RegListStatus.error;
  bool get isEmpty => status == RegListStatus.loaded && requests.isEmpty;

  RegMyRequestsState copyWith({
    RegListStatus? status,
    List<RegularizationRequest>? requests,
    MissedSignout? gate,
    bool clearGate = false,
    bool? hasMore,
    int? page,
    bool? loadingMore,
    String? busyCode,
    bool clearBusy = false,
    String? message,
  }) {
    return RegMyRequestsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      gate: clearGate ? null : (gate ?? this.gate),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      loadingMore: loadingMore ?? this.loadingMore,
      busyCode: clearBusy ? null : (busyCode ?? this.busyCode),
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        requests,
        gate?.attendanceCode,
        gate?.hasPendingRequest,
        hasMore,
        page,
        loadingMore,
        busyCode,
        message,
      ];
}
