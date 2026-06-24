import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';

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
      isPrivate: d['isPrivate'] as bool? ?? false,
      reactions: _parseReactions(d['reactions']),
      editedAt: _parseTimestamp(d['editedAt']),
      deletedAt: _parseTimestamp(d['deletedAt']),
      deletedPlaceholder: d['deletedPlaceholder'] as String?,
      threadParentCode: d['threadParentCode'] as String?,
      threadParentSenderCode: d['threadParentSenderCode'] as String?,
      threadParentSenderName: d['threadParentSenderName'] as String?,
      threadParentText: d['threadParentText'] as String?,
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
    int limit = 100,
  }) {
    return firestore
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
        .map(
          (snapshot) => snapshot.docChanges
              // `removed` only means the doc fell out of the
              // `limitToLast(limit)` window (e.g. an older message pushed
              // out by a new one) — it must NOT be treated as "delete this
              // from local history," or paginated/cached older messages
              // would be wiped the moment the thread gets busy. Only
              // `added`/`modified` represent an actual content change worth
              // merging.
              .where((change) => change.type != DocumentChangeType.removed)
              .map((change) => MessageFirestoreItem.fromFirestore(change.doc))
              .map((item) => item.toEntity())
              .toList(),
        );
  }
}
