import 'dart:async';

/// Singleton broadcast stream that decouples [ConversationThreadCubit] from
/// [ConversationListCubit].
///
/// When a thread is opened and [markConversationRead] succeeds,
/// [ConversationThreadCubit] publishes the conversation code here.
/// [ConversationListCubit] subscribes and immediately zeroes the badge in
/// its local state — without waiting for the Firestore round-trip (~1-3 s).
class MessagingEventService {
  MessagingEventService._();

  static final MessagingEventService instance = MessagingEventService._();

  final StreamController<String> _markedReadController =
      StreamController<String>.broadcast();

  /// Stream of conversation codes that have just been marked as read.
  Stream<String> get onConversationMarkedRead =>
      _markedReadController.stream;

  /// Notify listeners that [conversationCode] was marked read.
  void notifyMarkedRead(String conversationCode) {
    if (!_markedReadController.isClosed) {
      _markedReadController.add(conversationCode);
    }
  }

  void dispose() => _markedReadController.close();
}
