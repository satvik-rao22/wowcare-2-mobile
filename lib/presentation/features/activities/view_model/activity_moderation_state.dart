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
  const ActivityModerationInProgress({
    required this.action,
    required this.code,
  });

  final ActivityModerationAction action;

  /// The activity being moderated, so the view can reflect the in-flight state
  /// on the specific card.
  final String code;

  @override
  List<Object?> get props => [action, code];
}

final class ActivityModerationSuccess extends ActivityModerationState {
  const ActivityModerationSuccess({
    required this.action,
    required this.code,
    required this.message,
  });

  final ActivityModerationAction action;
  final String code;
  final String message;

  @override
  List<Object?> get props => [action, code, message];
}

final class ActivityModerationFailure extends ActivityModerationState {
  const ActivityModerationFailure({
    required this.action,
    required this.code,
    required this.message,
  });

  final ActivityModerationAction action;
  final String code;
  final String message;

  @override
  List<Object?> get props => [action, code, message];
}
