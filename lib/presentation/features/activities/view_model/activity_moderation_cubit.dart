import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/domain/features/activity/usecases/approve_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/delete_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/reject_activity_usecase.dart';

part 'activity_moderation_state.dart';

/// Which moderation action a result corresponds to (so the view can decide
/// whether to refresh the feed, etc.).
enum ActivityModerationAction { delete, approve, reject }

/// Owns the activity moderation operations (delete / approve / reject) so the
/// daily-feed view stays display-only: it dispatches an action and reacts to
/// the emitted success/failure state via a BlocListener.
class ActivityModerationCubit extends Cubit<ActivityModerationState> {
  ActivityModerationCubit({
    required DeleteActivityUseCase deleteActivityUseCase,
    required ApproveActivityUseCase approveActivityUseCase,
    required RejectActivityUseCase rejectActivityUseCase,
  }) : _delete = deleteActivityUseCase,
       _approve = approveActivityUseCase,
       _reject = rejectActivityUseCase,
       super(const ActivityModerationIdle());

  final DeleteActivityUseCase _delete;
  final ApproveActivityUseCase _approve;
  final RejectActivityUseCase _reject;

  /// Activity codes with a moderation mutation in flight. Keyed by activity so
  /// a double-tap — or a racing approve+reject on the SAME card — cannot fire a
  /// second mutation; a different activity can still be moderated concurrently.
  final Set<String> _inFlight = <String>{};

  Future<void> delete(String code) =>
      _run(code, ActivityModerationAction.delete, () => _delete(code: code));

  Future<void> approve(String code) =>
      _run(code, ActivityModerationAction.approve, () => _approve(code: code));

  Future<void> reject(String code) =>
      _run(code, ActivityModerationAction.reject, () => _reject(code: code));

  Future<void> _run(
    String code,
    ActivityModerationAction action,
    Future<String> Function() operation,
  ) async {
    final key = code.trim();
    if (key.isNotEmpty && _inFlight.contains(key)) {
      // A mutation for this activity is already running — drop the duplicate.
      return;
    }
    if (key.isNotEmpty) _inFlight.add(key);
    emit(ActivityModerationInProgress(action: action, code: key));
    try {
      final message = await operation();
      if (isClosed) return;
      emit(
        ActivityModerationSuccess(action: action, code: key, message: message),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        ActivityModerationFailure(
          action: action,
          code: key,
          message: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    } finally {
      _inFlight.remove(key);
    }
  }
}
