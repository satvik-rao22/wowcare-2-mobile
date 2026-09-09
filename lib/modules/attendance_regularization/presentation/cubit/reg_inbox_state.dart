import 'package:equatable/equatable.dart';

import '../../domain/entities/regularization_request.dart';
import '../controllers/reg_inbox_filter.dart';
import 'reg_my_requests_state.dart' show RegListStatus;

/// State of the admin's regularization list.
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

  final String message;

  bool get isLoading => status == RegListStatus.loading;
  bool get isError => status == RegListStatus.error;
  bool get isEmpty => status == RegListStatus.loaded && requests.isEmpty;

  /// The rows that can actually be selected.
  ///
  /// The list may mix statuses on the Approved / All tabs, so "select all" and
  /// the header count must both work off this rather than the whole page —
  /// otherwise an admin could tick an already-approved row.
  List<RegularizationRequest> get selectableRequests =>
      filter.supportsSelection
          ? requests.where((r) => r.status.isPending).toList(growable: false)
          : const [];

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
        message,
      ];
}
