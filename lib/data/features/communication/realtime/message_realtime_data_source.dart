import 'dart:developer';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/firebase/firebase_auth_service.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/domain/features/communication/entities/message_visibility_helper.dart';
import 'package:wowcare/domain/features/communication/entities/reaction_entry.dart';

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
    this.attachments = const [],
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
  final List<ReactionEntry> reactions;
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

  /// Attachments written on the message doc by the backend (fileUrl/mimeType/...), so a
  /// live-received image/file renders immediately instead of only after a REST refetch.
  final List<AttachmentEntity> attachments;

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
      sentAt: _parseTimestamp(d['sentAt']) ?? AppTime.nowUtc(),
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
      // The backend writes the quoted-message context under `parent*` keys
      // (parentMessageCode/parentSenderCode/parentSenderName/parentText). Reading
      // the old `threadParent*` names left these null, so a reply arriving live
      // showed no quote bubble until a REST refresh. Read `parent*` first, keep
      // `threadParent*` as a fallback for any legacy docs.
      threadParentCode:
          (d['parentMessageCode'] ?? d['threadParentCode']) as String?,
      threadParentSenderCode:
          (d['parentSenderCode'] ?? d['threadParentSenderCode']) as String?,
      threadParentSenderName:
          (d['parentSenderName'] ?? d['threadParentSenderName']) as String?,
      threadParentText: (d['parentText'] ?? d['threadParentText']) as String?,
      privateParentUserCode: d['privateParentUserCode'] as String?,
      deliveredTo: _parseReceiptMap(d['deliveredTo']),
      readBy: _parseReceiptMap(d['readBy']),
      attachments: _parseAttachments(
        d['attachments'],
        d['code'] as String? ?? doc.id,
        d['conversationCode'] as String? ?? '',
        d['senderCode'] as String? ?? '',
        _parseTimestamp(d['sentAt']) ?? AppTime.nowUtc(),
      ),
    );
  }

  /// Parse the backend's Firestore attachment array into [AttachmentEntity]s.
  ///
  /// Two things this used to get wrong, both invisible until a message with
  /// an attachment arrived over the LIVE stream while its file was still
  /// backend-side processing (the common case — a message doc can be
  /// written before the attachment finishes): it dropped the attachment
  /// entirely whenever `fileUrl` was still empty (never mind that the
  /// REST DTO's `AttachmentEntityDto.fromJson` never does this — it just
  /// keeps `fileUrl: ''`), which zeroed out `MessageEntity.hasAttachments`
  /// and skipped the whole image UI for that message — no placeholder, no
  /// retry, nothing, unlike history loaded via REST where the same
  /// still-processing attachment renders the "processing"/retry state via
  /// `AttachmentUrlResolver`. It also never read the attachment's actual
  /// `code` (the document-service asset code REST's `AttachmentEntityDto`
  /// reads from the very same field) — it fabricated `code` from the
  /// messaging-service's numeric `attachmentId` instead, which
  /// `resolveAttachmentUrl`'s code-based polling can't do anything with.
  /// Keep the attachment even with an empty `fileUrl`, and read the real
  /// asset code, so a live-arriving still-processing image resolves via the
  /// same retry path REST-loaded history already relies on — instead of
  /// only ever recovering via a manual pull-to-refresh.
  static List<AttachmentEntity> _parseAttachments(
    dynamic raw,
    String messageCode,
    String conversationCode,
    String senderCode,
    DateTime sentAt,
  ) {
    if (raw is! List) return const [];
    final result = <AttachmentEntity>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = item.cast<String, dynamic>();
      final fileUrl = (m['fileUrl'] as String?) ?? '';
      final mimeType = m['mimeType'] as String? ?? 'application/octet-stream';
      final rawId = m['attachmentId'];
      final assetCode = (m['code'] as String?)?.trim() ?? '';
      result.add(
        AttachmentEntity(
          code: assetCode.isNotEmpty ? assetCode : (rawId?.toString() ?? ''),
          messageCode: messageCode,
          conversationCode: conversationCode,
          fileName: m['fileName'] as String? ?? '',
          fileUrl: fileUrl,
          mimeType: mimeType,
          fileSizeBytes: (m['fileSizeBytes'] as num?)?.toInt() ?? 0,
          attachmentType: AttachmentType.fromMimeType(mimeType),
          thumbnailUrl: m['thumbnailUrl'] as String?,
          uploadedBy: senderCode,
          uploadedAt: sentAt,
          attachmentId: rawId is int ? rawId : int.tryParse('$rawId'),
        ),
      );
    }
    return result;
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
      attachments: attachments,
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

  /// The backend writes `reactions` as an ARRAY of `{userCode, emoji, timestamp}`
  /// objects (a message can carry many reactions per user), matching the REST
  /// payload and the web client. Map it to a flat `List<ReactionEntry>`
  /// preserving EVERY {userCode, emoji} pair — a user may hold multiple distinct
  /// emojis. A legacy `{userCode: emoji}` map shape is still tolerated by
  /// expanding each entry to a [ReactionEntry].
  static List<ReactionEntry> _parseReactions(dynamic value) {
    final result = <ReactionEntry>[];
    if (value is List) {
      for (final r in value) {
        if (r is Map) {
          final userCode = r['userCode']?.toString();
          final emoji = r['emoji']?.toString();
          if (userCode != null &&
              userCode.isNotEmpty &&
              emoji != null &&
              emoji.isNotEmpty) {
            result.add(ReactionEntry(userCode: userCode, emoji: emoji));
          }
        }
      }
    } else if (value is Map) {
      value.forEach((k, v) {
        if (k is String && v is String && k.isNotEmpty && v.isNotEmpty) {
          result.add(ReactionEntry(userCode: k, emoji: v));
        }
      });
    }
    return result;
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

    StreamSubscription<User?>? authWaitSub;

    void retryOrForward(Object error, int attempt) {
      if (controller.isClosed) return;
      final isPermissionDenied =
          error is FirebaseException && error.code == 'permission-denied';
      if (isPermissionDenied) {
        // Proactively (re)establish Firebase auth for the CURRENT user — the session
        // may be stale (account/persona switch) or expired. signIn() is deduped and
        // no-ops when already correct, so calling it here is cheap and makes an
        // authStateChanges event fire so the retry below reconnects.
        unawaited(serviceLocator<FirebaseAuthService>().signIn());
      }
      if (attempt < retryDelays.length) {
        // Retry on ANY error, not just permission-denied — a transient
        // network blip ('unavailable'), a brief 'deadline-exceeded', or
        // similar was previously treated as terminal (addError + close),
        // permanently killing this thread's live sync with no way back
        // short of leaving and reopening the screen (pull-to-refresh only
        // masks it via the REST fallback, one time). Standard exponential
        // backoff applies uniformly; only permission-denied gets the extra
        // re-auth nudge above.
        Future.delayed(Duration(seconds: retryDelays[attempt]), () {
          if (!controller.isClosed) subscribe(attempt + 1);
        });
      } else if (isPermissionDenied) {
        // Backoff exhausted — Firebase auth hasn't completed yet. Wait for
        // an authStateChanges event with a signed-in user, then restart.
        // This covers the race where the app opens the Firestore listener
        // before signInWithCustomToken finishes.
        authWaitSub?.cancel();
        authWaitSub = FirebaseAuth.instance.authStateChanges().listen((user) {
          if (controller.isClosed) {
            authWaitSub?.cancel();
            return;
          }
          if (user != null) {
            authWaitSub?.cancel();
            authWaitSub = null;
            subscribe(0);
          }
        });
      } else {
        // Non-auth error and backoff exhausted — genuinely give up; the
        // cubit's REST fallback still works either way.
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
      runZonedGuarded(() {
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
                // Parse each message defensively: a single unparseable doc (e.g. an
                // unexpected attachment shape) must NOT throw out of the snapshot
                // handler — with cancelOnError the whole thread's live sync would die
                // and stay dead while that doc remains in the query window. Skip the
                // bad one and keep delivering the rest.
                final entities = <MessageEntity>[];
                for (final doc in snapshot.docs) {
                  try {
                    final entity = MessageFirestoreItem.fromFirestore(
                      doc,
                    ).toEntity();
                    if (VisibilityHelper.canViewMessage(
                      entity,
                      currentUserCode,
                      isStaff,
                      isAdmin,
                    )) {
                      entities.add(entity);
                    }
                  } catch (e, st) {
                    log(
                      'Skipped unparseable message ${doc.id}: $e',
                      name: 'MessageRealtime',
                      error: e,
                      stackTrace: st,
                    );
                  }
                }
                controller.add(entities);
              },
              onError: (Object error) => retryOrForward(error, attempt),
              onDone: () {
                if (!controller.isClosed) controller.close();
              },
              cancelOnError: true,
            );
      }, (Object error, StackTrace _) => retryOrForward(error, attempt));
    };

    controller.onListen = () => subscribe(0);
    controller.onCancel = () {
      inner?.cancel();
      inner = null;
      authWaitSub?.cancel();
      authWaitSub = null;
    };

    return controller.stream;
  }
}
