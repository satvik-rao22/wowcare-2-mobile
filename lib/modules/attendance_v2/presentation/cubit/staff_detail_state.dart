import 'package:equatable/equatable.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import '../controllers/av2_day_filter.dart';

enum Av2Status { initial, loading, loaded, error }

class StaffDetailState extends Equatable {
  const StaffDetailState({
    required this.status,
    this.profile,
    this.errorMessage,
    this.reloadId = 0,
    this.filter = Av2DayFilter.all,
    this.page = 0,
    this.hasMore = false,
    this.loadingMore = false,
  });

  const StaffDetailState.initial()
      : status = Av2Status.initial,
        profile = null,
        errorMessage = null,
        reloadId = 0,
        filter = Av2DayFilter.all,
        page = 0,
        hasMore = false,
        loadingMore = false;

  final Av2Status status;
  final StaffOvertimeProfile? profile;
  final String? errorMessage;

  /// Active day filter — drives the server's `overtimeOnly` / `absentOnly`.
  final Av2DayFilter filter;

  /// Last loaded page (0-based) and whether another page may exist.
  final int page;
  final bool hasMore;

  /// True while the next page is being fetched (shows a bottom spinner).
  final bool loadingMore;

  /// Bumped on every successful (re)load — including after edit/delete — so
  /// expanded day rows know to re-fetch their (now stale) session detail.
  final int reloadId;

  bool get isLoading => status == Av2Status.loading;
  bool get isLoaded => status == Av2Status.loaded && profile != null;
  bool get isError => status == Av2Status.error;

  StaffDetailState copyWith({
    Av2Status? status,
    StaffOvertimeProfile? profile,
    String? errorMessage,
    int? reloadId,
    Av2DayFilter? filter,
    int? page,
    bool? hasMore,
    bool? loadingMore,
  }) {
    return StaffDetailState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      reloadId: reloadId ?? this.reloadId,
      filter: filter ?? this.filter,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        errorMessage,
        reloadId,
        filter,
        page,
        hasMore,
        loadingMore,
      ];
}
