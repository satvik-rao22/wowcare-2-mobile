import 'package:wowcare/core/util/logger_service.dart';

/// Structured observability sink for the messaging feature.
///
/// Wraps [AppLogger] (this app's existing debug-console logger) with a
/// consistent `[MESSAGING]` event shape so lifecycle, sync, and realtime
/// behaviour can be reasoned about from logs alone. Purely a side effect —
/// nothing here ever influences control flow, return values, or state.
class MessagingLogger {
  MessagingLogger._();

  /// Log a messaging event.
  ///
  /// [event] should be one of the constants below (or any short
  /// SCREAMING_SNAKE_CASE identifier). [duration] is in milliseconds.
  /// [metadata] is freeform context (conversationType, conversationCode,
  /// page counts, retry attempt, etc).
  static void log({
    required String event,
    int? duration,
    Map<String, dynamic>? metadata,
  }) {
    final buffer = StringBuffer('[MESSAGING] $event');
    if (duration != null) buffer.write(' (${duration}ms)');
    if (metadata != null && metadata.isNotEmpty) {
      buffer.write(' $metadata');
    }
    AppLogger.i(buffer.toString());
  }

  /// Same as [log] but routed to the warning/error channel — use for retry
  /// exhaustion, unexpected exceptions, or degraded-mode fallbacks.
  static void warn({
    required String event,
    Map<String, dynamic>? metadata,
    Object? error,
  }) {
    final buffer = StringBuffer('[MESSAGING] $event');
    if (metadata != null && metadata.isNotEmpty) buffer.write(' $metadata');
    if (error != null) buffer.write(' error=$error');
    AppLogger.w(buffer.toString());
  }
}

/// Event name constants — avoids typo drift across call sites.
abstract class MessagingEvent {
  static const String threadOpened = 'THREAD_OPENED';
  static const String threadClosed = 'THREAD_CLOSED';
  static const String threadLoaded = 'THREAD_LOADED';
  static const String conversationLoaded = 'CONVERSATION_LOADED';
  static const String messageSent = 'MESSAGE_SENT';
  static const String messageReceived = 'MESSAGE_RECEIVED';
  static const String firestoreConnected = 'FIRESTORE_CONNECTED';
  static const String firestoreDisconnected = 'FIRESTORE_DISCONNECTED';
  static const String firestoreRetry = 'FIRESTORE_RETRY';
  static const String connectivityLost = 'CONNECTIVITY_LOST';
  static const String connectivityRestored = 'CONNECTIVITY_RESTORED';
  static const String logout = 'LOGOUT';
  static const String appResumed = 'APP_RESUMED';
  static const String appPaused = 'APP_PAUSED';
  static const String appTerminated = 'APP_TERMINATED';
  static const String syncQueueDrained = 'SYNC_QUEUE_DRAINED';
  static const String dedupScan = 'STAFF_DIRECT_DEDUP_SCAN';
}
