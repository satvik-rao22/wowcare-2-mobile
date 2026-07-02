import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/get_unread_aggregates_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_unread_count_for_type_usecase.dart';
import 'unread_badge_state.dart';

/// Manages aggregate unread counts for navigation badges (drawer + bottom nav).
///
/// Uses [WatchUnreadCountForTypeUseCase] which reads directly from Firestore
/// without the Isar merge pipeline — so it never duplicates or races with
/// [ConversationListCubit]'s stream.
class UnreadBadgeCubit extends Cubit<UnreadBadgeState> {
  UnreadBadgeCubit({
    required WatchUnreadCountForTypeUseCase watchUnreadCountForTypeUseCase,
    required GetUnreadAggregatesUseCase getUnreadAggregatesUseCase,
  })  : _watchUnreadCountForTypeUseCase = watchUnreadCountForTypeUseCase,
        _getUnreadAggregatesUseCase = getUnreadAggregatesUseCase,
        super(const UnreadBadgeState.initial());

  final WatchUnreadCountForTypeUseCase _watchUnreadCountForTypeUseCase;
  final GetUnreadAggregatesUseCase _getUnreadAggregatesUseCase;

  final Map<String, StreamSubscription<int>> _subscriptions = {};
  final Map<String, int> _counts = {};

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Start one lightweight Firestore stream per conversation type.
  void startWatching() {
    for (final type in ConversationType.values) {
      _subscribeToType(type);
    }
  }

  /// Fallback: load counts once from REST API.
  Future<void> loadUnreadCounts() async {
    if (state.isLoading || state.isRefreshing) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetchFromApi();
  }

  // ─── Private ─────────────────────────────────────────────────────────────────

  void _subscribeToType(ConversationType type) {
    final key = type.toApiString();
    _subscriptions[key]?.cancel();

    _subscriptions[key] = _watchUnreadCountForTypeUseCase(type).listen(
      (count) {
        if (isClosed) return;
        _counts[key] = count;
        _emit();
      },
      onError: (_) => unawaited(_fetchFromApi()),
    );
  }

  void _emit() {
    if (!isClosed) {
      emit(UnreadBadgeState(
        countsByType: Map.unmodifiable(_counts),
        isLoading: false,
        isRefreshing: false,
      ));
    }
  }

  Future<void> _fetchFromApi() async {
    final result = await _getUnreadAggregatesUseCase();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: failure.message ?? 'Failed to load unread counts.',
      )),
      (counts) {
        _counts.addAll(counts);
        _emit();
      },
    );
  }
}
