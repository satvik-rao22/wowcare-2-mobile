import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/message_visibility_helper.dart';

// ─── Lightweight DTO for Firestore message data ──────────────────────────────

/// Represents a message document stored in Firestore under
/// orgs/{org}/schools/{school}/conversations/{conv}/messages/{msg}.
///
/// The backend writes this when a message is sent/edited/deleted.
/// Flutter only reads it — never writes directly.
class MessageFirestoreItem {
  const MessageFirestoreItem({
    required this.code,
    required this.conversationCode,
    required this.senderCode,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.messageType,
    required this.sentAt,
    required this.organizationCode,
    required this.schoolCode,
    required this.isDeleted,
    required this.isEdited,
    required this.reactions,
    this.senderAvatarUrl,
    this.isPrivate = false,
    this.editedAt,
    this.deletedAt,
    this.deletedPlaceholder,
    this.threadParentCode,
    this.threadParentSenderCode,
    this.threadParentSenderName,
    this.threadParentText,
    this.privateParentUserCode,
    this.deliveredTo = const {},
    this.readBy = const {},
  });

  final String code;
  final String conversationCode;
  final String senderCode;
  final String senderName;
  final String senderRole;
  final String? senderAvatarUrl;
  final String text;
  final String messageType;
  final DateTime sentAt;
  final String organizationCode;
  final String schoolCode;
  final bool isDeleted;
  final bool isEdited;
  final bool isPrivate;
  final Map<String, String> reactions;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final String? deletedPlaceholder;
  final String? threadParentCode;
  final String? threadParentSenderCode;
  final String? threadParentSenderName;
  final String? threadParentText;
  final String? privateParentUserCode;

  /// `{userCode: deliveredAt}` / `{userCode: readAt}` maps written by the
  /// backend directly on the message doc — mirrors the web app's
  /// `deliveredTo`/`readBy` fields (firestore-messaging.service.ts).
  final Map<String, DateTime> deliveredTo;
  final Map<String, DateTime> readBy;

  factory MessageFirestoreItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return MessageFirestoreItem(
      code: d['code'] as String? ?? doc.id,
      conversationCode: d['conversationCode'] as String? ?? '',
      senderCode: d['senderCode'] as String? ?? '',
      senderName: d['senderName'] as String? ?? '',
      senderRole: d['senderRole'] as String? ?? 'PARENT',
      senderAvatarUrl: d['senderAvatarUrl'] as String?,
      text: d['text'] as String? ?? '',
      messageType: d['messageType'] as String? ?? 'TEXT',
      sentAt: _parseTimestamp(d['sentAt']) ?? DateTime.now(),
      organizationCode: d['organizationCode'] as String? ?? '',
      schoolCode: d['schoolCode'] as String? ?? '',
      isDeleted: d['isDeleted'] as bool? ?? false,
      isEdited: d['isEdited'] as bool? ?? false,
      // ppc-presence is authoritative (backend invariant isPrivate = ppc != null)
      // and takes precedence over the `isPrivate`/`private` booleans, which can
      // be false even when ppc is set — see message_model.dart.
      isPrivate:
          ((d['privateParentUserCode'] as String?)?.trim().isNotEmpty ??
              false) ||
          (d['isPrivate'] as bool? ?? false) ||
          (d['private'] as bool? ?? false),
      reactions: _parseReactions(d['reactions']),
      editedAt: _parseTimestamp(d['editedAt']),
      deletedAt: _parseTimestamp(d['deletedAt']),
      deletedPlaceholder: d['deletedPlaceholder'] as String?,
      threadParentCode: d['threadParentCode'] as String?,
      threadParentSenderCode: d['threadParentSenderCode'] as String?,
      threadParentSenderName: d['threadParentSenderName'] as String?,
      threadParentText: d['threadParentText'] as String?,
      privateParentUserCode: d['privateParentUserCode'] as String?,
      deliveredTo: _parseReceiptMap(d['deliveredTo']),
      readBy: _parseReceiptMap(d['readBy']),
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: code,
      code: code,
      conversationCode: conversationCode,
      senderCode: senderCode,
      senderName: senderName,
      senderRole: ParticipantRole.fromApiString(senderRole),
      senderAvatarUrl: senderAvatarUrl,
      text: text,
      messageType: MessageType.fromApiString(messageType),
      status: MessageStatus.sent,
      sentAt: sentAt,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      isPrivate: isPrivate,
      isEdited: isEdited,
      isDeleted: isDeleted,
      deletedPlaceholder: deletedPlaceholder,
      editedAt: editedAt,
      deletedAt: deletedAt,
      reactions: reactions,
      readReceipts: _buildReadReceipts(),
      threadParentCode: threadParentCode,
      threadParentSenderCode: threadParentSenderCode,
      threadParentSenderName: threadParentSenderName,
      threadParentText: threadParentText,
      privateParentUserCode: privateParentUserCode,
    );
  }

  /// One [ReadReceiptEntity] per recipient (excluding the sender), merging
  /// [deliveredTo] / [readBy] — a read implies delivered too, matching the
  /// web app's `convertToBackendMessageFormat` derivation.
  ///
  /// Firestore's `deliveredTo`/`readBy` maps are keyed by userCode only — no
  /// display name is available at this layer, so [ReadReceiptEntity.userName]
  /// is left blank rather than defaulting to the code; UI must show a
  /// generic label instead of a blank/raw-code name (see
  /// MessageStatusDialog / MessageBubble's recipient list).
  List<ReadReceiptEntity> _buildReadReceipts() {
    final recipientCodes = {...deliveredTo.keys, ...readBy.keys}
      ..remove(senderCode);
    return recipientCodes
        .map(
          (userCode) => ReadReceiptEntity(
            messageCode: code,
            userCode: userCode,
            userName: '',
            deliveredAt: deliveredTo[userCode] ?? readBy[userCode],
            readAt: readBy[userCode],
          ),
        )
        .toList();
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) {
      return value > 1e12
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return null;
  }

  static Map<String, String> _parseReactions(dynamic value) {
    if (value is! Map) return const {};
    return Map<String, String>.fromEntries(
      value.entries
          .where((e) => e.key is String && e.value is String)
          .map((e) => MapEntry(e.key as String, e.value as String)),
    );
  }

  static Map<String, DateTime> _parseReceiptMap(dynamic value) {
    if (value is! Map) return const {};
    final result = <String, DateTime>{};
    value.forEach((key, raw) {
      if (key is! String) return;
      final parsed = _parseTimestamp(raw);
      if (parsed != null) result[key] = parsed;
    });
    return result;
  }
}

// ─── Abstract contract ───────────────────────────────────────────────────────

abstract class MessageRealtimeDataSource {
  /// Stream of messages for a conversation, ordered oldest-first.
  ///
  /// Returns an empty stream if the messages subcollection does not exist in
  /// Firestore — callers must handle this gracefully and fall back to the API.
  ///
  /// [limit] — how many recent messages to stream (prevents unbounded reads).
  Stream<List<MessageEntity>> watchMessages({
    required String organizationCode,
    required String schoolCode,
    required String conversationCode,
    required String currentUserCode,
    required bool isStaff,
    required bool isAdmin,
    int limit = 100,
  });
}

// ─── Firebase implementation ─────────────────────────────────────────────────

class FirebaseMessageRealtimeDataSource implements MessageRealtimeDataSource {
  const FirebaseMessageRealtimeDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Stream<List<MessageEntity>> watchMessages({
    required String organizationCode,
    required String schoolCode,
    required String conversationCode,
    required String currentUserCode,
    required bool isStaff,
    required bool isAdmin,
    int limit = 10000,
  }) {
    return _watchWithRetry(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      conversationCode: conversationCode,
      currentUserCode: currentUserCode,
      isStaff: isStaff,
      isAdmin: isAdmin,
      limit: limit,
    );
  }

  /// Subscribes to the Firestore messages collection and silently retries on
  /// `permission-denied` with exponential backoff.
  ///
  /// Why StreamController instead of async*:
  /// FlutterFire's `receiveGuardedBroadcastStream` delivers the
  /// `permission-denied` error through the platform-channel zone — it arrives
  /// on the stream's `onError` callback, NOT as a rethrown exception at
  /// `await for`. A try-catch around `await for` therefore never intercepts it.
  /// Attaching `onError` directly to `.listen()` is the only reliable
  /// interception point for Firestore stream errors.
  Stream<List<MessageEntity>> _watchWithRetry({
    required String organizationCode,
    required String schoolCode,
    required String conversationCode,
    required String currentUserCode,
    required bool isStaff,
    required bool isAdmin,
    required int limit,
  }) {
    // Backoff seconds per retry attempt.
    // A new STAFF_DIRECT conversation is written to Firestore asynchronously
    // by the backend after the REST API returns — Flutter can race ahead and
    // subscribe before the conversation document (and its security-rule anchor)
    // exists. Four retries cover the typical propagation window.
    const retryDelays = [2, 4, 8, 16];

    final controller = StreamController<List<MessageEntity>>();
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? inner;

    // Declared late so _retryOrForward can capture it before the body is assigned.
    late void Function(int attempt) subscribe;

    void retryOrForward(Object error, int attempt) {
      if (controller.isClosed) return;
      if (error is FirebaseException &&
          error.code == 'permission-denied' &&
          attempt < retryDelays.length) {
        Future.delayed(
          Duration(seconds: retryDelays[attempt]),
          () {
            if (!controller.isClosed) subscribe(attempt + 1);
          },
        );
      } else {
        controller.addError(error);
        controller.close();
      }
    }

    subscribe = (int attempt) {
      inner?.cancel();
      // runZonedGuarded wraps the subscription so that permission-denied errors
      // thrown into the Dart zone by FlutterFire's receiveGuardedBroadcastStream
      // are caught here instead of escaping to the root isolate zone and being
      // logged as "Unhandled Exception" at dart_vm_initializer.cc.
      runZonedGuarded(
        () {
          inner = firestore
              .collection('orgs')
              .doc(organizationCode)
              .collection('schools')
              .doc(schoolCode)
              .collection('conversations')
              .doc(conversationCode)
              .collection('messages')
              // Deliberately no `where('isDeleted', ...)` here — combining it with
              // orderBy('sentAt') requires a Firestore composite index, and the
              // web app's equivalent query (firestore-messaging.service.ts) doesn't
              // filter either. Deleted messages still flow through so the UI can
              // render the deleted-placeholder treatment instead of the row simply
              // never updating on other participants' devices.
              .orderBy('sentAt', descending: false)
              .limitToLast(limit)
              .snapshots()
              .listen(
                (snapshot) {
                  if (controller.isClosed) return;
                  // Using `docs` (the full current window) rather than
                  // `docChanges` (delta only). With `docChanges`, subsequent
                  // Firestore events after the initial snapshot only carry the
                  // 1–2 changed documents, so the cubit would replace its entire
                  // message list with just the delta — losing all previous
                  // messages. `docs` always delivers the complete set currently
                  // matching the query, which is what the cubit expects.
                  controller.add(
                    snapshot.docs
                        .map((doc) => MessageFirestoreItem.fromFirestore(doc))
                        .map((item) => item.toEntity())
                        .where(
                          (entity) => VisibilityHelper.canViewMessage(
                            entity,
                            currentUserCode,
                            isStaff,
                            isAdmin,
                          ),
                        )
                        .toList(),
                  );
                },
                onError: (Object error) => retryOrForward(error, attempt),
                onDone: () {
                  if (!controller.isClosed) controller.close();
                },
                cancelOnError: true,
              );
        },
        (Object error, StackTrace _) => retryOrForward(error, attempt),
      );
    };

    controller.onListen = () => subscribe(0);
    controller.onCancel = () {
      inner?.cancel();
      inner = null;
    };

    return controller.stream;
  }
}
