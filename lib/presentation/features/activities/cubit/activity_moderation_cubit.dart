import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/util/api_error_handler.dart';
import '../../../../domain/features/activity/usecases/approve_activity_usecase.dart';
import '../../../../domain/features/activity/usecases/delete_activity_usecase.dart';
import '../../../../domain/features/activity/usecases/reject_activity_usecase.dart';

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
  })  : _delete = deleteActivityUseCase,
        _approve = approveActivityUseCase,
        _reject = rejectActivityUseCase,
        super(const ActivityModerationIdle());

  final DeleteActivityUseCase _delete;
  final ApproveActivityUseCase _approve;
  final RejectActivityUseCase _reject;

  Future<void> delete(String code) =>
      _run(ActivityModerationAction.delete, () => _delete(code: code));

  Future<void> approve(String code) =>
      _run(ActivityModerationAction.approve, () => _approve(code: code));

  Future<void> reject(String code) =>
      _run(ActivityModerationAction.reject, () => _reject(code: code));

  Future<void> _run(
    ActivityModerationAction action,
    Future<String> Function() operation,
  ) async {
    emit(ActivityModerationInProgress(action));
    try {
      final message = await operation();
      if (isClosed) return;
      emit(ActivityModerationSuccess(action: action, message: message));
    } catch (e) {
      if (isClosed) return;
      emit(ActivityModerationFailure(
        action: action,
        message: ApiErrorHandler.extractErrorMessage(e),
      ));
    }
  }
}
