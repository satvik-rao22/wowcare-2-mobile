import 'dart:async';

/// Singleton broadcast stream that decouples messaging cubits from each other.
///
/// Events:
///   [onConversationMarkedRead]   — thread opened; badge should zero locally.
///   [onConversationListChanged]  — conversation was created/deleted; list
///                                  should refresh. Carries the conversation
///                                  type string (e.g. 'STAFF_DIRECT').
class MessagingEventService {
  MessagingEventService._();

  static final MessagingEventService instance = MessagingEventService._();

  // ── Mark-read ─────────────────────────────────────────────────────────────

  final StreamController<String> _markedReadController =
      StreamController<String>.broadcast();

  Stream<String> get onConversationMarkedRead =>
      _markedReadController.stream;

  void notifyMarkedRead(String conversationCode) {
    if (!_markedReadController.isClosed) {
      _markedReadController.add(conversationCode);
    }
  }

  // ── Conversation list changed ─────────────────────────────────────────────

  /// Emitted after a conversation is created or removed in the background.
  /// Value is the conversation type string, e.g. 'STAFF_DIRECT', 'ROOM_CHAT'.
  /// Subscribers (e.g. [StaffMessagingTab]) should refresh their list.
  final StreamController<String> _conversationListChangedController =
      StreamController<String>.broadcast();

  Stream<String> get onConversationListChanged =>
      _conversationListChangedController.stream;

  /// Call this after a background bulk-send job finishes creating conversations.
  void notifyConversationListChanged(String conversationType) {
    if (!_conversationListChangedController.isClosed) {
      _conversationListChangedController.add(conversationType);
    }
  }

  void dispose() {
    _markedReadController.close();
    _conversationListChangedController.close();
  }
}
