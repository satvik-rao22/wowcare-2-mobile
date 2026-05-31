part of 'push_notification_cubit.dart';

class PushNotificationState extends Equatable {
  const PushNotificationState({
    required this.token,
    required this.navigationRequest,
  });

  const PushNotificationState.initial()
      : token = null,
        navigationRequest = null;

  /// The current device FCM token, once resolved.
  final String? token;

  /// A tapped notification awaiting navigation by the View. Null when none is
  /// pending; cleared via [clearNavigationRequest] after the View handles it.
  final PushNotification? navigationRequest;

  PushNotificationState copyWith({
    String? token,
    PushNotification? navigationRequest,
  }) {
    return PushNotificationState(
      token: token ?? this.token,
      navigationRequest: navigationRequest ?? this.navigationRequest,
    );
  }

  PushNotificationState clearNavigationRequest() {
    return PushNotificationState(token: token, navigationRequest: null);
  }

  @override
  List<Object?> get props => [token, navigationRequest];
}
