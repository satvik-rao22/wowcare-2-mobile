import 'package:bloc/bloc.dart';
import 'package:wowcare/domain/features/communication/usecases/get_unread_aggregates_usecase.dart';
import 'unread_badge_state.dart';

/// Manages the aggregate unread counts used for navigation drawer badges.
///
/// Counts are keyed by [ConversationType.toApiString()] so the state is
/// role-agnostic — the UI reads [UnreadBadgeState.totalForRole] or the
/// per-type helpers to show the right badge for the active user.
class UnreadBadgeCubit extends Cubit<UnreadBadgeState> {
  UnreadBadgeCubit({
    required GetUnreadAggregatesUseCase getUnreadAggregatesUseCase,
  })  : _getUnreadAggregatesUseCase = getUnreadAggregatesUseCase,
        super(const UnreadBadgeState.initial());

  final GetUnreadAggregatesUseCase _getUnreadAggregatesUseCase;

  int _refreshRequestId = 0;

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Load unread counts on initial screen entry or app resume.
  Future<void> loadUnreadCounts() async {
    if (state.isLoading || state.isRefreshing) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetch();
  }

  /// Explicit pull-to-refresh or post-message-send refresh.
  Future<void> refreshUnreadCounts() async {
    final int requestId = ++_refreshRequestId;
    emit(state.copyWith(isRefreshing: true, clearError: true));
    await _fetchWithId(requestId);
  }

  /// Decrement the count for a specific conversation type after the user reads
  /// a conversation. Clamped to zero — no negative badges.
  void decrementFor(String conversationTypeApiString, {int by = 1}) {
    final updated = Map<String, int>.from(state.countsByType);
    final current = updated[conversationTypeApiString] ?? 0;
    updated[conversationTypeApiString] = (current - by).clamp(0, 999999);
    emit(state.copyWith(countsByType: updated));
  }

  /// Zero out the count for one conversation type (e.g. after marking all read).
  void clearFor(String conversationTypeApiString) {
    final updated = Map<String, int>.from(state.countsByType);
    updated[conversationTypeApiString] = 0;
    emit(state.copyWith(countsByType: updated));
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _fetch() async {
    final requestId = _refreshRequestId;
    await _fetchWithId(requestId);
  }

  Future<void> _fetchWithId(int requestId) async {
    final result = await _getUnreadAggregatesUseCase();

    if (isClosed || requestId != _refreshRequestId) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          isRefreshing: false,
          errorMessage: failure.message ?? 'Failed to load unread counts.',
        ),
      ),
      (counts) => emit(
        UnreadBadgeState(
          countsByType: counts,
          isLoading: false,
          isRefreshing: false,
        ),
      ),
    );
  }
}
