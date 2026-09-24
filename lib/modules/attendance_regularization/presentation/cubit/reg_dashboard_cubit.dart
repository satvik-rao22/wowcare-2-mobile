import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/missed_signout.dart';
import '../../domain/entities/regularization_request.dart';
import '../../domain/usecases/get_requests_usecase.dart';
import '../gate/reg_gate_coordinator.dart';

/// State behind the dashboard entry point.
class RegDashboardState extends Equatable {
  const RegDashboardState({
    this.loading = false,
    this.openSession,
    this.pendingCount = 0,
    this.autoSheetShown = false,
  });

  final bool loading;

  /// The staff's unresolved day, if any.
  final MissedSignout? openSession;

  /// Pending requests awaiting this admin. Hidden at zero.
  final int pendingCount;

  /// Whether the mandatory sheet has already auto-opened this session, so a
  /// rebuild or tab switch does not re-fire it.
  final bool autoSheetShown;

  bool get hasOpenSession => openSession != null;

  /// The unresolved day still blocks sign-in — nothing has been raised yet.
  bool get needsAction => openSession?.blocksSignIn ?? false;

  /// Raised, waiting on an admin. The day is still uncounted (§8.1), so the
  /// banner stays — but as "awaiting approval", not a call to action.
  bool get awaitingApproval =>
      openSession != null && !openSession!.blocksSignIn;

  bool get hasPendingForAdmin => pendingCount > 0;

  RegDashboardState copyWith({
    bool? loading,
    MissedSignout? openSession,
    bool clearOpenSession = false,
    int? pendingCount,
    bool? autoSheetShown,
  }) {
    return RegDashboardState(
      loading: loading ?? this.loading,
      openSession: clearOpenSession ? null : (openSession ?? this.openSession),
      pendingCount: pendingCount ?? this.pendingCount,
      autoSheetShown: autoSheetShown ?? this.autoSheetShown,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    openSession?.attendanceCode,
    openSession?.hasPendingRequest,
    pendingCount,
    autoSheetShown,
  ];
}

/// Feeds the dashboard entry point for both personas.
///
/// One cubit rather than two because the entry widget is itself role-aware:
/// a staff dashboard never reads [RegDashboardState.pendingCount] and an
/// admin-only dashboard never reads [RegDashboardState.openSession]. Two
/// cubits would mean two providers and two lifecycles for one card.
class RegDashboardCubit extends Cubit<RegDashboardState> {
  RegDashboardCubit({
    required RegGateCoordinator gate,
    required GetRequestsUseCase getRequests,
  }) : _gate = gate,
       _getRequests = getRequests,
       super(const RegDashboardState());

  final RegGateCoordinator _gate;
  final GetRequestsUseCase _getRequests;

  /// [forAdmin] also loads the approval count. Both reads are best-effort:
  /// a dashboard card must never break the dashboard.
  Future<void> load({required bool forAdmin}) async {
    emit(state.copyWith(loading: true));

    final sessionFuture = _gate.peek();
    final countFuture = forAdmin ? _pendingCount() : Future.value(0);

    final session = await sessionFuture;
    final count = await countFuture;

    emit(
      state.copyWith(
        loading: false,
        openSession: session,
        clearOpenSession: session == null,
        pendingCount: count,
      ),
    );
  }

  /// Reads the count from `totalElements` on a one-item page rather than
  /// pulling the whole queue — the badge only needs the number.
  Future<int> _pendingCount() async {
    try {
      final page = await _getRequests(
        status: RegStatus.pending,
        page: 0,
        size: 1,
      );
      return page.total;
    } catch (_) {
      return 0;
    }
  }

  /// Opens the resolve sheet for the unresolved day and reloads on success.
  Future<void> resolve({bool markAuto = false}) async {
    final session = state.openSession;
    if (session == null) return;
    if (markAuto) emit(state.copyWith(autoSheetShown: true));

    final outcome = await _gate.resolve(
      session,
      byAdmin: false,
      mandatory: false,
    );
    if (outcome.isProceed) await load(forAdmin: state.pendingCount > 0);
  }

  /// Marks the auto-open as spent without opening anything — used when the
  /// day is already raised, so no sheet is due.
  void markAutoSheetShown() {
    if (state.autoSheetShown) return;
    emit(state.copyWith(autoSheetShown: true));
  }
}
