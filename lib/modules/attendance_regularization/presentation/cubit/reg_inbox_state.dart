import 'package:equatable/equatable.dart';

import '../../domain/entities/regularization_request.dart';
import '../controllers/reg_inbox_filter.dart';

enum RegListStatus { initial, loading, loaded, error }

/// State of a regularization list — the admin inbox, or one staff member's
/// requests on their attendance profile.
class RegInboxState extends Equatable {
  const RegInboxState({
    this.status = RegListStatus.initial,
    this.filter = RegInboxFilter.pending,
    this.requests = const [],
    this.selected = const {},
    this.hasMore = false,
    this.page = 0,
    this.loadingMore = false,
    this.busy = false,
    this.busyCode,
    this.currentUserCode = '',
    this.message = '',
  });

  final RegListStatus status;
  final RegInboxFilter filter;
  final List<RegularizationRequest> requests;

  /// Codes ticked for bulk approve. Only pending rows can be here — the
  /// history tabs are read-only (§9.7 approves the chosen set as submitted).
  final Set<String> selected;

  final bool hasMore;
  final int page;
  final bool loadingMore;

  /// An approve or bulk-approve is in flight.
  final bool busy;

  /// The row whose edit is in flight, so only that card shows a spinner.
  final String? busyCode;

  /// Signed-in user. Only the raiser may edit, so rows compare against this.
  final String currentUserCode;

  final String message;

  bool get isLoading => status == RegListStatus.loading;
  bool get isError => status == RegListStatus.error;
  bool get isEmpty => status == RegListStatus.loaded && requests.isEmpty;

  /// The rows that can actually be selected.
  ///
  /// Selectability is a property of the **row**, not the tab: the All tab
  /// mixes statuses, and a pending row there is as approvable as one in the
  /// queue. "Select all" and the header count work off this so an
  /// already-approved row can never be ticked.
  List<RegularizationRequest> get selectableRequests =>
      requests.where((r) => r.status.isPending).toList(growable: false);

  int get pendingCount => selectableRequests.length;

  bool get allSelected =>
      selectableRequests.isNotEmpty &&
      selected.length == selectableRequests.length;

  bool get hasSelection => selected.isNotEmpty;

  RegInboxState copyWith({
    RegListStatus? status,
    RegInboxFilter? filter,
    List<RegularizationRequest>? requests,
    Set<String>? selected,
    bool? hasMore,
    int? page,
    bool? loadingMore,
    bool? busy,
    String? busyCode,
    bool clearBusyCode = false,
    String? currentUserCode,
    String? message,
  }) {
    return RegInboxState(
      status: status ?? this.status,
      filter: filter ?? this.filter,
      requests: requests ?? this.requests,
      selected: selected ?? this.selected,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      loadingMore: loadingMore ?? this.loadingMore,
      busy: busy ?? this.busy,
      busyCode: clearBusyCode ? null : (busyCode ?? this.busyCode),
      currentUserCode: currentUserCode ?? this.currentUserCode,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        filter,
        requests,
        selected,
        hasMore,
        page,
        loadingMore,
        busy,
        busyCode,
        currentUserCode,
        message,
      ];
}
