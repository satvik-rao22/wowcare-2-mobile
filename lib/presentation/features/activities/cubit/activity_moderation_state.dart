part of 'activity_moderation_cubit.dart';

sealed class ActivityModerationState extends Equatable {
  const ActivityModerationState();

  @override
  List<Object?> get props => [];
}

final class ActivityModerationIdle extends ActivityModerationState {
  const ActivityModerationIdle();
}

final class ActivityModerationInProgress extends ActivityModerationState {
  const ActivityModerationInProgress(this.action);

  final ActivityModerationAction action;

  @override
  List<Object?> get props => [action];
}

final class ActivityModerationSuccess extends ActivityModerationState {
  const ActivityModerationSuccess({
    required this.action,
    required this.message,
  });

  final ActivityModerationAction action;
  final String message;

  @override
  List<Object?> get props => [action, message];
}

final class ActivityModerationFailure extends ActivityModerationState {
  const ActivityModerationFailure({
    required this.action,
    required this.message,
  });

  final ActivityModerationAction action;
  final String message;

  @override
  List<Object?> get props => [action, message];
}
