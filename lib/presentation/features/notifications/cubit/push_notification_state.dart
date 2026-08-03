part of 'push_notification_cubit.dart';

class PushNotificationState extends Equatable {
  const PushNotificationState({
    required this.token,
    required this.navigationRequest,
    this.newMessageEventSeq = 0,
    this.incomingConversationCode,
  });

  const PushNotificationState.initial()
      : token = null,
        navigationRequest = null,
        newMessageEventSeq = 0,
        incomingConversationCode = null;

  /// The current device FCM token, once resolved.
  final String? token;

  /// A tapped notification awaiting navigation by the View. Null when none is
  /// pending; cleared via [clearNavigationRequest] after the View handles it.
  final PushNotification? navigationRequest;

  /// Increments each time a NEW_MESSAGE FCM arrives in the foreground.
  /// Used as an Equatable-safe event signal so BlocListeners always fire
  /// even when the conversation code is the same as the previous event.
  final int newMessageEventSeq;

  /// The conversationCode from the most recent NEW_MESSAGE FCM payload.
  final String? incomingConversationCode;

  PushNotificationState copyWith({
    String? token,
    PushNotification? navigationRequest,
    int? newMessageEventSeq,
    String? incomingConversationCode,
  }) {
    return PushNotificationState(
      token: token ?? this.token,
      navigationRequest: navigationRequest ?? this.navigationRequest,
      newMessageEventSeq: newMessageEventSeq ?? this.newMessageEventSeq,
      incomingConversationCode:
          incomingConversationCode ?? this.incomingConversationCode,
    );
  }

  PushNotificationState clearNavigationRequest() {
    return PushNotificationState(
      token: token,
      navigationRequest: null,
      newMessageEventSeq: newMessageEventSeq,
      incomingConversationCode: incomingConversationCode,
    );
  }

  @override
  List<Object?> get props => [
        token,
        navigationRequest,
        newMessageEventSeq,
        incomingConversationCode,
      ];
}
