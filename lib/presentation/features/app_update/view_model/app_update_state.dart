part of 'app_update_cubit.dart';

class AppUpdateState extends Equatable {
  const AppUpdateState({
    this.status,
    this.optionalDismissed = false,
    this.storeUnavailable = false,
  });

  /// The latest check. Null until the first one completes, which reads as
  /// "nothing to show".
  final AppUpdateStatus? status;

  /// "Not now" was tapped this session. Hides the banner at once, before the
  /// week-long dismissal is written, and keeps it hidden even if that write
  /// fails.
  final bool optionalDismissed;

  /// The store key was tapped and nothing opened.
  final bool storeUnavailable;

  bool get showsRequired => status?.isRequired ?? false;

  bool get showsOptional => (status?.isOptional ?? false) && !optionalDismissed;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    bool? optionalDismissed,
    bool? storeUnavailable,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      optionalDismissed: optionalDismissed ?? this.optionalDismissed,
      storeUnavailable: storeUnavailable ?? this.storeUnavailable,
    );
  }

  @override
  List<Object?> get props => [status, optionalDismissed, storeUnavailable];
}
